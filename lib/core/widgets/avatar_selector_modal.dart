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

    // All 28 individual avatars
    final allIndices = List.generate(28, (i) => i);

    int? selectedIndex = initialIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
                const SizedBox(height: 24),

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
                            'Sélectionnez votre photo de profil',
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

                const SizedBox(height: 28),

                // Divider
                Container(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),

                const SizedBox(height: 20),

                // Grid
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: allIndices.length,
                    itemBuilder: (context, i) {
                      final currentVm = context.watch<ProfileViewModel>();

                      // Highlight logic:
                      // 1. If we have a selectedIndex (staged flow), use it.
                      // 2. Otherwise, fallback to the saved avatar index.
                      final isSelected = selectedIndex != null
                          ? (selectedIndex == allIndices[i])
                          : (currentVm.user?.avatarIndex == allIndices[i]);

                      return GestureDetector(
                        onTap: () {
                          if (onSelect != null) {
                            onSelect(allIndices[i]);
                            Navigator.pop(context);
                          } else {
                            context
                                .read<ProfileViewModel>()
                                .updateProfile(avatarIndex: allIndices[i]);
                            Navigator.pop(context);
                          }
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.06)),
                              width: isSelected ? 3 : 1.5,
                            ),
                            color: isDark
                                ? Colors.white
                                    .withValues(alpha: isSelected ? 0.08 : 0.03)
                                : (isSelected
                                    ? Colors.blue.withValues(alpha: 0.05)
                                    : Colors.grey.withValues(alpha: 0.04)),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blueAccent
                                          .withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SpriteAvatar(
                                    index: allIndices[i], size: 80),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (i * 40).ms, duration: 400.ms)
                          .scale(
                              begin: const Offset(0.8, 0.8),
                              curve: Curves.easeOutBack);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
