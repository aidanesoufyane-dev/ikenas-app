import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class TimetableViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<TimetableSessionModel> _timetable = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TimetableSessionModel> get timetable => _timetable;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling(String studentId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => refreshSilent(studentId));
    debugPrint('Timetable polling started for student $studentId (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Timetable polling stopped');
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
      await fetchTimetable(studentId, silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> fetchTimetable(String studentId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _timetable = await _apiService.getTimetable(studentId);
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
}
