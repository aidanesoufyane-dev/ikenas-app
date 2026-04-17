import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';

import 'student_detail_full_screen.dart';
import 'media_history_screen.dart';

class GroupInfoScreen extends StatelessWidget {
  final String groupName;
  final ClassModel? classModel;
  final List<Map<String, dynamic>> messages;

  const GroupInfoScreen({
    super.key,
    required this.groupName,
    this.classModel,
    this.messages = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = isDark ? Colors.white : const Color(0xFF0F172A);
    final st = isDark ? Colors.white38 : Colors.black26;
    final loc = AppLocalizations.of(context)!;

    // Fallback students if classModel is null
    final students = classModel?.students ?? <StudentModel>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: pt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.translate('group_info_title'),
            style: TextStyle(
                color: pt, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.purpleAccent]),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: Colors.white, size: 50),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(groupName,
                        style: TextStyle(
                            color: pt,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                    Text(
                        '${students.length} ${loc.translate('participants_label')}',
                        style: TextStyle(
                            color: st,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Settings Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('settings').toUpperCase(),
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white),
                      ),
                      child: Column(
                        children: [
                          Consumer<AppState>(builder: (context, appState, _) {
                            final isAdminOnly = appState.groupAdminOnlyMessaging
                                .contains(groupName);
                            return SwitchListTile(
                              value: isAdminOnly,
                              activeThumbColor: Colors.blueAccent,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              title: Text(
                                loc.translate('only_admin_can_send_msgs'),
                                style: TextStyle(
                                    color: pt,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              subtitle: Text(
                                loc.translate('admin_only_desc'),
                                style: TextStyle(color: st, fontSize: 11),
                              ),
                              onChanged: (val) =>
                                  appState.toggleAdminOnlyMessaging(groupName),
                            );
                          }),
                          Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: isDark ? Colors.white10 : Colors.white),
                          ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MediaHistoryScreen(
                                    groupName: groupName,
                                    messages: messages,
                                  ),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.perm_media_rounded,
                                  color: Colors.blueAccent, size: 20),
                            ),
                            title: Text(loc.translate('media_links_docs'),
                                style: TextStyle(
                                    color: pt,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            trailing: Icon(Icons.chevron_right_rounded,
                                color: st.withValues(alpha: 0.5), size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Participants List
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Text(
                          loc.translate('participants_label').toUpperCase(),
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.5),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            // Admin (Teacher)
                            _buildParticipantTile(
                              context,
                              Provider.of<AppState>(context)
                                      .currentUser
                                      ?.name ??
                                  "Teacher",
                              loc.translate('admin_label'),
                              true,
                              isDark,
                              pt,
                              st,
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              child: Divider(height: 1, thickness: 0.5),
                            ),

                            // Students
                            ...students.map((student) => _buildParticipantTile(
                                  context,
                                  student.name,
                                  loc.translate('students'),
                                  false,
                                  isDark,
                                  pt,
                                  st,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              StudentDetailFullScreen(
                                                  student: student,
                                                  showChatButton: false))),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantTile(BuildContext context, String name, String sub,
      bool isAdmin, bool isDark, Color pt, Color st,
      {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: (isAdmin ? Colors.orangeAccent : Colors.blueAccent)
            .withValues(alpha: 0.1),
        child: Text(name[0],
            style: TextStyle(
                color: isAdmin ? Colors.orangeAccent : Colors.blueAccent,
                fontWeight: FontWeight.w900)),
      ),
      title: Text(name,
          style:
              TextStyle(color: pt, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub,
          style:
              TextStyle(color: st, fontSize: 12, fontWeight: FontWeight.w600)),
      trailing: isAdmin
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  AppLocalizations.of(context)!.translate('admin_label'),
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.w900)),
            )
          : Icon(Icons.chevron_right_rounded,
              color: st.withValues(alpha: 0.5), size: 20),
    );
  }
}
