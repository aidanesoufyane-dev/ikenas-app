import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/deep_space_background.dart';
import '../../../core/widgets/sprite_avatar.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const AttendanceDetailScreen({super.key, required this.sessionData});

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  late bool isEditable;
  final Map<String, String> _tempStatus = {}; // studentId -> status

  @override
  void initState() {
    super.initState();
    _calculateEditableStatus();
    _initTempStatus();
  }

  void _calculateEditableStatus() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime sessionDate = widget.sessionData['datetime'] as DateTime;

    final bool isRecent = sessionDate.isAtSameMomentAs(today) ||
        sessionDate.isAtSameMomentAs(yesterday);
    final bool isValidated = widget.sessionData['isValidatedByAdmin'] ?? false;

    isEditable = isRecent && !isValidated;
  }

  void _initTempStatus() {
    _tempStatus.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = isDark ? Colors.white : const Color(0xFF0F172A);
    final students = <dynamic>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: pt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.sessionData['subject'],
              style: TextStyle(
                  color: pt, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              widget.sessionData['date'],
              style: TextStyle(
                  color: pt.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (isEditable)
            IconButton(
              icon: Icon(Icons.save_rounded, color: Colors.blueAccent),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Modifications enregistrées !',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                );
                Navigator.pop(context);
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildValidationStatus(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentCard(student, index, isDark, pt);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationStatus() {
    final isValidated = widget.sessionData['isValidatedByAdmin'] ?? false;
    final color = isValidated ? Colors.blueAccent : Colors.orangeAccent;
    final text = isValidated
        ? 'Validé par l\'administration'
        : 'En attente de validation';
    final icon = isValidated
        ? Icons.verified_user_rounded
        : Icons.pending_actions_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(dynamic student, int index, bool isDark, Color pt) {
    final status = _tempStatus[student.id];

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
      ),
      child: Row(
        children: [
          SpriteAvatar(gender: student.gender as String?, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Text(student.name,
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 14, color: pt)),
          ),
          if (isEditable)
            Row(
              children: [
                _buildEditableStatusIcon(student.id, 'present',
                    Icons.check_circle_rounded, Colors.greenAccent),
                const SizedBox(width: 8),
                _buildEditableStatusIcon(student.id, 'late',
                    Icons.access_time_filled_rounded, Colors.orangeAccent),
                const SizedBox(width: 8),
                _buildEditableStatusIcon(student.id, 'absent',
                    Icons.cancel_rounded, Colors.redAccent),
              ],
            )
          else
            _buildReadOnlyStatus(status),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 30))
        .slideX(begin: 0.05);
  }

  Widget _buildEditableStatusIcon(
      String studentId, String status, IconData icon, Color color) {
    bool isSelected = _tempStatus[studentId] == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _tempStatus[studentId] = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : color.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.1))),
        ),
        child: Icon(icon,
            color:
                isSelected ? Colors.white : (isDark ? Colors.white54 : color),
            size: 16),
      ),
    );
  }

  Widget _buildReadOnlyStatus(String? status) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'present':
        icon = Icons.check_circle_rounded;
        color = Colors.greenAccent;
        label = 'Présent';
        break;
      case 'late':
        icon = Icons.access_time_filled_rounded;
        color = Colors.orangeAccent;
        label = 'Retard';
        break;
      default:
        icon = Icons.cancel_rounded;
        color = Colors.redAccent;
        label = 'Absent';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontWeight: FontWeight.w900,
                fontSize: 11)),
      ],
    );
  }
}
