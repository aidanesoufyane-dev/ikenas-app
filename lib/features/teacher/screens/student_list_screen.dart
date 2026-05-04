import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/widgets/sprite_avatar.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/api_service.dart';
import 'student_detail_full_screen.dart';

class StudentListScreen extends StatefulWidget {
  final ClassModel classModel;
  const StudentListScreen({super.key, required this.classModel});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<StudentModel> _allStudents = [];
  List<StudentModel> _filteredStudents = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _selectedSort = 'az';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final students = await ApiService.instance.getStudentsByClass(widget.classModel.id);
      if (mounted) {
        setState(() {
          _allStudents = students;
          _isLoading = false;
        });
        _applyFilters('', _selectedSort);
      }
    } catch (e) {
      debugPrint('[StudentListScreen] Error fetching students: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Impossible de charger les élèves.';
        });
      }
    }
  }

  void _onSearch(String query) {
    _applyFilters(query, _selectedSort);
  }

  void _applyFilters(String query, String sort) {
    setState(() {
      _selectedSort = sort;
      var list = _allStudents.where((s) {
        return s.name.toLowerCase().contains(query.toLowerCase()) ||
            (s.massarCode?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();

      if (sort == 'az') {
        list.sort((a, b) => a.name.compareTo(b.name));
      } else if (sort == 'avg_up') {
        list.sort((a, b) => b.average.compareTo(a.average));
      } else if (sort == 'avg_down') {
        list.sort((a, b) => a.average.compareTo(b.average));
      }

      _filteredStudents = list;
    });
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
        title: Column(
          children: [
            Text(AppLocalizations.of(context)!.translate('classes'),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                    fontSize: 16)),
            Text(
                '${widget.classModel.studentCount} ${AppLocalizations.of(context)!.translate('students')}',
                style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ],
        ),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!
                          .translate('search_student'),
                      hintStyle: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.normal),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: secondaryTextColor, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: secondaryTextColor, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // Filters
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip(
                        context,
                        AppLocalizations.of(context)!.translate('sort_az'),
                        _selectedSort == 'az',
                        onTap: () =>
                            _applyFilters(_searchController.text, 'az')),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                        context,
                        AppLocalizations.of(context)!.translate('sort_avg_up'),
                        _selectedSort == 'avg_up',
                        onTap: () =>
                            _applyFilters(_searchController.text, 'avg_up')),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                        context,
                        AppLocalizations.of(context)!
                            .translate('sort_avg_down'),
                        _selectedSort == 'avg_down',
                        onTap: () =>
                            _applyFilters(_searchController.text, 'avg_down')),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Student List
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(_error!, style: TextStyle(color: Colors.redAccent)),
                  ),
                )
              else if (_filteredStudents.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)?.translate('no_students') ?? 'Aucun élève trouvé.',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(context, student, index);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected,
      {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? Colors.white : const Color(0xFF0F172A);
    final activeText = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.7);
    final inactiveText = isDark ? Colors.white38 : Colors.black26;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white)),
          boxShadow: [
            if (isSelected && !isDark)
              BoxShadow(
                  color: activeBg.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeText : inactiveText,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(
      BuildContext context, StudentModel student, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white24 : Colors.black26;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
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
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StudentDetailFullScreen(student: student)),
        ),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: primaryTextColor.withValues(alpha: 0.1))),
          child: SpriteAvatar(gender: student.gender, size: 40),
        ),
        title: Text(student.name,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: primaryTextColor)),
        subtitle: Text(student.massarCode?.toUpperCase() ?? '---',
            style: TextStyle(
                color: secondaryTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  student.average.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: student.average >= 14
                        ? Colors.greenAccent
                        : student.average >= 10
                            ? Colors.orangeAccent
                            : Colors.redAccent,
                  ),
                ),
                Text(AppLocalizations.of(context)!.translate('average_label'),
                    style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: secondaryTextColor),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (index * 50)))
        .slideX(begin: 0.05);
  }
}
