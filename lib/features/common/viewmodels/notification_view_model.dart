import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => refreshSilent());
    debugPrint('Notification polling started (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Notification polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> refreshSilent() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchNotifications(silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  String? _currentUserId;

  void setCurrentUserId(String? id) {
    _currentUserId = id;
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final fetched = await _apiService.getNotifications(currentUserId: _currentUserId);
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_notification_ids') ?? <String>[];
      final updated = fetched.where((n) => !deletedIds.contains(n.id)).toList();
      final changed = updated.length != _notifications.length ||
          updated.any((n) => !_notifications.any((old) => old.id == n.id && old.isRead == n.isRead));
      _notifications = updated;
      if (changed) notifyListeners();
    } catch (e) {
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic UI
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      try {
        await _apiService.markNotificationRead(id);
      } catch (e) {
        // Rollback on failure
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        _errorMessage = _apiService.getLocalizedErrorMessage(e);
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final oldNotifications = List<NotificationModel>.from(_notifications);

    // Optimistic UI
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _apiService.markAllNotificationsRead();
    } catch (e) {
      _notifications = oldNotifications;
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    // Optimistic UI
    final oldNotifications = List<NotificationModel>.from(_notifications);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_notification_ids') ?? <String>[];
      if (!deletedIds.contains(id)) {
        deletedIds.add(id);
        await prefs.setStringList('deleted_notification_ids', deletedIds);
      }
      await _apiService.deleteNotification(id);
    } catch (e) {
      _notifications = oldNotifications;
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> deleteAllNotifications() async {
    // Optimistic UI
    final oldNotifications = List<NotificationModel>.from(_notifications);
    final idsToDelete = _notifications.map((n) => n.id).toList();
    _notifications.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_notification_ids') ?? <String>[];
      for (final id in idsToDelete) {
        if (!deletedIds.contains(id)) deletedIds.add(id);
      }
      await prefs.setStringList('deleted_notification_ids', deletedIds);
      await _apiService.deleteAllNotifications();
    } catch (e) {
      _notifications = oldNotifications;
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      notifyListeners();
    }
  }
}
