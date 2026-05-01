/// Central configuration for the Ikenas app.
///
/// Change [baseUrl] to match your backend environment:
///   - Android emulator : http://10.0.2.2:5000/api
///   - iOS simulator    : http://localhost:5000/api
///   - Real device      : http://YOUR_MACHINE_IP:5000/api
///   - Production       : https://api.yourdomain.com/api
class AppConfig {
  AppConfig._();

  /// The root URL that every API call is relative to.
  /// Override with the --dart-define flag at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ikenas-api-v2.onrender.com/api',
  );

  /// Server root (no trailing /api). Use this wherever code constructs its
  /// own Dio instance or builds a WebSocket URL directly.
  static String get serverUrl =>
      baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  /// WebSocket base URL (ws/wss), derived from [baseUrl].
  /// Used by [WebSocketService] to connect to Socket.io.
  static String get wsBaseUrl =>
      serverUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
}
