import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'chat_api_service.dart';
import 'models/chat_thread_model.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_service.dart';
import '../../core/config/app_config.dart';

class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ChatConversationsScreen> createState() => _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  late ChatApiService _apiService;
  final List<ChatThread> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initConversations();
  }

  Future<void> _initConversations() async {
    try {
      await AuthService.instance.init();
      final token = AuthService.instance.getStoredToken();

      if (token == null) {
        setState(() => _loading = false);
        return;
      }



      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.serverUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));
      _apiService = ChatApiService(dio);

      await _loadConversations();
    } catch (e) {
      debugPrint('Error initializing conversations: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadConversations() async {
    try {
      final threads = await _apiService.fetchMessages();
      final conversations = <ChatThread>[];

      for (final thread in threads) {
        try {
          conversations.add(ChatThread.fromJson(thread));
        } catch (e) {
          debugPrint('Error parsing thread: $e');
        }
      }

      setState(() {
        _conversations.clear();
        _conversations.addAll(conversations);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      setState(() {
        _loading = false;
        // Add demo conversations if API fails
        _conversations.addAll([
          ChatThread(
            id: 'general',
            name: 'General',
            description: 'General discussion',
            lastMessage: 'Welcome to the general chat',
            lastMessageTime: DateTime.now(),
            participantIds: [],
          ),
          ChatThread(
            id: 'announcements',
            name: 'Announcements',
            description: 'Important announcements',
            lastMessage: 'No new announcements',
            lastMessageTime: DateTime.now(),
            participantIds: [],
          ),
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Text('No conversations yet.'),
                )
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final thread = _conversations[index];
                    return _buildConversationTile(context, thread);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new conversation
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ChatThread thread) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade200,
        child: Text(
          thread.name[0].toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(thread.name),
      subtitle: Text(
        thread.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(thread.lastMessageTime),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (thread.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                thread.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(threadId: thread.id, threadName: thread.name),
          ),
        );
      },
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
      return '${time.day}/${time.month}';
    }
  }
}
