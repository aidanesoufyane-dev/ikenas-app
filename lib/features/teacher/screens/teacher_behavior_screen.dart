import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import './behavior_history_screen.dart';

class TeacherBehaviorScreen extends StatefulWidget {
  const TeacherBehaviorScreen({super.key});

  @override
  State<TeacherBehaviorScreen> createState() => _TeacherBehaviorScreenState();
}

class _TeacherBehaviorScreenState extends State<TeacherBehaviorScreen> {
  // --- Data layer ---
  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  List<StudentModel> _students = [];
  bool _isLoading = true;
  bool _isLoadingStudents = false;
  String? _error;

  StudentModel? _selectedStudent;
  bool _isPositive = true;
  double _points = 5.0; // Changed to double to allow 0.25 increments
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final classes = await ApiService.instance.getMyClasses();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStudentsForClass(String classId) async {
    setState(() {
      _isLoadingStudents = true;
      _students = [];
      _selectedStudent = null;
    });
    try {
      final students = await ApiService.instance.getStudentsByClass(classId);
      if (!mounted) return;
      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  void _saveBehavior() {
    if (_selectedStudent == null || _noteController.text.isEmpty) return;

    setState(() => _isSaving = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${AppLocalizations.of(context)!.translate('behavior_recorded')}${_selectedStudent!.name}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isPositive ? Colors.greenAccent : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;

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
        title: Text(AppLocalizations.of(context)!.translate('behavior_title'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: primaryTextColor),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BehaviorHistoryScreen())),
          ),
          const SizedBox(width: 8),
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
                // Form wrapper
                if (_isLoading)
                  const Center(
                      child:
                          CircularProgressIndicator(color: Colors.blueAccent))
                else if (_error != null)
                  Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)))
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class Selection
                      Text(AppLocalizations.of(context)!.translate('classe'),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      blurRadius: 10)
                                ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ClassModel>(
                            value: _selectedClass,
                            isExpanded: true,
                            dropdownColor:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: secondaryTextColor),
                            hint: Text(
                                AppLocalizations.of(context)!
                                    .translate('select_class'),
                                style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            items: _classes
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: primaryTextColor,
                                              fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null && v.id != _selectedClass?.id) {
                                setState(() => _selectedClass = v);
                                _fetchStudentsForClass(v.id);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Student Selection
                      Text(
                          AppLocalizations.of(context)!
                              .translate('concerned_student'),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      blurRadius: 10)
                                ],
                        ),
                        child: _isLoadingStudents
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))))
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<StudentModel>(
                                  value: _selectedStudent,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                                      color: secondaryTextColor),
                                  hint: Text(
                                      AppLocalizations.of(context)!
                                          .translate('choose_student'),
                                      style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  items: _students
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.name,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    color: primaryTextColor,
                                                    fontSize: 14)),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedStudent = v),
                                ),
                              ),
                      ),
                      const SizedBox(height: 40),

                      const SizedBox(height: 40),

                      // Behavior Type Toggle
                      Text(
                          AppLocalizations.of(context)!
                              .translate('evaluation_type'),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildTypeButton(
                              context,
                              true,
                              AppLocalizations.of(context)!
                                  .translate('positive_uppercase'),
                              Icons.emoji_events_rounded,
                              Colors.greenAccent),
                          const SizedBox(width: 16),
                          _buildTypeButton(
                              context,
                              false,
                              AppLocalizations.of(context)!
                                  .translate('negative_uppercase'),
                              Icons.warning_amber_rounded,
                              Colors.redAccent),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Points Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${AppLocalizations.of(context)!.translate('intensity')} : ${_isPositive ? "+" : "-"}${_points.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: _isPositive
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1)),
                          Text(AppLocalizations.of(context)!.translate('pts'),
                              style: TextStyle(
                                  color: isDark ? Colors.white10 : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _isPositive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          inactiveTrackColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          thumbColor: isDark
                              ? Colors.white
                              : (_isPositive
                                  ? Colors.greenAccent
                                  : Colors.redAccent),
                          overlayColor: (_isPositive
                                  ? Colors.greenAccent
                                  : Colors.redAccent)
                              .withValues(alpha: 0.1),
                        ),
                        child: Slider(
                          value: _points,
                          min: 0.25,
                          max: 20.0,
                          divisions: 79,
                          onChanged: (val) => setState(() => _points = val),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Note Textfield
                      Text(
                          AppLocalizations.of(context)!
                              .translate('observations'),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!
                              .translate('behavior_hint'),
                          hintStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide:
                                  const BorderSide(color: Colors.blueAccent)),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isSaving ||
                                  _selectedStudent == null ||
                                  _noteController.text.isEmpty)
                              ? null
                              : _saveBehavior,
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
                                  AppLocalizations.of(context)!
                                      .translate('validate_evaluation'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 1.5)),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 400))
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      const SizedBox(height: 48),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(BuildContext context, bool positive, String label,
      IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _isPositive == positive;
    final unselectedColor = isDark ? Colors.white12 : Colors.white;
    final unselectedTextColor = isDark ? Colors.white24 : Colors.black26;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPositive = positive),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : unselectedColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1.5),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.1), blurRadius: 20)
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? color : unselectedTextColor, size: 36),
              const SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                    color: isSelected ? color : unselectedTextColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02)),
    );
  }
}
