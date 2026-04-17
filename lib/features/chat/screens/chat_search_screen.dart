import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

class ChatSearchScreen extends StatefulWidget {
  final List<ChatMessage> messages;

  const ChatSearchScreen({
    Key? key,
    required this.messages,
  }) : super(key: key);

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatMessage> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterMessages);
  }

  void _filterMessages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMessages = [];
      } else {
        _filteredMessages = widget.messages
            .where((msg) => msg.content.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search messages',
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _searchController.text.isEmpty
          ? const Center(
              child: Text('Start typing to search messages'),
            )
          : _filteredMessages.isEmpty
              ? Center(
                  child: Text('No messages found for "${_searchController.text}"'),
                )
              : ListView.builder(
                  itemCount: _filteredMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _filteredMessages[index];
                    return ListTile(
                      title: Text(msg.senderName),
                      subtitle: Text(msg.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Text(
                        _formatTime(msg.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.pop(context, msg);
                      },
                    );
                  },
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
