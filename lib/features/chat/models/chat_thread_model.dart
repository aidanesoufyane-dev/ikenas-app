class ChatThread {
  final String id;
  final String name;
  final String? description;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<String> participantIds;
  final String? participantAvatar;

  ChatThread({
    required this.id,
    required this.name,
    this.description,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.participantIds,
    this.participantAvatar,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Chat',
      description: json['description']?.toString(),
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      participantIds: List<String>.from(json['participantIds'] as List? ?? []),
      participantAvatar: json['participantAvatar']?.toString(),
    );
  }
}
