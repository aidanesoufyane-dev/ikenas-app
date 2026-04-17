import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import 'add_homework_screen.dart';

class TeacherHomeworkScreen extends StatefulWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen> {
  bool _isLoading = true;
  List<HomeworkModel> _homeworkList = [];

  @override
  void initState() {
    super.initState();
    _fetchHomework();
  }

  Future<void> _fetchHomework() async {
    try {
      final list = await ApiService.instance.getHomework('me');
      if (mounted) {
        setState(() {
          _homeworkList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Could show a snackbar here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

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
        title: Text(AppLocalizations.of(context)!.translate('homework_title'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 18)),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryTextColor))
              : _homeworkList.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('no_homework'),
                        style: TextStyle(color: primaryTextColor, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                      itemCount: _homeworkList.length,
                      itemBuilder: (context, index) {
                        final hw = _homeworkList[index];
                        return _buildHomeworkCard(context, hw, index);
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHomeworkScreen()),
        ),
        backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(AppLocalizations.of(context)!.translate('new_homework_btn'),
            style: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
      ).animate().scale(
          delay: const Duration(milliseconds: 400), curve: Curves.elasticOut),
    );
  }

  Widget _buildHomeworkCard(BuildContext context, HomeworkModel hw, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.7),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        hw.subject.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 1.5),
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context)!.translate('due_date')}: ${hw.dueDate}',
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  hw.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: primaryTextColor,
                      letterSpacing: -0.2),
                ),
                const SizedBox(height: 12),
                Text(
                  hw.description,
                  style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.7),
                      border: Border.all(
                          color: isDark ? Colors.white10 : Colors.white),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.people_alt_rounded,
                      size: 16, color: primaryTextColor.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 14),
                Text(hw.className ?? 'Classe',
                    style: TextStyle(
                        color: primaryTextColor.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
                const Spacer(),
                Text(
                    '${hw.submissionCount ?? 0} ${AppLocalizations.of(context)!.translate('submitted')}',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (index * 100)))
        .slideY(begin: 0.1);
  }
}
