import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as sio;

/// Wraps a Socket.io connection to the backend.
/// The backend authenticates via [handshake.auth.token].
class ChatService {
  final String serverUrl;
  final String token;

  late sio.Socket _socket;
  bool _isConnected = false;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  ChatService(this.serverUrl, this.token);

  void connect() {
    _socket = sio.io(
      serverUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      _isConnected = true;
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
    });

    _socket.on('new-message', (data) {
      _messageController.add({'event': 'new-message', 'data': data});
    });

    _socket.on('message-updated', (data) {
      _messageController.add({'event': 'message-updated', 'data': data});
    });

    _socket.on('message-deleted', (data) {
      _messageController.add({'event': 'message-deleted', 'data': data});
    });

    _socket.connect();
  }

  /// Emit [send-message] to the server.
  void sendMessage(Map<String, dynamic> data) {
    if (!_isConnected) return;
    _socket.emit('send-message', data);
  }

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  void disconnect() {
    _socket.disconnect();
    _socket.dispose();
    _isConnected = false;
    _messageController.close();
  }

  bool get isConnected => _isConnected;
}
