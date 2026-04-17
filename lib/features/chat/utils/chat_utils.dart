import 'package:flutter/material.dart';
import '../models/chat_message_model.dart' as models;

typedef ChatMessageModel = models.ChatMessage;

class ChatUtils {
  // Search messages
  static List<ChatMessageModel> searchMessages(
    List<ChatMessageModel> messages,
    String query,
  ) {
    if (query.isEmpty) return messages;
    
    final lowercaseQuery = query.toLowerCase();
    return messages
        .where((msg) => msg.content.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Get online status color
  static Color getOnlineStatusColor(bool isOnline) {
    return isOnline ? Colors.green : Colors.grey;
  }

  // Format duration
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  // Detect URL in text
  static bool containsUrl(String text) {
    final urlRegex = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );
    return urlRegex.hasMatch(text);
  }

  // Highlight mentions in text
  static List<TextSpan> highlightMentions(String text) {
    final mentionRegex = RegExp(r'@[\w]+');
    final matches = mentionRegex.allMatches(text);

    if (matches.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    var lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }
}
