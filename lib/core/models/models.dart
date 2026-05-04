import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_config.dart';

enum HomeworkStatus { notStarted, inProgress, done, late }

enum UserRole { parent, teacher }

enum IconType {
  location,
  grade,
  absence,
  payment,
  post,
  message,
  info,
  exam,
  devoir,
  event
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final int? avatarIndex;
  final String? phone;
  final List<String> childrenIds; // for parent
  final List<String> classIds; // for teacher
  final String? schoolName;
  final String? gender; // 'M' or 'F' from backend

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.avatarIndex,
    this.phone,
    this.childrenIds = const [],
    this.classIds = const [],
    this.schoolName,
    this.gender,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    int? avatarIndex,
    String? phone,
    List<String>? childrenIds,
    List<String>? classIds,
    String? schoolName,
    String? gender,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      phone: phone ?? this.phone,
      childrenIds: childrenIds ?? this.childrenIds,
      classIds: classIds ?? this.classIds,
      schoolName: schoolName ?? this.schoolName,
      gender: gender ?? this.gender,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] == 'teacher' ? UserRole.teacher : UserRole.parent,
      avatarUrl: processImageUrl(json['avatarUrl']),
      avatarIndex: json['avatarIndex'],
      phone: json['phone'],
      childrenIds: List<String>.from(json['childrenIds'] ?? []),
      classIds: List<String>.from(json['classIds'] ?? []),
      schoolName: json['schoolName'],
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'avatarUrl': avatarUrl,
      'avatarIndex': avatarIndex,
      'phone': phone,
      'childrenIds': childrenIds,
      'classIds': classIds,
      'schoolName': schoolName,
      'gender': gender,
    };
  }
}

class ChildModel {
  final String id;
  final String name;
  final String className;
  final String? avatarUrl;
  final int age;
  final double attendanceRate;
  final double averageGrade;
  final String status; // 'at_school', 'on_way', 'at_home'
  final String lastUpdate;
  final int lateHomeworkCount;
  final String? nextExamDate;
  final String? nextExamSubject;

  ChildModel({
    required this.id,
    required this.name,
    required this.className,
    this.avatarUrl,
    required this.age,
    required this.attendanceRate,
    required this.averageGrade,
    this.status = 'at_school',
    this.lastUpdate = '',
    this.lateHomeworkCount = 0,
    this.nextExamDate,
    this.nextExamSubject,
  });

  ChildModel copyWith({
    String? id,
    String? name,
    String? className,
    String? avatarUrl,
    int? age,
    double? attendanceRate,
    double? averageGrade,
    String? status,
    String? lastUpdate,
    int? lateHomeworkCount,
    String? nextExamDate,
    String? nextExamSubject,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      className: className ?? this.className,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      averageGrade: averageGrade ?? this.averageGrade,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lateHomeworkCount: lateHomeworkCount ?? this.lateHomeworkCount,
      nextExamDate: nextExamDate ?? this.nextExamDate,
      nextExamSubject: nextExamSubject ?? this.nextExamSubject,
    );
  }
}

class GradeModel {
  final String id;
  final String subject;
  final double grade;
  final double maxGrade;
  final double coefficient;
  final String date;
  final String type; // 'exam', 'devoir', 'controle'
  final String? comment;
  final double? classAverage;
  final String? semester;
  final String? title;
  final int? rank;
  final int? classSize;
  final List<GradeComponentModel>? components;

  GradeModel({
    required this.id,
    required this.subject,
    required this.grade,
    required this.maxGrade,
    required this.coefficient,
    required this.date,
    required this.type,
    this.comment,
    this.classAverage,
    this.semester,
    this.title,
    this.rank,
    this.classSize,
    this.components,
  });

  GradeModel copyWith({
    String? id,
    String? subject,
    double? grade,
    double? maxGrade,
    double? coefficient,
    String? date,
    String? type,
    String? comment,
    double? classAverage,
    String? semester,
    String? title,
    int? rank,
    int? classSize,
    List<GradeComponentModel>? components,
  }) {
    return GradeModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      maxGrade: maxGrade ?? this.maxGrade,
      coefficient: coefficient ?? this.coefficient,
      date: date ?? this.date,
      type: type ?? this.type,
      comment: comment ?? this.comment,
      classAverage: classAverage ?? this.classAverage,
      semester: semester ?? this.semester,
      title: title ?? this.title,
      rank: rank ?? this.rank,
      classSize: classSize ?? this.classSize,
      components: components ?? this.components,
    );
  }

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    // Extract subject name from various possible structures
    String subjectName = '';
    if (json['subject'] is Map) {
      subjectName = json['subject']['name'] ?? json['subject']['title'] ?? '';
    } else if (json['matiere'] is Map) {
      subjectName = json['matiere']['name'] ?? json['matiere']['title'] ?? '';
    } else {
      subjectName =
          json['subject'] ?? json['subjectName'] ?? json['matiere'] ?? '';
    }

    // Infer semester from date if not provided
    String semester = json['semester']?.toString() ?? '';
    final rawDate = json['date'] ?? json['createdAt'] ?? json['passedAt'] ?? '';
    if (semester.isEmpty && rawDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate);
        semester = (dt.month >= 9 || dt.month <= 1) ? "1" : "2";
      } catch (_) {}
    }

    // Try all possible grade field names
    double gradeValue = 0.0;
    for (final key in [
      'note',
      'score',
      'mark',
      'grade',
      'result',
      'value',
      'obtainedGrade',
      'obtained'
    ]) {
      if (json[key] != null) {
        gradeValue = (json[key] as num).toDouble();
        break;
      }
    }

    // Try all possible title/name field names
    String? title;
    for (final key in [
      'title',
      'name',
      'label',
      'examName',
      'description',
      'evaluationName'
    ]) {
      if (json[key] != null && json[key].toString().isNotEmpty) {
        title = json[key].toString();
        break;
      }
    }

    List<GradeComponentModel>? parsedComponents;
    for (final key in [
      'components',
      'subGrades',
      'details',
      'children',
      'elements',
      'criterias',
      'competences',
      'mokawinat'
    ]) {
      if (json[key] is List && (json[key] as List).isNotEmpty) {
        parsedComponents = (json[key] as List)
            .map((x) => GradeComponentModel.fromJson(x as Map<String, dynamic>))
            .toList();
        break;
      }
    }

    return GradeModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      subject: subjectName,
      grade: gradeValue,
      maxGrade:
          (json['maxGrade'] ?? json['total'] ?? json['outOf'] ?? 10 as num)
              .toDouble(),
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      date: rawDate,
      type: json['type'] ?? json['evaluationType'] ?? 'exam',
      comment: json['comment'] ?? json['appreciation'] ?? json['observation'],
      classAverage:
          (json['classAverage'] ?? json['moyenne'] ?? json['average'] as num?)
              ?.toDouble(),
      semester: semester,
      title: title,
      rank: (json['rank'] ?? json['classement'] ?? json['position'] as num?)
          ?.toInt(),
      classSize: (json['classSize'] ??
              json['totalStudents'] ??
              json['effectif'] as num?)
          ?.toInt(),
      components: parsedComponents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'grade': grade,
      'maxGrade': maxGrade,
      'coefficient': coefficient,
      'date': date,
      'type': type,
      'comment': comment,
      'classAverage': classAverage,
      'semester': semester,
      'title': title,
      'rank': rank,
      'classSize': classSize,
      'components': components?.map((c) => c.toJson()).toList(),
    };
  }
}

