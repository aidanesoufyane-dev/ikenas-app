import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<StudentModel> _children = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _evolutionData = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<StudentModel> get children => _children;
  List<Map<String, dynamic>> get activities => _activities;
  List<Map<String, dynamic>> get evolutionData => _evolutionData;
  List<Map<String, dynamic>> _todayAgenda = [];
  List<Map<String, dynamic>> get todayAgenda => _todayAgenda;
  List<Map<String, dynamic>> _subjectAverages = [];
  List<Map<String, dynamic>> get subjectAverages => _subjectAverages;
  List<dynamic> _upcomingEvents = [];
  List<dynamic> get upcomingEvents => _upcomingEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int _currentEventIndex = 0;
  int get currentEventIndex => _currentEventIndex;

  // Cache for participation statuses loaded from SharedPreferences
  final Map<String, String?> _cachedParticipationStatuses = {};

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => refreshData());
    debugPrint('Dashboard polling started (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Dashboard polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> refreshData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    try {
      // 1. Fetch children first to get their IDs
      await fetchChildren(silent: true);

      // 2. Determine if we should fetch stats
      bool isStudent = false;
      try {
        final profile = await _apiService.getProfile();
        isStudent = profile.role.toString().contains('student') ||
            profile.role == UserRole.parent && profile.childrenIds.isEmpty;
      } catch (_) {}

      // 3. Fetch everything else in parallel
      final tasks = [
        fetchTodayAgenda(silent: true),
        fetchActivities(silent: true),
        fetchSubjectAverages(silent: true),
        fetchUpcomingEvents(silent: true),
      ];

      if (!isStudent) {
        tasks.add(fetchStats(silent: true));
      }

      await Future.wait(tasks);
    } finally {
      _isRefreshing = false;
    }
  }

  void setCurrentEventIndex(int index) {
    _currentEventIndex = index;
    notifyListeners();
  }

  Future<bool> submitParticipation(dynamic item, String response) async {
    final String id = item.id;
    final bool isPost = item is PostModel;

    // Ensure we send standardized values to API
    final String standardizedResponse =
        (response.toLowerCase() == 'going' || response.toLowerCase() == 'oui' || response.toLowerCase() == 'yes')
            ? 'going'
            : 'not_going';

    final success = await _apiService.respondToEvent(id, standardizedResponse,
        isPost: isPost);

    if (success) {
      // Save participation status to local storage for persistence
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('event_participation_$id', standardizedResponse);
        // Also update cache
        _cachedParticipationStatuses[id] = standardizedResponse;
        debugPrint('Saved participation status for $id: $standardizedResponse');
      } catch (e) {
        debugPrint('Error saving participation status: $e');
      }

      // Update local state
      final index = _upcomingEvents.indexWhere((e) => e.id == id);
      if (index != -1) {
        if (isPost) {
          _upcomingEvents[index] = (_upcomingEvents[index] as PostModel)
              .copyWith(participationStatus: standardizedResponse);
        } else {
          _upcomingEvents[index] = (_upcomingEvents[index] as EventModel)
              .copyWith(participationStatus: standardizedResponse);
        }
        notifyListeners();
      }

      // Optionally refresh everything silently after a short delay to ensure backend consistency
      Future.delayed(const Duration(seconds: 2), () => refreshData());
    }
    return success;
  }

  Future<void> init() async {
    // Standard init with loading indicator
    _isLoading = true;
    notifyListeners();
    
    // Load cached participation statuses early from SharedPreferences
    await _loadCachedParticipationStatuses();
    
    await refreshData();
    
    _isLoading = false;
    notifyListeners();
  }

  /// Load all participation statuses from SharedPreferences into cache
  Future<void> _loadCachedParticipationStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      _cachedParticipationStatuses.clear();
      
      for (final key in keys) {
        if (key.startsWith('event_participation_')) {
          final eventId = key.replaceFirst('event_participation_', '');
          final status = prefs.getString(key);
          if (status != null) {
            _cachedParticipationStatuses[eventId] = status;
            debugPrint('Loaded participation status for $eventId: $status');
          }
        }
      }
      debugPrint('Loaded ${_cachedParticipationStatuses.length} participation statuses from SharedPreferences');
    } catch (e) {
      debugPrint('Error loading cached participation statuses: $e');
    }
  }

  bool _isSameDay(dynamic dateA, DateTime dateB) {
    if (dateA == null) return false;
    DateTime? dtA;
    if (dateA is DateTime) {
      dtA = dateA;
    } else if (dateA is String) {
      if (dateA.isEmpty) return false;
      dtA = DateTime.tryParse(dateA);
      // Fallback for common school board formats
      if (dtA == null) {
        final cleanDate =
            dateA.split(' ')[0].replaceAll(RegExp(r'[^\d/-]'), '');
        if (cleanDate.contains('/')) {
          final parts = cleanDate.split('/');
          if (parts.length == 3) {
            if (parts[2].length == 4) {
              dtA = DateTime.tryParse(
                  "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}");
            } else if (parts[0].length == 4) {
              dtA = DateTime.tryParse(
                  "${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}");
            }
          }
        } else if (cleanDate.contains('-')) {
          final parts = cleanDate.split('-');
          if (parts.length == 3 &&
              parts[0].length != 4 &&
              parts[2].length == 4) {
            dtA = DateTime.tryParse(
                "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}");
          }
        }
      }
    }
    if (dtA == null) return false;
    return dtA.year == dateB.year &&
        dtA.month == dateB.month &&
        dtA.day == dateB.day;
  }

  bool _isFutureOrToday(dynamic dateA, DateTime dateB) {
    if (dateA == null) return false;
    DateTime? dtA;
    if (dateA is DateTime) {
      dtA = dateA;
    } else if (dateA is String) {
      if (dateA.isEmpty) return false;
      dtA = DateTime.tryParse(dateA);
      if (dtA == null) {
        final cleanDate =
            dateA.split(' ')[0].replaceAll(RegExp(r'[^\d/-]'), '');
        if (cleanDate.contains('/')) {
          final parts = cleanDate.split('/');
          if (parts.length == 3) {
            if (parts[2].length == 4) {
              dtA = DateTime.tryParse(
                  "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}");
            } else if (parts[0].length == 4) {
              dtA = DateTime.tryParse(
                  "${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}");
            }
          }
        } else if (cleanDate.contains('-')) {
          final parts = cleanDate.split('-');
          if (parts.length == 3 &&
              parts[0].length != 4 &&
              parts[2].length == 4) {
            dtA = DateTime.tryParse(
                "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}");
          }
        }
      }
    }
    if (dtA == null) return false;
    final normalizedA = DateTime(dtA.year, dtA.month, dtA.day);
    final normalizedB = DateTime(dateB.year, dateB.month, dateB.day);
    return normalizedA.isAtSameMomentAs(normalizedB) ||
        normalizedA.isAfter(normalizedB);
  }

  Future<void> fetchTodayAgenda({bool silent = false}) async {
    try {
      final now = DateTime.now();
      final dayOfWeekIndex = now.weekday - 1; // 0=Mon, ..., 6=Sun
      final studentId = _children.isNotEmpty ? _children[0].id : 'me';

      final results = await Future.wait([
        _apiService
            .getTimetable(studentId)
            .catchError((_) => <TimetableSessionModel>[]),
        _apiService.getGrades(studentId).catchError((_) => <GradeModel>[]),
        _apiService
            .getAbsences(studentId)
            .catchError((_) => <AttendanceRecord>[]),
        _apiService.getHomework(studentId).catchError((_) => <HomeworkModel>[]),
        _apiService
            .getCalendarEvents(
                studentId: studentId, month: now.month, year: now.year)
            .catchError((_) => <EventModel>[]),
        _apiService.getExams(studentId).catchError((_) => <HomeworkModel>[]),
        _apiService.getPosts().catchError((_) => <PostModel>[]),
      ]);

      final List<Map<String, dynamic>> agenda = [];

      // 1. Add Sessions (Classes)
      final sessions = results[0] as List<TimetableSessionModel>;
      for (var s in sessions) {
        if (s.dayIndex == dayOfWeekIndex) {
          agenda.add({
            'type': 'session',
            'title': s.subject,
            'content': 'Prof. ${s.teacher}',
            'time': s.time,
            'location': s.room.isNotEmpty ? s.room : null,
            'icon': Icons.schedule_rounded,
            'color': Colors.blueAccent,
            'date_raw': now,
          });
        }
      }

      // 2. Add Exams / Results available today
      final resultsAvailable = results[1] as List<GradeModel>;
      for (var e in resultsAvailable) {
        if (_isSameDay(e.date, now)) {
          agenda.add({
            'type': 'exam_result',
            'title': 'Résultat Examen: ${e.subject}',
            'content': '${e.grade}/${e.maxGrade.toInt()} - ${e.title ?? ""}',
            'date': 'Aujourd\'hui',
            'icon': Icons.assignment_turned_in_rounded,
            'color': Colors.purpleAccent,
            'date_raw': now,
          });
        }
      }

      // 3. Add Absences / Attendance today
      final absences = results[2] as List<AttendanceRecord>;
      for (var ab in absences) {
        if (_isSameDay(ab.date, now)) {
          final isAbsence = ab.status.toLowerCase().contains('absent');
          agenda.add({
            'type': 'absence',
            'title': isAbsence ? 'Absence Détectée' : 'Retard Détecté',
            'content': '${ab.subjectName ?? "Session"} - ${ab.status}',
            'date': 'Aujourd\'hui',
            'icon': isAbsence
                ? Icons.event_busy_rounded
                : Icons.history_toggle_off_rounded,
            'color': isAbsence ? Colors.redAccent : Colors.orangeAccent,
            'date_raw': now,
          });
        }
      }

      // 4. Add Homework (Due Today)
      final homeworks = results[3] as List<HomeworkModel>;
      for (var h in homeworks) {
        if (_isSameDay(h.dueDate, now)) {
          agenda.add({
            'type': 'homework',
            'title': 'Devoir: ${h.subject}',
            'content': h.title,
            'date': 'Aujourd\'hui',
            'icon': Icons.menu_book_rounded,
            'color': Colors.greenAccent,
            'date_raw': now,
          });
        }
      }

      // 5. Add Upcoming exams scheduled for today
      final upcomingExams = results[5] as List<HomeworkModel>;
      for (var ex in upcomingExams) {
        if (_isSameDay(ex.dueDate, now)) {
          agenda.add({
            'type': 'exam',
            'title': 'EXAMEN: ${ex.subject}',
            'content': ex.title,
            'time': 'Aujourd\'hui',
            'icon': Icons.notification_important_rounded,
            'color': Colors.redAccent,
            'date_raw': now,
          });
        }
      }

      // 6. Add Calendar Events (Today)
      final events = results[4] as List<EventModel>;
      for (var ev in events) {
        if (_isSameDay(ev.date, now)) {
          agenda.add({
            'id': ev.id,
            'event_id': ev.id,
            'type': 'event',
            'title': ev.title,
            'content': ev.description.isNotEmpty
                ? ev.description
                : 'Événement scolaire',
            'time': ev.time.isNotEmpty ? ev.time : 'À définir',
            'location': (ev.location?.isNotEmpty ?? false) ? ev.location : null,
            'icon': Icons.event_available_rounded,
            'color': Colors.indigoAccent,
            'date_raw': now,
            'participation_status': ev.participationStatus,
          });
        }
      }

      // 7. Add Event Posts (Today fallback)
      final newsPosts = results[6] as List<PostModel>;
      for (var p in newsPosts) {
        if (p.isEvent && _isSameDay(p.eventDate ?? p.date, now)) {
          agenda.add({
            'id': p.id,
            'event_id': p.id,
            'type': 'event',
            'title': p.title.isNotEmpty ? p.title : 'Événement',
            'content': p.content,
            'time': 'Aujourd\'hui',
            'icon': Icons.event_note_rounded,
            'color': p.isUrgent ? Colors.redAccent : Colors.indigoAccent,
            'date_raw': now,
            'participation_status': p.participationStatus,
            'is_post': true,
          });
        }
      }

      // Sort by time if it exists (for sessions)
      agenda.sort((a, b) {
        final timeA = a['time']?.toString() ?? '00:00';
        final timeB = b['time']?.toString() ?? '00:00';
        return timeA.compareTo(timeB);
      });

      _todayAgenda = agenda;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching today agenda: $e');
    }
  }

  Future<void> fetchUpcomingEvents({bool silent = false}) async {
    try {
      final now = DateTime.now();
      final studentId = _children.isNotEmpty ? _children[0].id : 'me';

      // Concurrent fetch for calendar events, upcoming exams, AND urgent posts
      final results = await Future.wait([
        _apiService
            .getCalendarEvents(
              studentId: studentId,
              month: now.month,
              year: now.year,
            )
            .catchError((_) => <EventModel>[]),
        _apiService
            .getCalendarEvents(
              studentId: studentId,
              month: DateTime(now.year, now.month + 1, 1).month,
              year: DateTime(now.year, now.month + 1, 1).year,
            )
            .catchError((_) => <EventModel>[]),
        _apiService.getExams(studentId).catchError((_) => <HomeworkModel>[]),
        _apiService.getPosts().catchError((_) => <PostModel>[]),
      ]);

      final calendarEvents = [
        ...(results[0] as List<EventModel>),
        ...(results[1] as List<EventModel>)
      ];
      // final exams = results[2] as List<HomeworkModel>; // Unused
      final posts = results[3] as List<PostModel>;

      final List<dynamic> allUpcoming = [];

      // 1. Filter and Add Calendar Events (School Calendar)
      allUpcoming
          .addAll(calendarEvents.where((e) => _isFutureOrToday(e.date, now)));

      // 2. Filter and Add News Posts that are explicitly marked as events
      final eventPosts = posts.where(
          (p) => p.isEvent && _isFutureOrToday(p.eventDate ?? p.date, now));
      allUpcoming.addAll(eventPosts);

      // 3. Add a temporary Mock event for verification if NONE found (testing purpose as requested)
      if (allUpcoming.isEmpty) {
        allUpcoming.add(EventModel(
          id: 'mock_test',
          title: 'Réunion Parents-Professeurs',
          description:
              'Discussion sur les progrès académiques du deuxième semestre.',
          date: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          time: '17:00',
          type: 'meeting',
          location: 'Salle de conférence A',
        ));
      }

      // sort all by date & importance (urgent posts first)
      allUpcoming.sort((a, b) {
        // Importance first (isUrgent)
        bool isUrgentA = false;
        if (a is PostModel) isUrgentA = a.isUrgent;

        bool isUrgentB = false;
        if (b is PostModel) isUrgentB = b.isUrgent;

        if (isUrgentA && !isUrgentB) return -1;
        if (!isUrgentA && isUrgentB) return 1;

        // Then by Date
        DateTime? dtA;
        if (a is EventModel) {
          dtA = DateTime.tryParse(a.date);
        } else if (a is HomeworkModel) {
          dtA = DateTime.tryParse(a.dueDate);
        } else if (a is PostModel) {
          dtA = DateTime.tryParse(a.eventDate ?? a.date);
        }

        DateTime? dtB;
        if (b is EventModel) {
          dtB = DateTime.tryParse(b.date);
        } else if (b is HomeworkModel) {
          dtB = DateTime.tryParse(b.dueDate);
        } else if (b is PostModel) {
          dtB = DateTime.tryParse(b.eventDate ?? b.date);
        }

        if (dtA != null && dtB != null) return dtA.compareTo(dtB);
        if (dtA != null) return -1;
        if (dtB != null) return 1;
        return 0;
      });

      // Preserve known RSVP statuses from the previous local list.
      // When the server returns participationStatus as null in list endpoints,
      // we merge back the locally-confirmed status so it stays visible to the user.
      final Map<String, String?> knownStatuses = {};
      for (final e in _upcomingEvents) {
        if (e is EventModel && e.participationStatus != null) {
          knownStatuses[e.id] = e.participationStatus;
        } else if (e is PostModel && e.participationStatus != null) {
          knownStatuses[e.id] = e.participationStatus;
        }
      }

      // Add cached participation statuses from SharedPreferences
      knownStatuses.addAll(_cachedParticipationStatuses);

      final mergedUpcoming = allUpcoming.map((e) {
        final localStatus = knownStatuses[e is EventModel ? e.id : (e is PostModel ? e.id : '')];
        if (localStatus != null) {
          if (e is EventModel && e.participationStatus == null) {
            return e.copyWith(participationStatus: localStatus);
          } else if (e is PostModel && e.participationStatus == null) {
            return e.copyWith(participationStatus: localStatus);
          }
        }
        return e;
      }).toList();

      _upcomingEvents = mergedUpcoming;

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching upcoming dashboard events: $e');
    } finally {
      // After fetching, ensure index is valid
      if (_currentEventIndex >= _upcomingEvents.length) {
        _currentEventIndex = 0;
      }
    }
  }

  Future<void> fetchChildren({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _children = await _apiService.getChildren();
    } catch (e) {
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchStats({bool silent = false}) async {
    try {
      final stats = await _apiService.getDashboardStats();
      if (stats.isEmpty) return;
      notifyListeners();
    } catch (e) {
      // Handle silently (403 or other)
      debugPrint('Dashboard stats skipped or forbidden: $e');
    }
  }

  Future<void> fetchActivities({bool silent = false}) async {
    try {
      final rawActivities = await _apiService.getDashboardActivities();
      _activities = rawActivities.map((a) {
        final iconType = a['icon_type'] ?? 'info';
        IconData icon;
        Color color;

        switch (iconType) {
          case 'post':
          case 'news':
            icon = Icons.newspaper_rounded;
            color = Colors.blueAccent;
            break;
          case 'absence':
            icon = Icons.event_busy_rounded;
            color = Colors.redAccent;
            break;
          case 'grade':
            icon = Icons.grade_rounded;
            color = Colors.greenAccent;
            break;
          default:
            icon = Icons.info_outline_rounded;
            color = Colors.blueGrey;
        }

        return {
          ...a,
          'icon': icon,
          'color': color,
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      // Background fetch, handle silently
    }
  }

  List<GradeModel>? _cachedGrades;

  Future<void> fetchSubjectAverages(
      {String? semester, bool forceRefresh = false, bool silent = false}) async {
    try {
      if (forceRefresh || _cachedGrades == null) {
        final studentId = _children.isNotEmpty ? _children[0].id : 'me';
        _cachedGrades = await _apiService.getGrades(studentId);
      }

      final grades = _cachedGrades ?? [];
      if (grades.isEmpty) {
        _subjectAverages = [];
        notifyListeners();
        return;
      }

      // Filter by semester if specified
      final filteredGrades = (semester == null || semester == 'all')
          ? grades
          : grades.where((g) {
              final s = g.semester.toString().toUpperCase().replaceAll('S', '');
              final target =
                  semester.toString().toUpperCase().replaceAll('S', '');
              return s == target;
            }).toList();

      if (filteredGrades.isEmpty) {
        _subjectAverages = [];
        notifyListeners();
        return;
      }

      final Map<String, List<double>> subjectScores = {};
      for (var g in filteredGrades) {
        if (!subjectScores.containsKey(g.subject)) {
          subjectScores[g.subject] = [];
        }
        // Normalize to a 10-point scale: (grade / maxGrade) * 10
        final normalizedGrade =
            (g.grade / (g.maxGrade > 0 ? g.maxGrade : 10.0)) * 10.0;
        subjectScores[g.subject]!.add(normalizedGrade);
      }

      _subjectAverages = [];
      int index = 0;
      for (var subject in subjectScores.keys) {
        final scores = subjectScores[subject]!;
        final average =
            scores.fold(0.0, (sum, score) => sum + score) / scores.length;
        _subjectAverages.add({
          'index': index++,
          'subject': subject,
          'grade': double.parse(average.toStringAsFixed(2)),
        });
      }
      notifyListeners();
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> fetchEvolution(
      String studentId, String year, String semester) async {
    try {
      _evolutionData = await _apiService.getGradeEvolution(
        studentId: studentId,
        year: year,
        semester: semester,
      );
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}
