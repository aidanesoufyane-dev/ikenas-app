import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import './grades_history_screen.dart';

class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  // --- API data ---
  List<ClassModel> _classes = [];
  List<Map<String, dynamic>> _subjects = [];

  ClassModel? _selectedClass;
  Map<String, dynamic>? _selectedSubjectData;

  List<StudentModel> _currentStudents = [];

  // --- Local selection ---
  final List<String> _terms = ['term_1', 'term_2'];
  String _selectedTerm = 'term_1';

  final List<String> _assignments = [
    'assign_1',
    'assign_2',
    'assign_3',
    'assign_exam'
  ];
  String _selectedAssignment = 'assign_1';

  // --- Loading state ---
  bool _isLoading = true;
  String? _error;

  // --- Grade controllers: studentId → componentName → TextEditingController ---
  final Map<String, Map<String, TextEditingController>> _gradeControllers = {};

  // Subjects with multiple components — exact names as required
  static const Map<String, List<String>> _componentSubjects = {
    'Arabe': [
      'القراءة',
      'الإملاء',
      'الإنشاء',
      'التركيب',
      'الصرف والتحويل',
      'فهم المقروء',
    ],
    'Français': [
      'Production écrite',
      'Lexique',
      'Grammaire',
      'Conjugaison',
      'Orthographe/Dictée',
      'Lecture',
      'Communication',
      'Poésie',
    ],
    'Histoire-Géographie': [
      'Histoire',
      'Géographie',
      'Éducation civique',
    ],
  };

  static const String _singleScoreLabel = 'الفرض';

  List<String>? _resolveComponents(String subjectName) {
    if (_componentSubjects.containsKey(subjectName)) {
      return _componentSubjects[subjectName]!;
    }
    for (final key in _componentSubjects.keys) {
      if (subjectName.toLowerCase().contains(key.toLowerCase()) ||
          key.toLowerCase().contains(subjectName.toLowerCase())) {
        return _componentSubjects[key]!;
      }
    }
    return null; // single-score subject
  }

  bool get _isSingleScore {
    final name = _selectedSubjectData?['name']?.toString() ?? '';
    return _resolveComponents(name) == null;
  }

  List<String> get _currentComponents {
    final name = _selectedSubjectData?['name']?.toString() ?? '';
    return _resolveComponents(name) ?? [_singleScoreLabel];
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    for (final studentMap in _gradeControllers.values) {
      for (final ctrl in studentMap.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
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
        _classes = classes;
        _subjects = subjects;
        _selectedClass = classes.isNotEmpty ? classes.first : null;
        _selectedSubjectData = subjects.isNotEmpty ? subjects.first : null;
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
    try {
      final students =
          await ApiService.instance.getStudentsByClass(_selectedClass!.id);
      if (!mounted) return;
      setState(() {
        _currentStudents = students;
      });
      _rebuildGradeControllers();
    } catch (e) {
      if (!mounted) return;
      debugPrint('[GradeEntry] _loadStudentsForClass error: $e');
    }
  }

  void _rebuildGradeControllers() {
    // Dispose old controllers
    for (final studentMap in _gradeControllers.values) {
      for (final ctrl in studentMap.values) {
        ctrl.dispose();
      }
    }
    _gradeControllers.clear();

    for (final student in _currentStudents) {
      _gradeControllers[student.id] = {};
      for (final component in _currentComponents) {
        _gradeControllers[student.id]![component] = TextEditingController();
      }
    }
  }

  Future<void> _saveGrades() async {
    if (_selectedClass == null || _selectedSubjectData == null) return;

    final components = _currentComponents;

    // Build entries — clamp scores to [0, 10]
    final entries = _currentStudents.map((student) {
      final scores = <Map<String, dynamic>>[];
      for (final component in components) {
        final raw =
            _gradeControllers[student.id]?[component]?.text.trim() ?? '';
        final score = double.tryParse(raw);
        if (score != null) {
          scores.add({'component': component, 'score': score.clamp(0.0, 10.0)});
        }
      }
      return {'student': student.id, 'scores': scores};
    }).toList();

    String devTitle = 'devoir1';
    if (_selectedAssignment == 'assign_2') devTitle = 'devoir2';
    if (_selectedAssignment == 'assign_3') devTitle = 'devoir3';
    if (_selectedAssignment == 'assign_exam') devTitle = 'devoir4';

    final subjectId = _selectedSubjectData!['id']?.toString() ??
        _selectedSubjectData!['_id']?.toString() ?? '';

    final payload = {
      'sheet': {
        'classe': _selectedClass!.id,
        'subject': subjectId,
        'semester': _selectedTerm == 'term_1' ? 'S1' : 'S2',
        'type': 'autre',
        'title': devTitle,
        'maxScore': 10,
        'components': _isSingleScore
            ? [{'key': 'score', 'name': _singleScoreLabel}]
            : components.map((c) => {'key': c, 'name': c}).toList(),
      },
      'results': entries,
    };

    await ApiService.instance.saveNotes(payload);
  }

  void _showGradesTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final components = _currentComponents;

    _rebuildGradeControllers();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Grades Table',
      transitionDuration: 400.ms,
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(builder: (dialogContext, setStateModal) {
          bool isSaving = false;

          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.8,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 10))
                ],
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white,
                    width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .translate('grade_entry_title'),
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: primaryTextColor),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded,
                                color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),

                    // Component chips — only for multi-component subjects
                    if (!_isSingleScore)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Composantes:',
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                          ...components.map((c) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(c,
                                    style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                              )),
                        ],
                      ),
                    ),

                    Container(
                        height: 1,
                        color: isDark ? Colors.white10 : Colors.white),
                    // Data table
                    Expanded(
                      child: _currentStudents.isEmpty
                          ? Center(
                              child: Text(
                                  'Aucun élève dans cette classe',
                                  style: TextStyle(
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w900)),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: isDark
                                        ? Colors.white10
                                        : Colors.white,
                                  ),
                                  child: DataTable(
                                    headingRowColor:
                                        WidgetStateProperty.all(isDark
                                            ? Colors.white.withValues(alpha: 0.02)
                                            : Colors.white
                                                .withValues(alpha: 0.5)),
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 60,
                                    columnSpacing: 30,
                                    border: TableBorder.all(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.white,
                                        width: 1),
                                    columns: [
                                      DataColumn(
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .translate(
                                                      'table_student_header'),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: primaryTextColor,
                                                  fontSize: 12))),
                                      DataColumn(
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .translate(
                                                      'table_grade_header'),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: secondaryTextColor,
                                                  fontSize: 12))),
                                      ...components.map((c) => DataColumn(
                                          label: Text(c,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryTextColor,
                                                  fontSize: 11)))),
                                    ],
                                    rows: _currentStudents.map((student) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(student.name,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryTextColor,
                                                  fontSize: 12))),
                                          // Live average for component subjects
                                          DataCell(Builder(builder: (_) {
                                            if (_isSingleScore) {
                                              return Text('—',
                                                  style: TextStyle(
                                                      color: secondaryTextColor,
                                                      fontWeight: FontWeight.w900));
                                            }
                                            double sum = 0; int count = 0;
                                            for (final c in components) {
                                              final v = double.tryParse(
                                                  _gradeControllers[student.id]?[c]?.text.trim() ?? '');
                                              if (v != null) { sum += v; count++; }
                                            }
                                            if (count == 0) {
                                              return Text('—',
                                                  style: TextStyle(
                                                      color: secondaryTextColor,
                                                      fontWeight: FontWeight.w900));
                                            }
                                            return Text(
                                              (sum / count).toStringAsFixed(2),
                                              style: const TextStyle(
                                                  color: Colors.blueAccent,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13),
                                            );
                                          })),
                                          ...components.map((c) {
                                            final ctrl = _gradeControllers[student.id]?[c];
                                            return DataCell(
                                                Container(
                                                  width: 60,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.white
                                                            .withValues(
                                                                alpha: 0.03)
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: isDark
                                                            ? Colors.white
                                                                .withValues(
                                                                    alpha: 0.1)
                                                            : Colors.black
                                                                .withValues(
                                                                    alpha: 0.1)),
                                                  ),
                                                  child: TextField(
                                                    controller: ctrl,
                                                    textAlign: TextAlign.center,
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(decimal: true),
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                                    ],
                                                    onChanged: (val) {
                                                      final v = double.tryParse(val);
                                                      if (v != null && v > 10) {
                                                        ctrl?.text = '10';
                                                        ctrl?.selection = const TextSelection.collapsed(offset: 2);
                                                      }
                                                      setStateModal(() {});
                                                    },
                                                    style: TextStyle(
                                                        color: primaryTextColor,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 13),
                                                    decoration: InputDecoration(
                                                      border: InputBorder.none,
                                                      hintText: '—',
                                                      hintStyle: TextStyle(
                                                          color:
                                                              secondaryTextColor),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 4,
                                                              vertical: 12),
                                                    ),
                                                  ),
                                                ),
                                              );
                                          }),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Footer actions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                color:
                                    isDark ? Colors.white10 : Colors.white)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(alpha: 0.1))),
                            ),
                            child: Text(
                                AppLocalizations.of(context)!
                                    .translate('cancel_uppercase'),
                                style: TextStyle(
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12)),
                          ),
                          const SizedBox(width: 16),
                          StatefulBuilder(
                            builder: (ctx, setSaveState) =>
                                ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setSaveState(() => isSaving = true);
                                      try {
                                        await _saveGrades();
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              AppLocalizations.of(context)!
                                                  .translate(
                                                      'table_save_success'),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                          backgroundColor: Colors.blueAccent,
                                        ));
                                      } catch (e) {
                                        setSaveState(() => isSaving = false);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Erreur: ${e.toString()}'),
                                          backgroundColor: Colors.redAccent,
                                        ));
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                  AppLocalizations.of(context)!
                                      .translate('save_btn'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn()
              .scale(
                  begin: const Offset(0.9, 0.9), curve: Curves.easeOutExpo);
        });
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: anim1, curve: Curves.easeOutExpo)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
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
        title: Text(loc.translate('report_cards'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: primaryTextColor),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GradesHistoryScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent))
              : _error != null
                  ? _buildErrorState(context)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(loc.translate('report_cards'),
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  color: primaryTextColor,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(
                              loc.translate('grade_selection_subtitle'),
                              style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 40),

                          // Row 1: Class + Subject + Term
                          Row(
                            children: [
                              // Class dropdown (from API)
                              Expanded(
                                  child: _buildApiDropdown<ClassModel>(
                                items: _classes,
                                value: _selectedClass,
                                labelBuilder: (c) => c.name,
                                onChanged: (cls) {
                                  if (cls != null && cls.id != _selectedClass?.id) {
                                    setState(() {
                                      _selectedClass = cls;
                                      _currentStudents = [];
                                    });
                                    _loadStudentsForClass();
                                  }
                                },
                                isDark: isDark,
                              )),
                              const SizedBox(width: 16),
                              // Subject dropdown (from API)
                              Expanded(
                                  child: _buildApiDropdown<Map<String, dynamic>>(
                                items: _subjects,
                                value: _selectedSubjectData,
                                labelBuilder: (s) =>
                                    s['name']?.toString() ?? '',
                                onChanged: (s) {
                                  setState(() => _selectedSubjectData = s);
                                  _rebuildGradeControllers();
                                },
                                isDark: isDark,
                              )),
                              const SizedBox(width: 16),
                              // Term dropdown (local)
                              Expanded(
                                  child: _buildLocalDropdown(
                                items: _terms,
                                value: _selectedTerm,
                                onChanged: (v) =>
                                    setState(() => _selectedTerm = v!),
                                isDark: isDark,
                                loc: loc,
                              )),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Row 2: Assignment + Open Table
                          Row(
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: _buildLocalDropdown(
                                    items: _assignments,
                                    value: _selectedAssignment,
                                    onChanged: (v) => setState(
                                        () => _selectedAssignment = v!),
                                    isDark: isDark,
                                    loc: loc,
                                  )),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton.icon(
                                  onPressed: (_selectedClass == null ||
                                          _selectedSubjectData == null)
                                      ? null
                                      : _showGradesTable,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: Text(
                                      loc.translate('table_open_btn'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13)),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),
                          Center(
                            child: Icon(Icons.my_library_books_rounded,
                                size: 120,
                                color: isDark ? Colors.white10 : Colors.white),
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
        ),
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

  /// Generic dropdown for objects from the API.
  Widget _buildApiDropdown<T>({
    required List<T> items,
    required T? value,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
    required bool isDark,
  }) {
    final T? safeValue = (value != null && items.contains(value)) ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          hint: Text(items.isEmpty ? '—' : '...',
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w900,
                  fontSize: 13)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white38 : Colors.black38),
          style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 13),
          items: items
              .map((i) => DropdownMenuItem<T>(
                  value: i, child: Text(labelBuilder(i))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Dropdown for local string items (terms, assignments) using i18n keys.
  Widget _buildLocalDropdown({
    required List<String> items,
    required String value,
    required void Function(String?) onChanged,
    required bool isDark,
    required AppLocalizations loc,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white38 : Colors.black38),
          style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 13),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i, child: Text(loc.translate(i))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
