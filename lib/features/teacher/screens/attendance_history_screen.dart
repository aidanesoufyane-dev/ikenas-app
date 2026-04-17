import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import './attendance_detail_screen.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = isDark ? Colors.white : const Color(0xFF0F172A);
    final loc = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> history = []; // To be fetched from API

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
        title: Text(
          loc.translate('attendance_history_title'),
          style:
              TextStyle(color: pt, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildHistoryCard(context, item, index, isDark, pt);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item,
      int index, bool isDark, Color pt) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AttendanceDetailScreen(sessionData: item)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(28),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['date'],
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['class'],
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['subject'],
                  style: TextStyle(
                      color: pt, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                if (item['isValidatedByAdmin'] == true)
                  Icon(Icons.verified_user_rounded,
                      color: Colors.blueAccent.withValues(alpha: 0.5),
                      size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSmallStat(Icons.check_circle_rounded,
                    '${item['present']}', Colors.greenAccent),
                const SizedBox(width: 12),
                _buildSmallStat(Icons.access_time_filled_rounded,
                    '${item['late']}', Colors.orangeAccent),
                const SizedBox(width: 12),
                _buildSmallStat(Icons.cancel_rounded, '${item['absent']}',
                    Colors.redAccent),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.blueAccent, size: 20),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideY(begin: 0.1);
  }

  Widget _buildSmallStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 12)),
      ],
    );
  }
}
