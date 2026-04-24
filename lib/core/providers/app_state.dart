import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/websocket_service.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _initializeApp();
  }

  UserModel? _currentUser;
  bool _isDarkMode = true;
  int _selectedChildIndex = 0;
  Locale _locale = const Locale('fr');
  bool _isOffline = false;

  /// Initialize app settings and auth service
  Future<void> _initializeApp() async {
    await AuthService.instance.init();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'fr';
    _locale = Locale(lang);
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;

    final token = prefs.getString('auth_token');
    if (token != null) {
      ApiService.instance.setToken(token);
    }
    notifyListeners();
  }

  int _dashboardIndex = 0;
  bool _biometricsEnabled = true;
// Removed global _profileAvatarIndex in favor of UserModel.avatarIndex

  // Notification settings
  bool _pushEnabled = true;
  bool _academicAlertsEnabled = true;
  bool _securitySafetyEnabled = true;
  bool _newsAlertsEnabled = true;
  final List<String> _savedPostIds = [];
  final Set<String> _mutedChatIds = {};
  final Set<String> _groupAdminOnlyMessaging = {};

  UserModel? get currentUser => _currentUser;
  bool get isDarkMode => _isDarkMode;
  int get selectedChildIndex => _selectedChildIndex;
  Locale get locale => _locale;
  bool get isOffline => _isOffline;
  int get dashboardIndex => _dashboardIndex;
  bool get biometricsEnabled => _biometricsEnabled;
  int? get profileAvatarIndex => _currentUser?.avatarIndex;

  // Notification getters
  bool get pushEnabled => _pushEnabled;
  bool get academicAlertsEnabled => _academicAlertsEnabled;
  bool get securitySafetyEnabled => _securitySafetyEnabled;
  bool get newsAlertsEnabled => _newsAlertsEnabled;
  List<String> get savedPostIds => _savedPostIds;
  Set<String> get mutedChatIds => _mutedChatIds;
  Set<String> get groupAdminOnlyMessaging => _groupAdminOnlyMessaging;

  // RTL Logic
  TextDirection get textDirection =>
      _locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  void setLocale(Locale loc) async {
    _locale = loc;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', loc.languageCode);

    notifyListeners();
  }

  bool get isLoggedIn => _currentUser != null;
  bool get isParent => _currentUser?.role == UserRole.parent;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;

  /// Restore user session from persistent storage on app startup
  /// Returns true if session was successfully restored, false otherwise
  Future<bool> restoreSessionFromStorage() async {
    try {
      final session = await AuthService.instance.restoreSession();
      if (session != null) {
        _currentUser = session.user;
        ApiService.instance.setToken(session.token);

        // Reconnect WebSocket on session restore
        WebSocketService().initialize(token: session.token, baseUrl: ApiService.instance.baseUrl, userId: _currentUser!.id);

        notifyListeners();
        // Re-register FCM token on session restore (token may have rotated)
        final fcmToken = await NotificationService.instance.getToken();
        if (fcmToken != null) {
          await ApiService.instance.registerFcmToken(fcmToken);
        }
        return true;
      }
      return false;
    } catch (e) {
      // If restoration fails, clear any corrupted data
      await AuthService.instance.clearSession();
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final authData = await ApiService.instance.login(email, password);
      if (authData['user'] != null) {
        _currentUser = UserModel.fromJson(authData['user']);
        final token = authData['token'] ?? authData['access_token'];

        // Save session persistently
        await AuthService.instance.saveSession(
          token: token,
          user: _currentUser!,
        );

        // Set token in API service
        ApiService.instance.setToken(token);

        // Connect WebSocket for real-time notifications
        WebSocketService().initialize(token: token, baseUrl: ApiService.instance.baseUrl, userId: _currentUser!.id);

        // Register FCM device token so backend can send push notifications
        final fcmToken = await NotificationService.instance.getToken();
        if (fcmToken != null) {
          await ApiService.instance.registerFcmToken(fcmToken);
        }

        notifyListeners();
      } else {
        throw Exception('User data not found in response');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _dashboardIndex = 0;

    // Clear session from storage
    await AuthService.instance.clearSession();

    // Clear API token
    ApiService.instance.clearToken();

    notifyListeners();
  }

  void toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  void toggleOfflineMode() {
    _isOffline = !_isOffline;
    notifyListeners();
  }

  void setSelectedChild(int index) {
    _selectedChildIndex = index;
    notifyListeners();
  }

  void setDashboardIndex(int index) {
    _dashboardIndex = index;
    notifyListeners();
  }

  void toggleBiometrics() {
    _biometricsEnabled = !_biometricsEnabled;
    notifyListeners();
  }

  void updatePhone(String newPhone) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(phone: newPhone);
      notifyListeners();
    }
  }

  void updateName(String newName) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(name: newName);
      notifyListeners();
    }
  }

  void updateProfileAvatar(int index) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(avatarIndex: index);
      notifyListeners();
    }
  }

  void togglePush(bool value) {
    _pushEnabled = value;
    notifyListeners();
  }

  void toggleAcademicAlerts(bool value) {
    _academicAlertsEnabled = value;
    notifyListeners();
  }

  void toggleSecuritySafety(bool value) {
    _securitySafetyEnabled = value;
    notifyListeners();
  }

  void toggleNewsAlerts(bool value) {
    _newsAlertsEnabled = value;
    notifyListeners();
  }

  void toggleSavePost(String postId) {
    if (_savedPostIds.contains(postId)) {
      _savedPostIds.remove(postId);
    } else {
      _savedPostIds.add(postId);
    }
    notifyListeners();
  }

  bool isPostSaved(String postId) => _savedPostIds.contains(postId);

  void toggleMuteChat(String chatId) {
    if (_mutedChatIds.contains(chatId)) {
      _mutedChatIds.remove(chatId);
    } else {
      _mutedChatIds.add(chatId);
    }
    notifyListeners();
  }

  void deleteChat(String chatId) {
    notifyListeners();
  }

  void toggleAdminOnlyMessaging(String groupName) {
    if (_groupAdminOnlyMessaging.contains(groupName)) {
      _groupAdminOnlyMessaging.remove(groupName);
    } else {
      _groupAdminOnlyMessaging.add(groupName);
    }
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _currentUser = user;
    final token = AuthService.instance.getStoredToken();
    if (token != null) {
      AuthService.instance.saveSession(token: token, user: user);
    }
    notifyListeners();
  }
}
