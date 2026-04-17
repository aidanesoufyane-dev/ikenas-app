import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../viewmodels/behavior_view_model.dart';

class BehaviorScreen extends StatefulWidget {
  final StudentModel student;
  const BehaviorScreen({super.key, required this.student});

  @override
  State<BehaviorScreen> createState() => _BehaviorScreenState();
}

class _BehaviorScreenState extends State<BehaviorScreen> {
  int _selectedTab = 0; // 0: Week, 1: Month

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final behaviorVM = context.read<BehaviorViewModel>();
      behaviorVM.startPolling(widget.student.id);
      behaviorVM.fetchBehaviorData(widget.student.id);
    });
  }

  @override
  void dispose() {
    context.read<BehaviorViewModel>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    final loc = AppLocalizations.of(context)!;

    return Consumer<BehaviorViewModel>(
      builder: (context, vm, child) {
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
            title: Text(loc.translate('behavior_summary'),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                    fontSize: 20,
                    letterSpacing: -0.5)),
            centerTitle: true,
            actions: [
              IconButton(
                icon:
                    Icon(Icons.help_outline_rounded, color: secondaryTextColor),
                onPressed: () {},
              ),
            ],
          ),
          body: DeepSpaceBackground(
            showOrbs: true,
            child: SafeArea(
              child: Builder(builder: (context) {
                if (vm.isLoading && vm.history.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.errorMessage != null && vm.history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.blueAccent.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(loc.translate(vm.errorMessage!),
                            style: TextStyle(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () =>
                              vm.fetchBehaviorData(widget.student.id),
                          child: Text(loc.translate('retry')),
                        ),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlatinumScore(context, isDark, vm.summary),
                      const SizedBox(height: 48),
                      _buildEvolutionChart(context, isDark,
                          vm.summary['weekly_evolution'] ?? []),
                      const SizedBox(height: 48),
                      _buildAppreciationSection(
                          context, isDark, vm.summary['appreciation']),
                      const SizedBox(height: 48),
                      Text(loc.translate('recent_history').toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: secondaryTextColor,
                              letterSpacing: 2)),
                      const SizedBox(height: 24),
                      _buildBehaviorTimeline(context, isDark, vm.history),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlatinumScore(
      BuildContext context, bool isDark, Map<String, dynamic> summary) {
    final loc = AppLocalizations.of(context)!;
    final score = summary['score'] ?? 0;
    final delta = summary['delta'] ?? 0;
    final congratulations = summary['congratulations'] ?? 0;
    final warnings = summary['warnings'] ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.translate('global_score').toUpperCase(),
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text('$score',
                      style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 56,
                          letterSpacing: -3)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: delta >= 0
                            ? Colors.greenAccent.withValues(alpha: 0.1)
                            : Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(
                            delta >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: delta >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 14),
                        const SizedBox(width: 6),
                        Text(
                            '${delta >= 0 ? "+" : ""}$delta ${loc.translate('this_week')}',
                            style: TextStyle(
                                color: delta >= 0
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  _buildMiniStat(loc.translate('congratulations'),
                      '$congratulations', Colors.indigoAccent),
                  const SizedBox(height: 16),
                  _buildMiniStat(loc.translate('warnings'), '$warnings',
                      Colors.orangeAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart(
      BuildContext context, bool isDark, List evolution) {
    final loc = AppLocalizations.of(context)!;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.translate('weekly_points_evolution'),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: primaryTextColor)),
            _buildChartTabs(isDark),
          ],
        ),
        const SizedBox(height: 32),
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 20,
              barGroups: _generateBarGroups(isDark, evolution),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final days = [
                        loc.translate('mon_short'),
                        loc.translate('tue_short'),
                        loc.translate('wed_short'),
                        loc.translate('thu_short'),
                        loc.translate('fri_short')
                      ];
                      if (val.toInt() < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(days[val.toInt()],
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  List<BarChartGroupData> _generateBarGroups(bool isDark, List evolution) {
    final values = evolution.isEmpty
        ? [0.0, 0.0, 0.0, 0.0, 0.0]
        : evolution.map((v) => (v['value'] as num).toDouble()).toList();
    return List.generate(values.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent,
                Colors.blueAccent.withValues(alpha: 0.3)
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 16,
            borderRadius: BorderRadius.circular(8),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 20,
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildChartTabs(bool isDark) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton(loc.translate('week_short'), _selectedTab == 0,
              () => setState(() => _selectedTab = 0)),
          _buildTabButton(loc.translate('month_short'), _selectedTab == 1,
              () => setState(() => _selectedTab = 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w900,
                fontSize: 10)),
      ),
    );
  }

  Widget _buildAppreciationSection(
      BuildContext context, bool isDark, Map<String, dynamic>? appreciation) {
    final loc = AppLocalizations.of(context)!;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final content =
        appreciation?['content'] ?? loc.translate('no_appreciation_yet');
    final teacherName =
        appreciation?['teacher_name'] ?? loc.translate('teacher');
    final teacherRole =
        appreciation?['teacher_role'] ?? loc.translate('main_teacher');
    final teacherAvatar = appreciation?['teacher_avatar'] ??
        'https://i.pravatar.cc/150?u=teacher';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('general_appreciation'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: primaryTextColor)),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.format_quote_rounded,
                            color: Colors.blueAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          content,
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 13,
                              height: 1.6,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(teacherAvatar)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teacherName,
                              style: TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13)),
                          Text(teacherRole,
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.verified_rounded,
                          color: Colors.blueAccent, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildBehaviorTimeline(
      BuildContext context, bool isDark, List<Map<String, dynamic>> history) {
    return Column(
      children: history.asMap().entries.map((entry) {
        final item = entry.value;
        final iconData = _getIconForType(item['type']);
        final color = _getColorForType(item['type']);

        return _buildTimelineItem(
          context: context,
          icon: iconData,
          color: color,
          title: item['title'] ?? '',
          points: item['points'] ?? '',
          date: item['date'] ?? '',
          desc: item['description'] ?? '',
          teacher: item['teacher_name'] ?? '',
          teacherAvatar: item['teacher_avatar'],
          isLast: entry.key == history.length - 1,
        );
      }).toList(),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'positive':
        return Icons.star_rounded;
      case 'negative':
        return Icons.report_problem_rounded;
      case 'bonus':
        return Icons.emoji_events_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'positive':
        return Colors.amberAccent;
      case 'negative':
        return Colors.redAccent;
      case 'bonus':
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String points,
    required String date,
    required String desc,
    required String teacher,
    String? teacherAvatar,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.2))),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                      width: 2,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: primaryTextColor))),
                      Text(points,
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(date,
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Text(desc,
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                          radius: 10,
                          backgroundImage: NetworkImage(teacherAvatar ??
                              'https://i.pravatar.cc/150?u=$teacher')),
                      const SizedBox(width: 8),
                      Text(teacher,
                          style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
