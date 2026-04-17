import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class LocationViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  BusLocationModel? _currentLocation;
  List<LocationHistoryRecord> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  BusLocationModel? get currentLocation => _currentLocation;
  List<LocationHistoryRecord> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling(String studentId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => refreshSilent(studentId));
    debugPrint('Location polling started for student $studentId (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Location polling stopped');
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
      await fetchLocationData(studentId, silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> fetchLocationData(String studentId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _apiService.getBusLocation(studentId),
        _apiService.getLocationHistory(studentId),
      ]);

      _currentLocation = results[0] as BusLocationModel;
      _history = results[1] as List<LocationHistoryRecord>;
    } catch (e) {
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error fetching location data: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
