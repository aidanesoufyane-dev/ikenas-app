import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'chat_api_service.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_service.dart';
import 'models/chat_message_model.dart';
import 'screens/chat_search_screen.dart';
import '../../core/config/app_config.dart';

class ChatScreen extends StatefulWidget {
  final String? threadId;
  final String? threadName;

  const ChatScreen({
    Key? key,
    this.threadId,
    this.threadName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatService? _chatService;
  ChatApiService? _apiService;
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _userId;
  String? _userName;
  bool _isConnected = false;
  
  // Use threadId from widget or default to 'general'
  late String _threadId;

  @override
  void initState() {
    super.initState();
    _threadId = widget.threadId ?? 'general';
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      // Ensure AuthService is initialized
      await AuthService.instance.init();
      final token = AuthService.instance.getStoredToken();
      final user = AuthService.instance.getStoredUser();

      setState(() {
        _userId = user?.id;
        _userName = user?.name;
      });

      if (token == null) {
        setState(() => _loading = false);
        return;
      }

      // Setup API and WebSocket with token
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.serverUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));
      _apiService = ChatApiService(dio);
      _chatService = ChatService(AppConfig.wsBaseUrl, token);

      await _loadHistory();
      try {
        _chatService!.connect();
      } catch (e) {
        debugPrint('WebSocket connection error: $e');
      }

      _chatService!.onMessage.listen((message) {
        _handleIncomingMessage(message);
      });
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      setState(() => _loading = false);
    }
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      setState(() {
        _isConnected = _chatService?.isConnected ?? false;
      });

      if (message is Map<String, dynamic>) {
        final chatMsg = ChatMessage.fromJson(message, isOwn: message['senderId'] == _userId);
        setState(() {
          _messages.add(chatMsg);
        });
      } else if (message is Map) {
        // Cast to Map<String, dynamic>
        final jsonMap = Map<String, dynamic>.from(message);
        final chatMsg = ChatMessage.fromJson(jsonMap, isOwn: jsonMap['senderId'] == _userId);
        setState(() {
          _messages.add(chatMsg);
        });
      } else if (message is String) {
        // Fallback for string messages
        final chatMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          senderName: 'System',
          senderAvatar: '',
          content: message,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(chatMsg);
        });
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  Future<void> _loadHistory() async {
    if (_apiService == null) return;
    try {
      final history = await _apiService!.fetchMessages();
      final messages = <ChatMessage>[];
      for (final msg in history) {
        messages.add(ChatMessage.fromJson(msg, isOwn: msg['senderId'] == _userId));
      }
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => _loading = false);
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty && _chatService != null) {
      final message = {
        'type': 'message',
        'action': 'send',
        'threadId': _threadId,
        'content': _controller.text.trim(),
        'messageType': 'text',
        'timestamp': DateTime.now().toIso8601String(),
      };
      _chatService!.sendMessage(message);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _chatService?.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.threadName ?? 'Chat'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatSearchScreen(messages: _messages),
                ),
              );
              if (result is ChatMessage) {
                // Scroll to message or show it
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Found: ${result.content}')),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: _isConnected
                  ? const Tooltip(
                      message: 'Connected',
                      child: Chip(
                        label: Text('Online'),
                        backgroundColor: Colors.green,
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    )
                  : const Tooltip(
                      message: 'Disconnected',
                      child: Chip(
                        label: Text('Offline'),
                        backgroundColor: Colors.red,
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else if (_messages.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No messages yet. Start a conversation!'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[_messages.length - 1 - index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),
          // Typing Indicators
          if (_isConnected && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 30,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Others typing', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 30,
                        height: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isOwn = msg.isOwn;
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '😭'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isOwn) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  child: msg.senderAvatar.isNotEmpty
                      ? Image.network(msg.senderAvatar)
                      : Text(msg.senderName[0].toUpperCase()),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showMessageOptions(context, msg, emojis),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOwn ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isOwn)
                          Text(
                            msg.senderName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        if (msg.isDeleted)
                          Text(
                            'This message was deleted',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          )
                        else
                          Text(
                            msg.content,
                            style: const TextStyle(fontSize: 14),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(msg.timestamp),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                            if (msg.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(edited)',
                                style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isOwn) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(
                    (_userName?.isNotEmpty ?? false) ? _userName![0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          // Show reactions if any
          if (msg.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4, left: isOwn ? 0 : 56, right: isOwn ? 56 : 0),
              child: Wrap(
                spacing: 4,
                children: msg.reactions.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage msg, List<String> emojis) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Message Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (!msg.isDeleted) ...[
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionMenu(context, msg, emojis);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
          ],
          if (msg.isOwn && !msg.isDeleted) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(msg);
              },
            ),
          ],
          if (msg.isDeleted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'This message was deleted',
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ChatMessage msg) {
    final editController = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Edit your message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReactionMenu(BuildContext context, ChatMessage msg, List<String> emojis) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reacted with $emoji')),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(time.year, time.month, time.day);

    if (msgDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
