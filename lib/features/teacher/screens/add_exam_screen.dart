import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/deep_space_background.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<ClassModel> _myClasses = [];
  ClassModel? _selectedClass;

  List<Map<String, dynamic>> _mySubjects = [];
  Map<String, dynamic>? _selectedSubjectData;

  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2 > 23 ? 23 : TimeOfDay.now().hour + 2);

  bool _isLoading = true;
  bool _isPublishing = false;
  String? _error;

  final List<String> _evaluationTypes = [
    'examen',
    'contrôle',
    'devoir_surveillé',
    'rattrapage'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        ApiService.instance.getMyClasses(),
        ApiService.instance.getMySubjects(),
      ]);

      if (!mounted) return;

      final classes = results[0] as List<ClassModel>;
      final subjects = results[1] as List<Map<String, dynamic>>;

      setState(() {
        _myClasses = classes;
        if (_myClasses.isNotEmpty) _selectedClass = _myClasses.first;

        _mySubjects = subjects;
        if (_mySubjects.isNotEmpty) _selectedSubjectData = _mySubjects.first;

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
    );
    if (picked != null) setState(() => _selectedEndTime = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('title_required'))),
      );
      return;
    }
    if (_selectedClass == null || _selectedSubjectData == null || _selectedType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('fill_all_fields'))),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isPublishing = true);

      try {
        final startFormat = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
        final endFormat = '${_selectedEndTime.hour.toString().padLeft(2, '0')}:${_selectedEndTime.minute.toString().padLeft(2, '0')}';

        await ApiService.instance.addExam(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          classId: _selectedClass!.id,
          subjectId: _selectedSubjectData!['_id'],
          date: _selectedDate,
          startTime: startFormat,
          endTime: endFormat,
          type: _selectedType!,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('announcement_published')),
            backgroundColor: Colors.greenAccent,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const DeepSpaceBackground(
          showOrbs: true,
          child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: DeepSpaceBackground(
          showOrbs: true,
          child: Center(
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      );
    }

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
        title: Text(
          loc.translate('new_exam') != 'new_exam' ? loc.translate('new_exam') : loc.translate('examens'),
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: primaryTextColor,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildSectionHeader(loc.translate('homework_title_label'), isDark),
                  _buildTextField(
                    controller: _titleController,
                    hint: loc.translate('homework_title_label'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(loc.translate('description_label'), isDark),
                  _buildTextField(
                    controller: _descriptionController,
                    hint: loc.translate('description_hint'),
                    isDark: isDark,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(loc.translate('class_label'), isDark),
                  _buildDropdown<ClassModel>(
                    value: _selectedClass,
                    items: _myClasses.map((c) => DropdownMenuItem<ClassModel>(
                      value: c,
                      child: Text(c.name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14)),
                    )).toList(),
                    hint: loc.translate('select_class_hint'),
                    onChanged: (val) => setState(() => _selectedClass = val),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(loc.translate('subject_label'), isDark),
                  _buildDropdown<Map<String, dynamic>>(
                    value: _selectedSubjectData,
                    items: _mySubjects.map((s) {
                      final title = s['name']?.toString() ?? 'Inconnu';
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: s,
                        child: Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14)),
                      );
                    }).toList(),
                    hint: loc.translate('select_subject_hint'),
                    onChanged: (val) => setState(() => _selectedSubjectData = val),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                      loc.translate('evaluation_type_label'), isDark),
                  _buildDropdown<String>(
                    value: _selectedType,
                    items: _evaluationTypes.map((t) => DropdownMenuItem<String>(
                      value: t,
                      child: Text(t, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14)),
                    )).toList(),
                    hint: loc.translate('evaluation_type_label'),
                    onChanged: (val) => setState(() => _selectedType = val),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(loc.translate('date_label'), isDark),
                  _buildPickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('dd/MM/yyyy')
                        .format(_selectedDate),
                    onTap: _pickDate,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                                loc.translate('startTime'), isDark),
                            _buildPickerTile(
                              icon: Icons.access_time_rounded,
                              label: _selectedTime.format(context),
                              onTap: _pickTime,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                                loc.translate('endTime'), isDark),
                            _buildPickerTile(
                              icon: Icons.access_time_rounded,
                              label: _selectedEndTime.format(context),
                              onTap: _pickEndTime,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPublishing ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: _isPublishing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              loc.translate('validate_upper'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String hint,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white38 : Colors.black38),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          items: items,
          onChanged: onChanged,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }
}
