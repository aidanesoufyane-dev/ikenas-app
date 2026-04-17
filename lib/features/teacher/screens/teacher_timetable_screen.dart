import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/api_service.dart';

class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  String _selectedDay = 'monday';
  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday'
  ];

  Map<String, List<Map<String, dynamic>>> _scheduleMap = {};
  bool _isLoading = true;

  static const _dayIndexToFrench = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    try {
      final sessions = await ApiService.instance.getTeacherTimetable();
      if (!mounted) return;
      final map = <String, List<Map<String, dynamic>>>{};
      for (final s in sessions) {
        final day = s.dayIndex < _dayIndexToFrench.length
            ? _dayIndexToFrench[s.dayIndex]
            : 'Lundi';
        map.putIfAbsent(day, () => []);
        map[day]!.add({
          'time': '${s.time} - ',
          'subject': s.subject,
          'room': s.room,
          'class': s.teacher,
        });
      }
      setState(() {
        _scheduleMap = map;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleMap = _scheduleMap;
    final displayDay = _getDisplayDay(_selectedDay);
    final schedule = scheduleMap[displayDay] ?? [];
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
        title: Text(AppLocalizations.of(context)!.translate('timetable_title'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 18)),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : Column(
            children: [
              // Day Selector
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected = day == _selectedDay;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.8)),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white)),
                          boxShadow: isSelected && !isDark
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF0F172A)
                                          .withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5))
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate(day)
                              .toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white)
                                : (isDark ? Colors.white38 : Colors.black26),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: (index * 50)))
                        .slideX(begin: 0.2);
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Schedule List
              Expanded(
                child: schedule.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
                        itemCount: schedule.length,
                        itemBuilder: (context, index) {
                          final item = schedule[index];
                          return _buildTimelineItem(context, item, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      BuildContext context, Map<String, dynamic> item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white24 : Colors.black26;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return IntrinsicHeight(
      child: Row(
        children: [
          // Time Column
          SizedBox(
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['time']?.split(' - ')[0] ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: primaryTextColor,
                      letterSpacing: -0.5),
                ),
                Text(
                  item['time']?.split(' - ')[1] ?? '',
                  style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          ),

          // Timeline vertical line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Container(
                  width: 1.5,
                  height: 20,
                  color: isDark
                      ? Colors.white.withValues(alpha: index == 0 ? 0 : 0.1)
                      : Colors.black.withValues(alpha: index == 0 ? 0 : 0.05),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.4),
                          blurRadius: 10)
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Card Column
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.8)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(item['subject'] ?? '',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: primaryTextColor,
                                  letterSpacing: -0.5))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    Colors.blueAccent.withValues(alpha: 0.15))),
                        child: Text(item['room'] ?? '',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.blueAccent,
                                letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.school_rounded,
                          color: secondaryTextColor, size: 14),
                      const SizedBox(width: 8),
                      Text(
                          '${AppLocalizations.of(context)!.translate('class_label')}: ${item['class']}'
                              .toUpperCase(),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: (index * 120)))
          .slideY(begin: 0.1),
    );
  }

  String _getDisplayDay(String key) {
    switch (key) {
      case 'monday':
        return 'Lundi';
      case 'tuesday':
        return 'Mardi';
      case 'wednesday':
        return 'Mercredi';
      case 'thursday':
        return 'Jeudi';
      case 'friday':
        return 'Vendredi';
      case 'saturday':
        return 'Samedi';
      default:
        return 'Lundi';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle),
            child: Icon(Icons.event_busy_rounded,
                size: 64, color: isDark ? Colors.white10 : Colors.black12),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.translate('no_sessions'),
              style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
