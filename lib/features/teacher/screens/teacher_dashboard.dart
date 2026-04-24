import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'attendance_screen.dart';
import 'teacher_chat_screen.dart';
import 'reports_screen.dart';
import 'student_list_screen.dart';
import 'teacher_homework_screen.dart';
import 'teacher_timetable_screen.dart';
import 'grade_entry_screen.dart';
import 'teacher_behavior_screen.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/screens/notifications_screen.dart';
import 'add_activity_screen.dart';
import 'school_news_screen.dart';
import 'add_exam_screen.dart';
import '../../../core/models/models.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/widgets/sprite_avatar.dart';
import '../../../core/localization/app_localizations.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      const _TeacherHome(),
      const SchoolNewsScreen(),
      const TeacherChatScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: _buildBottomNav(isDark),
          ).animate().slideY(
              begin: 1,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutExpo),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white,
                  width: 1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.grid_view_rounded,
                    AppLocalizations.of(context)!.translate('home'), 0, isDark),
                _buildNavItem(
                    Icons.feed_rounded,
                    AppLocalizations.of(context)!.translate('feed_nav'),
                    1,
                    isDark),
                _buildNavItem(Icons.chat_bubble_rounded,
                    AppLocalizations.of(context)!.translate('chat'), 2, isDark),
                _buildNavItem(
                    Icons.analytics_rounded,
                    AppLocalizations.of(context)!.translate('stats'),
                    3,
                    isDark),
                _buildNavItem(
                    Icons.person_rounded,
                    AppLocalizations.of(context)!.translate('profile_nav'),
                    4,
                    isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isActive = _currentIndex == index;
    final activeColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final inactiveColor = isDark ? Colors.white24 : Colors.black26;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: Colors.blueAccent, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeacherHome extends StatefulWidget {
  const _TeacherHome();

  @override
  State<_TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<_TeacherHome> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<ClassModel> _classes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // /dashboard/stats requires admin role — teachers can't access it.
      // We build the stats ourselves from teacher-accessible endpoints.
      final results = await Future.wait([
        ApiService.instance.getMyClasses(),
        ApiService.instance.getHomework('me').catchError((_) => <HomeworkModel>[]),
        ApiService.instance.getExams('me').catchError((_) => <HomeworkModel>[]),
        ApiService.instance.getClasses().catchError((_) => <ClassModel>[]),
        ApiService.instance.getTodayAbsentCount().catchError((_) => 0),
      ]);

      final classes = results[0] as List<ClassModel>;
      final homework = results[1] as List<HomeworkModel>;
      final exams = results[2] as List<HomeworkModel>;
      final allClasses = results[3] as List<ClassModel>;
      final absentToday = results[4] as int;

      // Encomapss myClasses with accurate student counts from allClasses
      // because getMyClasses originally strips off studentCount property
      int totalStudents = 0;
      final List<ClassModel> enrichedClasses = [];
      
      for (var myClass in classes) {
        try {
          final fullClass = allClasses.firstWhere((c) => c.id == myClass.id);
          enrichedClasses.add(fullClass);
          totalStudents += fullClass.studentCount;
        } catch (_) {
          enrichedClasses.add(myClass);
          totalStudents += myClass.studentCount;
        }
      }

      // Assignments the teacher needs to correct = submissions exist but no grade yet.
      // We approximate with the total number of active assignments + exams.
      final pendingCorrections = homework.length;
      final newHomework = exams.length;

      if (mounted) {
        setState(() {
          _classes = enrichedClasses;
          _stats = {
            'totalStudents': totalStudents,
            'students': totalStudents,
            'absentToday': absentToday,
            'absent': absentToday,
            'pendingCorrections': pendingCorrections,
            'pendingAssignments': pendingCorrections,
            'newHomework': newHomework,
            'assignments': newHomework,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).currentUser!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, user, isDark),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchData,
                  color: Colors.blueAccent,
                  backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12)),
                          ),
                        const SizedBox(height: 40),
                        Text(AppLocalizations.of(context)!.translate('key_indicators'),
                                style: TextStyle(
                                    color: isDark ? Colors.white24 : Colors.black26,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5))
                            .animate()
                            .fadeIn(delay: const Duration(milliseconds: 200)),
                        const SizedBox(height: 16),
                        _buildStatsRow(context, isDark),
                        const SizedBox(height: 20),
                        _buildActionsGrid(context, isDark),
                        const SizedBox(height: 12),
                        _buildClassesList(context, isDark),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, bool isDark) {
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryColor = isDark ? Colors.white24 : Colors.black26;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    ),
                    child: user.avatarIndex != null
                        ? SpriteAvatar(index: user.avatarIndex!, size: 40)
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Colors.blueAccent.withValues(alpha: 0.1),
                            child: Icon(Icons.person_rounded,
                                color: isDark ? Colors.white38 : Colors.black26,
                                size: 20),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.translate('hello_upper'),
                      style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(
                    user.name,
                    style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn().slideX(begin: -0.1),
          _buildNotificationIcon(context, isDark)
              .animate()
              .fadeIn()
              .slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        ),
        child: Stack(
          children: [
            Icon(Icons.notifications_none_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 24),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.redAccent, blurRadius: 4)
                      ])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark) {
    final loc = AppLocalizations.of(context)!;
    final studentCount = _isLoading
        ? '--'
        : (_stats['totalStudents'] ?? _stats['students'] ?? '--').toString();
    final absentCount = _isLoading
        ? '--'
        : (_stats['absentToday'] ?? _stats['absent'] ?? '--').toString();
    final pendingCount = _isLoading
        ? '--'
        : (_stats['pendingCorrections'] ??
                _stats['pendingAssignments'] ??
                '--')
            .toString();
    final homeworkCount = _isLoading
        ? '--'
        : (_stats['newHomework'] ?? _stats['assignments'] ?? '--').toString();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                        studentCount,
                        loc.translate('students'),
                        Icons.groups_rounded,
                        Colors.blueAccent,
                        isDark)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 300))
                    .slideY(begin: 0.1)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                        absentCount,
                        loc.translate('absent'),
                        Icons.person_off_rounded,
                        Colors.redAccent,
                        isDark)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 400))
                    .slideY(begin: 0.1)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                        pendingCount,
                        loc.translate('correction'),
                        Icons.pending_actions_rounded,
                        Colors.amberAccent,
                        isDark)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 500))
                    .slideY(begin: 0.1)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                        homeworkCount,
                        loc.translate('new_homework'),
                        Icons.assignment_rounded,
                        Colors.greenAccent,
                        isDark)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 600))
                    .slideY(begin: 0.1)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 20),
          Text(value,
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.translate('quick_actions'),
            style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0, // Adjusted for better square fit
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildActionIcon(
                    context,
                    Icons.how_to_reg_rounded,
                    AppLocalizations.of(context)!.translate('roll_call'),
                    Colors.blueAccent,
                    const AttendanceScreen(),
                    isDark)
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400))
                .scale(begin: const Offset(0.8, 0.8)),
            _buildActionIcon(
                    context,
                    Icons.menu_book_rounded,
                    AppLocalizations.of(context)!.translate('report_cards'),
                    Colors.purpleAccent,
                    const GradeEntryScreen(),
                    isDark)
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 500))
                .scale(begin: const Offset(0.8, 0.8)),
            _buildActionIcon(
                    context,
                    Icons.psychology_rounded,
                    AppLocalizations.of(context)!.translate('behavior'),
                    Colors.amberAccent,
                    const TeacherBehaviorScreen(),
                    isDark)
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 600))
                .scale(begin: const Offset(0.8, 0.8)),
            _buildActionIcon(
                    context,
                    Icons.assignment_rounded,
                    AppLocalizations.of(context)!
                        .translate('devoirs_evaluations'),
                    Colors.orangeAccent,
                    const TeacherHomeworkScreen(),
                    isDark)
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 700))
                .scale(begin: const Offset(0.8, 0.8)),
            _buildActionIcon(
                    context,
                    Icons.assignment_turned_in_rounded,
                    AppLocalizations.of(context)!.translate('examens'),
                    Colors.redAccent,
                    const AddExamScreen(),
                    isDark)
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 750))
                .scale(begin: const Offset(0.8, 0.8)),
            _buildActionIcon(
                    context,
                    Icons.calendar_today_rounded,
                    AppLocalizations.of(context)!.translate('timetable'),
                    Colors.tealAccent,
                    const TeacherTimetableScreen(),
                    isDark)
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 800))
                .scale(begin: const Offset(0.8, 0.8)),
            _buildActionIcon(
                    context,
                    Icons.local_activity_rounded,
                    AppLocalizations.of(context)!.translate('activities'),
                    Colors.indigoAccent,
                    const AddActivityScreen(),
                    isDark)
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 900))
                .scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 300))
        .slideY(begin: 0.05);
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, String label,
      Color color, Widget? screen, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.white.withValues(alpha: 0.7),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList(BuildContext context, bool isDark) {
    final classes = _classes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.translate('active_classes'),
            style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        ...[
          if (classes.isNotEmpty)
            _buildClassItem(
                context,
                classes[0].name,
                '${classes[0].studentCount}${AppLocalizations.of(context)!.translate('students_count_suffix')}',
                0.85,
                Colors.blueAccent,
                isDark,
                classes[0]),
          if (classes.length > 1)
            _buildClassItem(
                context,
                classes[1].name,
                '${classes[1].studentCount}${AppLocalizations.of(context)!.translate('students_count_suffix')}',
                0.92,
                Colors.greenAccent,
                isDark,
                classes[1]),
        ],
      ],
    );
  }

  Widget _buildClassItem(BuildContext context, String name, String count,
      double progress, Color color, bool isDark, ClassModel? classModel) {
    return GestureDetector(
      onTap: () {
        if (classModel != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StudentListScreen(classModel: classModel)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(28),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.school_rounded, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  Text(count.toUpperCase(),
                      style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline_rounded,
                  color: color, size: 22),
              onPressed: () {
                if (classModel != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        name: classModel.name,
                        avatarUrl:
                            'https://img.icons8.com/clouds/150/000000/groups.png',
                        classModel: classModel,
                      ),
                    ),
                  );
                }
              },
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : Colors.black26, size: 22),
          ],
        ),
      ),
    );
  }
}
