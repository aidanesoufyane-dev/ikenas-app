import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import './attendance_history_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final ClassModel? initialClass;
  const AttendanceScreen({super.key, this.initialClass});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  // Classes the teacher is assigned to (from API)
  List<ClassModel> _myClasses = [];
  ClassModel? _selectedClass;

  // Students for the currently selected class
  List<StudentModel> _currentStudents = [];
  bool _isLoadingStudents = false;

  // Subjects the teacher teaches (from API)
  List<Map<String, dynamic>> _mySubjects = [];
  Map<String, dynamic>? _selectedSubjectData;

  // student-id → status map
  final Map<String, String> _studentStatus = {};

  bool _isLoading = true;
  bool _isSaving = false;
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
      final results = await Future.wait([
        ApiService.instance.getMyClasses(),
        ApiService.instance.getMySubjects(),
      ]);

      final classes = results[0] as List<ClassModel>;
      final subjects = results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        _myClasses = classes;
        _mySubjects = subjects;
        // Pre-select initialClass if provided, otherwise first in list
        if (widget.initialClass != null) {
          _selectedClass = classes.firstWhere(
            (c) => c.id == widget.initialClass!.id,
            orElse: () => classes.isNotEmpty ? classes.first : widget.initialClass!,
          );
        } else if (classes.isNotEmpty) {
          _selectedClass = classes.first;
        }
        _isLoading = false;
      });
      await _loadStudentsForClass();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadStudentsForClass() async {
    if (_selectedClass == null) return;
    setState(() => _isLoadingStudents = true);
    try {
      final students = await ApiService.instance.getStudentsByClass(_selectedClass!.id);
      if (!mounted) return;
      setState(() {
        _currentStudents = students;
        _isLoadingStudents = false;
      });
      _initStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStudents = false);
      // Optional: show error toast here
    }
  }

  void _initStatus() {
    _studentStatus.clear();
    for (var student in _currentStudents) {
      _studentStatus[student.id] = 'present';
    }
    if (mounted) setState(() {});
  }

  int get _absentCount =>
      _studentStatus.values.where((v) => v == 'absent').length;
  int get _lateCount =>
      _studentStatus.values.where((v) => v == 'late').length;
  int get _presentCount =>
      _studentStatus.values.where((v) => v == 'present').length;
  int get _totalStudents => _studentStatus.length;

  Future<void> _onSave() async {
    if (_totalStudents == 0 || _selectedClass == null) return;

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Build list: everyone whose status is not 'present'
      // (the backend stores absences; present is default)
      final absences = _studentStatus.entries
          .where((e) => e.value != 'present')
          .map((e) => {'student': e.key, 'status': e.value})
          .toList();

      await ApiService.instance.bulkMarkAttendance(
        date: dateStr,
        classeId: _selectedClass!.id,
        subjectId: _selectedSubjectData?['id']?.toString() ??
            _selectedSubjectData?['_id']?.toString() ??
            '',
        absences: absences,
      );

      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${loc.translate('attendance_validated')} : $_presentCount ${loc.translate('present')}, $_absentCount ${loc.translate('absent_count')}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.translate('select_date'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: Colors.blueAccent,
            onPrimary: Colors.white,
            surface: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            onSurface: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
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
        title: Text(loc.translate('mark_attendance'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: primaryTextColor),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AttendanceHistoryScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : _error != null
                  ? _buildErrorState(context)
                  : Column(
                      children: [
                        const SizedBox(height: 10),

                        // Stats row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildMiniStat(context, loc.translate('present'),
                                  _presentCount.toString(), Colors.greenAccent),
                              const SizedBox(width: 8),
                              _buildMiniStat(context, loc.translate('delays'),
                                  _lateCount.toString(), Colors.orangeAccent),
                              const SizedBox(width: 8),
                              _buildMiniStat(
                                  context,
                                  loc.translate('absent_count'),
                                  _absentCount.toString(),
                                  Colors.redAccent),
                            ],
                          ),
                        ).animate().fadeIn().slideX(begin: 0.1),

                        // Selectors row
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Row 1: Date + Class
                              Row(
                                children: [
                                  // Date picker
                                  Expanded(
                                    flex: 3,
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context),
                                      child: _selectorBox(
                                        isDark,
                                        icon: Icons.calendar_today_outlined,
                                        label: DateFormat(
                                                'dd MMMM',
                                                loc.locale.languageCode)
                                            .format(_selectedDate),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Class dropdown
                                  Expanded(
                                    flex: 4,
                                    child: _myClasses.isEmpty
                                        ? _selectorBox(isDark,
                                            icon: Icons.class_outlined,
                                            label: loc.translate('no_classes_today'))
                                        : DropdownButtonHideUnderline(
                                            child: DropdownButton<ClassModel>(
                                              value: _selectedClass,
                                              isExpanded: true,
                                              dropdownColor: isDark
                                                  ? const Color(0xFF1E293B)
                                                  : Colors.white,
                                              style: TextStyle(
                                                  color: primaryTextColor,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13),
                                              items: _myClasses
                                                  .map((c) =>
                                                      DropdownMenuItem(
                                                          value: c,
                                                          child: Text(c.name)))
                                                  .toList(),
                                              onChanged: (cls) {
                                                if (cls != null && cls.id != _selectedClass?.id) {
                                                  setState(() {
                                                    _selectedClass = cls;
                                                    _currentStudents = [];
                                                  });
                                                  _loadStudentsForClass();
                                                }
                                              },
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Row 2: Subject dropdown
                              DropdownButtonHideUnderline(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.blueAccent
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.blueAccent
                                                .withValues(alpha: 0.1)),
                                  ),
                                  child: DropdownButton<Map<String, dynamic>>(
                                    value: _selectedSubjectData,
                                    isExpanded: true,
                                    dropdownColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    hint: Row(children: [
                                      const Icon(Icons.book_rounded,
                                          size: 16, color: Colors.blueAccent),
                                      const SizedBox(width: 8),
                                      Text(
                                          loc.translate('select_subject'),
                                          style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12)),
                                    ]),
                                    style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12),
                                    items: _mySubjects
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                  s['name']?.toString() ?? ''),
                                            ))
                                        .toList(),
                                    onChanged: (s) => setState(
                                        () => _selectedSubjectData = s),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Students list or empty state
                        Expanded(
                          child: _selectedClass == null || (_currentStudents.isEmpty && !_isLoadingStudents)
                              ? _buildEmptyState(context)
                              : _isLoadingStudents 
                                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                                  : ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      itemCount: _currentStudents.length,
                                      itemBuilder: (context, i) => _buildStudentRow(
                                          context,
                                          _currentStudents[i],
                                          i),
                                    ),
                        ),

                        _buildBottomAction(context),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _selectorBox(bool isDark,
      {required IconData icon, required String label}) {
    final color = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: color),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 16),
          Text(_error ?? 'Erreur de chargement',
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: const Text('Réessayer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded,
              size: 64,
              color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('no_classes_today'),
            style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w900,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(),
                style: TextStyle(
                    color: color.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentRow(
      BuildContext context, StudentModel student, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: primaryTextColor.withValues(alpha: 0.1)),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundImage:
                  NetworkImage('https://i.pravatar.cc/150?u=${student.id}'),
              backgroundColor: secondaryTextColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(student.name,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: primaryTextColor)),
          ),
          _buildStatusIcon(
              student.id, 'present', Icons.check_circle_rounded, Colors.greenAccent),
          const SizedBox(width: 8),
          _buildStatusIcon(
              student.id, 'late', Icons.access_time_filled_rounded, Colors.orangeAccent),
          const SizedBox(width: 8),
          _buildStatusIcon(
              student.id, 'absent', Icons.cancel_rounded, Colors.redAccent),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 30))
        .slideX(begin: 0.05);
  }

  Widget _buildStatusIcon(
      String studentId, String status, IconData icon, Color color) {
    final isSelected = _studentStatus[studentId] == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _studentStatus[studentId] = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : color.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.2))),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
              : [],
        ),
        child: Icon(icon,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white54 : color),
            size: 18),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.9);
    final loc = AppLocalizations.of(context)!;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          decoration: BoxDecoration(
            color: primaryBg,
            border: Border(
                top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white)),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                        color: Colors.white,
                        blurRadius: 20,
                        offset: const Offset(0, -5))
                  ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _totalStudents == 0
                        ? null
                        : () => setState(
                            () => _studentStatus.updateAll((k, v) => 'present')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: Colors.blueAccent.withValues(alpha: 0.2))),
                      backgroundColor:
                          Colors.blueAccent.withValues(alpha: 0.1),
                    ),
                    child: Text(loc.translate('mark_all_present'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        '$_absentCount ${loc.translate('absent_count').toLowerCase()}',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isSaving || _totalStudents == 0) ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.white : const Color(0xFF0F172A),
                    foregroundColor:
                        isDark ? const Color(0xFF0F172A) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                    shadowColor: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.2),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              strokeWidth: 3))
                      : Text(
                          loc.translate('validate_attendance').toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
