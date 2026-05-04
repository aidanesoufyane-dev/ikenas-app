import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Returns the SVG asset path for the gender avatar.
/// gender: 'F' / 'female' / 'f' → girl-01.svg (female)
/// anything else / null           → boy-01.svg (male)
String genderAvatarAsset(String? gender) {
  final g = gender?.toLowerCase().trim() ?? '';
  if (g == 'f' || g == 'female' || g == 'féminin' || g == 'feminin') {
    return 'avatarss/girl-01.svg';
  }
  return 'avatarss/boy-01.svg';
}

class SpriteAvatar extends StatelessWidget {
  /// 0 = female (girl-01), 1 = male (boy-01), null = male default
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
      assetPath = 'avatarss/girl-01.svg';
    } else {
      assetPath = 'avatarss/boy-01.svg';
    }

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
