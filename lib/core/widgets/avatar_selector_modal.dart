import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'sprite_avatar.dart';
import '../../features/common/viewmodels/profile_view_model.dart';

class AvatarSelectorModal {
  static void show(BuildContext context,
      {int? initialIndex, Function(int)? onSelect}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    int? selectedIndex = initialIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.face_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choisir un Avatar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sélectionnez votre genre',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                const SizedBox(height: 40),

                // Two avatar choices: 0=female, 1=male
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChoice(
                      context: context,
                      setState: setState,
                      index: 0,
                      label: 'Féminin',
                      selectedIndex: selectedIndex,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onSelect: onSelect,
                      onChanged: (i) => selectedIndex = i,
                    ),
                    const SizedBox(width: 32),
                    _buildChoice(
                      context: context,
                      setState: setState,
                      index: 1,
                      label: 'Masculin',
                      selectedIndex: selectedIndex,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      onSelect: onSelect,
                      onChanged: (i) => selectedIndex = i,
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    curve: Curves.easeOutBack),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildChoice({
    required BuildContext context,
    required StateSetter setState,
    required int index,
    required String label,
    required int? selectedIndex,
    required bool isDark,
    required Color primaryTextColor,
    required Function(int)? onSelect,
    required Function(int) onChanged,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => onChanged(index));
        if (onSelect != null) {
          onSelect(index);
        } else {
          context
              .read<ProfileViewModel>()
              .updateProfile(avatarIndex: index);
        }
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 3 : 1.5,
          ),
          color: isSelected
              ? Colors.blueAccent.withValues(alpha: isDark ? 0.15 : 0.06)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.withValues(alpha: 0.04)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            SpriteAvatar(index: index, size: 100),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: isSelected ? Colors.blueAccent : primaryTextColor,
                letterSpacing: 0.3,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '✓ Sélectionné',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
