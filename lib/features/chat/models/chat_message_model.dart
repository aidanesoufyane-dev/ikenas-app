class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final String type;
  final DateTime timestamp;
  final bool isOwn;
  final Map<String, int> reactions;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    this.type = 'text',
    required this.timestamp,
    this.isOwn = false,
    this.reactions = const {},
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {bool isOwn = false}) {
    final reactionsData = json['reactions'] as Map?;
    final reactions = <String, int>{};
    if (reactionsData != null) {
      reactionsData.forEach((key, value) {
        if (value is int) reactions[key] = value;
      });
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? json['sender_name']?.toString() ?? 'Unknown',
      senderAvatar: json['senderAvatar']?.toString() ?? json['sender_avatar']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? json['messageType']?.toString() ?? 'text',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isOwn: isOwn,
      reactions: reactions,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'].toString())
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isOwn': isOwn,
      'reactions': reactions,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}
