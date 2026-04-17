import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                shape: BoxShape.circle),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: primaryTextColor, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.translate('notification_settings_title'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 20,
                letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCategoryCard(
                context,
                'academic',
                Icons.school_outlined,
                Colors.greenAccent,
                loc.translate('academic_alerts'),
                loc.translate('academic_alerts_desc'),
              ),
              _buildCategoryCard(
                context,
                'security',
                Icons.security_outlined,
                Colors.orangeAccent,
                loc.translate('security_alerts'),
                loc.translate('security_alerts_desc'),
              ),
              _buildCategoryCard(
                context,
                'financial',
                Icons.account_balance_wallet_outlined,
                Colors.blueAccent,
                loc.translate('financial_alerts'),
                loc.translate('financial_alerts_desc'),
              ),
              _buildCategoryCard(
                context,
                'announcements',
                Icons.campaign_outlined,
                Colors.purpleAccent,
                loc.translate('school_announcements_alerts'),
                loc.translate('school_announcements_desc'),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String key,
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: primaryTextColor)),
                          Text(subtitle,
                              style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildToggleRow(
                  context,
                  AppLocalizations.of(context)!.translate('push_notifications'),
                  Icons.notifications_active_outlined,
                  _getValue(context, key),
                  (val) => _toggleValue(context, key, val),
                  color,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutQuart);
  }

  bool _getValue(BuildContext context, String key) {
    final appState = Provider.of<AppState>(context, listen: false);
    switch (key) {
      case 'academic':
        return appState.academicAlertsEnabled;
      case 'security':
        return appState.securitySafetyEnabled;
      case 'announcements':
        return appState.newsAlertsEnabled;
      case 'financial':
        return appState.pushEnabled;
      default:
        return true;
    }
  }

  void _toggleValue(BuildContext context, String key, bool value) {
    final appState = Provider.of<AppState>(context, listen: false);
    switch (key) {
      case 'academic':
        appState.toggleAcademicAlerts(value);
        break;
      case 'security':
        appState.toggleSecuritySafety(value);
        break;
      case 'announcements':
        appState.toggleNewsAlerts(value);
        break;
      case 'financial':
        appState.togglePush(value);
        break;
    }
  }

  Widget _buildToggleRow(
    BuildContext context,
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, size: 16, color: value ? color : Colors.grey),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: value ? primaryTextColor : Colors.grey)),
        ],
      ),
      activeThumbColor: color,
      inactiveThumbColor: Colors.grey.withValues(alpha: 0.5),
      inactiveTrackColor: Colors.grey.withValues(alpha: 0.1),
    );
  }
}
