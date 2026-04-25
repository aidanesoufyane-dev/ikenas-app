import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';

class AddHomeworkScreen extends StatefulWidget {
  const AddHomeworkScreen({super.key});

  @override
  State<AddHomeworkScreen> createState() => _AddHomeworkScreenState();
}

class _AddHomeworkScreenState extends State<AddHomeworkScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<ClassModel> _myClasses = [];
  ClassModel? _selectedClass;
  
  List<Map<String, dynamic>> _mySubjects = [];
  Map<String, dynamic>? _selectedSubjectData;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _attachedFilePath;
  String? _attachedFileName;
  bool _isPublishing = false;
  bool _isLoading = true;
  String? _error;

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
          icon: Icon(Icons.close_rounded, color: primaryTextColor, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.translate('new_homework'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isPublishing || _isLoading ? null : _publish,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isPublishing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryTextColor))
                  : Text(AppLocalizations.of(context)!.translate('publish'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1)),
            ),
          ),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),

                // Subject & Class row
                Row(
                  children: [
                    Expanded(
                      child: _buildSubjectDropdown(context, AppLocalizations.of(context)!.translate('subject_label')),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildClassDropdown(context, AppLocalizations.of(context)!.translate('class_label')),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                    AppLocalizations.of(context)!
                        .translate('homework_title_label'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!
                        .translate('homework_title_hint'),
                    hintStyle:
                        TextStyle(color: secondaryTextColor, fontSize: 14),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.blueAccent)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                ),

                const SizedBox(height: 32),

                // Description
                Text(
                    AppLocalizations.of(context)!
                        .translate('instructions_desc'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!
                        .translate('instructions_hint'),
                    hintStyle:
                        TextStyle(color: secondaryTextColor, fontSize: 14),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.blueAccent)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                  ),
                ),

                const SizedBox(height: 32),

                // Deadline
                Text(AppLocalizations.of(context)!.translate('submission_date'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  blurRadius: 10)
                            ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 20, color: Colors.blueAccent),
                        const SizedBox(width: 16),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: primaryTextColor),
                        ),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: secondaryTextColor),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Attachments
                Text(AppLocalizations.of(context)!.translate('attachments'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.01)
                          : Colors.white.withValues(alpha: 0.5),
                      border: Border.all(
                          color: _attachedFileName != null
                              ? Colors.blueAccent
                              : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.1)),
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _attachedFileName != null
                              ? Icons.check_circle_rounded
                              : Icons.cloud_upload_outlined,
                          color: _attachedFileName != null
                              ? Colors.blueAccent
                              : secondaryTextColor.withValues(alpha: 0.5),
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _attachedFileName ??
                              AppLocalizations.of(context)!.translate('upload_doc_hint'),
                          style: TextStyle(
                              color: _attachedFileName != null
                                  ? Colors.blueAccent
                                  : secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_attachedFileName != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _attachedFilePath = null;
                              _attachedFileName = null;
                            }),
                            child: Text('Supprimer',
                                style: TextStyle(
                                    color: Colors.redAccent.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
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

  Widget _buildSubjectDropdown(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: secondaryTextColor,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedSubjectData,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: secondaryTextColor),
              style: TextStyle(fontSize: 14, color: primaryTextColor, fontWeight: FontWeight.w900),
              items: _mySubjects.map((s) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: s,
                  child: Text(s['name']?.toString() ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSubjectData = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassDropdown(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: secondaryTextColor,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          ),
          child: DropdownButtonHideUnderline(
            child: _myClasses.isEmpty
                ? DropdownButton<String>(
                    value: null,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: secondaryTextColor),
                    items: const [],
                    onChanged: null,
                    hint: Text(AppLocalizations.of(context)!.translate('no_classes_today'),
                      style: TextStyle(fontSize: 14, color: secondaryTextColor),
                    ),
                  )
                : DropdownButton<ClassModel>(
                    value: _selectedClass,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: secondaryTextColor),
                    style: TextStyle(fontSize: 14, color: primaryTextColor, fontWeight: FontWeight.w900),
                    items: _myClasses.map((ClassModel value) {
                      return DropdownMenuItem<ClassModel>(
                        value: value,
                        child: Text(value.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedClass = val);
                      }
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    setState(() {
      _attachedFilePath = file.path;
      _attachedFileName = file.name;
    });
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _publish() async {
    if (_titleController.text.isEmpty || _selectedClass == null || _selectedSubjectData == null) return;
    
    setState(() => _isPublishing = true);
    
    try {
      await ApiService.instance.addHomework(
        title: _titleController.text,
        description: _descriptionController.text,
        classId: _selectedClass!.id,
        subjectId: _selectedSubjectData!['_id']?.toString() ?? _selectedSubjectData!['id']?.toString() ?? '',
        deadline: _selectedDate,
        filePath: _attachedFilePath,
        fileName: _attachedFileName,
      );
      
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('homework_published'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}
