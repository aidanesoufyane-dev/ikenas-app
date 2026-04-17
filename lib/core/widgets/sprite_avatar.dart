import 'package:flutter/material.dart';

class SpriteAvatar extends StatelessWidget {
  final int index;
  final double size;

  const SpriteAvatar({super.key, required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    // Safety check for 28 avatars (0-27)
    if (index < 0 || index > 27) {
      return _buildFallback();
    }

    // Files are saved as avatar_1.png to avatar_28.png (1-indexed) in assets/images/avatars/
    final assetPath = 'assets/images/avatars/avatar_${index + 1}.png';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF0EDE8), // Match the avatar background tint
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Use gapless playback to avoid flicker on rebuild
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white.withValues(alpha: 0.8),
        size: size * 0.5,
      ),
    );
  }
}
