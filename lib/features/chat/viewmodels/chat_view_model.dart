import 'package:flutter/material.dart';
import '../chat_api_service.dart';
import '../models/chat_message_model.dart';
import '../models/chat_thread_model.dart';

class ChatViewModel extends ChangeNotifier {
  ChatApiService? _apiService;
  final List<ChatThread> _conversations = [];
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _isConnected = false;
  String? _currentThreadId;
  String? _userId;
  String? _userName;
  Map<String, bool> _typingUsers = {}; // threadId -> isTyping

  // Getters
  List<ChatThread> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  bool get loading => _loading;
  bool get isConnected => _isConnected;
  String? get currentThreadId => _currentThreadId;
  String? get userId => _userId;
  String? get userName => _userName;
  Map<String, bool> get typingUsers => _typingUsers;

  ChatViewModel(this._apiService);

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setApiService(ChatApiService apiService) {
    _apiService = apiService;
  }

  Future<void> loadConversations() async {
    if (_apiService == null) return;
    try {
      _loading = true;
      notifyListeners();

      final threads = await _apiService!.fetchMessages();
      _conversations.clear();

      for (final thread in threads) {
        try {
          _conversations.add(ChatThread.fromJson(thread));
        } catch (e) {
          debugPrint('Error parsing thread: $e');
        }
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String threadId) async {
    if (_apiService == null) return;
    try {
      _currentThreadId = threadId;
      _loading = true;
      notifyListeners();

      final history = await _apiService!.fetchMessages();
      _messages.clear();

      for (final msg in history) {
        _messages.add(ChatMessage.fromJson(msg, isOwn: msg['senderId'] == _userId));
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      _loading = false;
      notifyListeners();
    }
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void setConnectionStatus(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  void setTypingIndicator(String userId, bool isTyping) {
    if (isTyping) {
      _typingUsers[userId] = true;
    } else {
      _typingUsers.remove(userId);
    }
    notifyListeners();
  }

  void clearTypingIndicators() {
    _typingUsers.clear();
    notifyListeners();
  }

  Future<void> sendMessage(String content, {String? reactedMessageId}) async {
    if (_apiService == null || _currentThreadId == null) return;

    try {
      await _apiService!.sendMessage(
        content: content,
        recipientType: 'individual',
        targetUserId: _currentThreadId,
      );

      // Create local message for immediate UI update
      final localMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _userId ?? 'unknown',
        senderName: _userName ?? 'You',
        senderAvatar: '',
        content: content,
        timestamp: DateTime.now(),
        isOwn: true,
      );

      addMessage(localMsg);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }
}
