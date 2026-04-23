import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/widgets/sprite_avatar.dart';
import '../../../core/widgets/avatar_selector_modal.dart';
import '../viewmodels/profile_view_model.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  int? _tempAvatarIndex;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController =
        TextEditingController(text: appState.currentUser?.name ?? '');
    _emailController =
        TextEditingController(text: appState.currentUser?.email ?? '');
    _dobController = TextEditingController(text: '-- / -- / ----');
    _phoneController =
        TextEditingController(text: appState.currentUser?.phone ?? '');
    _tempAvatarIndex = appState.currentUser?.avatarIndex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Informations Personnelles',
          style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.w900,
              fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => AvatarSelectorModal.show(
                                context,
                                initialIndex: _tempAvatarIndex,
                                onSelect: (index) =>
                                    setState(() => _tempAvatarIndex = index),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF8B5CF6),
                                          Color(0xFF06B6D4)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF3B82F6)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? const Color(0xFF0F172A)
                                            : Colors.white,
                                      ),
                                      child: _tempAvatarIndex != null
                                          ? SpriteAvatar(
                                              index: _tempAvatarIndex!,
                                              size: 100)
                                          : Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blueAccent
                                                        .withValues(
                                                            alpha: 0.15),
                                                    Colors.purpleAccent
                                                        .withValues(
                                                            alpha: 0.15),
                                                  ],
                                                ),
                                              ),
                                              child: Icon(Icons.person_rounded,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.black26,
                                                  size: 50),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF8B5CF6)
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF0F172A)
                                              : Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blueAccent
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.edit_rounded,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Photo de Profil',
                              style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        context: context,
                        label: 'Nom Complet',
                        icon: Icons.person_outline_rounded,
                        controller: _nameController,
                        trailingIcon: Icons.lock_outline_rounded,
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        context: context,
                        label: 'Adresse Email',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        trailingIcon: Icons.lock_outline_rounded,
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        context: context,
                        label: 'Date de Naissance',
                        icon: Icons.cake_outlined,
                        controller: _dobController,
                        trailingIcon: Icons.lock_outline_rounded,
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        context: context,
                        label: 'Numéro de Téléphone',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        trailingIcon: Icons.edit_rounded,
                        readOnly: false,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Consumer<ProfileViewModel>(
                  builder: (context, vm, child) => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.isUpdating
                          ? null
                          : () async {
                              await vm.updateProfile(
                                phone: _phoneController.text,
                                avatarIndex: _tempAvatarIndex,
                              );
                              if (!context.mounted) return;
                              if (vm.errorMessage == null) {
                                Navigator.pop(context);
                              } else if (vm.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(vm.errorMessage!),
                                      backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: vm.isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('SAUVEGARDER',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required IconData trailingIcon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    // Premium Glass Colors
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.7);
    final glassBorder =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isDark ? Colors.white24 : Colors.black26, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  cursorColor: Colors.blueAccent,
                  style: TextStyle(
                    color: readOnly
                        ? (isDark ? Colors.white54 : Colors.black54)
                        : primaryTextColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              Icon(trailingIcon,
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.1),
                  size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
