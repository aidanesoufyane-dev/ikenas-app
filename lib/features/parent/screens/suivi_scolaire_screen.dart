import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/suivi_view_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

//hello
class SuiviScolaireScreen extends StatefulWidget {
  final StudentModel student;
  const SuiviScolaireScreen({super.key, required this.student});

  @override
  State<SuiviScolaireScreen> createState() => _SuiviScolaireScreenState();
}

class _SuiviScolaireScreenState extends State<SuiviScolaireScreen> {
  int _activeTab = 0;
  int _currentMonthIndex = 0; // Will be set in initState
  int _selectedSubjectIndex = 0;
  late String _selectedYear;

  @override
  void dispose() {
    context.read<SuiviViewModel>().stopPolling();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startYear = now.month >= 9 ? now.year : now.year - 1;
    _selectedYear = '$startYear - ${startYear + 1}';

    // Set current month index based on now
    final schoolMonths = [9, 10, 11, 12, 1, 2, 3, 4, 5, 6];
    _currentMonthIndex = schoolMonths.indexOf(now.month);
    if (_currentMonthIndex == -1) {
      // If outside school months, default to first (Sep) or last (Jun)
      _currentMonthIndex = now.month < 9 && now.month > 6 ? 0 : 9;
    }

    // Fetch data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final suiviVM = context.read<SuiviViewModel>();
      suiviVM.startPolling(widget.student.id);
      suiviVM.fetchSuiviData(widget.student.id);
    });
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
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Performance :  ${AppLocalizations.of(context)!.translate('academic_summary')}',
                      style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white),
                  ),
                  child: Stack(
                    children: [
                      // Sliding background indicator
                      AnimatedAlign(
                        duration: 400.ms,
                        curve: Curves.easeOutCirc,
                        alignment: Alignment(
                            _activeTab == 0 ? -1 : (_activeTab == 1 ? 0 : 1),
                            0),
                        child: FractionallySizedBox(
                          widthFactor: 1 / 3,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.blueAccent, Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildTabItem(
                              AppLocalizations.of(context)!
                                  .translate('Notes des Examens'),
                              0,
                              isDark),
                          _buildTabItem(
                              AppLocalizations.of(context)!
                                  .translate('evolution'),
                              1,
                              isDark),
                          _buildTabItem(
                              AppLocalizations.of(context)!
                                  .translate('absences_tab'),
                              2,
                              isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Consumer<SuiviViewModel>(
                  builder: (context, vm, child) {
                    if (vm.isLoading &&
                        vm.grades.isEmpty &&
                        vm.absences.isEmpty) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.blueAccent));
                    }

                    if (vm.errorMessage != null &&
                        vm.grades.isEmpty &&
                        vm.absences.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 64,
                                color: Colors.redAccent.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(vm.errorMessage!,
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                                onPressed: () =>
                                    vm.fetchSuiviData(widget.student.id),
                                child: const Text("Réessayer")),
                          ],
                        ),
                      );
                    }

                    return AnimatedSwitcher(
                      duration: 400.ms,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _getActiveTabContent(isDark, vm),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getActiveTabContent(bool isDark, SuiviViewModel vm) {
    switch (_activeTab) {
      case 0:
        return KeyedSubtree(
            key: const ValueKey(0), child: _buildEvaluationsTab(isDark, vm));
      case 1:
        return KeyedSubtree(
            key: const ValueKey(1), child: _buildEvolutionTab(isDark, vm));
      case 2:
        return KeyedSubtree(
            key: const ValueKey(2), child: _buildAbsencesTab(isDark, vm));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTabItem(String label, int index, bool isDark) {
    bool isActive = _activeTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white38 : Colors.black38),
              fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationsTab(bool isDark, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final groupedGrades = vm.groupedGrades;
    final subjects = groupedGrades.keys.toList();

    if (groupedGrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined,
                size: 64, color: Colors.blueAccent.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.translate('no_history'),
                style: const TextStyle(
                    color: Colors.white54, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subjectId = subjects[index];
        final subjectAvg = vm.calculateSubjectAverage(subjectId);
        final subjectName = AppLocalizations.of(context)!.translate(subjectId);
        final color = _getSubjectColor(subjectId, subjectName, index);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                width: 1.5),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              if (isDark)
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Modern Icon Badge
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.8), color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Icon(
                        _getSubjectIcon(subjectId, subjectName),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Subject info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjectName,
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: primaryTextColor,
                                letterSpacing: -0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Ranking info
                          Row(
                            children: [
                              Icon(Icons.leaderboard_rounded,
                                  size: 14,
                                  color: color.withValues(alpha: 0.6)),
                              const SizedBox(width: 6),
                              Text(
                                "Rang: ${vm.getSubjectRank(subjectId) ?? '-'} / ${vm.getSubjectClassSize(subjectId) ?? '-'}",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // History Button
                          GestureDetector(
                            onTap: () => _showSubjectHistory(subjectId, color),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.15),
                                    color.withValues(alpha: 0.05)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Historique du Suivi",
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 10, color: color),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Value Display
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : color.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.withValues(alpha: 0.15), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            subjectAvg.toStringAsFixed(1),
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                color: color,
                                height: 1.1),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'pts',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1,
                                color: color.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: (index * 100).ms, duration: 600.ms)
            .slideX(begin: 0.1, curve: Curves.easeOutCubic);
      },
    );
  }



  Widget _buildEvolutionTab(bool isDark, SuiviViewModel vm) {
    // Subject keys used in API/ViewModel
    final subjectKeys = vm.evolutionData.keys.toList();

    // If empty, use a default list to avoid UI crash, or show empty state
    if (subjectKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded,
                size: 64, color: Colors.blueAccent.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.translate('no_history'),
                style: const TextStyle(
                    color: Colors.white54, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    // Map keys to localized names
    final schoolSubjects = subjectKeys
        .map((key) => AppLocalizations.of(context)!.translate(key))
        .toList();

    // Ensure selected index is within bounds
    if (_selectedSubjectIndex >= subjectKeys.length) {
      _selectedSubjectIndex = 0;
    }

    final currentKey = subjectKeys[_selectedSubjectIndex];
    final semesterData = vm.evolutionDataBySemester[currentKey] ?? {};
    final s1Data = semesterData['1'] ?? [];
    final s2Data = semesterData['2'] ?? [];

    final List<FlSpot> s1Spots = s1Data
        .map((p) => FlSpot((p['x'] as num?)?.toDouble() ?? 0.0,
            (p['y'] as num?)?.toDouble() ?? 0.0))
        .toList();
    final int s1Count = s1Spots.length;
    final List<FlSpot> s2Spots = s2Data
        .map((p) => FlSpot(((p['x'] as num?)?.toDouble() ?? 0.0) + s1Count,
            (p['y'] as num?)?.toDouble() ?? 0.0))
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(isDark, vm)
              .animate()
              .fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 48),
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: schoolSubjects.length,
              itemBuilder: (context, index) {
                final subject = schoolSubjects[index];
                final isSelected = index == _selectedSubjectIndex;

                return GestureDetector(
                  onTap: () => setState(() => _selectedSubjectIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)])
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05)),
                          width: 1.5),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8)),
                        if (!isSelected && !isDark)
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(subject,
                        style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black54),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.2)),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 40),
          Text(AppLocalizations.of(context)!.translate('quarterly_progression'),
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2))
              .animate()
              .fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          _buildEvolutionChart(isDark, s1Spots, s2Spots, vm, currentKey)
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 16),
          _buildSimpleExtremas(isDark, [...s1Spots, ...s2Spots])
              .animate()
              .fadeIn(delay: 600.ms),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 40,
                offset: const Offset(0, 15)),
          if (isDark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10)),
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
                          .translate('general_average')
                          .toUpperCase(),
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(vm.generalAverage.toStringAsFixed(2),
                          style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2)),
                      const SizedBox(width: 8),
                      Text('/10',
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.blueAccent, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            height: 1.5,
            width: double.infinity,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat(AppLocalizations.of(context)!.translate('rank'),
                  () {
                final rank = vm.getOverallRank();
                final size = vm.getOverallClassSize();
                if (rank == null) return '--';
                return size != null ? '$rank/$size' : '$rank';
              }(), Colors.orangeAccent, isDark),
              () {
                final trend = vm.getGeneralTrend();
                final trendStr =
                    (trend >= 0 ? '+' : '') + trend.toStringAsFixed(1);
                final trendColor =
                    trend >= 0 ? Colors.greenAccent : Colors.redAccent;
                return _buildSimpleStat(
                    'Tendance', trendStr, trendColor, isDark);
              }(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(
      String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildEvolutionChart(bool isDark, List<FlSpot> s1Spots,
      List<FlSpot> s2Spots, SuiviViewModel vm, String subjectId) {
    if (s1Spots.isEmpty && s2Spots.isEmpty) return const SizedBox(height: 220);

    final combinedSpots = [...s1Spots, ...s2Spots];
    double maxY = 10;
    double minY = 0;

    double maxX = combinedSpots.isNotEmpty
        ? combinedSpots.map((e) => e.x).reduce((a, b) => a > b ? a : b)
        : 4;
    if (maxX < 4) maxX = 4;

    for (var s in combinedSpots) {
      if (s.y > maxY) maxY = ((s.y / 5).ceil() * 5).toDouble();
    }

    int s1Count = s1Spots.length;

    return Container(
      height: 260,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, right: 30, left: 10),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (v) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    strokeWidth: 1,
                  )),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, meta) {
                  final index = v.toInt();
                  if (index >= 0 &&
                      index < combinedSpots.length &&
                      v == index) {
                    final semester = index >= s1Count ? "2" : "1";
                    final pointIndex =
                        index >= s1Count ? (index - s1Count) : index;
                    final label =
                        vm.getLabelForPoint(subjectId, semester, pointIndex);

                    return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(label,
                            style: TextStyle(
                                color: isDark ? Colors.white24 : Colors.black26,
                                fontWeight: FontWeight.w900,
                                fontSize: 10)));
                  }
                  return const SizedBox.shrink();
                },
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                    style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontWeight: FontWeight.w900,
                        fontSize: 10)),
                interval: 5,
                reservedSize: 32,
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              if (s1Spots.isNotEmpty && s2Spots.isNotEmpty)
                VerticalLine(
                  x: s1Count - 0.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.15),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: VerticalLineLabel(
                    show: true,
                    labelResolver: (l) => " S2 ",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    alignment: Alignment.topRight,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                ),
            ],
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: combinedSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(colors: [
                Color(0xFF3B82F6),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899)
              ]), // Beautiful gradient line
              barWidth: 5,
              isStrokeCapRound: true,
              shadow: Shadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5)), // Line glow
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFF8B5CF6), // Purple stroke
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      const Color(0xFF3B82F6).withValues(alpha: 0.0)
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleExtremas(bool isDark, List<FlSpot> spots) {
    if (spots.isEmpty) return const SizedBox.shrink();
    final highestSpot = spots.reduce((a, b) => a.y > b.y ? a : b);
    final lowestSpot = spots.reduce((a, b) => a.y < b.y ? a : b);

    Widget buildBadge(
        String label, String value, Color color, IconData icon, bool isDark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.5)),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5)),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildBadge(
            AppLocalizations.of(context)!.translate('min'),
            '${lowestSpot.y.toStringAsFixed(1)}/10',
            const Color(0xFFEF4444),
            Icons.arrow_downward_rounded,
            isDark),
        buildBadge(
            AppLocalizations.of(context)!.translate('max'),
            '${highestSpot.y.toStringAsFixed(1)}/10',
            const Color(0xFF10B981),
            Icons.arrow_upward_rounded,
            isDark),
      ],
    );
  }

  Widget _buildAbsencesTab(bool isDark, SuiviViewModel vm) {
    final textColor = isDark ? Colors.white54 : Colors.black45;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                  AppLocalizations.of(context)!
                      .translate('academic_summary')
                      .toUpperCase(),
                  style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5))
              .animate()
              .fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          _buildSummaryAbsenceCards(isDark, vm)
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 32),
          _buildAttendanceDistribution(isDark, vm)
              .animate()
              .fadeIn(delay: 300.ms),
          const SizedBox(height: 48),
          _buildAttendanceCalendar(isDark, vm)
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 48),
          Text(
                  AppLocalizations.of(context)!
                      .translate('recent_history')
                      .toUpperCase(),
                  style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5))
              .animate()
              .fadeIn(delay: 500.ms),
          const SizedBox(height: 24),
          _buildRecentHistory(isDark, vm)
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAttendanceDistribution(bool isDark, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    final rate = vm.attendanceRate;
    final total = vm.totalAttendanceDays;
    final absRate = total > 0
        ? ((vm.unjustifiedAbsences + vm.justifiedAbsences) / total * 100)
        : 0.0;
    final lateRate = total > 0 ? (vm.delays / total * 100) : 0.0;
    final presentRate = total > 0 ? (vm.presentDays / total * 100) : 100.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 40,
                offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular Indicator with Glow & Depth
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00F2FE).withValues(alpha: 0.15),
                          const Color(0xFF00F2FE).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.1, 1.1),
                          duration: 3.seconds,
                          curve: Curves.easeInOut),

                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 10),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 56,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            color: Colors.greenAccent,
                            value: rate,
                            radius: 14,
                            showTitle: false,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00F2FE),
                                Color(0xFF4FACFE),
                                Color(0xFF4F46E5)
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                          PieChartSectionData(
                              color: Colors.transparent,
                              value: 100 - rate,
                              radius: 10,
                              showTitle: false),
                        ],
                      ),
                    )
                        .animate()
                        .rotate(duration: 1500.ms, curve: Curves.easeOutQuart),
                  ),
                  _CountUpText(
                      value: rate,
                      suffix: '%',
                      style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2)),
                ],
              ),
              const SizedBox(width: 32),
              // Status Text & Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PRÉS.",
                        style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5)),
                    const SizedBox(height: 10),
                    Text(
                            rate >= 90
                                ? "Excellent"
                                : (rate >= 75 ? "Bon État" : "À Surveiller"),
                            style: TextStyle(
                                color: rate >= 75
                                    ? (rate >= 90
                                        ? Colors.greenAccent
                                        : const Color(0xFF00F2FE))
                                    : Colors.orangeAccent,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                      color: (rate >= 75
                                              ? const Color(0xFF00F2FE)
                                              : Colors.orangeAccent)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 15)
                                ]))
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideX(begin: 0.1),
                    const SizedBox(height: 20),
                    // Glass Badge with Shimmer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.greenAccent.withValues(alpha: 0.05),
                                blurRadius: 10)
                          ]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 8),
                          Text("VÉRIFIÉ",
                              style: TextStyle(
                                  color:
                                      primaryTextColor.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 3.seconds, delay: 2.seconds),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          Container(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
          const SizedBox(height: 32),
          // Enhanced Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDistributionDetail("Présent", presentRate,
                  const Color(0xFF10B981), Icons.check_circle_rounded, isDark),
              _buildDistributionDetail(
                  "Retard",
                  lateRate,
                  const Color(0xFFFBBF24),
                  Icons.access_time_filled_rounded,
                  isDark),
              _buildDistributionDetail("Absent", absRate, Colors.redAccent,
                  Icons.error_outline_rounded, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionDetail(String label, double percentage, Color color,
      IconData icon, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.withValues(alpha: 0.6), size: 12),
            const SizedBox(width: 8),
            _CountUpText(
                value: percentage,
                suffix: '%',
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 6),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        // Mini Progress Bar
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percentage / 100).clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        )
            .animate()
            .scaleX(begin: 0, duration: 1.seconds, curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildAttendanceCalendar(bool isDark, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    final schoolMonths = [
      {'key': 'september', 'month': 9},
      {'key': 'october', 'month': 10},
      {'key': 'november', 'month': 11},
      {'key': 'december', 'month': 12},
      {'key': 'january', 'month': 1},
      {'key': 'february', 'month': 2},
      {'key': 'march', 'month': 3},
      {'key': 'april', 'month': 4},
      {'key': 'may', 'month': 5},
      {'key': 'june', 'month': 6}
    ];

    final currentMonthData = schoolMonths[_currentMonthIndex];
    final realMonth = currentMonthData['month'] as int;
    final yearParts = _selectedYear.split(' - ');
    final realYear = int.parse(realMonth >= 9 ? yearParts[0] : yearParts[1]);

    final currentMonthLabel = AppLocalizations.of(context)!
        .translate(currentMonthData['key'] as String);
    final daysInMonth = DateTime(realYear, realMonth + 1, 0).day;
    final firstDay = DateTime(realYear, realMonth, 1);
    final offset = firstDay.weekday - 1;

    return Stack(
      children: [
        // Background decorative glass glow
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: isDark ? 0.05 : 0.03),
            ),
          )
              .animate()
              .fadeIn(duration: 1200.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        ),

        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 40,
                    offset: const Offset(0, 10)),
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
                      Text(realYear.toString(),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text(currentMonthLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: primaryTextColor,
                              letterSpacing: -0.5)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalendarNav(
                          Icons.chevron_left_rounded,
                          () => setState(() => _currentMonthIndex =
                              (_currentMonthIndex > 0)
                                  ? _currentMonthIndex - 1
                                  : 9),
                          isDark),
                      const SizedBox(width: 8),
                      _buildCalendarNav(
                          Icons.chevron_right_rounded,
                          () => setState(() => _currentMonthIndex =
                              (_currentMonthIndex < 9)
                                  ? _currentMonthIndex + 1
                                  : 0),
                          isDark),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Weekdays header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                    .map((d) => SizedBox(
                        width: 38,
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.5))))
                    .toList(),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12),
                itemCount: 35,
                itemBuilder: (context, index) {
                  final dayNum = index - offset + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final currentDayDate = DateTime(realYear, realMonth, dayNum);
                  final attendance = vm.getAttendanceForDate(currentDayDate);

                  final statusStr = attendance?.status.toLowerCase() ?? '';
                  final isAbsent = statusStr == 'absent';
                  final isLate = statusStr == 'late' || statusStr == 'retard';
                  final isPresent = statusStr == 'present';
                  final isToday = dayNum == DateTime.now().day &&
                      realMonth == DateTime.now().month &&
                      realYear == DateTime.now().year;

                  Color? dotColor;
                  if (isPresent) {
                    dotColor = const Color(0xFF10B981); // Teal for presence
                  } else if (attendance?.isJustified ?? false) {
                    dotColor =
                        const Color(0xFF8B5CF6); // Violet for justified absence
                  } else if (isAbsent) {
                    dotColor = Colors.redAccent;
                  } else if (isLate) {
                    dotColor = const Color(
                        0xFFFBBF24); // Amber for late to match Image 4
                  }

                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.blueAccent
                          : (dotColor != null
                              ? dotColor.withValues(alpha: 0.15)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                      border: isToday
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5)
                          : (dotColor != null
                              ? Border.all(
                                  color: dotColor.withValues(alpha: 0.2))
                              : null),
                      boxShadow: [
                        if (isToday)
                          BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(dayNum.toString(),
                            style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : (dotColor ?? primaryTextColor),
                                fontWeight: isToday || dotColor != null
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                fontSize: 13)),
                        if (dotColor != null && !isToday)
                          Positioned(
                            bottom: 6,
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                  color: dotColor, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (index * 10).ms)
                      .scale(begin: const Offset(0.9, 0.9));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarNav(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon,
            color:
                isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.8),
            size: 20),
      ),
    );
  }

  Widget _buildRecentHistory(bool isDark, SuiviViewModel vm) {
    final schoolMonths = [
      {'key': 'september', 'month': 9},
      {'key': 'october', 'month': 10},
      {'key': 'november', 'month': 11},
      {'key': 'december', 'month': 12},
      {'key': 'january', 'month': 1},
      {'key': 'february', 'month': 2},
      {'key': 'march', 'month': 3},
      {'key': 'april', 'month': 4},
      {'key': 'may', 'month': 5},
      {'key': 'june', 'month': 6}
    ];

    // Get current selected month/year from calendar state
    final currentMonthData = schoolMonths[_currentMonthIndex];
    final realMonth = currentMonthData['month'] as int;
    final yearParts = _selectedYear.split(' - ');
    final realYear = int.parse(realMonth >= 9 ? yearParts[0] : yearParts[1]);

    // Keep complete attendance history for the selected month:
    // - late
    // - unjustified absences
    // - justified absences (even if backend normalizes status differently)
    final filteredHistory = vm.absences.where((a) {
      try {
        final dt = DateTime.parse(a.date);
        final matchesMonth = dt.month == realMonth && dt.year == realYear;
        final isHistoryEntry =
            true; // Show all attendance records (absent, late, present) as seen in Image 4
        return matchesMonth && isHistoryEntry;
      } catch (e) {
        return false;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
            height:
                12), // Placeholder for removed pills spacing if needed, but the heading spacing is already handled

        if (filteredHistory.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(Icons.history_rounded,
                    size: 48, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.translate('no_history'),
                  style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredHistory.length,
            itemBuilder: (context, index) {
              final a = filteredHistory[index];

              Color color;

              final statusStr = a.status.toLowerCase();
              if (a.isJustified) {
                color = const Color(0xFF8B5CF6); // Violet for justified absence
              } else if (statusStr == 'absent') {
                color = Colors.redAccent;
              } else if (statusStr == 'late' || statusStr == 'retard') {
                color = const Color(0xFFFBBF24); // Amber for late/retard
              } else {
                color = const Color(0xFF10B981); // Teal for presence
              }

              // Format Date
              String formattedDate = a.date;
              String formattedDateLong = a.date;
              try {
                final dt = DateTime.parse(a.date);
                formattedDate = DateFormat('dd MMM yyyy',
                        Localizations.localeOf(context).languageCode)
                    .format(dt);
                formattedDateLong = DateFormat('EEEE dd MMMM yyyy',
                        Localizations.localeOf(context).languageCode)
                    .format(dt);
              } catch (e) {/* Fallback */}

              // Resolve timing from record or schedule cross-reference
              final slot = vm.getScheduleForAttendance(a);
              final startTime = a.startTime ?? slot?.time;
              final endTime = a.endTime;
              final timing = (startTime != null && endTime != null)
                  ? '$startTime - $endTime'
                  : (startTime ?? '');
              final sessionTitle = a.subjectName ??
                  a.sessionName ??
                  slot?.subject ??
                  AppLocalizations.of(context)!.translate('session');
              final teacher = slot?.teacher;
              final room = slot?.room;

              void showDetailSheet() {
                bool isUploading = false;
                bool isEditing = !a.isJustified;

                // Try to extract previously selected reason if editing
                String selectedReason = 'Maladie';
                if (a.motif != null && a.motif!.contains(':')) {
                  final parts = a.motif!.split(':');
                  selectedReason = parts[0].trim();
                } else if (a.motif != null && a.motif!.isNotEmpty) {
                  final reasons = [
                    'Maladie',
                    'Médical',
                    'Famille',
                    'Voyage',
                    'Autre'
                  ];
                  for (var r in reasons) {
                    if (a.motif!.contains(r)) {
                      selectedReason = r;
                      break;
                    }
                  }
                }

                final TextEditingController commentController =
                    TextEditingController(
                        text: a.motif != null && a.motif!.contains(':')
                            ? a.motif!.split(':').sublist(1).join(':').trim()
                            : (a.motif ?? ''));
                PlatformFile? selectedFile;
                int uploadCountdown = 30;

                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setStateSheet) {
                        final reasons = [
                          'Maladie',
                          'Médical',
                          'Famille',
                          'Voyage',
                          'Autre'
                        ];
                        final isJustified = a.isJustified;
                        final statusStr = a.status.toLowerCase();
                        final isPresent = statusStr == 'present';
                        final isLate = statusStr == 'late' || statusStr == 'retard';
                        final isAbsent = statusStr == 'absent';

                        // Color & icon for header
                        final headerColor = isPresent
                            ? const Color(0xFF10B981)
                            : isLate
                                ? const Color(0xFFFBBF24)
                                : isJustified
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.redAccent;
                        final headerIcon = isPresent
                            ? Icons.check_circle_rounded
                            : isLate
                                ? Icons.watch_later_rounded
                                : isJustified
                                    ? Icons.verified_rounded
                                    : Icons.cancel_rounded;
                        final headerLabel = isPresent
                            ? 'PRÉSENCE'
                            : isLate
                                ? 'RETARD'
                                : isJustified
                                    ? AppLocalizations.of(context)!.translate('absence_justifiee').toUpperCase()
                                    : AppLocalizations.of(context)!.translate('unjustified').toUpperCase();

                        return Container(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(40)),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(2))),
                                ),
                                const SizedBox(height: 32),

                                // Header Section
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: headerColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        headerIcon,
                                        color: headerColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: headerColor.withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              headerLabel,
                                              style: TextStyle(
                                                  color: headerColor,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 10,
                                                  letterSpacing: 0.8),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(sessionTitle,
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 24,
                                                  letterSpacing: -0.5)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),

                                // Info Rows
                                _buildSheetInfoRow(Icons.calendar_today_rounded,
                                    formattedDateLong, isDark),
                                const SizedBox(height: 16),
                                _buildSheetInfoRow(
                                    Icons.schedule_rounded, timing, isDark),
                                const SizedBox(height: 16),
                                _buildSheetInfoRow(Icons.person_outline_rounded,
                                    teacher ?? 'Kaoutar Ben', isDark),
                                const SizedBox(height: 16),
                                _buildSheetInfoRow(Icons.location_on_outlined,
                                    room ?? 'Salle s2', isDark),

                                const SizedBox(height: 48),

                                // Only show justification section for absences
                                if (!isAbsent) ...[
                                  // For presence/late: just a close button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: headerColor.withValues(alpha: 0.12),
                                        foregroundColor: headerColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: Text(
                                        'Fermer',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: headerColor),
                                      ),
                                    ),
                                  ),
                                ] else if (!isEditing) ...[
                                  // View Mode (Details of existing justification)
                                  Text("Motif de l'absence",
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2)),
                                  const SizedBox(height: 20),
                                  _buildSheetInfoRow(Icons.folder_outlined,
                                      selectedReason, isDark),

                                  if (a.attachment != null) ...[
                                    const SizedBox(height: 32),
                                    InkWell(
                                      onTap: () async {
                                        if (a.attachment != null) {
                                          final uri = Uri.parse(a.attachment!);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent
                                              .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.blueAccent
                                                  .withValues(alpha: 0.1)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                  color: Colors.blueAccent
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: const Icon(
                                                  Icons
                                                      .insert_drive_file_rounded,
                                                  color: Colors.blueAccent,
                                                  size: 24),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      "Visualiser le document actuel",
                                                      style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF0F172A),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14)),
                                                  const SizedBox(height: 2),
                                                  Text("PDF / Image",
                                                      style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white38
                                                              : Colors.black38,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                                Icons.open_in_new_rounded,
                                                color: Colors.blueAccent,
                                                size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 48),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          setStateSheet(() => isEditing = true),
                                      icon: const Icon(Icons.edit_rounded,
                                          size: 20),
                                      label: const Text(
                                          "Mettre à jour la justification",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.blueAccent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            side: const BorderSide(
                                                color: Colors.blueAccent,
                                                width: 2)),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Edit Mode
                                  Text("Motif de l'absence",
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2)),
                                  const SizedBox(height: 20),

                                  // Reason chips
                                  SizedBox(
                                    height: 44,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: reasons.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        final r = reasons[index];
                                        final isSelected = selectedReason == r;
                                        return GestureDetector(
                                          onTap: () => setStateSheet(
                                              () => selectedReason = r),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.blueAccent
                                                      .withValues(alpha: 0.1)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: isSelected
                                                      ? Colors.blueAccent
                                                      : (isDark
                                                          ? Colors.white12
                                                          : Colors.black12),
                                                  width: 1.5),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              r,
                                              style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.blueAccent
                                                      : (isDark
                                                          ? Colors.white38
                                                          : Colors.black38),
                                                  fontWeight: isSelected
                                                      ? FontWeight.w900
                                                      : FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Comment field
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.black
                                              .withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.06)
                                              : Colors.black
                                                  .withValues(alpha: 0.05)),
                                    ),
                                    child: TextField(
                                      controller: commentController,
                                      maxLines: 3,
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                          fontSize: 15),
                                      decoration: InputDecoration(
                                        hintText: "Décrivez le motif...",
                                        hintStyle: TextStyle(
                                            color: (isDark
                                                ? Colors.white38
                                                : Colors.black38),
                                            fontSize: 14),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // File selection or preview
                                  if (selectedFile != null)
                                    InkWell(
                                      onTap: () {
                                        if (selectedFile!.path != null) {
                                          OpenFilex.open(selectedFile!.path!);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981)
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: Icon(
                                                selectedFile!.extension == 'pdf'
                                                    ? Icons
                                                        .picture_as_pdf_rounded
                                                    : (selectedFile!.extension
                                                                ?.contains(
                                                                    'doc') ??
                                                            false)
                                                        ? Icons
                                                            .description_rounded
                                                        : Icons.image_rounded,
                                                color: const Color(0xFF10B981),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(selectedFile!.name,
                                                      style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF0F172A),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                      "Cliquer pour prévisualiser",
                                                      style: TextStyle(
                                                          color: const Color(
                                                              0xFF10B981),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.redAccent,
                                                  size: 24),
                                              onPressed: () => setStateSheet(
                                                  () => selectedFile = null),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () async {
                                        try {
                                          FilePickerResult? result =
                                              await FilePicker.platform
                                                  .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: [
                                              'jpg',
                                              'png',
                                              'pdf',
                                              'doc',
                                              'docx'
                                            ],
                                            withData: true,
                                          );
                                          if (result != null) {
                                            setStateSheet(() => selectedFile =
                                                result.files.first);
                                          }
                                        } catch (e) {
                                          debugPrint('File picker error: $e');
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 32),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.02)
                                              : Colors.black
                                                  .withValues(alpha: 0.02),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          border: Border.all(
                                              color: (isDark
                                                      ? Colors.white
                                                      : Colors.black)
                                                  .withValues(alpha: 0.06),
                                              style: BorderStyle.solid),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(Icons.cloud_upload_outlined,
                                                color: Colors.blueAccent
                                                    .withValues(alpha: 0.5),
                                                size: 32),
                                            const SizedBox(height: 12),
                                            Text(
                                                "Joindre un fichier (Image, PDF, Word)",
                                                style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.black38,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 48),

                                  // Action Buttons
                                  SizedBox(
                                    width: double.infinity,
                                    height: 64,
                                    child: ElevatedButton(
                                      onPressed: isUploading
                                          ? null
                                          : () async {
                                              final bool isCreateMode =
                                                  !a.isJustified;
                                              final String finalReasonString =
                                                  '$selectedReason: ${commentController.text}'
                                                      .trim();
                                              final bool isReasonModified =
                                                  a.motif != finalReasonString;

                                              if (isCreateMode) {
                                                // Strict Rule 1: CREATE -> Must provide BOTH reason and attachment
                                                if (selectedFile == null) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(const SnackBar(
                                                          content: Text(
                                                              'Veuillez fournir un fichier de justification (document/image).')));
                                                  return;
                                                }
                                                if (commentController.text
                                                    .trim()
                                                    .isEmpty) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(const SnackBar(
                                                          content: Text(
                                                              'Veuillez préciser le motif de l\'absence.')));
                                                  return;
                                                }
                                              } else {
                                                // Strict Rule 2: UPDATE -> Must provide AT LEAST ONE change
                                                if (selectedFile == null &&
                                                    !isReasonModified) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(const SnackBar(
                                                          content: Text(
                                                              'Veuillez modifier le motif ou joindre un nouveau document.')));
                                                  return;
                                                }
                                              }
                                              setStateSheet(
                                                  () => isUploading = true);
                                              final timer = Stream.periodic(
                                                  const Duration(seconds: 1),
                                                  (i) =>
                                                      30 -
                                                      i -
                                                      1).take(30).listen(
                                                  (val) => setStateSheet(() =>
                                                      uploadCountdown = val));

                                              try {
                                                final success = await vm
                                                    .submitJustification(
                                                  a.id,
                                                  filePath: selectedFile?.path,
                                                  fileBytes:
                                                      selectedFile?.bytes,
                                                  fileName:
                                                      selectedFile?.name ??
                                                          'document',
                                                  reason:
                                                      '$selectedReason: ${commentController.text}',
                                                );

                                                timer.cancel();
                                                if (!context.mounted) return;

                                                if (success) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .translate(
                                                                  'justification_sent')),
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF10B981),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                    ),
                                                  );
                                                } else {
                                                  setStateSheet(() =>
                                                      isUploading = false);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .error_outline_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 20),
                                                          const SizedBox(
                                                              width: 12),
                                                          Expanded(
                                                              child: Text(vm
                                                                      .errorMessage ??
                                                                  'Échec de l\'envoi au serveur')),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                timer.cancel();
                                                setStateSheet(
                                                    () => isUploading = false);
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        shadowColor: const Color(0xFF3B82F6)
                                            .withValues(alpha: 0.4),
                                        elevation: 8,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                      ),
                                      child: isUploading
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                            value: 1 -
                                                                (uploadCountdown /
                                                                    30),
                                                            strokeWidth: 3,
                                                            color: Colors.white,
                                                            backgroundColor:
                                                                Colors
                                                                    .white24)),
                                                    Text(
                                                        uploadCountdown
                                                            .toString(),
                                                        style: const TextStyle(
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ],
                                                ),
                                                const SizedBox(width: 16),
                                                const Text("Envoi en cours...",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 0.5)),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.send_rounded,
                                                    size: 20),
                                                const SizedBox(width: 12),
                                                Text(
                                                    a.isJustified
                                                        ? "Mettre à jour la justification"
                                                        : "Soumettre Justification",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 16,
                                                        letterSpacing: -0.2)),
                                              ],
                                            ),
                                    ),
                                  ),

                                  if (a.isJustified) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        onPressed: () => setStateSheet(
                                            () => isEditing = false),
                                        child: Text("Annuler la modification",
                                            style: TextStyle(
                                                color: isDark
                                                    ? Colors.white38
                                                    : Colors.black38,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                      ),
                                    ),
                                  ],
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }

              return GestureDetector(
                onTap: showDetailSheet,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.02)),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 40,
                            offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Status Tag Sidebar
                          Container(
                            width: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.5)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),

                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 16, 20),
                              child: Row(
                                children: [
                                  // Left Side (Pill, Subject, Motif/Badge)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Status Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: color.withValues(
                                                    alpha: 0.15)),
                                          ),
                                          child: Text(
                                            (() {
                                              final rawStatus = a.isJustified
                                                  ? 'absence_justifiee'
                                                  : a.status;
                                              final local =
                                                  AppLocalizations.of(context)!;
                                              // Try common key variations
                                              final translated =
                                                  local.translate(rawStatus);
                                              if (translated == rawStatus) {
                                                return local
                                                    .translate(
                                                        '${rawStatus}_label')
                                                    .toUpperCase();
                                              }
                                              return translated.toUpperCase();
                                            })(),
                                            style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 10,
                                                letterSpacing: 0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Subject & Session Name
                                        Text(
                                          sessionTitle,
                                          style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 17,
                                              letterSpacing: -0.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        // Motif (if any) or Warning
                                        if (a.isJustified &&
                                            a.motif != null &&
                                            a.motif!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(a.motif!,
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.4)
                                                      : Colors.black.withValues(
                                                          alpha: 0.4),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ] else if (a.status == 'absent' &&
                                            !a.isJustified) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: Colors.redAccent
                                                        .withValues(
                                                            alpha: 0.3))),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons.warning_rounded,
                                                    color: Colors.redAccent,
                                                    size: 10),
                                                const SizedBox(width: 4),
                                                Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .translate(
                                                            'submit_justification')
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                        color: Colors.redAccent,
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.w900)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Right Side (Date and Time)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.calendar_today_rounded,
                                              color: (isDark
                                                      ? Colors.white38
                                                      : Colors.black38)
                                                  .withValues(alpha: 0.4),
                                              size: 12),
                                          const SizedBox(width: 6),
                                          Text(formattedDate,
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.black38,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 11,
                                                  letterSpacing: -0.2)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.schedule_rounded,
                                              color: (isDark
                                                      ? Colors.white38
                                                      : Colors.black38)
                                                  .withValues(alpha: 0.4),
                                              size: 12),
                                          const SizedBox(width: 6),
                                          Text(timing,
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.black38,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 11,
                                                  letterSpacing: -0.2)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Chevron / Action
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Center(
                              child: Icon(Icons.chevron_right_rounded,
                                  color:
                                      (isDark ? Colors.white38 : Colors.black38)
                                          .withValues(alpha: 0.3),
                                  size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (index * 60).ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSummaryAbsenceCards(bool isDark, SuiviViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCardItem(
            vm.unjustifiedAbsences.toString().padLeft(2, '0'),
            'NON JUSTIFIÉ',
            Colors.redAccent,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCardItem(
            vm.justifiedAbsences.toString().padLeft(2, '0'),
            'JUSTIFIÉ',
            const Color(0xFF8B5CF6),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCardItem(
            vm.delays.toString().padLeft(2, '0'),
            'RETARDS',
            const Color(0xFFFBBF24),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCardItem(
      String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          if (isDark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 36,
                height: 1.1),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  void _showSubjectHistory(String subjectId, Color subjectColor) {
    final vm = context.read<SuiviViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectGrades = vm.grades.where((g) => g.subject == subjectId).toList();
    subjectGrades.sort((a, b) => b.date.compareTo(a.date));

    final subjectName = AppLocalizations.of(context)!.translate(subjectId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Parcours Académique",
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.blueAccent
                                      : Colors.blueAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subjectName,
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded,
                            color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: subjectGrades.isEmpty
                      ? Center(
                          child: Text("Aucun historique pour cette matière",
                              style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontWeight: FontWeight.bold)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          itemCount: subjectGrades.length,
                          itemBuilder: (context, index) {
                            final g = subjectGrades[index];
                            final isSem1 = g.semester?.toString().contains('1') ?? false;
                            final color = isSem1
                                ? Color.lerp(subjectColor, isDark ? Colors.white : Colors.black, 0.4) ?? subjectColor
                                : subjectColor;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HistoryRowItem(
                                  h: g, isDark: isDark, themeColor: color),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper widget for detail rows in sheet
  Widget _buildSheetInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: isDark ? Colors.white38 : Colors.black38, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.2,
              )),
        ),
      ],
    );
  }
}

class _HistoryRowItem extends StatefulWidget {
  final GradeModel h;
  final bool isDark;
  final Color themeColor;

  const _HistoryRowItem({
    required this.h,
    required this.isDark,
    required this.themeColor,
  });

  @override
  State<_HistoryRowItem> createState() => _HistoryRowItemState();
}

class _HistoryRowItemState extends State<_HistoryRowItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final primaryTextColor =
        widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = widget.isDark ? Colors.white54 : Colors.black54;
    final h = widget.h;
    final hLabel = h.title ?? AppLocalizations.of(context)!.translate(h.type);
    final semesterClean = h.semester?.toString().replaceAll(RegExp(r'[Ss]'), '').trim();
    final title =
        "$hLabel${h.semester != null ? ' (Semestre $semesterClean)' : ''}";
    final score = '${h.grade.toStringAsFixed(1)}/${h.maxGrade.toInt()}';
    final hasComponents = h.components != null && h.components!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color:
            widget.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                widget.themeColor.withValues(alpha: _isExpanded ? 0.3 : 0.15)),
        boxShadow: [
          BoxShadow(
              color:
                  widget.themeColor.withValues(alpha: _isExpanded ? 0.1 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasComponents
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            child: Row(
              children: [
                // Colored bar indicator
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.themeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
                // Score
                Text(score,
                    style: TextStyle(
                        color: widget.themeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 20)),
                if (hasComponents) ...[
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: widget.themeColor),
                  ),
                ],
              ],
            ),
          ),
          if (hasComponents)
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: h.components!.map((c) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.themeColor.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c.title,
                              style: TextStyle(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                          Text(
                            '${c.grade.toStringAsFixed(1)}/${c.maxGrade.toInt()}',
                            style: TextStyle(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
        ],
      ),
    );
  }
}

class _CountUpText extends StatelessWidget {
  final double value;
  final String suffix;
  final TextStyle style;
  const _CountUpText(
      {required this.value, this.suffix = '', required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: 1500.ms,
      builder: (context, val, child) {
        return Text('${val.toInt()}$suffix', style: style);
      },
    );
  }
}

IconData _getSubjectIcon(String id, String name) {
  final lower = '$id $name'.toLowerCase();
  if (lower.contains('math') || lower.contains('رياضيات')) return Icons.functions_rounded;
  if (lower.contains('arab') || lower.contains('عرب')) return Icons.language_rounded;
  if (lower.contains('fran') || lower.contains('french') || lower.contains('فرنس')) return Icons.auto_stories_rounded;
  if (lower.contains('islam') || lower.contains('tarbiya') || lower.contains('إسلام') || lower.contains('دين')) return Icons.mosque_rounded;
  if (lower.contains('eng') || lower.contains('angl') || lower.contains('إنجليزي')) return Icons.translate_rounded;
  if (lower.contains('phys') || lower.contains('chim') || lower.contains('فيزياء') || lower.contains('كيمياء')) return Icons.science_rounded;
  if (lower.contains('svt') || lower.contains('bio') || lower.contains('science') || lower.contains('علوم')) return Icons.biotech_rounded;
  if (lower.contains('info') || lower.contains('comput') || lower.contains('حاسوب') || lower.contains('informatique')) return Icons.computer_rounded;
  if (lower.contains('hist') || lower.contains('geo') || lower.contains('تاريخ') || lower.contains('جغرافيا')) return Icons.public_rounded;
  if (lower.contains('sport') || lower.contains('eps') || lower.contains('رياضة')) return Icons.sports_soccer_rounded;
  if (lower.contains('philo') || lower.contains('فلسفة')) return Icons.psychology_rounded;
  return Icons.book_rounded;
}

Color _getSubjectColor(String id, String name, int fallbackIndex) {
  final lower = '$id $name'.toLowerCase();
  if (lower.contains('math') || lower.contains('رياضيات')) return Colors.blueAccent;
  if (lower.contains('arab') || lower.contains('عرب')) return Colors.purpleAccent;
  if (lower.contains('fran') || lower.contains('french') || lower.contains('فرنس')) return Colors.orangeAccent;
  if (lower.contains('islam') || lower.contains('tarbiya') || lower.contains('إسلام') || lower.contains('دين')) return const Color(0xFF10B981);
  if (lower.contains('eng') || lower.contains('angl') || lower.contains('إنجليزي')) return Colors.redAccent;
  if (lower.contains('phys') || lower.contains('chim') || lower.contains('فيزياء') || lower.contains('كيمياء')) return Colors.cyanAccent;
  if (lower.contains('svt') || lower.contains('bio') || lower.contains('science') || lower.contains('علوم')) return Colors.greenAccent;
  if (lower.contains('info') || lower.contains('comput') || lower.contains('حاسوب') || lower.contains('informatique')) return Colors.indigoAccent;
  if (lower.contains('hist') || lower.contains('geo') || lower.contains('تاريخ') || lower.contains('جغرافيا')) return Colors.brown;
  if (lower.contains('sport') || lower.contains('eps') || lower.contains('رياضة')) return Colors.deepOrangeAccent;
  if (lower.contains('philo') || lower.contains('فلسفة')) return Colors.pinkAccent;

  return (fallbackIndex % 4 == 0
      ? Colors.blueAccent
      : fallbackIndex % 4 == 1
          ? Colors.orangeAccent
          : fallbackIndex % 4 == 2
              ? Colors.purpleAccent
              : const Color(0xFF10B981));
}
