import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 70),
        receiveTimeout: const Duration(seconds: 90),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  String? get token {
    final authHeader = _dio.options.headers['Authorization'];
    if (authHeader is String && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }
    return null;
  }

  String get baseUrl => _dio.options.baseUrl;

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ---------------------------------------------------------------------------
  // Response unwrapping helpers
  // ---------------------------------------------------------------------------

  /// Extract the list/object payload from the standard
  /// `{ success, data: [...] }` envelope (and various other shapes).
  dynamic _handleResponseData(Response response) {
    final d = response.data;
    if (d is List) return d;
    if (d is Map) {
      for (final key in [
        'data',
        'result',
        'results',
        'list',
        'items',
        'attendances',
        'attendance',
        'records',
        'grades',
        'notes',
        'exams',
        'absences',
        'sessions',
      ]) {
        if (d.containsKey(key) && d[key] is List) {
          debugPrint(
              '[API] Extracted list from key "$key" (${(d[key] as List).length} items)');
          return d[key];
        }
      }
      if (d.containsKey('data')) return d['data'];
    }
    return d;
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION  –  /api/auth/*
  // ---------------------------------------------------------------------------

  /// POST /auth/login → { token, user }
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      final tok = data['token'] ?? data['access_token'];
      if (tok != null) setToken(tok);
      return data;
    }
    throw Exception('Login failed: ${response.statusCode}');
  }

  /// POST /auth/fcm-token — register device push token
  Future<void> registerFcmToken(String fcmToken) async {
    try {
      await _dio.post('/auth/fcm-token', data: {'fcmToken': fcmToken});
    } catch (e) {
      // Non-fatal — don't block login if this fails
      debugPrint('[ApiService] registerFcmToken failed: $e');
    }
  }

  /// GET /auth/me → UserModel
  Future<UserModel> getProfile() async {
    final response = await _dio.get('/auth/me');
    if (response.statusCode == 200) {
      final data = _handleResponseData(response);
      return UserModel.fromJson(data is Map<String, dynamic> ? data : response.data);
    }
    throw Exception('Failed to load profile');
  }

  /// PUT /auth/update-password → { success, token, message }
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.put('/auth/update-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update password: ${response.statusCode}');
    }
    // If the server returns a fresh token, re-apply it.
    final newToken = response.data?['token'];
    if (newToken != null) setToken(newToken);
  }

  // No generic profile-update endpoint exists on this backend.
  // Callers that need to update fields should use updatePassword or
  // contact the admin-side staff/student routes.
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    // Graceful degradation: return current profile unchanged.
    debugPrint('[API] updateProfile: no generic profile-update endpoint – returning current profile');
    return getProfile();
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD  –  /api/dashboard/*
  // ---------------------------------------------------------------------------

  /// GET /dashboard/stats → { success, data: statistics }
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard/stats');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } catch (e) {
      debugPrint('[API] getDashboardStats failed: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getDashboardActivities() async {
    try {
      final results = await Future.wait([
        getPosts().catchError((_) => <PostModel>[]),
        getAbsences('me').catchError((_) => <AttendanceRecord>[]),
        getGrades('me').catchError((_) => <GradeModel>[]),
      ]);

      final List<Map<String, dynamic>> activities = [];

      for (var post in results[0] as List<PostModel>) {
        activities.add({
          'id': post.id,
          'type': 'news',
          'title': post.title.isNotEmpty ? post.title : 'Actualité',
          'content': post.content,
          'date': post.date,
          'icon_type': 'post',
        });
      }
      for (var abs in results[1] as List<AttendanceRecord>) {
        activities.add({
          'id': abs.id,
          'type': 'absence',
          'title': 'Absence / Retard',
          'content': '${abs.subjectName ?? "Session"} - ${abs.status}',
          'date': abs.date,
          'icon_type': 'absence',
        });
      }
      for (var grade in results[2] as List<GradeModel>) {
        activities.add({
          'id': grade.id,
          'type': 'grade',
          'title': 'Nouvelle Note',
          'content': '${grade.subject}: ${grade.grade}/${grade.maxGrade}',
          'date': grade.date,
          'icon_type': 'grade',
        });
      }

      activities.sort((a, b) {
        try {
          return DateTime.parse(b['date'] as String)
              .compareTo(DateTime.parse(a['date'] as String));
        } catch (_) {
          return (b['date'] as String).compareTo(a['date'] as String);
        }
      });

      return activities.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  // Grade evolution is not a dedicated backend endpoint.
  // We derive it from the student's notes instead of calling a missing route.
  Future<List<Map<String, dynamic>>> getGradeEvolution({
    required String studentId,
    required String year,
    required String semester,
  }) async {
    try {
      final grades = await getGrades(studentId);
      return grades
          .map((g) => {
                'subject': g.subject,
                'grade': g.grade,
                'maxGrade': g.maxGrade,
                'date': g.date,
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // NEWS / FEED  –  /api/news/*
  // ---------------------------------------------------------------------------

  /// GET /news → [PostModel]
  Future<List<PostModel>> getPosts() async {
    final response = await _dio.get('/news');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((json) => PostModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load news');
  }

  /// POST /news/:id/like
  Future<bool> likePost(String id) async {
    final response = await _dio.post('/news/$id/like');
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// POST /news/:id/comments  (backend field: content)
  Future<CommentModel> addComment(String postId, String content) async {
    final response = await _dio.post('/news/$postId/comments', data: {
      'content': content,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _handleResponseData(response);
      return CommentModel.fromJson(data);
    }
    throw Exception('Failed to add comment');
  }

  /// DELETE /news/:id  (fixed: was /posts/:id)
  Future<bool> deletePost(String id) async {
    final response = await _dio.delete('/news/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // updatePost has no matching backend endpoint – graceful no-op.
  Future<PostModel> updatePost(String id, Map<String, dynamic> data) async {
    throw UnsupportedError('updatePost: no backend endpoint available');
  }

  // ---------------------------------------------------------------------------
  // STUDENTS  –  /api/students/*
  // ---------------------------------------------------------------------------

  /// GET /students?classe=... → Filter students by class
  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      final response = await _dio.get('/students', queryParameters: {
        'classe': classId,
        'limit': 100, // Make sure we grab everyone
      });
      if (response.statusCode == 200) {
        final List data = _handleResponseData(response);
        return data.map((s) => StudentModel.fromJson(s as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load students for class');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StudentModel>> getChildren() async {
    try {
      // For a logged-in student/parent, the space endpoint gives student info.
      final response = await _dio.get('/payments/student/me/space');
      if (response.statusCode == 200) {
        final dataMap = _handleResponseData(response);
        if (dataMap is Map) {
          final studentJson = dataMap['student'];
          if (studentJson != null) {
            return [StudentModel.fromJson(studentJson as Map<String, dynamic>)];
          }
        } else if (dataMap is List) {
          return dataMap
              .map((s) => StudentModel.fromJson(s as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
      throw Exception('Failed to load children data');
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // GRADES / NOTES  –  /api/notes/* and /api/exams/*
  // ---------------------------------------------------------------------------

  /// Fetches grades from both /notes/my-results and /exams/my-results,
  /// merges and deduplicates them.
  Future<List<GradeModel>> getGrades(String studentId) async {
    List<GradeModel> allGrades = [];
    final endpoints = ['/notes/my-results', '/exams/my-results'];

    for (final endpoint in endpoints) {
      try {
        final response = await _dio.get(endpoint);
        if (response.statusCode == 200) {
          final raw = _handleResponseData(response);
          if (raw is List && raw.isNotEmpty) {
            final parsed = raw
                .map((json) {
                  try {
                    return GradeModel.fromJson(json as Map<String, dynamic>);
                  } catch (e) {
                    debugPrint('[Grades] parse error: $e');
                    return null;
                  }
                })
                .whereType<GradeModel>()
                .toList();
            allGrades.addAll(parsed);
          }
        }
      } catch (e) {
        debugPrint('[Grades] $endpoint failed: $e');
      }
    }

    allGrades.sort((a, b) => b.date.compareTo(a.date));
    final seen = <String>{};
    allGrades = allGrades.where((g) => g.id.isEmpty || seen.add(g.id)).toList();
    return allGrades;
  }

  /// GET /notes/sheets → [NoteSheet] for teacher
  Future<List<Map<String, dynamic>>> getNoteSheets({
    String? classId,
    String? subjectId,
    String? semester,
  }) async {
    final response = await _dio.get('/notes/sheets', queryParameters: {
      if (classId != null) 'classId': classId,
      if (subjectId != null) 'subjectId': subjectId,
      if (semester != null) 'semester': semester,
    });
    if (response.statusCode == 200) {
      final raw = _handleResponseData(response);
      if (raw is List) return List<Map<String, dynamic>>.from(raw);
    }
    return [];
  }

  /// POST /notes/save → save a note sheet (teacher)
  Future<bool> saveNotes(Map<String, dynamic> noteSheetData) async {
    final response = await _dio.post('/notes/save', data: noteSheetData);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// GET /exams/:id/results → exam results list
  Future<List<Map<String, dynamic>>> getExamResults(String examId) async {
    final response = await _dio.get('/exams/$examId/results');
    if (response.statusCode == 200) {
      final raw = _handleResponseData(response);
      if (raw is List) return List<Map<String, dynamic>>.from(raw);
    }
    return [];
  }

  /// POST /exams/:id/results → { results: [{studentId, score}] }
  Future<bool> saveExamResults(
      String examId, List<Map<String, dynamic>> results) async {
    final response = await _dio.post(
      '/exams/$examId/results',
      data: {'results': results},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ---------------------------------------------------------------------------
  // HOMEWORK / ASSIGNMENTS  –  /api/assignments/*
  // ---------------------------------------------------------------------------

  Future<List<HomeworkModel>> getHomework(String studentId) async {
    final response = await _dio.get('/assignments');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((json) => HomeworkModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load homework');
  }

  Future<List<HomeworkModel>> getExams(String studentId) async {
    final response = await _dio.get('/exams');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((json) {
        return HomeworkModel.fromJson(json).copyWith(type: 'exam');
      }).toList();
    }
    throw Exception('Failed to load exams');
  }

  Future<HomeworkModel> updateHomeworkStatus(
      String id, String studentId, HomeworkStatus status,
      {String? filePath}) async {
    if (status == HomeworkStatus.done) {
      final formData = FormData();
      formData.fields
          .add(const MapEntry('text', 'Terminé depuis l\'application'));

      if (filePath != null && filePath.isNotEmpty) {
        final fileName = filePath.split('/').last;
        formData.files.add(MapEntry(
            'files', await MultipartFile.fromFile(filePath, filename: fileName)));
      }

      final response = await _dio.post('/assignments/$id/submit', data: formData);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        try {
          return HomeworkModel.fromJson(response.data);
        } catch (_) {
          return HomeworkModel(
              id: id,
              subject: '',
              title: '',
              description: '',
              dueDate: '',
              status: HomeworkStatus.done);
        }
      }
    } else {
      // inProgress is local-only state; no backend endpoint exists.
      return HomeworkModel(
          id: id,
          subject: '',
          title: '',
          description: '',
          dueDate: '',
          status: status);
    }
    throw Exception('Failed to update homework status');
  }

  Future<void> addHomework({
    required String title,
    required String description,
    required String classId,
    required String subjectId,
    required DateTime deadline,
    String? filePath,
    String? fileName,
  }) async {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'classe': classId,
      'subject': subjectId,
      'deadline': deadline.toIso8601String(),
    };
    if (filePath != null && fileName != null) {
      map['files'] = await MultipartFile.fromFile(filePath, filename: fileName);
    }
    final formData = FormData.fromMap(map);
    final response = await _dio.post('/assignments', data: formData);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add homework');
    }
  }

  Future<void> addExam({
    required String title,
    required String description,
    required String classId,
    required String subjectId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String type,
  }) async {
    final data = {
      'title': title,
      'description': description,
      'classe': classId,
      'subject': subjectId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
    };
    
    final response = await _dio.post('/exams', data: data);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add exam');
    }
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE  –  /api/attendances/*
  // ---------------------------------------------------------------------------

  /// GET /attendances/me → student's own absences
  Future<List<AttendanceRecord>> getAbsences(String studentId) async {
    final endpoints = ['/attendances/me', '/attendances/student/me'];

    for (final endpoint in endpoints) {
      try {
        final response = await _dio.get(endpoint);
        if (response.statusCode == 200) {
          final raw = _handleResponseData(response);
          if (raw is List) {
            return raw
                .map((json) {
                  try {
                    return AttendanceRecord.fromJson(
                        json as Map<String, dynamic>);
                  } catch (e) {
                    debugPrint('[Absences] parse error: $e');
                    return null;
                  }
                })
                .whereType<AttendanceRecord>()
                .toList();
          }
        }
      } catch (e) {
        debugPrint('[Absences] $endpoint failed: $e');
      }
    }
    return [];
  }

  /// PUT /attendances/:id/justify  (multipart file upload)
  Future<AttendanceRecord?> submitJustification({
    required String attendanceId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    String reason = '',
    String? oldAttachmentUrl,
    void Function(int, int)? onProgress,
  }) async {
    MultipartFile? attachment;
    final hasFilePath = filePath != null && filePath.isNotEmpty;
    final hasFileBytes = fileBytes != null && fileBytes.isNotEmpty;

    if (hasFilePath || hasFileBytes) {
      final ext = fileName.split('.').last.toLowerCase();
      MediaType? mediaType;
      if (ext == 'pdf') {
        mediaType = MediaType('application', 'pdf');
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      }

      if (fileBytes != null && fileBytes.isNotEmpty) {
        attachment = MultipartFile.fromBytes(fileBytes,
            filename: fileName, contentType: mediaType);
      } else if (filePath != null && filePath.isNotEmpty) {
        attachment = await MultipartFile.fromFile(filePath,
            filename: fileName, contentType: mediaType);
      }
    }

    final payload = <String, dynamic>{
      'reason': reason,
      'motif': reason,
      'justificationReason': reason,
      'justificationText': reason,
      'justifiedByStudent': true,
      'hasJustification': true,
      'isJustified': true,
    };

    final formDataMap = <String, dynamic>{};
    payload.forEach((k, v) => formDataMap[k] = v.toString());
    final formData = FormData.fromMap(formDataMap);

    if (attachment != null) {
      formData.files.add(MapEntry('attachment', attachment));
    } else if (oldAttachmentUrl != null && oldAttachmentUrl.isNotEmpty) {
      formData.fields.add(MapEntry('attachment', oldAttachmentUrl));
    }

    final response = await _dio.put(
      '/attendances/$attendanceId/justify',
      data: formData,
      onSendProgress: onProgress,
      options: Options(
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        contentType: 'multipart/form-data',
        headers: {'Accept': 'application/json'},
      ),
    );

    // Secondary JSON sync to ensure boolean/reason fields are persisted.
    try {
      await _dio.put('/attendances/$attendanceId', data: payload);
    } catch (e) {
      debugPrint('[API] Secondary JSON sync failed: $e');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data is Map) {
        if (response.data['success'] == false) {
          throw Exception(response.data['message'] ?? 'Erreur Serveur');
        }
        final responseData = response.data['data'];
        if (responseData != null && responseData is Map<String, dynamic>) {
          return AttendanceRecord.fromJson(responseData);
        }
      }
      return AttendanceRecord(
        id: attendanceId,
        date: '',
        status: 'absent',
        motif: reason,
        justifiedByStudent: true,
      );
    }
    return null;
  }

  /// POST /attendances/bulk
  /// Body: { date, classe, subject, schedule?, absences: [{student, status}] }
  Future<bool> bulkMarkAttendance({
    required String date,
    required String classeId,
    required String subjectId,
    String? scheduleId,
    required List<Map<String, String>> absences,
  }) async {
    final response = await _dio.post('/attendances/bulk', data: {
      'date': date,
      'classe': classeId,
      'subject': subjectId,
      if (scheduleId != null) 'schedule': scheduleId,
      'absences': absences,
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// GET /attendances?date=today → count of absent/late students recorded by this teacher today
  Future<int> getTodayAbsentCount() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await _dio.get('/attendances',
          queryParameters: {'date': today, 'limit': '500'});
      if (response.statusCode == 200) {
        final raw = response.data;
        final total = raw['total'];
        if (total != null) return (total as num).toInt();
        final data = raw['data'];
        if (data is List) return data.length;
      }
    } catch (e) {
      debugPrint('[API] getTodayAbsentCount failed: $e');
    }
    return 0;
  }

  /// GET /attendances?classe=&date=&includePresent=true → student-id → status map
  Future<Map<String, String>> getAttendanceForClassDate({
    required String classId,
    required String date,
    String? subjectId,
  }) async {
    try {
      final params = <String, dynamic>{
        'classe': classId,
        'date': date,
        'includePresent': 'true',
        'limit': '200',
        if (subjectId != null && subjectId.isNotEmpty) 'subject': subjectId,
      };
      final response = await _dio.get('/attendances', queryParameters: params);
      if (response.statusCode == 200) {
        final raw = response.data;
        final List items = (raw['data'] ?? raw['attendances'] ?? []) as List;
        final result = <String, String>{};
        for (final item in items) {
          final studentObj = item['student'];
          String? studentId;
          if (studentObj is Map) {
            studentId = (studentObj['_id'] ?? studentObj['id'])?.toString();
          } else {
            studentId = studentObj?.toString();
          }
          if (studentId != null && studentId.isNotEmpty) {
            result[studentId] = item['status']?.toString() ?? 'absent';
          }
        }
        return result;
      }
    } catch (e) {
      debugPrint('[API] getAttendanceForClassDate failed: $e');
    }
    return {};
  }

  /// GET /attendances/daily-report?classId=&date=
  Future<Map<String, dynamic>> getDailyAttendanceReport({
    required String classId,
    required String date,
  }) async {
    try {
      final response = await _dio.get('/attendances/daily-report',
          queryParameters: {'classId': classId, 'date': date});
      if (response.statusCode == 200) {
        final data = _handleResponseData(response);
        if (data is Map<String, dynamic>) return data;
      }
      return {};
    } catch (e) {
      debugPrint('[API] getDailyAttendanceReport failed: $e');
      return {};
    }
  }

  /// GET /attendances/class-schedule?classId=&date=
  Future<Map<String, dynamic>> getClassSchedule({
    required String classId,
    required String date,
  }) async {
    try {
      final response = await _dio.get('/attendances/class-schedule',
          queryParameters: {'classId': classId, 'date': date});
      if (response.statusCode == 200) {
        final data = _handleResponseData(response);
        if (data is Map<String, dynamic>) return data;
      }
      return {};
    } catch (e) {
      debugPrint('[API] getClassSchedule failed: $e');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // PAYMENTS  –  /api/payments/*
  // ---------------------------------------------------------------------------

  Future<List<PaymentModel>> getPayments() async {
    final response = await _dio.get('/payments/student/me/space');
    if (response.statusCode == 200) {
      final dynamic data = _handleResponseData(response);
      List history = [];
      String? globalStudentName;
      String? globalClassName;

      if (data is List) {
        history = data;
      } else if (data is Map) {
        debugPrint('[PaymentAPI] Top-level keys: ${data.keys.toList()}');

        void extractStudentInfo(Map s) {
          if (s['user'] is Map) {
            globalStudentName ??= s['user']['fullName']?.toString() ??
                s['user']['name']?.toString();
          }
          globalStudentName ??= s['fullName']?.toString() ?? s['name']?.toString();
          for (final key in ['class', 'classe', 'group']) {
            if (s[key] is Map) {
              globalClassName ??= (s[key] as Map)['name']?.toString() ??
                  (s[key] as Map)['label']?.toString();
            }
          }
          if (s['affectation'] is Map) {
            final aff = s['affectation'] as Map;
            for (final key in ['class', 'classe', 'group']) {
              if (aff[key] is Map) {
                globalClassName ??= (aff[key] as Map)['name']?.toString();
              }
            }
          }
          globalClassName ??=
              s['className']?.toString() ?? s['level']?.toString();
          if (globalClassName == null) {
            for (final key in ['classe', 'class']) {
              if (s[key] is String) {
                globalClassName ??= s[key].toString();
              }
            }
          }
        }

        if (data.containsKey('student') && data['student'] is Map) {
          extractStudentInfo(data['student'] as Map);
        }
        if (globalStudentName == null &&
            data.containsKey('user') &&
            data['user'] is Map) {
          globalStudentName = data['user']['fullName']?.toString() ??
              data['user']['name']?.toString();
        }
        for (final key in ['class', 'classe', 'group']) {
          if (data[key] is Map) {
            globalClassName ??= (data[key] as Map)['name']?.toString() ??
                (data[key] as Map)['label']?.toString();
          }
        }
        globalClassName ??= data['className']?.toString() ??
            data['level']?.toString() ??
            data['groupName']?.toString();

        if (data.containsKey('space') && data['space'] is Map) {
          final space = data['space'] as Map;
          history = space['history'] ??
              space['payments'] ??
              space['invoices'] ??
              space['dues'] ??
              space['scolarity'] ??
              [];
          if (globalStudentName == null &&
              space.containsKey('student') &&
              space['student'] is Map) {
            extractStudentInfo(space['student'] as Map);
          }
        }
        if (history.isEmpty) {
          history = data['history'] ??
              data['payments'] ??
              data['invoices'] ??
              data['scolarity'] ??
              data['dues'] ??
              [];
        }
        if (history.isEmpty &&
            data.containsKey('data') &&
            data['data'] is List) {
          history = data['data'];
        }
      }

      return history
          .map((json) {
            try {
              final payment = PaymentModel.fromJson(json);
              return PaymentModel(
                id: payment.id,
                month: payment.month,
                amount: payment.amount,
                status: payment.status,
                date: payment.date,
                invoiceUrl: payment.invoiceUrl,
                childIds: payment.childIds,
                invoiceNumber: payment.invoiceNumber,
                studentName: payment.studentName ?? globalStudentName,
                className: payment.className ?? globalClassName,
                paymentMethod: payment.paymentMethod,
                year: payment.year,
                paymentType: payment.paymentType,
              );
            } catch (e) {
              debugPrint('[PaymentAPI] parse error: $e');
              return null;
            }
          })
          .whereType<PaymentModel>()
          .toList();
    }
    throw Exception('Failed to load payments');
  }

  Future<String?> downloadInternalFile(String endpoint, String savePath) async {
    final response = await _dio.download(endpoint, savePath,
        onReceiveProgress: (count, total) {
      if (total != -1) {
        debugPrint(
            '[API] Download ${(count / total * 100).toStringAsFixed(0)}%');
      }
    });
    return response.statusCode == 200 ? savePath : null;
  }

  /// Returns the relative endpoint path to download a receipt/invoice.
  Future<String> downloadReceipt(String paymentId, String type) async {
    final normalizedType = type.toLowerCase();
    final category =
        (normalizedType.contains('invoice') || normalizedType.contains('scolarit'))
            ? 'invoices'
            : 'receipts';
    return '/payments/student/me/$category/$paymentId/download';
  }

  // ---------------------------------------------------------------------------
  // MESSAGING  –  /api/messages/*
  // ---------------------------------------------------------------------------

  /// GET /messages → [ChatThreadModel]
  Future<List<ChatThreadModel>> getChatThreads() async {
    final response = await _dio.get('/messages');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((json) => ChatThreadModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load messages');
  }

  /// GET /messages/:id → single message + its replies
  Future<List<ChatMessageModel>> getMessages(String threadId) async {
    final response = await _dio.get('/messages/$threadId');
    if (response.statusCode == 200) {
      final data = _handleResponseData(response);
      if (data is List) {
        return data.map((json) => ChatMessageModel.fromJson(json)).toList();
      }
      return [ChatMessageModel.fromJson(data)];
    }
    throw Exception('Failed to load messages');
  }

  /// POST /messages/:id/reply
  Future<ChatMessageModel> sendMessage(
      String threadId, String content, String type) async {
    final response = await _dio.post('/messages/$threadId/reply', data: {
      'content': content,
      'type': type,
    });
    if (response.statusCode == 201 || response.statusCode == 200) {
      return ChatMessageModel.fromJson(_handleResponseData(response));
    }
    throw Exception('Failed to send message');
  }

  // ---------------------------------------------------------------------------
  // TRANSPORT  –  /api/transports/*
  //
  // NOTE: The backend has NO real-time bus-location or trip-history endpoint.
  // These methods return empty/null values so screens degrade gracefully.
  // ---------------------------------------------------------------------------

  Future<BusLocationModel> getBusLocation(String studentId) async {
    try {
      final response = await _dio.get('/transports/location', queryParameters: {'studentId': studentId});
      if (response.data != null && response.data['data'] != null) {
        return BusLocationModel.fromJson(response.data['data']);
      }
      throw UnsupportedError('Real-time bus location is not available on this backend.');
    } catch (e) {
      debugPrint('[API] getBusLocation failed: $e');
      throw UnsupportedError(
          'Real-time bus location is not available on this backend.');
    }
  }

  Future<List<LocationHistoryRecord>> getLocationHistory(
      String studentId) async {
    try {
      final response = await _dio.get('/transports/history', queryParameters: {'studentId': studentId});
      if (response.data != null && response.data['data'] is List) {
        final List data = response.data['data'];
        return data.map((record) => LocationHistoryRecord.fromJson(record)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[API] getLocationHistory failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS  –  /api/notifications/*
  // ---------------------------------------------------------------------------

  /// GET /notifications
  Future<List<NotificationModel>> getNotifications({String? currentUserId}) async {
    final response = await _dio.get('/notifications', queryParameters: {'limit': 100});
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((json) => NotificationModel.fromJson(json, currentUserId: currentUserId)).toList();
    }
    throw Exception('Failed to load notifications');
  }

  /// GET /notifications/unread-count
  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      if (response.statusCode == 200) {
        final data = response.data;
        return (data['unreadCount'] ?? data['count'] ?? 0) as int;
      }
      return 0;
    } catch (e) {
      debugPrint('[API] getUnreadNotificationCount failed: $e');
      return 0;
    }
  }

  /// PUT /notifications/read  (marks one or all notifications as read)
  /// Pass [id] to mark a single one; omit to mark all.
  Future<void> markNotificationRead(String id) async {
    try {
      await _dio.put('/notifications/read', data: {'id': id});
    } catch (e) {
      debugPrint('[API] markNotificationRead failed: $e');
    }
  }

  /// PUT /notifications/read  (no body → marks all as read)
  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.put('/notifications/read');
    } catch (e) {
      debugPrint('[API] markAllNotificationsRead failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // EVENTS / CALENDAR  –  /api/events/*
  // ---------------------------------------------------------------------------

  /// GET /events
  Future<List<EventModel>> getEvents() async {
    final response = await _dio.get('/events');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((json) => EventModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load events');
  }

  /// GET /events  (calendar view – backend has no /calendar/events route;
  /// we call /events and filter client-side by month/year)
  Future<List<EventModel>> getCalendarEvents({
    required String studentId,
    required int month,
    required int year,
  }) async {
    try {
      final allEvents = await getEvents();
      return allEvents.where((e) {
        try {
          final dt = DateTime.parse(e.date);
          return dt.month == month && dt.year == year;
        } catch (_) {
          return true;
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// DELETE /notifications/:id
  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete('/notifications/$id');
    } catch (e) {
      debugPrint('[API] deleteNotification failed: $e');
    }
  }

  /// DELETE /notifications
  Future<void> deleteAllNotifications() async {
    try {
      await _dio.delete('/notifications');
    } catch (e) {
      debugPrint('[API] deleteAllNotifications failed: $e');
    }
  }

  /// GET /events/:id
  Future<EventModel> getEventDetails(String eventId) async {
    final response = await _dio.get('/events/$eventId');
    if (response.statusCode == 200) {
      return EventModel.fromJson(_handleResponseData(response));
    }
    throw Exception('Failed to load event details');
  }

  /// DELETE /events/:id
  Future<bool> deleteEvent(String eventId) async {
    final response = await _dio.delete('/events/$eventId');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// PUT /events/:id/respond
  /// Backend expects status: "going" | "not_going"
  /// We map any incoming value to the two valid backend values.
  Future<EventModel?> respondToEventNew(String eventId, String status) async {
    final backendStatus = _mapEventStatus(status);

    try {
      String? studentId;
      try {
        final children = await getChildren();
        if (children.isNotEmpty) studentId = children.first.id;
      } catch (_) {}

      final payload = <String, dynamic>{'status': backendStatus};
      if (studentId != null) {
        payload['studentId'] = studentId;
        payload['student_id'] = studentId;
      }

      final response = await _dio.put('/events/$eventId/respond', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          final eventData = data['data'] ?? data['event'] ?? data;
          if (eventData is Map && eventData.containsKey('id')) {
            try {
              return EventModel.fromJson(Map<String, dynamic>.from(eventData));
            } catch (_) {}
          }
        }
        // Fetch fresh copy so UI reflects persisted state.
        try {
          final fresh = await _dio.get('/events/$eventId');
          if (fresh.statusCode == 200) {
            final raw = fresh.data;
            final eventData =
                (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
            if (eventData is Map) {
              return EventModel.fromJson(Map<String, dynamic>.from(eventData));
            }
          }
        } catch (_) {}
      }
      return null;
    } catch (e) {
      debugPrint('[API] respondToEventNew failed: $e');
      return null;
    }
  }

  Future<bool> respondToEvent(String id, String response,
      {bool isPost = false}) async {
    try {
      String? studentId;
      try {
        final children = await getChildren();
        if (children.isNotEmpty) studentId = children.first.id;
      } catch (_) {}

      final payload = <String, dynamic>{
        'status': isPost ? response : _mapEventStatus(response),
      };
      if (studentId != null) {
        payload['studentId'] = studentId;
        payload['student_id'] = studentId;
      }

      // /news/:id/respond does not exist on the backend – skip for posts.
      if (isPost) {
        debugPrint('[API] respondToEvent: /news/:id/respond not available – skipping');
        return false;
      }

      final res = await _dio.put('/events/$id/respond', data: payload);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[API] respondToEvent failed: $e');
      return false;
    }
  }

  /// Maps frontend event status values to the two values the backend accepts.
  String _mapEventStatus(String status) {
    final s = status.toLowerCase();
    if (s == 'going' || s == 'yes' || s == 'attending' || s == 'present') {
      return 'going';
    }
    return 'not_going';
  }

  // ---------------------------------------------------------------------------
  // TIMETABLE / SCHEDULES  –  /api/schedules/*
  // ---------------------------------------------------------------------------

  /// GET /schedules/my-schedule-student  (student timetable)
  Future<List<TimetableSessionModel>> getTimetable(String studentId) async {
    final response = await _dio.get('/schedules/my-schedule-student');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((item) => _parseScheduleItem(item)).toList();
    }
    throw Exception('Failed to load timetable');
  }

  /// GET /schedules/my-schedule  (teacher timetable)
  Future<List<TimetableSessionModel>> getTeacherTimetable() async {
    final response = await _dio.get('/schedules/my-schedule');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((item) => _parseScheduleItem(item)).toList();
    }
    throw Exception('Failed to load teacher timetable');
  }

  TimetableSessionModel _parseScheduleItem(dynamic item) {
    final Map<String, dynamic> mapped = Map<String, dynamic>.from(item as Map);

    final dayRaw =
        (mapped['dayOfWeek'] ?? mapped['day'] ?? mapped['day_index'] ?? '')
            .toString()
            .toLowerCase();

    int dayIndex = 0;
    if (dayRaw == '1' || dayRaw.contains('mon') || dayRaw.contains('lun')) {
      dayIndex = 0;
    } else if (dayRaw == '2' ||
        dayRaw.contains('tue') ||
        dayRaw.contains('mar')) {
      dayIndex = 1;
    } else if (dayRaw == '3' ||
        dayRaw.contains('wed') ||
        dayRaw.contains('mer')) {
      dayIndex = 2;
    } else if (dayRaw == '4' ||
        dayRaw.contains('thu') ||
        dayRaw.contains('jeu')) {
      dayIndex = 3;
    } else if (dayRaw == '5' ||
        dayRaw.contains('fri') ||
        dayRaw.contains('ven')) {
      dayIndex = 4;
    } else if (dayRaw == '6' ||
        dayRaw.contains('sat') ||
        dayRaw.contains('sam')) {
      dayIndex = 5;
    } else if (dayRaw == '0' ||
        dayRaw.contains('sun') ||
        dayRaw.contains('dim')) {
      dayIndex = 6;
    } else if (int.tryParse(dayRaw) != null) {
      dayIndex = (int.parse(dayRaw) - 1).clamp(0, 5);
    } else {
      try {
        final dt = DateTime.parse(dayRaw);
        dayIndex = dt.weekday - 1;
      } catch (_) {}
    }

    String subject = 'Subject';
    if (mapped['subject'] is Map) {
      subject = (mapped['subject'] as Map)['name'] ?? 'Subject';
    } else if (mapped['subject'] is String) {
      subject = mapped['subject'];
    }

    String teacher = 'Teacher';
    if (mapped['teacher'] is Map) {
      final user = (mapped['teacher'] as Map)['user'];
      if (user is Map) {
        teacher = user['fullName'] ?? user['name'] ?? 'Teacher';
      }
    }

    return TimetableSessionModel(
      dayIndex: dayIndex,
      time: mapped['startTime']?.toString() ?? '00:00',
      subject: subject,
      teacher: teacher,
      room: mapped['room']?.toString() ?? 'Room',
      isCanceled: mapped['is_canceled'] ?? mapped['isCanceled'] ?? false,
      isLive: mapped['is_live'] ?? mapped['isLive'] ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // CLASSES  –  /api/classes/* and /api/teachers/my-classes
  // ---------------------------------------------------------------------------

  /// GET /classes → all classes (admin / general use)
  Future<List<ClassModel>> getClasses() async {
    final response = await _dio.get('/classes');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((json) => ClassModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load classes');
  }

  /// GET /teachers/my-classes → only the logged-in teacher's classes
  Future<List<ClassModel>> getMyClasses() async {
    final response = await _dio.get('/teachers/my-classes');
    if (response.statusCode == 200) {
      final List data = _handleResponseData(response);
      return data.map((json) => ClassModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load my classes');
  }

  /// Build class stats from /notes/class-ranking + /attendances (no dedicated endpoint exists).
  Future<Map<String, dynamic>> getClassStats(String classId) async {
    try {
      final results = await Future.wait([
        _dio.get('/notes/class-ranking', queryParameters: {'classe': classId}),
        _dio.get('/attendances', queryParameters: {'classe': classId, 'limit': '500'}),
        _dio.get('/students', queryParameters: {'classe': classId, 'limit': '200'}),
        _dio.get('/notes/sheets', queryParameters: {'classe': classId}),
      ]);

      // ── grades ──
      final rankingRaw = results[0].data;
      final rankingList = (rankingRaw['data'] ?? []) as List;
      double classAvg = 0;
      int successCount = 0;
      final List<Map<String, dynamic>> top5 = [];
      final List<Map<String, dynamic>> bottom5 = [];

      if (rankingList.isNotEmpty) {
        double total = 0;
        for (final r in rankingList) {
          final pts = (r['points'] as num?)?.toDouble() ?? 0;
          final subCount = ((r['subjectsCount'] as num?)?.toInt() ?? 1).clamp(1, 100);
          final avg20 = (pts / subCount) * 2;
          total += avg20;
          if (avg20 >= 10) successCount++;
        }
        classAvg = total / rankingList.length;

        for (final r in rankingList.take(5)) {
          final pts = (r['points'] as num?)?.toDouble() ?? 0;
          final subCount = ((r['subjectsCount'] as num?)?.toInt() ?? 1).clamp(1, 100);
          top5.add({
            'id': r['studentId'],
            'name': '${r['firstName'] ?? ''} ${r['lastName'] ?? ''}'.trim(),
            'average': (pts / subCount) * 2,
          });
        }
        for (final r in rankingList.reversed.take(5)) {
          final pts = (r['points'] as num?)?.toDouble() ?? 0;
          final subCount = ((r['subjectsCount'] as num?)?.toInt() ?? 1).clamp(1, 100);
          bottom5.insert(0, {
            'id': r['studentId'],
            'name': '${r['firstName'] ?? ''} ${r['lastName'] ?? ''}'.trim(),
            'average': (pts / subCount) * 2,
          });
        }
      }

      final successRate = rankingList.isEmpty ? 0.0 : (successCount / rankingList.length) * 100;

      // ── attendance ──
      final absRaw = results[1].data;
      final absList = (absRaw['data'] ?? absRaw['attendances'] ?? []) as List;
      final absentStudentIds = absList.map((a) {
        final s = a['student'];
        return s is Map ? (s['_id'] ?? s['id'])?.toString() ?? '' : s?.toString() ?? '';
      }).toSet();

      final studentsRaw = results[2].data;
      final studentsList = (studentsRaw['data'] ?? studentsRaw['students'] ?? []) as List;
      final totalStudents = (studentsRaw['total'] as num?)?.toInt() ?? studentsList.length;
      final attendanceRate = totalStudents > 0
          ? ((totalStudents - absentStudentIds.length) / totalStudents) * 100
          : 100.0;

      // ── trend: group note sheets by month, plot class avg per active month ──
      final sheetsList = ((results[3].data['data'] ?? []) as List);
      final monthSet = <String>{};
      for (final sheet in sheetsList) {
        final dt = DateTime.tryParse(sheet['createdAt']?.toString() ?? '');
        if (dt == null) continue;
        monthSet.add('${dt.year}-${dt.month.toString().padLeft(2, '0')}');
      }
      final sortedMonths = monthSet.toList()..sort();
      final trendMonths = sortedMonths.length > 5
          ? sortedMonths.sublist(sortedMonths.length - 5)
          : sortedMonths;
      final trendSpots = trendMonths.asMap().entries.map((e) => {
        'x': e.key.toDouble(),
        'y': double.parse(classAvg.toStringAsFixed(1)),
      }).toList();
      final trendLabels = trendMonths.map((ym) {
        final dt = DateTime.parse('$ym-01');
        return DateFormat('MMM', 'fr').format(dt);
      }).toList();

      return {
        'classAverage': double.parse(classAvg.toStringAsFixed(2)),
        'attendanceRate': double.parse(attendanceRate.toStringAsFixed(1)),
        'successRate': double.parse(successRate.toStringAsFixed(1)),
        'alerts': 0,
        'top5': top5,
        'bottom5': bottom5,
        'trend': trendSpots,
        'trendLabels': trendLabels,
      };
    } catch (e) {
      debugPrint('[API] getClassStats failed: $e');
      return {};
    }
  }

  /// GET /teachers/my-subjects → [{id, name, code}]
  Future<List<Map<String, dynamic>>> getMySubjects() async {
    try {
      final response = await _dio.get('/teachers/my-subjects');
      if (response.statusCode == 200) {
        final raw = _handleResponseData(response);
        if (raw is List) return List<Map<String, dynamic>>.from(raw);
      }
      return [];
    } catch (e) {
      debugPrint('[API] getMySubjects failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // TEACHER PRESENCE  –  /api/teachers/*
  // ---------------------------------------------------------------------------

  /// POST /teachers/sign-presence  { arrivalTime, departureTime? }
  Future<bool> signPresence({
    required String arrivalTime,
    String? departureTime,
  }) async {
    final response = await _dio.post('/teachers/sign-presence', data: {
      'arrivalTime': arrivalTime,
      if (departureTime != null) 'departureTime': departureTime,
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// GET /teachers/my-presence
  Future<List<Map<String, dynamic>>> getMyPresence() async {
    try {
      final response = await _dio.get('/teachers/my-presence');
      if (response.statusCode == 200) {
        final raw = _handleResponseData(response);
        if (raw is List) return List<Map<String, dynamic>>.from(raw);
      }
      return [];
    } catch (e) {
      debugPrint('[API] getMyPresence failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // LEAVE REQUESTS  –  /api/leave-requests/*
  // ---------------------------------------------------------------------------

  /// POST /leave-requests  (teacher submits a leave request)
  Future<bool> submitLeaveRequest({
    required String startDate,
    required String endDate,
    required String reason,
    String? filePath,
  }) async {
    final formData = FormData.fromMap({
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
    });
    if (filePath != null && filePath.isNotEmpty) {
      formData.files.add(MapEntry(
        'attachments',
        await MultipartFile.fromFile(filePath,
            filename: filePath.split('/').last),
      ));
    }
    final response =
        await _dio.post('/leave-requests', data: formData);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// GET /leave-requests/my → teacher's own leave requests
  Future<List<Map<String, dynamic>>> getMyLeaveRequests() async {
    try {
      final response = await _dio.get('/leave-requests/my');
      if (response.statusCode == 200) {
        final raw = _handleResponseData(response);
        if (raw is List) return List<Map<String, dynamic>>.from(raw);
      }
      return [];
    } catch (e) {
      debugPrint('[API] getMyLeaveRequests failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // BEHAVIOR  –  no backend route; graceful degradation
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getBehaviorSummary(String studentId) async {
    try {
      final response = await _dio.get('/behavior/summary', queryParameters: {'studentId': studentId});
      return response.data['data'] ?? {};
    } catch (e) {
      debugPrint('[API] getBehaviorSummary failed: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getBehaviorHistory(
      String studentId) async {
    try {
      final response = await _dio.get('/behavior/history', queryParameters: {'studentId': studentId});
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('[API] getBehaviorHistory failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // SECURITY / GEOFENCING
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSecurityStatus(String studentId) async {
    try {
      final response = await _dio.get('/security/status', queryParameters: {'studentId': studentId});
      return response.data['data'] ?? {};
    } catch (e) {
      debugPrint('[API] getSecurityStatus failed: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getSecurityAlerts(String studentId) async {
    try {
      final response = await _dio.get('/security/alerts', queryParameters: {'studentId': studentId});
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('[API] getSecurityAlerts failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR HELPER
  // ---------------------------------------------------------------------------

  String getLocalizedErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'server_down_or_no_internet';
      }
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map &&
          data.containsKey('message') &&
          data['message'] != null) {
        return data['message'].toString();
      }
      switch (status) {
        case 401:
          return 'unauthorized';
        case 403:
          return 'forbidden';
        case 404:
          return 'resource_not_found';
        case 500:
          return 'internal_server_error';
        default:
          return 'something_went_wrong';
      }
    }
    return 'unknown_error';
  }
}
