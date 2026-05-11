import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/mock_data_service.dart';

class CalendarViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEvents(String studentId, int month, int year) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _apiService.getCalendarEvents(
        studentId: studentId,
        month: month,
        year: year,
      );
    } catch (e) {
      _events = [];
      _errorMessage = 'Impossible de charger le calendrier.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
