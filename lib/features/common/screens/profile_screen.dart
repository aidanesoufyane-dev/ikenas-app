import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'notifications_settings_screen.dart';
import '../viewmodels/profile_view_model.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models/models.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/screens/auth_screen.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/widgets/sprite_avatar.dart';
import 'personal_info_screen.dart';
import 'help_support_screen.dart';
import '../../../core/widgets/confirmation_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Consumer<ProfileViewModel>(
      builder: (context, vm, child) {
        final user = vm.user;
        if (user == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final primaryTextColor =
            isDark ? Colors.white : const Color(0xFF0F172A);
        final secondaryTextColor = const Color(0xFF94A3B8);
        final glassColor = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7);
        final glassBorder =
            isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(context, loc, primaryTextColor, glassColor),
          body: DeepSpaceBackground(
            showOrbs: true,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildUserHeader(context, vm, user, isDark,
                        primaryTextColor, secondaryTextColor),
                    const SizedBox(height: 48),

                    // Dark Mode Toggle
                    _buildGlassTile(
                      child: SwitchListTile(
                        value: appState.isDarkMode,
                        onChanged: (_) => appState.toggleDarkMode(),
                        secondary: _buildTileIcon(
                            Icons.dark_mode_rounded, Colors.blueAccent),
                        title: Text(loc.translate('dark_mode'),
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: primaryTextColor)),
                        subtitle: Text(loc.translate('optimize_night'),
                            style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        activeThumbColor: Colors.blueAccent,
                      ),
                      glassColor: glassColor,
                      glassBorder: glassBorder,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                    const SizedBox(height: 16),

                    // Profile Sections
                    _buildProfileTile(
                        context,
                        Icons.person_outline_rounded,
                        loc.translate('personal_info'),
                        loc.translate('personal_info_desc'),
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PersonalInfoScreen())),
                        glassColor,
                        glassBorder,
                        primaryTextColor,
                        secondaryTextColor),
                    _buildProfileTile(
                        context,
                        Icons.notifications_none_rounded,
                        loc.translate('notifications_settings'),
                        'Gérer vos alertes',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationSettingsScreen())),
                        glassColor,
                        glassBorder,
                        primaryTextColor,
                        secondaryTextColor),
                    _buildProfileTile(
                        context,
                        Icons.language_rounded,
                        loc.translate('language'),
                        'Changer la langue',
                        () => _showLanguageSwitcher(context),
                        glassColor,
                        glassBorder,
                        primaryTextColor,
                        secondaryTextColor),
                    _buildProfileTile(
                        context,
                        Icons.help_outline_rounded,
                        loc.translate('help_support'),
                        'Centre de support',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen())),
                        glassColor,
                        glassBorder,
                        primaryTextColor,
                        secondaryTextColor),

                    const SizedBox(height: 48),
                    _buildLogoutButton(context, loc),
                    const SizedBox(height: 180),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppLocalizations loc,
      Color textColor, Color glassColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(loc.translate('my_profile'),
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w900, fontSize: 18)),
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : Provider.of<AppState>(context, listen: false)
                  .setDashboardIndex(0),
          child: Container(
            decoration:
                BoxDecoration(color: glassColor, shape: BoxShape.circle),
            child: Icon(Icons.chevron_left_rounded, color: textColor, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, ProfileViewModel vm,
      UserModel user, bool isDark, Color primary, Color secondary) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
            child: Stack(
              children: [
                // Gradient ring + glow
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
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    ),
                    child: vm.user?.avatarIndex != null
                        ? SpriteAvatar(index: vm.user!.avatarIndex!, size: 100)
                        : Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blueAccent.withValues(alpha: 0.15),
                                  Colors.purpleAccent.withValues(alpha: 0.15),
                                ],
                              ),
                            ),
                            child: Icon(Icons.person_rounded,
                                color: isDark ? Colors.white38 : Colors.black26,
                                size: 50),
                          ),
                  ),
                ),
                // Camera edit badge
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(user.name,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: primary)),
          const SizedBox(height: 4),
          Text(
              AppLocalizations.of(context)!
                  .translate(
                      user.role == UserRole.teacher ? 'teacher' : 'parent')
                  .toUpperCase(),
              style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildGlassTile(
      {required Widget child,
      required Color glassColor,
      required Color glassBorder}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: glassBorder),
      ),
      child: child,
    );
  }

  Widget _buildTileIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildProfileTile(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      Color glassColor,
      Color glassBorder,
      Color primary,
      Color secondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: glassColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: glassBorder)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: _buildTileIcon(icon, primary),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 16, color: primary)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: secondary, fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, color: secondary, size: 20),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          ConfirmationDialog.show(
            context,
            title: loc.translate('logout_btn'),
            message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
            onConfirm: () {
              Provider.of<AppState>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AuthScreen(key: UniqueKey())),
                  (route) => false);
            },
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(loc.translate('logout_btn').toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 14)),
      ),
    );
  }

  void _showLanguageSwitcher(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        final appState = Provider.of<AppState>(context);
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.translate('choose_language'),
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: textColor)),
              const SizedBox(height: 24),
              _buildLanguageOption(
                  context,
                  AppLocalizations.of(context)!.translate('fr_lang'),
                  'fr',
                  appState.locale.languageCode == 'fr'),
              _buildLanguageOption(
                  context,
                  AppLocalizations.of(context)!.translate('ar_lang'),
                  'ar',
                  appState.locale.languageCode == 'ar'),
              _buildLanguageOption(
                  context,
                  AppLocalizations.of(context)!.translate('en_lang'),
                  'en',
                  appState.locale.languageCode == 'en'),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, String label, String code, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isSelected
        ? (isDark ? Colors.white : const Color(0xFF0F172A))
        : (isDark ? Colors.white60 : Colors.black45);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10)),
        child: Text(code.toUpperCase(),
            style: TextStyle(
                fontWeight: FontWeight.w900, color: textColor, fontSize: 11)),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              color: textColor,
              fontSize: 14)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A))
          : null,
      onTap: () {
        Provider.of<AppState>(context, listen: false).setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }
}
