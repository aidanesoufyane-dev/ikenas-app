import 'package:flutter/material.dart';

/// Returns the asset path for the gender avatar.
/// gender: 'F' / 'female' / 'f' → avatar_1 (female)
/// anything else / null           → avatar_2 (male)
String genderAvatarAsset(String? gender) {
  final g = gender?.toLowerCase().trim() ?? '';
  if (g == 'f' || g == 'female' || g == 'féminin' || g == 'feminin') {
    return 'assets/images/avatars/avatar_1.png';
  }
  return 'assets/images/avatars/avatar_2.png';
}

class SpriteAvatar extends StatelessWidget {
  /// 0 = female (avatar_1), 1 = male (avatar_2), null = male default
  final int? index;
  final double size;
  final String? gender;

  const SpriteAvatar({
    super.key,
    this.index,
    required this.size,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final String assetPath;
    if (gender != null) {
      assetPath = genderAvatarAsset(gender);
    } else if (index == 0) {
      assetPath = 'assets/images/avatars/avatar_1.png';
    } else {
      assetPath = 'assets/images/avatars/avatar_2.png';
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF0EDE8),
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
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
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