class GradeComponentModel {
  final String title;
  final double grade;
  final double maxGrade;

  GradeComponentModel({
    required this.title,
    required this.grade,
    required this.maxGrade,
  });

  factory GradeComponentModel.fromJson(Map<String, dynamic> json) {
    return GradeComponentModel(
      title: json['title'] ??
          json['name'] ??
          json['label'] ??
          json['mokawin'] ??
          '',
      grade: ((json['grade'] ??
              json['note'] ??
              json['score'] ??
              json['value'] ??
              0) as num)
          .toDouble(),
      maxGrade:
          ((json['maxGrade'] ?? json['total'] ?? json['outOf'] ?? 10) as num)
              .toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'grade': grade,
      'maxGrade': maxGrade,
    };
  }
}

class AttendanceRecord {
  final String id;
  final String date;
  final String status; // 'present', 'absent', 'late', 'sick'
  final String? motif;
  final String? attachment;
  final String? rawStatus;
  final String? startTime;
  final String? endTime;
  final String? subjectName;
  final String? sessionName;
  final bool justifiedByStudent;
  final String? approvalStatus; // 'pending', 'approved', 'rejected'
  final String? recordedBy;
  final String? scheduleId;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.motif,
    this.attachment,
    this.rawStatus,
    this.startTime,
    this.endTime,
    this.subjectName,
    this.sessionName,
    this.justifiedByStudent = false,
    this.approvalStatus,
    this.recordedBy,
    this.scheduleId,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Standardize status: absent_justifie, absent_non_justifie, retard, present
    String rawStatus = (json['status'] ??
            json['attendanceStatus'] ??
            json['type'] ??
            'present')
        .toString()
        .toLowerCase();
    String? scheduleId =
        json['schedule']?.toString() ?? json['calendarId']?.toString();

    // Normalize status strings
    String finalStatus = 'present';
    if (rawStatus.contains('absent') ||
        rawStatus.contains('justifie') ||
        rawStatus.contains('justified') ||
        rawStatus.contains('sick') ||
        rawStatus.contains('malade')) {
      finalStatus = 'absent';
    } else if (rawStatus.contains('retard') || rawStatus.contains('late')) {
      finalStatus = 'late';
    }

    // Extract subject/session info
    String? subjectName;
    String? sessionName;
    if (json['session'] is Map) {
      final session = json['session'];
      sessionName = session['name'] ?? session['title'];
      if (session['subject'] is Map) {
        subjectName = session['subject']['name'] ?? session['subject']['title'];
      }
    } else if (json['matiere'] is Map) {
      subjectName = json['matiere']['name'] ?? json['matiere']['title'];
    }

    // Fallback subject mapping - handle Map or String
    if (subjectName == null) {
      final rawSubject =
          json['subjectName'] ?? json['subject'] ?? json['matiere'];
      if (rawSubject is Map) {
        subjectName =
            rawSubject['name'] ?? rawSubject['title'] ?? rawSubject['nom'];
      } else if (rawSubject is String && rawSubject.isNotEmpty) {
        subjectName = rawSubject;
      }
    }

    // Also extract timing from session if available
    String? startTime = json['startTime'] ?? json['hourStart'] ?? json['start'];
    String? endTime = json['endTime'] ?? json['hourEnd'] ?? json['end'];
    if (json['session'] is Map) {
      final session = json['session'];
      startTime ??=
          session['startTime'] ?? session['hourStart'] ?? session['start'];
      endTime ??= session['endTime'] ?? session['hourEnd'] ?? session['end'];
    }

