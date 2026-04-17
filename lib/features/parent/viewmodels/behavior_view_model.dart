import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

class BehaviorViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get summary => _summary;
  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling(String studentId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => refreshSilent(studentId));
    debugPrint('Behavior polling started for student $studentId (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Behavior polling stopped');
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
      await fetchBehaviorData(studentId, silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> fetchBehaviorData(String studentId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _apiService.getBehaviorSummary(studentId),
        _apiService.getBehaviorHistory(studentId),
      ]);
      _summary = results[0] as Map<String, dynamic>;
      _history = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
