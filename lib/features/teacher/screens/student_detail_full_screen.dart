import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/widgets/sprite_avatar.dart';
import '../../../core/localization/app_localizations.dart';
import 'teacher_chat_screen.dart';

class StudentDetailFullScreen extends StatelessWidget {
  final StudentModel student;
  final bool showChatButton;

  const StudentDetailFullScreen(
      {super.key, required this.student, this.showChatButton = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(student.name,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 100),

              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: primaryTextColor.withValues(alpha: 0.1),
                            width: 1),
                        boxShadow: [
                          if (isDark)
                            BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                blurRadius: 40)
                        ],
                      ),
                      child: SpriteAvatar(gender: student.gender, size: 112),
                    ).animate().scale(
                        delay: 100.ms,
                        duration: 600.ms,
                        curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    Text(
                      student.name,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loc.translate('massar_code_label')}: ${student.massarCode ?? '---'}'
                          .toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Quick Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildStatCard(
                        context,
                        loc.translate('average_label'),
                        '${student.average.toStringAsFixed(1)}/20',
                        Icons.analytics_rounded,
                        Colors.blueAccent),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        context,
                        loc.translate('attendance'),
                        '${(student.attendanceRate ?? 0).toInt()}%',
                        Icons.verified_rounded,
                        Colors.greenAccent),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        context,
                        loc.translate('behavior_label'),
                        (student.behavior ?? 'B').toUpperCase(),
                        Icons.auto_awesome_rounded,
                        Colors.orangeAccent),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 30),

              // Student Detailed Info Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(loc.translate('student_info').toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: Colors.blueAccent,
                                  letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(loc.translate('massar_code_label'),
                          student.massarCode ?? '---', isDark),
                      _buildInfoRow(loc.translate('full_student_file'),
                          student.name, isDark),
                      _buildInfoRow(loc.translate('birthday'),
                          student.birthDate ?? '---', isDark),
                      _buildInfoRow(
                          loc.translate('age_label'),
                          '${student.age ?? '---'} ${loc.translate('years_old')}',
                          isDark),
                      _buildInfoRow(
                          loc.translate('class_group'),
                          '${student.className ?? '---'} / ${student.group ?? '---'}',
                          isDark,
                          isLast: true),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 30),

              // Folders Section (The 4 Cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('full_student_file').toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: secondaryTextColor,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.6,
                      children: [
                        _buildFolderCard(
                            context,
                            Icons.family_restroom_rounded,
                            loc.translate('parent_info'),
                            Colors.indigoAccent,
                            () => _showParentInfo(context)),
                        _buildFolderCard(
                            context,
                            Icons.medical_information_rounded,
                            loc.translate('medical_file'),
                            Colors.redAccent,
                            () => _showMedicalInfo(context)),
                        _buildFolderCard(
                            context,
                            Icons.history_edu_rounded,
                            loc.translate('grade_summary'),
                            Colors.amberAccent,
                            () => _showGradesSummary(context)),
                        _buildFolderCard(
                            context,
                            Icons.gavel_rounded,
                            loc.translate('disciplinary_records'),
                            Colors.purpleAccent,
                            () => _showDisciplinaryRecords(context)),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Text(
                      loc.translate('direct_contact').toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: secondaryTextColor,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    _buildContactTile(
                        context,
                        Icons.phone_iphone_rounded,
                        loc.translate('emergency_contact'),
                        student.parentPhone ?? '---',
                        Colors.redAccent),

                    const SizedBox(height: 30),

                    // Action Buttons (Full Width Chat Button)
                    if (showChatButton) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  name:
                                      "${loc.translate('parent_of')} ${student.name}",
                                  avatarUrl: '',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 20),
                          label: Text(
                              loc.translate('chat_with_parent').toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            elevation: 10,
                            shadowColor:
                                Colors.blueAccent.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black26,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _showParentInfo(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    _showCustomBottomSheet(context, loc.translate('parent_info_detail'),
        Icons.family_restroom_rounded, Colors.indigoAccent, [
      {
        'label': loc.translate('father_mother'),
        'value': student.parentName ?? '---'
      },
      {'label': loc.translate('phone'), 'value': student.parentPhone ?? '---'},
    ]);
  }

  void _showMedicalInfo(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    _showCustomBottomSheet(context, loc.translate('medical_file'),
        Icons.medical_services_rounded, Colors.redAccent, [
      {'label': loc.translate('blood_type'), 'value': '---'},
      {
        'label': loc.translate('allergies'),
        'value': loc.translate('no_allergy')
      },
    ]);
  }

  void _showGradesSummary(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    _showCustomBottomSheet(context, loc.translate('grade_summary'),
        Icons.history_edu_rounded, Colors.amberAccent, [
      {
        'label': loc.translate('general_average'),
        'value': '${student.average.toStringAsFixed(2)}/20'
      },
      {'label': loc.translate('ranking_class'), 'value': '-- / --'},
    ]);
  }

  void _showDisciplinaryRecords(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    _showCustomBottomSheet(context, loc.translate('disciplinary_records'),
        Icons.gavel_rounded, Colors.purpleAccent, [
      {
        'label': loc.translate('status_label'),
        'value': loc.translate('no_disciplinary')
      },
    ]);
  }

  void _showCustomBottomSheet(BuildContext context, String title, IconData icon,
      Color color, List<Map<String, String>> details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(title,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 32),
            ...details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['label']!.toUpperCase(),
                          style: TextStyle(
                              color: isDark ? Colors.white24 : Colors.black26,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(d['value']!,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.7),
                      blurRadius: 10)
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54,
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16, color: color)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(),
                style: TextStyle(
                    color: color.withValues(alpha: 0.5),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, IconData icon, String label,
      String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A))),
              ],
            ),
          ),
          Icon(Icons.phone_rounded,
              color: color.withValues(alpha: 0.5), size: 18),
        ],
      ),
    );
  }
}