    String? extractAttachment(dynamic data) {
      if (data == null) return null;
      if (data is Map) {
        return data['url']?.toString() ??
            data['path']?.toString() ??
            data['file']?.toString() ??
            data['filename']?.toString();
      }
      if (data is String && data.isNotEmpty && data != 'null' && data != '{}') {
        return data;
      }
      return null;
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val.toString().toLowerCase() == 'true') return true;
      return false;
    }

    String? motif = json['motif']?.toString() ??
        json['justificationText']?.toString() ??
        json['reason']?.toString() ??
        json['justificationReason']?.toString();
    String? attachment = extractAttachment(json['attachment']) ??
        extractAttachment(json['file']) ??
        extractAttachment(json['justification_file']) ??
        extractAttachment(json['proof']) ??
        extractAttachment(json['justificationAttachment']);

    // Keep this strict: a teacher-marked absence must not become "justified"
    // unless there is an explicit student/parent justification signal.
    bool justifiedByStudent = parseBool(json['justifiedByStudent']) ||
        parseBool(json['hasJustification']) ||
        parseBool(json['justificationSubmitted']);

    String? approvalStatus = json['approvalStatus']?.toString() ??
        json['justificationStatus']?.toString();

    // Check for nested justification object
    if (json['justification'] != null) {
      if (json['justification'] is Map) {
        final j = json['justification'];
        final jMotif = j['motif']?.toString() ??
            j['reason']?.toString() ??
            j['text']?.toString();
        final jAttachment = extractAttachment(j['attachment']) ??
            extractAttachment(j['file']) ??
            extractAttachment(j['url']);
        final hasAnyJustificationPayload = j.isNotEmpty;
        if (jMotif != null && jMotif.isNotEmpty) motif ??= jMotif;
        if (jAttachment != null && jAttachment.isNotEmpty) {
          attachment ??= jAttachment;
        }
        if (hasAnyJustificationPayload ||
            parseBool(j['justified']) ||
            parseBool(j['isJustified'])) {
          justifiedByStudent = true;
        }
        approvalStatus ??= j['status']?.toString() ??
            j['approvalStatus']?.toString() ??
            j['justificationStatus']?.toString();
      } else if (json['justification'] is String &&
          (json['justification'] as String).isNotEmpty &&
          json['justification'] != 'null') {
        final jStr = (json['justification'] as String).toLowerCase();
        if (jStr == 'true') {
          justifiedByStudent = true;
        } else {
          motif ??= json['justification'].toString();
          justifiedByStudent = true;
        }
      } else if (json['justification'] is bool &&
          json['justification'] == true) {
        justifiedByStudent = true;
      }
    }

    // Check array of justifications
    if (json['justifications'] != null &&
        json['justifications'] is List &&
        (json['justifications'] as List).isNotEmpty) {
      final latest = (json['justifications'] as List).last;
      if (latest is Map) {
        final jMotif = latest['motif']?.toString() ??
            latest['reason']?.toString() ??
            latest['text']?.toString();
        final jAttachment = extractAttachment(latest['attachment']) ??
            extractAttachment(latest['file']) ??
            extractAttachment(latest['url']);
        if (jMotif != null && jMotif.isNotEmpty) motif ??= jMotif;
        if (jAttachment != null && jAttachment.isNotEmpty) {
          attachment ??= jAttachment;
        }
        justifiedByStudent = true;
        approvalStatus ??= latest['status']?.toString() ??
            latest['approvalStatus']?.toString();
      }
    }

    if (attachment != null &&
        attachment.isNotEmpty &&
        attachment != 'null' &&
        attachment != '{}') {
      justifiedByStudent = true;
    }

    return AttendanceRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      date: (json['date'] ??
              json['passedAt'] ??
              json['createdAt'] ??
              json['day'] ??
              '')
          .toString(),
      status: finalStatus,
      motif: motif,
      attachment: processImageUrl(attachment),
      rawStatus: rawStatus,
      startTime: startTime,
      endTime: endTime,
      subjectName: subjectName,
      sessionName: sessionName,
      justifiedByStudent: justifiedByStudent,
      approvalStatus: approvalStatus,
      recordedBy: json['recordedBy'] is Map
          ? (json['recordedBy']['fullName'] ?? json['recordedBy']['name'])
          : json['recordedBy']?.toString(),
      scheduleId: scheduleId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status,
      'motif': motif,
      'attachment': attachment,
      'rawStatus': rawStatus,
      'startTime': startTime,
      'endTime': endTime,
      'subjectName': subjectName,
      'sessionName': sessionName,
      'justifiedByStudent': justifiedByStudent,
      'approvalStatus': approvalStatus,
      'recordedBy': recordedBy,
      'scheduleId': scheduleId,
    };
  }

  bool get isJustified {
    // 1) Explicit student/parent justification flag.
    if (justifiedByStudent) return true;

    // 2) Check for presence of motif or attachment as proxy for justification
    final hasContent =
        (motif != null && motif!.trim().isNotEmpty && motif != 'null') ||
            (attachment != null &&
                attachment!.trim().isNotEmpty &&
                attachment != 'null');

    return hasContent;
  }
}

class PostModel {
  final String id;
  final String authorName;
  final String authorRole;
  final String? authorAvatar;
  final String title; // Added for homework
  final String content;
  final String? imageUrl;
  final String date;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isSaved;
  final bool isEvent;
  final bool isUrgent;
  final bool? isCompleted; // Added for homework
  final String? eventDate;
  final String? participationStatus; // 'yes', 'no', null
  final List<CommentModel> commentsList;
  final List<LikeModel> likedBy;

