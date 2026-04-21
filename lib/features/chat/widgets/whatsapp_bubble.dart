import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/models.dart';
import 'audio_message_player.dart';

class WhatsappBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isGroup;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  const WhatsappBubble({
    super.key,
    required this.message,
    this.isGroup = false,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMe
        ? (isDark ? const Color(0xFF005C4B) : const Color(0xFFE7FFDB))
        : (isDark ? const Color(0xFF202C33) : Colors.white);

    final textColor = isMe
        ? (isDark ? Colors.white : const Color(0xFF303030))
        : (isDark ? Colors.white : const Color(0xFF303030));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isGroup && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Stack(
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: EdgeInsets.only(
                    left: isMe ? 20 : 8,
                    right: isMe ? 8 : 20,
                    top: 2,
                    bottom: 2,
                  ),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContent(context, textColor),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.time,
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: isDark ? Colors.blueAccent : Colors.blue,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Tail
                Positioned(
                  top: 2,
                  right: isMe ? 0 : null,
                  left: isMe ? null : 0,
                  child: CustomPaint(
                    painter: BubbleTailPainter(
                      color: bubbleColor,
                      isMe: isMe,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (message.type) {
      case 'image':
        return _buildImage(context);
      case 'audio':
      case 'voice':
        return AudioMessagePlayer(
          url: message.attachments.isNotEmpty ? message.attachments.first : '',
          isMe: message.isMe,
        );
      case 'document':
        return _buildDocument(context, textColor);
      default:
        return Text(
          message.content,
          style: TextStyle(color: textColor, fontSize: 16),
        );
    }
  }

  Widget _buildImage(BuildContext context) {
    final url = message.attachments.isNotEmpty ? message.attachments.first : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () {
          // Navigator.push(context, MaterialPageRoute(builder: (_) => MediaViewer(url: url)));
        },
        child: CachedNetworkImage(
          imageUrl: url,
          placeholder: (context, url) => const SizedBox(
            height: 200,
            width: double.infinity,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _buildLocalImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLocalImage(String path) {
    // If it's a local path from a fresh pick
    try {
      return Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
    } catch (_) {
      return const Icon(Icons.broken_image);
    }
  }

  Widget _buildDocument(BuildContext context, Color textColor) {
    final name = message.content.isNotEmpty ? message.content : 'Document';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  BubbleTailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isMe) {
      path.moveTo(0, 0);
      path.lineTo(10, 0);
      path.lineTo(0, 10);
    } else {
      path.moveTo(0, 0);
      path.lineTo(-10, 0);
      path.lineTo(0, 10);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
