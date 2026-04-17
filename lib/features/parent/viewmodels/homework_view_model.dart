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

      // Data Sync: Overwriting _homeworks ensures that items deleted in backend
      // (not returned in list) disappear from the UI.
      _homeworks = combined;

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

    final originalStatus = _homeworks[index].status;

    // Optimistic UI update
    _homeworks[index] = _homeworks[index].copyWith(status: newStatus);
    notifyListeners();

    try {
      final h = _homeworks[index];
      // Sync with API - Use h.id because endpoint expects Assignment ID, and pass studentId
      final updatedHomework = await _apiService
          .updateHomeworkStatus(h.id, studentId, newStatus, filePath: filePath);

      // Update with backend response if valid
      _homeworks[index] = _homeworks[index].copyWith(
        submissionId: updatedHomework.submissionId,
      );

      // If we transition to 'done', we might want to refresh the list to get new submission IDs
      if (newStatus == HomeworkStatus.done) {
        // Optional: fetchHomework(currentStudentId);
      }
      return true;
    } catch (e) {
      // Rollback on actual error
      _homeworks[index] = _homeworks[index].copyWith(status: originalStatus);
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
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