  PostModel({
    required this.id,
    required this.authorName,
    required this.authorRole,
    this.authorAvatar,
    this.title = '',
    required this.content,
    this.imageUrl,
    required this.date,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isEvent = false,
    this.isUrgent = false,
    this.isCompleted = false,
    this.eventDate,
    this.participationStatus,
    this.commentsList = const [],
    this.likedBy = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    String authorName = json['authorName'] ?? '';
    String authorRole = json['authorRole'] ?? '';
    String? authorAvatar = json['authorAvatar'];

    if (json['author'] is Map) {
      final author = json['author'];
      authorName = author['fullName'] ?? author['name'] ?? authorName;
      authorRole = author['role'] ?? authorRole;
      authorAvatar = author['avatar'] ?? authorAvatar;
    }

    String? extractFileUrl(dynamic fileOrFiles) {
      if (fileOrFiles == null) return null;
      if (fileOrFiles is Map) {
        return fileOrFiles['url'] ??
            fileOrFiles['path'] ??
            fileOrFiles['filename'] ??
            fileOrFiles['file'];
      }
      if (fileOrFiles is List && fileOrFiles.isNotEmpty) {
        final first = fileOrFiles.first;
        if (first is Map) {
          return first['url'] ??
              first['path'] ??
              first['filename'] ??
              first['file'];
        }
        return first?.toString();
      }
      if (fileOrFiles is String && fileOrFiles.isNotEmpty) return fileOrFiles;
      return null;
    }

    // Extract ID robustly (handle nested _id.$oid or direct string)
    String idValue = '';
    final rawId =
        json['id'] ?? json['_id'] ?? json['postId'] ?? json['newsId'] ?? '';
    if (rawId is Map && rawId.containsKey('\$oid')) {
      idValue = rawId['\$oid']?.toString() ?? '';
    } else {
      idValue = rawId.toString();
    }
    if (idValue == 'null' || idValue == '{}') idValue = '';

    return PostModel(
      id: idValue,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: processImageUrl(authorAvatar),
      title: json['title'] ?? '',
      content: (json['content'] == null ||
              json['content'] == 'string' ||
              json['content'] == '')
          ? (json['description'] ?? json['message'] ?? json['body'] ?? '')
          : json['content'],
      imageUrl: processImageUrl(extractFileUrl(json['imageUrl']) ??
          extractFileUrl(json['image']) ??
          extractFileUrl(json['media']) ??
          extractFileUrl(json['photo']) ??
          extractFileUrl(json['files']) ??
          extractFileUrl(json['attachments']) ??
          extractFileUrl(json['documents'])),
      date: json['date'] ?? json['createdAt'] ?? '',
      likes: json['likesCount'] ??
          (json['likes'] is List ? (json['likes'] as List).length : 0),
      comments: json['commentsCount'] ??
          (json['comments'] is List ? (json['comments'] as List).length : 0),
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      isEvent: json['isEvent'] ?? (json['type'] == 'event'),
      isUrgent: json['isUrgent'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      eventDate: json['eventDate'],
      // NOTE: Don't fall back to json['status'] — that holds post publication state,
      // not the user's RSVP answer ('oui'/'non').
      participationStatus: json['myAttendance']?['status'] ??
          json['participationStatus'] ??
          json['participation_status'] ??
          json['userResponse'] ??
          json['userParticipation'] ??
          json['myParticipation'] ??
          json['myStatus'],
      commentsList: (json['comments'] is List &&
              json['comments'].isNotEmpty &&
              json['comments'][0] is Map)
          ? (json['comments'] as List)
              .map((c) => CommentModel.fromJson(c))
              .toList()
          : const [],
      likedBy: (json['likes'] is List &&
              json['likes'].isNotEmpty &&
              json['likes'][0] is Map)
          ? (json['likes'] as List).map((l) => LikeModel.fromJson(l)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorAvatar': authorAvatar,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'date': date,
      'likes': likes,
      'comments': comments,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'isEvent': isEvent,
      'isUrgent': isUrgent,
      'isCompleted': isCompleted,
      'eventDate': eventDate,
      'participationStatus': participationStatus,
      'commentsList': commentsList.map((c) => c.toJson()).toList(),
      'likedBy': likedBy.map((l) => l.toJson()).toList(),
    };
  }

  PostModel copyWith({
    String? id,
    String? authorName,
    String? authorRole,
    String? authorAvatar,
    String? title,
    String? content,
    String? imageUrl,
    String? date,
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isSaved,
    bool? isEvent,
    bool? isUrgent,
    bool? isCompleted,
    String? eventDate,
    String? participationStatus,
    List<CommentModel>? commentsList,
    List<LikeModel>? likedBy,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isEvent: isEvent ?? this.isEvent,
      isUrgent: isUrgent ?? this.isUrgent,
      isCompleted: isCompleted ?? this.isCompleted,
      eventDate: eventDate ?? this.eventDate,
      participationStatus: participationStatus ?? this.participationStatus,
      commentsList: commentsList ?? this.commentsList,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

class LikeModel {
  final String userName;
  final String? userAvatar;

  LikeModel({required this.userName, this.userAvatar});

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    String name = json['fullName'] ?? json['name'] ?? 'Utilisateur';
    String? avatar = processImageUrl(json['avatar'] ?? json['avatarUrl']);

    // Handle nested author/user structures
    if (json['user'] is Map) {
      final user = json['user'];
      name = user['fullName'] ?? user['name'] ?? name;
      avatar = processImageUrl(user['avatar'] ?? user['avatarUrl']) ?? avatar;
    } else if (json['author'] is Map) {
      final author = json['author'];
      name = author['fullName'] ?? author['name'] ?? name;
      avatar =
          processImageUrl(author['avatar'] ?? author['avatarUrl']) ?? avatar;
    }

    return LikeModel(userName: name, userAvatar: avatar);
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userAvatar': userAvatar,
    };
  }
}

String? processImageUrl(dynamic img) {
  if (img == null || img.toString().trim().isEmpty) return null;
  String url = img.toString();
  if (url.startsWith('http')) return url;
  final String baseUrl = AppConfig.serverUrl;
  if (url.startsWith('/')) {
    return '$baseUrl$url';
  }
  return '$baseUrl/$url';
}

class CommentModel {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String date;

  CommentModel({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.date,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String authorName = json['authorName'] ?? '';
    String? authorAvatar = json['authorAvatar'];

    if (json['author'] is Map) {
      final author = json['author'];
      authorName = author['fullName'] ?? author['name'] ?? authorName;
      authorAvatar = author['avatar'] ?? authorAvatar;
    }

    return CommentModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      authorName: authorName,
      authorAvatar: processImageUrl(authorAvatar),
      content: json['content'] ?? '',
      date: json['date'] ?? json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'date': date,
    };
  }
}

class ChatThreadModel {
  final String id;
  final String contactName;
  final String contactRole;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final bool onlyAdminsCanMessage;
  final String? avatarUrl;

  ChatThreadModel({
    required this.id,
    required this.contactName,
    required this.contactRole,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.onlyAdminsCanMessage = false,
    this.avatarUrl,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: json['id']?.toString() ?? '',
      contactName: json['contactName'] ?? '',
      contactRole: json['contactRole'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastTime: json['lastTime'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      onlyAdminsCanMessage: json['onlyAdminsCanMessage'] ?? false,
      avatarUrl: processImageUrl(json['avatarUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactName': contactName,
      'contactRole': contactRole,
      'lastMessage': lastMessage,
      'lastTime': lastTime,
      'unreadCount': unreadCount,
      'onlyAdminsCanMessage': onlyAdminsCanMessage,
      'avatarUrl': avatarUrl,
    };
  }
}

class ChatMessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String time;
  final DateTime? createdAt;
  final bool isMe;
  final String type; // 'text', 'image', 'video', 'document', 'voice'
  final Map<String, dynamic>? metadata; // for duration, size, etc.
  final List<String> attachments;

  ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    this.senderName = '',
    this.senderAvatar,
    required this.content,
    required this.time,
    this.createdAt,
    this.isMe = false,
    this.type = 'text',
    this.metadata,
    this.attachments = const [],
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    String senderId = json['senderId']?.toString() ?? '';
    String senderName = '';
    String? senderAvatar;
    // Handle nested sender object
    if (json['sender'] is Map) {
      final s = json['sender'];
      senderId = (s['id'] ?? s['_id'])?.toString() ?? senderId;
      senderName = s['fullName']?.toString() ?? s['name']?.toString() ?? '';
      senderAvatar = s['avatar']?.toString();
    }

    // Extract attachments
    List<String> attachments = [];
    if (json['attachments'] is List) {
      for (final a in json['attachments']) {
        if (a is String && a.isNotEmpty) {
          attachments.add(a);
        } else if (a is Map) {
          final url = a['url']?.toString() ?? a['path']?.toString() ?? '';
          if (url.isNotEmpty) attachments.add(url);
        }
      }
    }

    return ChatMessageModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      threadId: (json['threadId'] ?? json['message_id'])?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: processImageUrl(senderAvatar),
      content: json['content'] ?? '',
      time: json['time'] ?? json['createdAt'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      isMe: json['isMe'] ?? false,
      type: json['type'] ?? 'text',
      metadata: json['metadata'],
      attachments: attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'time': time,
      'isMe': isMe,
      'type': type,
      'metadata': metadata,
      'attachments': attachments,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String time;
  final bool isMe;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.time,
    this.isMe = false,
    this.isRead = false,
  });
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String type;
  final String? location;
  final String? participationStatus; // 'yes', 'no', null
  final String? createdAt; // Admin sent date

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.type,
    this.location,
    this.participationStatus,
    this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? '',
      location: json['location'],
      // Map the `myAttendance` field returned by the backend event endpoint.
      // E.g., `myAttendance: { status: 'going' }` -> 'going'
      participationStatus: json['myAttendance']?['status'] ??
          json['participationStatus'] ??
          json['participation_status'] ??
          json['userResponse'] ??
          json['userParticipation'] ??
          json['myParticipation'] ??
          json['myStatus'],
      createdAt:
          json['createdAt'] ?? json['date'], // fallback to date if not provided
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'type': type,
      'location': location,
      'participationStatus': participationStatus,
      'createdAt': createdAt,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? time,
    String? type,
    String? location,
    String? participationStatus,
    String? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      location: location ?? this.location,
      participationStatus: participationStatus ?? this.participationStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class HomeworkModel {
  final String id, subject, title, description, dueDate, startDate;
  final String? submissionId;
  final HomeworkStatus status;
  final String? attachment;
  final String? teacherComment;
  final String? teacherName;
  final String type; // 'devoir' or 'exam'
  final double progressRate; // 0-100
  final String? className;
  final int? submissionCount;

  HomeworkModel({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    this.startDate = '',
    this.submissionId,
    this.status = HomeworkStatus.notStarted,
    this.attachment,
    this.teacherComment,
    this.teacherName,
    this.type = 'devoir',
    this.progressRate = 0,
    this.className,
    this.submissionCount,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    String subjectName = '';
    if (json['subject'] is Map) {
      subjectName = json['subject']['name'] ?? json['subject']['title'] ?? '';
    } else {
      subjectName = json['subject'] ?? json['subjectName'] ?? '';
    }

    String teacherName = 'Unknown';
    if (json['teacher'] != null) {
      if (json['teacher'] is Map) {
        final t = json['teacher'] as Map;
        teacherName = t['name'] ??
            t['fullName'] ??
            t['username'] ??
            ((t['firstName'] != null || t['lastName'] != null)
                ? "${t['firstName'] ?? ''} ${t['lastName'] ?? ''}".trim()
                : 'Unknown');
      } else if (json['teacher'] is String &&
          json['teacher'].toString().isNotEmpty) {
        teacherName = json['teacher'];
      }
    } else if (json['teacherName'] != null &&
        json['teacherName'].toString().isNotEmpty) {
      teacherName = json['teacherName'];
    } else if (json['createdBy'] != null) {
      if (json['createdBy'] is Map) {
        final c = json['createdBy'] as Map;
        teacherName = c['name'] ??
            c['fullName'] ??
            ((c['firstName'] != null || c['lastName'] != null)
                ? "${c['firstName'] ?? ''} ${c['lastName'] ?? ''}".trim()
                : 'Unknown');
      } else {
        teacherName = json['createdBy'].toString();
      }
    }

    // Advanced status extraction
    bool isDone = false;
    String statusStr = (json['status'] ?? '').toString().toLowerCase();
    if (json['isSubmitted'] == true ||
        statusStr == 'done' ||
        statusStr == 'completed' ||
        statusStr == 'submitted') {
      isDone = true;
    }

    // Check nested submissions array
    if (json['submissions'] is List &&
        (json['submissions'] as List).isNotEmpty) {
      isDone = true;
    }

    // Check nested studentAssignments
    String? nestedAttachment;
    String? submissionId;
    if (json['studentAssignments'] is List &&
        (json['studentAssignments'] as List).isNotEmpty) {
      final sa = (json['studentAssignments'] as List).first;
      submissionId = (sa['id'] ?? sa['_id'])?.toString();
      final saStatus = (sa['status'] ?? '').toString().toLowerCase();
      if (saStatus == 'completed' ||
          saStatus == 'done' ||
          saStatus == 'submitted' ||
          sa['isSubmitted'] == true) {
        isDone = true;
      }
      nestedAttachment = sa['fileUrl'] ?? sa['attachment'];
    }

    if (isDone) statusStr = 'done';

    // Extract progress/percentage
    double progress = (json['progress'] ??
            json['percentage'] ??
            json['completionRate'] ??
            0.0)
        .toDouble();
    if (progress == 0 && statusStr == 'done') progress = 100.0;
    if (progress == 0 && statusStr == 'inProgress') progress = 50.0;

    String? foundAttachment = json['attachment'] ??
        json['fileUrl'] ??
        json['document'] ??
        nestedAttachment;

    // Aggressive media hunt
    if (foundAttachment == null) {
      for (final key in ['attachments', 'files', 'media', 'documents']) {
        if (json[key] is List && (json[key] as List).isNotEmpty) {
          final first = (json[key] as List).first;
          if (first is String) {
            foundAttachment = first;
          } else if (first is Map) {
            foundAttachment = first['original_url'] ??
                first['url'] ??
                first['fileUrl'] ??
                first['path'] ??
                first['link'] ??
                first['file'];
          }
          if (foundAttachment != null && foundAttachment.isNotEmpty) break;
        }
      }
    }

    return HomeworkModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      subject: subjectName,
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? json['content'] ?? '',
      dueDate: json['dueDate'] ??
          json['due_date'] ??
          json['deadline'] ??
          json['date']?.toString() ??
          '',
      startDate: json['createdAt']?.toString().split('T')[0] ??
          json['startDate']?.toString() ??
          '',
      submissionId: submissionId,
      status: _statusFromString(statusStr),
      attachment: processImageUrl(foundAttachment),
      teacherComment: json['teacherComment'] ?? json['feedback'],
      teacherName: teacherName,
      type: (json['type'] ?? json['assignmentType'] ?? 'devoir')
                  .toString()
                  .toLowerCase() ==
              'exam'
          ? 'exam'
          : 'devoir',
      progressRate: progress,
      className: json['classe'] is Map ? json['classe']['name'] : null,
      submissionCount: json['submissionCount'],
    );
  }

  static HomeworkStatus _statusFromString(String? status) {
    switch (status) {
      case 'notStarted':
        return HomeworkStatus.notStarted;
      case 'inProgress':
        return HomeworkStatus.inProgress;
      case 'done':
        return HomeworkStatus.done;
      case 'late':
        return HomeworkStatus.late;
      default:
        return HomeworkStatus.notStarted;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'status': status.toString().split('.').last,
      'attachment': attachment,
      'teacherComment': teacherComment,
      'teacherName': teacherName,
    };
  }

  HomeworkModel copyWith({
    String? id,
    String? subject,
    String? title,
    String? description,
    String? dueDate,
    String? startDate,
    String? submissionId,
    HomeworkStatus? status,
    String? attachment,
    String? teacherComment,
    String? teacherName,
    String? type,
    double? progressRate,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      submissionId: submissionId ?? this.submissionId,
      status: status ?? this.status,
      attachment: attachment ?? this.attachment,
      teacherComment: teacherComment ?? this.teacherComment,
      teacherName: teacherName ?? this.teacherName,
      type: type ?? this.type,
      progressRate: progressRate ?? this.progressRate,
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String time;
  final String type;
  final IconType iconType;
  final bool isRead;
  final bool? isUrgent;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.iconType,
    this.isRead = false,
    this.isUrgent = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? time,
    String? type,
    IconType? iconType,
    bool? isRead,
    bool? isUrgent,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      type: type ?? this.type,
      iconType: iconType ?? this.iconType,
      isRead: isRead ?? this.isRead,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    bool isRead;
    final readBy = json['readBy'] as List?;
    if (currentUserId != null && readBy != null) {
      isRead = readBy.any((id) => id?.toString() == currentUserId);
    } else {
      isRead = readBy?.isNotEmpty ?? json['isRead'] ?? false;
    }
    return NotificationModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['message'] ?? json['body'] ?? '',
      time: json['createdAt'] ?? json['time'] ?? '',
      type: json['type'] ?? '',
      iconType: _iconTypeFromString(json['type'] ?? ''),
      isRead: isRead,
      isUrgent: json['isUrgent'] ?? (json['type'] == 'exam_scheduled'),
    );
  }

  static IconType _iconTypeFromString(String type) {
    if (type.contains('location') || type.contains('zone')) {
      return IconType.location;
    }
    switch (type.toLowerCase()) {
      case 'grade':
        return IconType.grade;
      case 'absence':
        return IconType.absence;
      case 'payment':
        return IconType.payment;
      case 'post':
        return IconType.post;
      case 'message':
        return IconType.message;
      case 'exam':
      case 'examen':
        return IconType.exam;
      case 'devoir':
      case 'assignment':
        return IconType.devoir;
      case 'event':
      case 'evenement':
        return IconType.event;
      default:
        return IconType.info;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time,
      'type': type,
      'iconType': iconType.toString().split('.').last,
      'isRead': isRead,
      'isUrgent': isUrgent,
    };
  }
}

class ClassModel {
  final String id;
  final String name;
  final String? level;
  final int studentCount;
  final double? attendanceRate;
  final double? classAverage;
  final List<StudentModel> students;

  ClassModel({
    required this.id,
    required this.name,
    this.level,
    required this.studentCount,
    this.attendanceRate,
    this.classAverage,
    this.students = const [],
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name'] ?? json['baseName'] ?? json['label'] ?? '',
      level: json['level']?.toString(),
      studentCount: json['studentCount'] ?? (json['students'] is List ? (json['students'] as List).length : 0),
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble(),
      classAverage: (json['classAverage'] as num?)?.toDouble(),
      students: json['students'] is List
          ? (json['students'] as List)
              .map((s) => StudentModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

class StudentModel {
  final String id;
  final String name;
  final double average;
  final String? massarCode;
  final double? attendanceRate;
  final String? parentName;
  final String? parentPhone;
  final String? behavior;
  final String? birthDate;
  final int? age;
  final String? className;
  final String? group;
  final String? avatarUrl;
  final String? gender; // 'M' or 'F' from backend

  StudentModel({
    required this.id,
    required this.name,
    required this.average,
    this.massarCode,
    this.attendanceRate,
    this.parentName,
    this.parentPhone,
    this.behavior,
    this.birthDate,
    this.age,
    this.className,
    this.group,
    this.avatarUrl,
    this.gender,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    String studentName = json['name'] ?? '';
    if (json['user'] is Map) {
      studentName =
          json['user']['fullName'] ?? json['user']['name'] ?? studentName;
    }

    String className = json['className'] ?? '';
    if (json['classe'] is Map) {
      className = json['classe']['name'] ?? className;
    }

    String? gender = json['gender']?.toString();
    if (gender == null && json['user'] is Map) {
      gender = json['user']['gender']?.toString();
    }

    return StudentModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: studentName,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      massarCode: json['matricule'] ?? json['massarCode'],
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble(),
      parentName: json['parentName'],
      parentPhone: json['parentPhone'],
      behavior: json['behavior'],
      birthDate: json['dateOfBirth'] ?? json['birthDate'],
      age: json['age'],
      className: className,
      group: json['group'],
      avatarUrl: processImageUrl(json['avatarUrl'] ?? json['avatar']),
      gender: gender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'average': average,
      'massarCode': massarCode,
      'attendanceRate': attendanceRate,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'behavior': behavior,
      'birthDate': birthDate,
      'age': age,
      'className': className,
      'group': group,
      'avatarUrl': avatarUrl,
      'gender': gender,
    };
  }
}

class TeacherActivityModel {
  final String id;
  final String title;
  final String? description;
  final String? type; // for older screens
  final String? detail; // for older screens
  final String date; // for older screens
  final String? time;
  final IconData? icon;
  final Color? color;

  TeacherActivityModel({
    required this.id,
    required this.title,
    this.description,
    this.type,
    this.detail,
    required this.date,
    this.time,
    this.icon,
    this.color,
  });
}

class BusLocationModel {
  final String id;
  final double latitude;
  final double longitude;
  final double speed;
  final double batteryLevel;
  final String lastUpdate;
  final String status; // 'moving', 'stopped', 'offline'

  BusLocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.batteryLevel,
    required this.lastUpdate,
    required this.status,
  });

  factory BusLocationModel.fromJson(Map<String, dynamic> json) {
    return BusLocationModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      batteryLevel: (json['batteryLevel'] as num?)?.toDouble() ?? 0.0,
      lastUpdate: json['lastUpdate'] ?? '',
      status: json['status'] ?? 'offline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'batteryLevel': batteryLevel,
      'lastUpdate': lastUpdate,
      'status': status,
    };
  }
}

class LocationHistoryRecord {
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLast;

  // Rich Trip Data
  final String mode; // 'school_bus_mode', 'walking_mode', etc.
  final String status; // 'trip_finished', 'trip_in_progress'
  final String duration;
  final String fromAddress;
  final String toAddress;
  final String startTime;
  final String endTime;
  final LatLng? startCoord;
  final LatLng? endCoord;

  LocationHistoryRecord({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isLast = false,
    this.mode = 'school_bus_mode',
    this.status = 'trip_finished',
    this.duration = '',
    this.fromAddress = '',
    this.toAddress = '',
    this.startTime = '',
    this.endTime = '',
    this.startCoord,
    this.endCoord,
  });

  factory LocationHistoryRecord.fromJson(Map<String, dynamic> json) {
    // Helper to map type to Icon and Color
    final String mode = json['mode'] ?? 'school_bus_mode';
    IconData icon;
    Color color;

    switch (mode) {
      case 'walking_mode':
        icon = Icons.directions_walk_rounded;
        color = Colors.orangeAccent;
        break;
      case 'private_transport_mode':
        icon = Icons.directions_car_rounded;
        color = Colors.greenAccent;
        break;
      default:
        icon = Icons.directions_bus_rounded;
        color = Colors.blueAccent;
    }

    return LocationHistoryRecord(
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: icon,
      color: color,
      isLast: json['isLast'] ?? false,
      mode: mode,
      status: json['status'] ?? 'trip_finished',
      duration: json['duration'] ?? '',
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      startCoord: json['startLat'] != null
          ? LatLng(json['startLat'], json['startLng'])
          : null,
      endCoord: json['endLat'] != null
          ? LatLng(json['endLat'], json['endLng'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'title': title,
      'subtitle': subtitle,
      'isLast': isLast,
      'mode': mode,
      'status': status,
      'duration': duration,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'startTime': startTime,
      'endTime': endTime,
      'startLat': startCoord?.latitude,
      'startLng': startCoord?.longitude,
      'endLat': endCoord?.latitude,
      'endLng': endCoord?.longitude,
    };
  }
}

enum PaymentStatus {
  paid,
  pending,
  overdue,
}

enum PaymentType {
  scolarity,
  transport,
}

class PaymentModel {
  final String id;
  final String month;
  final double amount;
  final PaymentStatus status;
  final String date;
  final String? invoiceUrl;
  final List<String> childIds;
  // Receipt display fields
  final String? invoiceNumber;
  final String? studentName;
  final String? className;
  final String? paymentMethod;
  final int? year;
  final PaymentType paymentType;

  PaymentModel({
    required this.id,
    required this.month,
    required this.amount,
    required this.status,
    required this.date,
    this.invoiceUrl,
    required this.childIds,
    this.invoiceNumber,
    this.studentName,
    this.className,
    this.paymentMethod,
    this.year,
    this.paymentType = PaymentType.scolarity,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    String rawMonth = json['month']?.toString() ??
        json['periodMonth']?.toString() ??
        json['label']?.toString() ??
        '';

    String normalizeMonth(String mStr) {
      if (mStr.isEmpty) return '';
      String m = mStr.toLowerCase().trim();

      // Handle "Scolarité • Avril" format
      if (m.contains('•')) {
        m = m.split('•').last.trim();
      }

      int? num = int.tryParse(m);
      if (num != null) {
        if (num == 9) return 'september';
        if (num == 10) return 'october';
        if (num == 11) return 'november';
        if (num == 12) return 'december';
        if (num == 1) return 'january';
        if (num == 2) return 'february';
        if (num == 3) return 'march';
        if (num == 4) return 'april';
        if (num == 5) return 'may';
        if (num == 6) return 'june';
      }
      if (m.startsWith('sep') || m.startsWith('sép')) return 'september';
      if (m.startsWith('oct')) return 'october';
      if (m.startsWith('nov')) return 'november';
      if (m.startsWith('dec') || m.startsWith('déc')) return 'december';
      if (m.startsWith('jan')) return 'january';
      if (m.startsWith('feb') || m.startsWith('fév')) return 'february';
      if (m.startsWith('mar')) return 'march';
      if (m.startsWith('apr') || m.startsWith('avr')) return 'april';
      if (m.startsWith('may') || m.startsWith('mai')) return 'may';
      if (m.startsWith('jun') || m.startsWith('jui')) return 'june';
      return mStr;
    }

    // Extract date robustly
    String dateValue = json['date']?.toString() ??
        json['paidAt']?.toString() ??
        json['createdAt']?.toString() ??
        '';

    // Extract student name from nested student/user object or direct field
    String? studentName;
    if (json['student'] is Map) {
      final s = json['student'] as Map;
      final user = s['user'];
      if (user is Map) {
        studentName = user['fullName']?.toString() ?? user['name']?.toString();
      }
      studentName ??= s['fullName']?.toString() ?? s['name']?.toString();
    }
    studentName ??=
        json['studentName']?.toString() ?? json['student']?.toString();

    // Extract class name
    String? className;
    if (json['class'] is Map) {
      className = (json['class'] as Map)['name']?.toString() ??
          (json['class'] as Map)['label']?.toString();
    } else if (json['classe'] is Map) {
      className = (json['classe'] as Map)['name']?.toString() ??
          (json['classe'] as Map)['label']?.toString();
    } else if (json['group'] is Map) {
      className = (json['group'] as Map)['name']?.toString() ??
          (json['group'] as Map)['label']?.toString();
    } else if (json['affectation'] is Map) {
      final aff = json['affectation'];
      if (aff['class'] is Map) {
        className = aff['class']['name']?.toString();
      } else if (aff['classe'] is Map)
        className = aff['classe']['name']?.toString();
      else if (aff['group'] is Map)
        className = aff['group']['name']?.toString();
    }
    className ??= json['className']?.toString() ??
        json['level']?.toString() ??
        json['groupName']?.toString();
    if (className == null && json['classe'] is String) {
      className = json['classe'].toString();
    }
    if (className == null && json['class'] is String) {
      className = json['class'].toString();
    }

    // Extract year from paidAt date or periodYear
    int? year = json['periodYear'] is int
        ? json['periodYear'] as int
        : int.tryParse(json['periodYear']?.toString() ?? '');
    if (year == null && dateValue.length >= 4) {
      year = int.tryParse(dateValue.substring(0, 4));
    }

    // Detect payment type from invoiceNumber prefix or label
    final invoiceNum = json['invoiceNumber']?.toString() ??
        json['reference']?.toString() ??
        json['invoiceRef']?.toString() ??
        json['ref']?.toString() ??
        '';
    final label = json['label']?.toString().toLowerCase() ?? '';
    PaymentType pType = PaymentType.scolarity;
    if (invoiceNum.toUpperCase().startsWith('INV-TRA') ||
        label.contains('transport')) {
      pType = PaymentType.transport;
    }

    // Extract ID robustly (handle nested _id.$oid or direct string)
    String idValue = '';
    final rawId = json['id'] ??
        json['_id'] ??
        json['paymentId'] ??
        json['invoiceId'] ??
        json['uid'] ??
        json['key'] ??
        '';
    if (rawId is Map && rawId.containsKey('\$oid')) {
      idValue = rawId['\$oid']?.toString() ?? '';
    } else {
      idValue = rawId.toString();
    }
    // Final fallback: if ID is still empty but we have an invoice number,
    // it's better than nothing, but let's stick to empty if it looks like a junk value.
    if (idValue == 'null' || idValue == '{}') idValue = '';

    return PaymentModel(
      id: idValue,
      month: normalizeMonth(rawMonth),
      amount: (json['amount'] ??
                  json['totalAmount'] ??
                  json['fee'] ??
                  json['total'] as num?)
              ?.toDouble() ??
          0.0,
      status: PaymentStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            json['status']?.toString().toLowerCase(),
        orElse: () => (json['isPaid'] == true ||
                json['status']?.toString().toLowerCase() == 'paid' ||
                json['paidAt'] != null ||
                (json['paidAmount'] != null && json['paidAmount'] != 0))
            ? PaymentStatus.paid
            : PaymentStatus.pending,
      ),
      date: dateValue,
      invoiceUrl:
          json['invoiceUrl'] ?? json['receiptUrl'] ?? json['downloadUrl'],
      childIds: json['childIds'] is List
          ? List<String>.from(json['childIds'])
          : (json['studentId'] != null ? [json['studentId'].toString()] : []),
      invoiceNumber: invoiceNum.isNotEmpty ? invoiceNum : null,
      studentName: studentName,
      className: className,
      paymentMethod: json['paymentMethod']?.toString() ??
          json['paymentMode']?.toString() ??
          json['method']?.toString() ??
          json['mode']?.toString(),
      year: year,
      paymentType: pType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'status': status.toString().split('.').last,
      'date': date,
      'invoiceUrl': invoiceUrl,
      'childIds': childIds,
      'invoiceNumber': invoiceNumber,
      'studentName': studentName,
      'className': className,
      'paymentMethod': paymentMethod,
      'periodYear': year,
      'paymentType': paymentType.toString().split('.').last,
    };
  }
}

class TimetableSessionModel {
  final int dayIndex;
  final String time;
  final String subject;
  final String teacher;
  final String room;
  final bool isCanceled;
  final bool isLive;

  TimetableSessionModel({
    required this.dayIndex,
    required this.time,
    required this.subject,
    required this.teacher,
    required this.room,
    this.isCanceled = false,
    this.isLive = false,
  });
}

/// Groups scolarité and transport payments for a single month
class MonthPaymentGroup {
  final String month;
  final PaymentModel? scolarity;
  final PaymentModel? transport;

  MonthPaymentGroup({
    required this.month,
    this.scolarity,
    this.transport,
  });

  bool get scolarityPaid => scolarity?.status == PaymentStatus.paid;
  bool get transportPaid => transport?.status == PaymentStatus.paid;
  bool get scolarityOverdue => scolarity?.status == PaymentStatus.overdue;
  bool get transportOverdue => transport?.status == PaymentStatus.overdue;
  bool get allPaid =>
      (scolarity == null || scolarityPaid) &&
      (transport == null || transportPaid);
  bool get anyPaid => scolarityPaid || transportPaid;

  PaymentStatus get overallStatus {
    if (allPaid) return PaymentStatus.paid;
    if (scolarity?.status == PaymentStatus.overdue ||
        transport?.status == PaymentStatus.overdue) {
      return PaymentStatus.overdue;
    }
    return PaymentStatus.pending;
  }
}
