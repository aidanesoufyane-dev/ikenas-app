import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class HomeworkViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<HomeworkModel> _homeworks = [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _seenAssignmentIds = {};
  // IDs the parent has locally marked as done — persisted so polling never reverts them
  final Set<String> _localDoneIds = {};
  bool _initialized = false;

  List<HomeworkModel> get homeworks => _homeworks;
  List<HomeworkModel> get devoirsList =>
      _homeworks.where((h) => h.type == 'devoir').toList();
  List<HomeworkModel> get examsList =>
      _homeworks.where((h) => h.type == 'exam').toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasNewAssignments {
    if (_homeworks.isEmpty) return false;
    // Check if any assignment in the list is NOT in our seen set
    return _homeworks.any((h) => !_seenAssignmentIds.contains(h.id));
  }

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling(String studentId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => refreshSilent(studentId));
    debugPrint('Homework polling started for student $studentId (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Homework polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> refreshSilent(String studentId) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchHomework(studentId, silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> fetchHomework(String studentId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_initialized) {
      await _loadSeenIds();
      _initialized = true;
    }

    try {
      // Fetch homework and exams in parallel to ensure fresh data for both
      final results = await Future.wait([
        _apiService.getHomework(studentId),
        _apiService.getExams(studentId),
      ]);

      final combined = [...results[0], ...results[1]];

      // Preserve locally-marked-done items so the 1-second poll never reverts them
      // before (or even after) the server confirms the submission.
      _homeworks = combined.map((h) {
        if (_localDoneIds.contains(h.id)) {
          return h.copyWith(status: HomeworkStatus.done);
        }
        return h;
      }).toList();

      // Sort by due date (closest first)
      _homeworks.sort((a, b) {
        if (a.dueDate.isEmpty) return 1;
        if (b.dueDate.isEmpty) return -1;
        return a.dueDate.compareTo(b.dueDate);
      });
    } catch (e) {
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      // Always notify listeners so UI updates reflect data changes
      notifyListeners();
    }
  }

  Future<void> _loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final seenList = prefs.getStringList('seen_homework_ids') ?? [];
    _seenAssignmentIds = seenList.toSet();

    final doneList = prefs.getStringList('local_done_homework_ids') ?? [];
    _localDoneIds.addAll(doneList);
  }

  Future<void> _saveLocalDoneIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('local_done_homework_ids', _localDoneIds.toList());
  }

  Future<void> markAllAsSeen() async {
    if (_homeworks.isEmpty) return;

    bool changed = false;
    for (var h in _homeworks) {
      if (_seenAssignmentIds.add(h.id)) {
        changed = true;
      }
    }

    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'seen_homework_ids', _seenAssignmentIds.toList());
      notifyListeners();
    }
  }

  Future<bool> updateStatus(
      String homeworkId, String studentId, HomeworkStatus newStatus,
      {String? filePath}) async {
    final index = _homeworks.indexWhere((h) => h.id == homeworkId);
    if (index == -1) return false;

    try {
      final h = _homeworks[index];

      final updatedHomework = await _apiService
          .updateHomeworkStatus(h.id, studentId, newStatus, filePath: filePath);

      if (newStatus == HomeworkStatus.done) {
        // Lock this ID so polling never reverts it back to not-started
        _localDoneIds.add(h.id);
        _saveLocalDoneIds();
      }

      _homeworks[index] = _homeworks[index].copyWith(
        status: newStatus,
        submissionId: updatedHomework.submissionId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      
      // If the backend says it was already submitted, treat it as a success locally
      if (_errorMessage != null && _errorMessage!.toLowerCase().contains('soumis')) {
        if (newStatus == HomeworkStatus.done) {
          _localDoneIds.add(_homeworks[index].id);
          _saveLocalDoneIds();
        }
        _homeworks[index] = _homeworks[index].copyWith(status: newStatus);
        _errorMessage = null; // Clear the error since we are handling it gracefully
        notifyListeners();
        return true;
      }

      notifyListeners();
      return false;
    }
  }

  // Stats for the UI - ONLY for Devoirs
  double get progressionRate {
    final devoirs = _homeworks.where((h) => h.type == 'devoir').toList();
    if (devoirs.isEmpty) return 0.0;
    final done = devoirs.where((h) => h.status == HomeworkStatus.done).length;
    return (done / devoirs.length) * 100;
  }

  String get progressionLabel {
    final devoirs = _homeworks.where((h) => h.type == 'devoir').toList();
    final done = devoirs.where((h) => h.status == HomeworkStatus.done).length;
    return "$done/${devoirs.length}";
  }
}

// Extension to help with copyWith if not already there (it wasn't in models.dart)
extension HomeworkModelExtension on HomeworkModel {
  HomeworkModel copyWith({
    String? id,
    String? subject,
    String? title,
    String? description,
    String? dueDate,
    String? startDate,
    HomeworkStatus? status,
    String? attachment,
    String? teacherComment,
    String? teacherName,
    String? submissionId,
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
      status: status ?? this.status,
      attachment: attachment ?? this.attachment,
      teacherComment: teacherComment ?? this.teacherComment,
      teacherName: teacherName ?? this.teacherName,
      submissionId: submissionId ?? this.submissionId,
      type: type ?? this.type,
      progressRate: progressRate ?? this.progressRate,
    );
  }
}
