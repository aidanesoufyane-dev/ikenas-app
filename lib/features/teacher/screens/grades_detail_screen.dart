import 'package:flutter/material.dart';

import '../../../core/widgets/deep_space_background.dart';

class GradesDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const GradesDetailScreen({super.key, required this.sessionData});

  @override
  State<GradesDetailScreen> createState() => _GradesDetailScreenState();
}

class _GradesDetailScreenState extends State<GradesDetailScreen> {
  late bool isReadOnly;
  late List<String> components;

  final Map<String, List<String>> _subjectComponents = {
    // These will eventually be fetched from the API based on the curriculum.
    // For now, removing the hardcoded demo strings.
  };

  @override
  void initState() {
    super.initState();
    isReadOnly = widget.sessionData['status'] == 'Validé';
    components =
        _subjectComponents[widget.sessionData['subject']] ?? ['Général'];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = isDark ? Colors.white : const Color(0xFF0F172A);
    final st = isDark ? Colors.white38 : Colors.black26;
    final students = widget.sessionData['students'] as List<dynamic>? ?? [];

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
              '${widget.sessionData['subject']} - ${widget.sessionData['assignment']}',
              style: TextStyle(
                  color: pt, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              widget.sessionData['class'],
              style: TextStyle(
                  color: st, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!isReadOnly)
            IconButton(
              icon: Icon(Icons.check_circle_outline_rounded,
                  color: Colors.greenAccent),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Modification enregistrée avec succès !',
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
              _buildStatusBadge(widget.sessionData['status']),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: WidgetStateProperty.all(isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.white.withValues(alpha: 0.5)),
                          columns: [
                            DataColumn(
                                label: Text('Élève',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: pt,
                                        fontSize: 12))),
                            ...components.map((c) => DataColumn(
                                label: Text(c,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: pt,
                                        fontSize: 11)))),
                          ],
                          rows: students.map((student) {
                            return DataRow(
                              cells: [
                                DataCell(Text(student.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: pt,
                                        fontSize: 12))),
                                ...components.map((c) => DataCell(
                                      _buildGradeInput(
                                          isReadOnly, isDark, pt, st),
                                    )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusColor = status == 'Validé'
        ? Colors.greenAccent
        : (status == 'En cours' ? Colors.orangeAccent : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeInput(bool readOnly, bool isDark, Color pt, Color st) {
    if (readOnly) {
      return Text('16.5',
          style:
              TextStyle(color: pt, fontWeight: FontWeight.w900, fontSize: 13));
    }

    return Container(
      width: 50,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1)),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(color: pt, fontWeight: FontWeight.w900, fontSize: 12),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '--',
          hintStyle: TextStyle(color: st, fontSize: 12),
          contentPadding: const EdgeInsets.only(bottom: 14),
        ),
      ),
    );
  }
}
