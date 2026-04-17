import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

class SecurityViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  Map<String, dynamic> _status = {};
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get status => _status;
  List<Map<String, dynamic>> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSecurityData(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getSecurityStatus(studentId),
        _apiService.getSecurityAlerts(studentId),
      ]);
      _status = results[0] as Map<String, dynamic>;
      _alerts = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
