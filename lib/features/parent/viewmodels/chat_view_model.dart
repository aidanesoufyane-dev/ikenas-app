import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../chat/chat_api_service.dart';

/// Parent-side ChatViewModel.
/// Groups the flat /messages list into per-partner (individual) and
/// per-class (group) threads so both tabs are populated.
class ChatViewModel extends ChangeNotifier {
  ChatApiService? _chatApi;
  String? _currentUserId;

  List<ChatThreadModel> _threads = [];
  List<ChatMessageModel> _activeMessages = [];
  bool _isLoadingThreads = false;
  bool _isLoadingMessages = false;
  String? _errorMessage;
  String? _activeThreadId;
  // 'individual' | 'class' — remembered so fetchMessages filters correctly
  String? _activeThreadType;

  Timer? _pollingTimer;
  bool _isRefreshing = false;
  final bool _isWebSocketConnected = false;

  // ── getters ──────────────────────────────────────────────────
  List<ChatThreadModel> get threads => _threads;
  List<ChatMessageModel> get activeMessages => _activeMessages;
  bool get isLoadingThreads => _isLoadingThreads;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get errorMessage => _errorMessage;
  String? get activeThreadId => _activeThreadId;
  bool get isWebSocketConnected => _isWebSocketConnected;

  // ── API init ─────────────────────────────────────────────────
  Future<ChatApiService> _getApi() async {
    if (_chatApi != null) return _chatApi!;
    final token = ApiService.instance.token ?? '';
    final baseUrl = ApiService.instance.baseUrl;
    await AuthService.instance.init();
    _currentUserId = AuthService.instance.getStoredUser()?.id;
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));
    _chatApi = ChatApiService(dio);
    return _chatApi!;
  }

  // ── lifecycle ────────────────────────────────────────────────
  Future<void> initializeWebSocket() async {}

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _refreshSilent());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _refreshSilent() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchThreads(silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // ── fetchThreads ─────────────────────────────────────────────
  Future<void> fetchThreads({bool silent = false}) async {
    if (!silent) {
      _isLoadingThreads = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final api = await _getApi();
      final msgs = await api.fetchMessages();
      _threads = _groupIntoThreads(msgs);
    } catch (e) {
      if (!silent) _errorMessage = e.toString();
      debugPrint('[ParentChatVM] fetchThreads error: $e');
    } finally {
      _isLoadingThreads = false;
      notifyListeners();
    }
  }

  // ── fetchMessages ────────────────────────────────────────────
  /// [threadId] is a partnerId for individual threads or a classId for groups.
  Future<void> fetchMessages(String threadId, {bool silent = false}) async {
    _activeThreadId = threadId;
    // Determine thread type from the loaded threads list
    final thread = _threads.firstWhere(
      (t) => t.id == threadId,
      orElse: () => ChatThreadModel(
        id: threadId,
        contactName: '',
        contactRole: 'ENSEIGNANT',
        lastMessage: '',
        lastTime: '',
      ),
    );
    _activeThreadType =
        thread.contactRole == 'GROUPE' ? 'class' : 'individual';

    if (!silent) {
      _isLoadingMessages = true;
      _activeMessages = [];
      notifyListeners();
    }
    try {
      final api = await _getApi();
      final msgs = await api.fetchMessages();

      List<ChatMessageModel> freshFromServer;

      if (_activeThreadType == 'class') {
        freshFromServer = msgs
            .where((msg) =>
                msg['recipientType'] == 'class' &&
                _extractClassId(msg) == threadId)
            .map(_toModel)
            .toList();
      } else {
        freshFromServer = msgs
            .where((msg) {
              if (msg['recipientType'] != 'individual') return false;
              final senderId = _extractSenderId(msg);
              final targetId = _extractTargetId(msg);
              final isOwn = senderId == _currentUserId;
              return (isOwn && targetId == threadId) ||
                  (!isOwn && senderId == threadId);
            })
            .map(_toModel)
            .toList();
      }

      // The backend filter does NOT return messages sent BY the parent
      // (their replies have targetUser=teacher, not targetUser=parent).
      // On silent refresh, preserve locally-sent messages so they don't vanish.
      if (silent) {
        final serverIds = freshFromServer.map((m) => m.id).toSet();
        final localOnly = _activeMessages
            .where((m) => m.isMe && !serverIds.contains(m.id))
            .toList();
        _activeMessages = [...freshFromServer, ...localOnly]
          ..sort((a, b) => a.time.compareTo(b.time));
      } else {
        _activeMessages = freshFromServer;
      }
    } catch (e) {
      if (!silent) _errorMessage = e.toString();
      debugPrint('[ParentChatVM] fetchMessages error: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // ── canReply / replyableMessageId ────────────────────────────
  /// The backend only allows replies to messages where allowReply == true.
  /// POST /messages is restricted to admin/teacher/supervisor roles.
  /// Parents can only use POST /messages/:id/reply.
  String? get replyableMessageId {
    for (final msg in _activeMessages.reversed) {
      if (msg.isMe) continue; // can't reply to own messages
      if (msg.id.isEmpty || msg.id.startsWith('temp_')) continue;
      if (msg.metadata?['allowReply'] == true) return msg.id;
    }
    return null;
  }

  bool get canReply => replyableMessageId != null;

  // ── sendMessage ──────────────────────────────────────────────
  Future<void> sendMessage(String threadId, String content,
      [String type = 'text']) async {
    final replyId = replyableMessageId;
    if (replyId == null) {
      // No message with allowReply=true — cannot send
      _errorMessage = 'replies_not_allowed';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final temp = ChatMessageModel(
      id: 'temp_${now.millisecondsSinceEpoch}',
      threadId: threadId,
      senderId: _currentUserId ?? '',
      content: content,
      time: _fmt(now),
      isMe: true,
    );
    _activeMessages.add(temp);
    notifyListeners();

    try {
      final api = await _getApi();
      // POST /messages/:id/reply — the only endpoint available to parents
      final result = await api.replyToMessage(replyId, content);
      // Replace temp with the real message ID from the server response
      final realId = (result['_id'] ?? result['id'])?.toString() ?? '';
      if (realId.isNotEmpty) {
        final idx = _activeMessages.indexWhere((m) => m.id == temp.id);
        if (idx != -1) {
          _activeMessages[idx] = ChatMessageModel(
            id: realId,
            threadId: temp.threadId,
            senderId: temp.senderId,
            content: temp.content,
            time: temp.time,
            isMe: true,
          );
        }
      }
      _errorMessage = null;
    } catch (e) {
      _activeMessages.removeWhere((m) => m.id == temp.id);
      _errorMessage = e.toString();
      debugPrint('[ParentChatVM] sendMessage error: $e');
    } finally {
      notifyListeners();
    }
  }

  // ── editMessage ──────────────────────────────────────────────
  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      final api = await _getApi();
      final ok = await api.editMessage(messageId, newContent);
      if (ok) {
        final idx = _activeMessages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          final old = _activeMessages[idx];
          _activeMessages[idx] = ChatMessageModel(
            id: old.id,
            threadId: old.threadId,
            senderId: old.senderId,
            senderName: old.senderName,
            senderAvatar: old.senderAvatar,
            content: newContent,
            time: old.time,
            createdAt: old.createdAt,
            isMe: old.isMe,
            metadata: old.metadata,
            attachments: old.attachments,
          );
          notifyListeners();
        }
      }
      return ok;
    } catch (e) {
      debugPrint('[ParentChatVM] editMessage error: $e');
      return false;
    }
  }

  // ── deleteConversation ─────────────────────────────────────────
  Future<bool> deleteConversation(String threadId) async {
    try {
      // Since the backend doesn't have a clear "delete entire thread" 
      // endpoint for parents yet, we just remove it locally.
      _threads.removeWhere((t) => t.id == threadId);
      if (_activeThreadId == threadId) {
        clearActiveChat();
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ParentChatVM] deleteConversation error: $e');
      return false;
    }
  }

  // ── deleteMessage ───────────────────────────────────────────
  Future<bool> deleteMessage(String messageId) async {
    try {
      final api = await _getApi();
      final ok = await api.deleteMessage(messageId);
      if (ok) {
        _activeMessages.removeWhere((m) => m.id == messageId);
        notifyListeners();
      }
      return ok;
    } catch (e) {
      debugPrint('[ParentChatVM] deleteMessage error: $e');
      return false;
    }
  }

  void sendTypingIndicator(String threadId) {}
  void stopTypingIndicator(String threadId) {}

  void clearActiveChat() {
    _activeThreadId = null;
    _activeThreadType = null;
    _activeMessages = [];
    notifyListeners();
  }

  // ── grouping ─────────────────────────────────────────────────

  List<ChatThreadModel> _groupIntoThreads(List<Map<String, dynamic>> msgs) {
    // Individual: keyed by partnerId
    final Map<String, Map<String, dynamic>> latestInd = {};
    final Map<String, String> indNames = {};
    final Map<String, String?> indAvatars = {};

    // Class/group: keyed by classId
    final Map<String, Map<String, dynamic>> latestCls = {};
    final Map<String, String> clsNames = {};

    for (final msg in msgs) {
      final recipientType = msg['recipientType']?.toString();

      if (recipientType == 'individual') {
        final senderId = _extractSenderId(msg);
        final targetId = _extractTargetId(msg);
        final isOwn = senderId == _currentUserId;
        final partnerId = isOwn ? targetId : senderId;
        if (partnerId == null || partnerId.isEmpty) continue;

        // Capture partner name from whichever side has a full object
        if (!isOwn) {
          final s = msg['sender'];
          if (s is Map) {
            indNames[partnerId] =
                (s['fullName'] ?? s['name'] ?? '').toString();
            indAvatars[partnerId] = s['avatar']?.toString();
          }
        } else {
          final t = msg['targetUser'];
          if (t is Map) {
            indNames.putIfAbsent(partnerId,
                () => (t['fullName'] ?? t['name'] ?? '').toString());
            indAvatars.putIfAbsent(
                partnerId, () => t['avatar']?.toString());
          }
        }
        _keepLatest(latestInd, partnerId, msg);

      } else if (recipientType == 'class') {
        final classId = _extractClassId(msg);
        if (classId == null || classId.isEmpty) continue;

        final cls = msg['targetClass'];
        if (cls is Map) {
          clsNames.putIfAbsent(
              classId,
              () =>
                  (cls['name'] ?? cls['className'] ?? classId).toString());
        } else {
          clsNames.putIfAbsent(classId, () => classId);
        }
        _keepLatest(latestCls, classId, msg);
      }
    }

    final threads = <ChatThreadModel>[];

    // Individual threads
    for (final e in latestInd.entries) {
      final partnerId = e.key;
      final msg = e.value;
      final createdAt =
          DateTime.tryParse(msg['createdAt']?.toString() ?? '') ??
              DateTime.now();
      threads.add(ChatThreadModel(
        id: partnerId,
        contactName: indNames[partnerId]?.isNotEmpty == true
            ? indNames[partnerId]!
            : 'Inconnu',
        contactRole: 'ENSEIGNANT',
        lastMessage: msg['content']?.toString() ?? '',
        lastTime: _fmt(createdAt),
        unreadCount: 0,
        avatarUrl: indAvatars[partnerId],
      ));
    }

    // Group / class threads
    for (final e in latestCls.entries) {
      final classId = e.key;
      final msg = e.value;
      final createdAt =
          DateTime.tryParse(msg['createdAt']?.toString() ?? '') ??
              DateTime.now();
      final senderObj = msg['sender'];
      final senderName =
          (senderObj is Map ? (senderObj['fullName'] ?? senderObj['name'] ?? '') : '')
              .toString();
      final content = msg['content']?.toString() ?? '';
      threads.add(ChatThreadModel(
        id: classId,
        contactName: clsNames[classId] ?? classId,
        contactRole: 'GROUPE',
        lastMessage:
            senderName.isNotEmpty ? '$senderName: $content' : content,
        lastTime: _fmt(createdAt),
        unreadCount: 0,
        avatarUrl: null,
      ));
    }

    threads.sort((a, b) => b.lastTime.compareTo(a.lastTime));
    return threads;
  }

  void _keepLatest(Map<String, Map<String, dynamic>> map, String key,
      Map<String, dynamic> msg) {
    final createdAt =
        DateTime.tryParse(msg['createdAt']?.toString() ?? '') ?? DateTime(2000);
    final existing = map[key];
    final existingDate = existing != null
        ? DateTime.tryParse(existing['createdAt']?.toString() ?? '') ??
            DateTime(2000)
        : DateTime(2000);
    if (existingDate.isBefore(createdAt)) map[key] = msg;
  }

  ChatMessageModel _toModel(Map<String, dynamic> msg) {
    final senderId = _extractSenderId(msg);
    final createdAt =
        DateTime.tryParse(msg['createdAt']?.toString() ?? '') ?? DateTime.now();

    // Extract sender name & avatar
    String senderName = '';
    String? senderAvatar;
    final senderObj = msg['sender'];
    if (senderObj is Map) {
      senderName = (senderObj['fullName'] ?? senderObj['name'] ?? '').toString();
      senderAvatar = senderObj['avatar']?.toString();
    }

    // Extract attachments
    List<String> attachments = [];
    if (msg['attachments'] is List) {
      for (final a in msg['attachments']) {
        if (a is String && a.isNotEmpty) {
          attachments.add(a);
        } else if (a is Map) {
          final url = (a['url'] ?? a['path'] ?? '').toString();
          if (url.isNotEmpty) attachments.add(url);
        }
      }
    }

    return ChatMessageModel(
      id: (msg['_id'] ?? msg['id'])?.toString() ?? '',
      threadId: _activeThreadId ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: msg['content']?.toString() ?? '',
      time: _fmt(createdAt),
      createdAt: createdAt,
      isMe: senderId == _currentUserId,
      metadata: {'allowReply': msg['allowReply'] ?? false},
      attachments: attachments,
    );
  }

  // ── field extractors ──────────────────────────────────────────

  String _extractSenderId(Map<String, dynamic> msg) {
    final s = msg['sender'];
    if (s is Map) return (s['_id'] ?? s['id'])?.toString() ?? '';
    return s?.toString() ?? '';
  }

  String? _extractTargetId(Map<String, dynamic> msg) {
    final t = msg['targetUser'];
    if (t is Map) return (t['_id'] ?? t['id'])?.toString();
    return t?.toString();
  }

  String? _extractClassId(Map<String, dynamic> msg) {
    final c = msg['targetClass'];
    if (c is Map) return (c['_id'] ?? c['id'])?.toString();
    return c?.toString();
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
