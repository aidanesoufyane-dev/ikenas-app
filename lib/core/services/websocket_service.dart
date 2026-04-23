import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/models.dart';
import 'notification_service.dart';

/// Real-time chat via Socket.io, which is the protocol used by the backend.
///
/// The backend emits/listens on these events:
///   receive_message  – new chat message arrives
///   new_notification – new notification arrives
///   join_thread      – join a message thread room
///   leave_thread     – leave a message thread room
///   send_message     – client sends a message
///   typing           – typing indicator
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() => _instance;

  WebSocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  final _messageStreamController =
      StreamController<ChatMessageModel>.broadcast();
  final _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<ChatMessageModel> get messageStream =>
      _messageStreamController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;
  Stream<bool> get connectionStatusStream =>
      _connectionStatusController.stream;

  bool get isConnected => _isConnected;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Call once after login with the JWT token.
  void initialize({required String token, required String baseUrl}) {
    // Derive WS URL from the HTTP base URL (strip /api, swap http→ws)
    final serverRoot = baseUrl
        .replaceAll(RegExp(r'/api/?$'), '')
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    _connect(token: token, serverUrl: serverRoot);
  }

  void _connect({required String token, required String serverUrl}) {
    _socket?.disconnect();
    _socket?.dispose();

    debugPrint('[Socket.io] Connecting to $serverUrl');

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _isConnected = true;
        _connectionStatusController.add(true);
        debugPrint('[Socket.io] Connected');
      })
      ..onDisconnect((_) {
        _isConnected = false;
        _connectionStatusController.add(false);
        debugPrint('[Socket.io] Disconnected');
      })
      ..onConnectError((err) {
        _isConnected = false;
        _connectionStatusController.add(false);
        debugPrint('[Socket.io] Connect error: $err');
      })
      ..on('receive_message', _onReceiveMessage)
      ..on('new_message', _onReceiveMessage)
      ..on('new_notification', _onNotification)
      ..on('notification', _onNotification)
      ..on('typing', (data) {
        _eventStreamController.add({'type': 'typing', 'data': data});
      })
      ..on('stop_typing', (data) {
        _eventStreamController.add({'type': 'stop_typing', 'data': data});
      })
      ..connect();
  }

  Future<void> connect() async {
    _socket?.connect();
  }

  Future<void> disconnect() async {
    _socket?.disconnect();
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  void dispose() {
    _socket?.dispose();
    _messageStreamController.close();
    _eventStreamController.close();
    _connectionStatusController.close();
  }

  // ---------------------------------------------------------------------------
  // Sending events
  // ---------------------------------------------------------------------------

  void sendMessage({
    required String threadId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) {
    if (!_isConnected) {
      debugPrint('[Socket.io] Not connected – cannot send message');
      return;
    }
    _socket?.emit('send_message', {
      'threadId': threadId,
      'content': content,
      'type': type,
      if (metadata != null) ...metadata,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void joinThread(String threadId) {
    _socket?.emit('join_thread', {'threadId': threadId});
    debugPrint('[Socket.io] Joined thread $threadId');
  }

  void leaveThread(String threadId) {
    _socket?.emit('leave_thread', {'threadId': threadId});
    debugPrint('[Socket.io] Left thread $threadId');
  }

  void sendTypingIndicator(String threadId) {
    _socket?.emit('typing', {'threadId': threadId});
  }

  void stopTypingIndicator(String threadId) {
    _socket?.emit('stop_typing', {'threadId': threadId});
  }

  void sendPing() {
    _socket?.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
  }

  // ---------------------------------------------------------------------------
  // Incoming event handlers
  // ---------------------------------------------------------------------------

  void _onReceiveMessage(dynamic data) {
    try {
      final Map<String, dynamic> raw = Map<String, dynamic>.from(
          data is Map ? data : {'message': data});
      final msgData = raw['message'] ?? raw;
      final chatMessage =
          ChatMessageModel.fromJson(Map<String, dynamic>.from(msgData as Map));
      _messageStreamController.add(chatMessage);
      debugPrint('[Socket.io] Message received: ${chatMessage.id}');

      // Show local push notification for incoming messages
      NotificationService.instance.show(
        title: 'Nouveau message',
        body: chatMessage.content.isNotEmpty ? chatMessage.content : '...',
      );
    } catch (e) {
      debugPrint('[Socket.io] Error parsing message: $e');
    }
  }

  void _onNotification(dynamic data) {
    try {
      _eventStreamController.add({
        'type': 'notification',
        'data': data,
      });
      debugPrint('[Socket.io] Notification received');

      // Show local notification so user sees it while app is open
      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final title = map['title']?.toString() ?? 'Nouvelle notification';
      final body = map['message']?.toString() ?? '';
      NotificationService.instance.show(title: title, body: body);
    } catch (e) {
      debugPrint('[Socket.io] Error handling notification: $e');
    }
  }
}
