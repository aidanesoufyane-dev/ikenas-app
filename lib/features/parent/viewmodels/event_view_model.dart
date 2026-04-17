import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class EventViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<EventModel> _events = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  // Cache for participation statuses loaded from SharedPreferences
  final Map<String, String?> _cachedParticipationStatuses = {};

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => refreshSilent());
    debugPrint('Event polling started (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Event polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  /// Initialize EventViewModel - load cached participation statuses
  Future<void> init() async {
    await _loadCachedParticipationStatuses();
    await fetchEvents();
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

  Future<void> refreshSilent() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchEvents(silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  // Fetch all events
  Future<void> fetchEvents({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final freshEvents = await _apiService.getEvents();

      // Preserve known RSVP status from local state if the server doesn't return one.
      // This prevents the 1-second polling from erasing the user's confirmed response.
      final Map<String, String?> knownStatuses = {
        for (final e in _events) e.id: e.participationStatus
      };

      // Add cached participation statuses from SharedPreferences
      knownStatuses.addAll(_cachedParticipationStatuses);

      _events = freshEvents.map((e) {
        final localStatus = knownStatuses[e.id];
        if (e.participationStatus == null && localStatus != null) {
          return e.copyWith(participationStatus: localStatus);
        }
        return e;
      }).toList();
    } catch (e) {
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error fetching events: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Get event details
  Future<void> fetchEventDetails(String eventId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedEvent = await _apiService.getEventDetails(eventId);
      _isLoadingDetails = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDetails = false;
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error fetching event details: $e');
      notifyListeners();
    }
  }

  // Select an event for preview
  void selectEvent(EventModel event) {
    _selectedEvent = event;
    notifyListeners();
  }

  // Clear selected event
  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }

  // Respond to event (RSVP)
  Future<bool> respondToEvent(String eventId, String status) async {
    try {
      // Ensure we send standardized values to API
      final String standardizedStatus =
          (status.toLowerCase() == 'going' || status.toLowerCase() == 'oui' || status.toLowerCase() == 'yes')
              ? 'going'
              : 'not_going';

      final success =
          await _apiService.respondToEvent(eventId, standardizedStatus);

      if (success) {
        // Save participation status to local storage for persistence
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('event_participation_$eventId', standardizedStatus);
          // Also update cache
          _cachedParticipationStatuses[eventId] = standardizedStatus;
          debugPrint('Saved participation status for $eventId: $standardizedStatus');
        } catch (e) {
          debugPrint('Error saving participation status: $e');
        }

        // Update local event with the updated data from API
        final index = _events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          _events[index] = _events[index].copyWith(participationStatus: standardizedStatus);
          notifyListeners();
        }

        // Update selected event if it's the same
        if (_selectedEvent?.id == eventId) {
          _selectedEvent = _selectedEvent!.copyWith(participationStatus: standardizedStatus);
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error responding to event: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      final success = await _apiService.deleteEvent(eventId);

      if (success) {
        _events.removeWhere((e) => e.id == eventId);
        if (_selectedEvent?.id == eventId) {
          clearSelectedEvent();
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error deleting event: $e');
      notifyListeners();
      return false;
    }
  }

  // Refresh events
  Future<void> refresh() async {
    await fetchEvents();
  }
}
