class ChatUser {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final bool isOnline;
  final DateTime lastSeen;
  final String status;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.isOnline = false,
    required this.lastSeen,
    this.status = 'offline',
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'offline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'status': status,
    };
  }
}
