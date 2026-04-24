import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  List<StudentModel> _students = [];
  Map<String, dynamic> _stats = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final classes = await ApiService.instance.getMyClasses();
      if (!mounted) return;
      if (classes.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _classes = classes;
        _selectedClass = classes[0];
      });
      await _fetchStatsAndStudents(classes[0].id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStatsAndStudents(String classId) async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.instance.getStudentsByClass(classId).catchError((e) {
          debugPrint('[ReportsScreen] getStudentsByClass error: $e');
          return <StudentModel>[];
        }),
        ApiService.instance.getClassStats(classId).catchError((e) {
          debugPrint('[ReportsScreen] getClassStats error: $e');
          return <String, dynamic>{};
        }),
      ]);
      if (!mounted) return;
      setState(() {
        _students = results[0] as List<StudentModel>;
        _stats = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[ReportsScreen] _fetchStatsAndStudents error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Safely parse a value that may be a num, a numeric string, or '--' from the backend.
  double? _safeDouble(dynamic v) {
    if (v == null || v == '--') return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: DeepSpaceBackground(
          showOrbs: true,
          child: const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent)),
        ),
      );
    }

    if (_error != null || _classes.isEmpty) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(AppLocalizations.of(context)!.translate('reports_stats'),
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ),
        body: DeepSpaceBackground(
          showOrbs: true,
          child: Center(
            child: Text(AppLocalizations.of(context)!.translate('no_results'),
                style: const TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
        ),
      );
    }

    final selectedClass = _selectedClass!;
    // Backend wraps in { success, data } — _handleResponseData already unwraps data,
    // but guard against both wrapped and unwrapped shapes.
    final statsData = (_stats['data'] is Map ? _stats['data'] : _stats) as Map<String, dynamic>;

    List<StudentModel> top5 = [];
    final rawTop5 = statsData['top5'];
    if (rawTop5 is List && rawTop5.isNotEmpty) {
      top5 = rawTop5.map((e) {
        final m = e as Map;
        return StudentModel(
          id: (m['id'] ?? m['_id'] ?? '').toString(),
          name: (m['name'] ?? 'Unknown').toString(),
          average: _safeDouble(m['average']) ?? 0.0,
        );
      }).toList();
    } else {
      final students = [..._students]..sort((a, b) => b.average.compareTo(a.average));
      top5 = students.where((s) => s.average > 0).take(5).toList();
    }

    List<StudentModel> bottom5 = [];
    final rawBottom5 = statsData['bottom5'];
    if (rawBottom5 is List && rawBottom5.isNotEmpty) {
      bottom5 = rawBottom5.map((e) {
        final m = e as Map;
        return StudentModel(
          id: (m['id'] ?? m['_id'] ?? '').toString(),
          name: (m['name'] ?? 'Unknown').toString(),
          average: _safeDouble(m['average']) ?? 0.0,
        );
      }).toList();
    } else {
      final students = [..._students]..sort((a, b) => a.average.compareTo(b.average));
      bottom5 = students.where((s) => s.average > 0).take(5).toList();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;

    // Build trend spots
    final rawTrend = statsData['trend'];
    final trendLabels = (statsData['trendLabels'] as List?)?.cast<String>() ?? [];
    List<FlSpot> trendSpots = [];
    if (rawTrend is List && rawTrend.isNotEmpty) {
      trendSpots = rawTrend.map((e) {
        final m = e as Map;
        return FlSpot(
          (_safeDouble(m['x']) ?? 0),
          (_safeDouble(m['y']) ?? 0),
        );
      }).toList();
    }
    if (trendSpots.isEmpty) trendSpots = [FlSpot(0, 0)];

    final classAvg = _safeDouble(statsData['classAverage']) ?? selectedClass.classAverage;
    final attRate = _safeDouble(statsData['attendanceRate']);
    final attRateText = attRate != null ? '${attRate.toStringAsFixed(0)}%' : '--%';
    final sucRate = _safeDouble(statsData['successRate']);
    final sucRateText = sucRate != null ? '${sucRate.toStringAsFixed(0)}%' : '--%';
    final alertsText = statsData['alerts']?.toString() ?? '0';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: DropdownButtonHideUnderline(
          child: DropdownButton<ClassModel>(
            value: _selectedClass,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            icon: Icon(Icons.arrow_drop_down, color: primaryTextColor),
            style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w900,
                fontSize: 18),
            onChanged: (newClass) {
              if (newClass != null && newClass != _selectedClass) {
                setState(() => _selectedClass = newClass);
                _fetchStatsAndStudents(newClass.id);
              }
            },
            items: _classes
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download_outlined,
                color: primaryTextColor.withValues(alpha: 0.7)),
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Performance Summary Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 20,
                                offset: const Offset(0, 10))
                          ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  AppLocalizations.of(context)!
                                      .translate('class_average'),
                                  style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              Text('${classAvg != null ? classAvg.toStringAsFixed(1) : '--'} / 20',
                                  style: TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      letterSpacing: -1)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.1)),
                            ),
                            child: const Icon(Icons.show_chart_rounded,
                                color: Colors.blueAccent, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Divider(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(
                              context,
                              AppLocalizations.of(context)!
                                  .translate('assiduity'),
                              attRateText,
                              Colors.greenAccent),
                          _buildMiniStat(
                              context,
                              AppLocalizations.of(context)!
                                  .translate('success'),
                              sucRateText,
                              Colors.blueAccent),
                          _buildMiniStat(
                              context,
                              AppLocalizations.of(context)!
                                  .translate('alerts_label'),
                              alertsText,
                              Colors.orangeAccent),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 48),

                // Performance Lists
                Text('🏆 ${AppLocalizations.of(context)!.translate('top_5')}',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 20),
                ...top5.asMap().entries.map((e) => _buildPerformanceTile(
                    context, e.value, e.key + 1,
                    isTop: true)),

                const SizedBox(height: 40),

                Text(
                    '⚠️ ${AppLocalizations.of(context)!.translate('vigilance_points')}',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 20),
                ...bottom5.asMap().entries.map((e) => _buildPerformanceTile(
                    context, e.value, e.key + 1,
                    isTop: false)),

                const SizedBox(height: 48),

                // Evolution Chart
                Text(AppLocalizations.of(context)!.translate('grade_evolution'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 20),
                if (trendSpots.length < 2)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('not_enough_data'),
                        style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  )
                else
                Container(
                  height: 260,
                  padding: const EdgeInsets.fromLTRB(16, 32, 24, 24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.7),
                                blurRadius: 20)
                          ],
                  ),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 20,
                      minX: 0,
                      maxX: (trendSpots.length - 1).toDouble().clamp(0, 4),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => FlLine(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.8),
                            strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              final label = idx >= 0 && idx < trendLabels.length
                                  ? trendLabels[idx]
                                  : '';
                              return Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(label,
                                    style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) => Text(
                                val.toInt().toString(),
                                style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900)),
                            reservedSize: 28,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trendSpots,
                          isCurved: true,
                          gradient: const LinearGradient(
                              colors: [Colors.blueAccent, Colors.cyanAccent]),
                          barWidth: 6,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                      radius: 6,
                                      color: Colors.blueAccent,
                                      strokeWidth: 3,
                                      strokeColor: Colors.white)),
                          belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                  colors: [
                                    Colors.blueAccent.withValues(alpha: 0.2),
                                    Colors.blueAccent.withValues(alpha: 0)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter)),
                        ),
                        LineChartBarData(
                          spots: trendSpots,
                          isCurved: true,
                          color: Colors.white24,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          dashArray: [5, 5],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(
      BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: secondaryTextColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildPerformanceTile(
      BuildContext context, StudentModel student, int rank,
      {required bool isTop}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : null;
    final color = isTop ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
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
                    color: Colors.white.withValues(alpha: 0.7), blurRadius: 10)
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Center(
              child: medal != null
                  ? Text(medal, style: const TextStyle(fontSize: 16))
                  : Text('$rank',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: color,
                          fontSize: 13)),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
              child: Text(student.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: primaryTextColor,
                      letterSpacing: -0.2))),
          Text('${student.average.toStringAsFixed(1)}/20',
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (rank * 80).ms)
        .slideX(begin: isTop ? -0.05 : 0.05);
  }

  void _showExportOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.translate('export_report'),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5)),
            const SizedBox(height: 32),
            _buildExportTile(
                context,
                Icons.picture_as_pdf_rounded,
                AppLocalizations.of(context)!.translate('pdf_format'),
                Colors.redAccent),
            _buildExportTile(
                context,
                Icons.table_view_rounded,
                AppLocalizations.of(context)!.translate('excel_format'),
                Colors.greenAccent),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile(
      BuildContext context, IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
      ),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20)),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: primaryTextColor)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: isDark ? Colors.white24 : Colors.black26, size: 20),
        onTap: () {},
      ),
    );
  }
}
