import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white24 : Colors.black26;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('new_activity'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: primaryTextColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                        AppLocalizations.of(context)!
                            .translate('activity_details_upper'),
                        style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5))
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideX(begin: -0.1),
                const SizedBox(height: 24),
                _buildInput(
                        context,
                        AppLocalizations.of(context)!
                            .translate('activity_title_hint'),
                        Icons.title_rounded,
                        _titleController,
                        isDark)
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 16),
                _buildInput(
                        context,
                        AppLocalizations.of(context)!
                            .translate('activity_desc_hint'),
                        Icons.description_rounded,
                        _descController,
                        isDark,
                        maxLines: 5)
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .translate('activity_added_success')),
                              backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                      foregroundColor:
                          isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                        AppLocalizations.of(context)!
                            .translate('add_activity_upper'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1)),
                  ).animate().fadeIn(delay: 500.ms).scale(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context, String hint, IconData icon,
      TextEditingController controller, bool isDark,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon,
                color: isDark ? Colors.white60 : Colors.black45, size: 20),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
