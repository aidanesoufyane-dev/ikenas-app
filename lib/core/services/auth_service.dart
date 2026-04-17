import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

/// AuthService handles all authentication state persistence and recovery.
/// This service manages:
/// - Secure token storage
/// - User data persistence
/// - Session recovery on app startup
/// - Logout clearing
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _roleKey = 'user_role';

  late SharedPreferences _prefs;

  static final AuthService _instance = AuthService._internal();

  AuthService._internal();

  static AuthService get instance => _instance;

  /// Initialize the auth service with SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save authentication token and user data after successful login
  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    try {
      await Future.wait([
        _prefs.setString(_tokenKey, token),
        _prefs.setString(_userDataKey, _encodeUserData(user)),
        _prefs.setString(_roleKey, user.role.toString()),
      ]);
    } catch (e) {
      throw Exception('Failed to save session: $e');
    }
  }

  /// Restore user session from persistent storage
  /// Returns null if no valid session exists
  Future<({String token, UserModel user})?>
      restoreSession() async {
    try {
      final token = _prefs.getString(_tokenKey);
      final userDataJson = _prefs.getString(_userDataKey);

      if (token == null || userDataJson == null) {
        return null;
      }

      final user = _decodeUserData(userDataJson);
      if (user == null) return null;

      return (token: token, user: user);
    } catch (e) {
      // If restoration fails, clear corrupted data
      await clearSession();
      return null;
    }
  }

  /// Get stored auth token without restoring full session
  String? getStoredToken() {
    return _prefs.getString(_tokenKey);
  }

  /// Get stored user without full restoration
  UserModel? getStoredUser() {
    final userDataJson = _prefs.getString(_userDataKey);
    if (userDataJson == null) return null;
    return _decodeUserData(userDataJson);
  }

  /// Get stored user role
  UserRole? getStoredRole() {
    final roleStr = _prefs.getString(_roleKey);
    if (roleStr == null) return null;
    return roleStr.contains('teacher') ? UserRole.teacher : UserRole.parent;
  }

  /// Clear all authentication data (called on logout)
  Future<void> clearSession() async {
    try {
      await Future.wait([
        _prefs.remove(_tokenKey),
        _prefs.remove(_userDataKey),
        _prefs.remove(_roleKey),
      ]);
    } catch (e) {
      throw Exception('Failed to clear session: $e');
    }
  }

  /// Check if a valid session exists
  Future<bool> hasValidSession() async {
    final session = await restoreSession();
    return session != null;
  }

  // ==================== Private Methods ====================

  /// Encode UserModel to JSON string for storage
  String _encodeUserData(UserModel user) {
    final json = user.toJson();
    // Simple encoding: convert to JSON string
    // For production, consider encryption using flutter_secure_storage
    return _jsonEncode(json);
  }

  /// Decode UserModel from JSON string
  UserModel? _decodeUserData(String jsonString) {
    try {
      final json = _jsonDecode(jsonString);
      return UserModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Simple JSON encoding (replacement for dart:convert if needed)
  String _jsonEncode(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Simple JSON decoding
  Map<String, dynamic> _jsonDecode(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
