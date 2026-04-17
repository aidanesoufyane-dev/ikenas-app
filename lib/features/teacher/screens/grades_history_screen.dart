import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/api_service.dart';
import './grades_detail_screen.dart';

class GradesHistoryScreen extends StatefulWidget {
  const GradesHistoryScreen({super.key});

  @override
  State<GradesHistoryScreen> createState() => _GradesHistoryScreenState();
}

class _GradesHistoryScreenState extends State<GradesHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await ApiService.instance.getNoteSheets();
      if (!mounted) return;
      setState(() {
        // Map the backend structure to our UI format
        _history = data.map((json) {
          final clazz = json['classe'] != null ? json['classe']['name'] ?? 'Classe' : 'Classe Inconnue';
          final subj = json['subject'] != null ? json['subject']['name'] ?? 'Matière' : 'Matière Inconnue';
          final title = json['title'] ?? 'Examen';
          
          final dateStr = json['createdAt'] != null 
             ? json['createdAt'].toString().substring(0, 10) 
             : 'N/A';
          
          // Determine status loosely based on completion count
          final entriesCount = json['entriesCount'] ?? 0;
          final completedCount = json['completedCount'] ?? 0;
          
          String status = 'En cours';
          if (entriesCount > 0 && completedCount >= entriesCount) {
             status = 'Validé';
          }

          return {
            ...json,
            'date': dateStr,
            'class': clazz,
            'subject': subj,
            'assignment': title,
            'status': status,
          };
        }).toList();
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
    final pt = isDark ? Colors.white : const Color(0xFF0F172A);
    final loc = AppLocalizations.of(context)!;

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
        title: Text(
          loc.translate('grades_history_title'),
          style:
              TextStyle(color: pt, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text('Erreur: $_error',
                          style: const TextStyle(color: Colors.redAccent)))
                  : _history.isEmpty
                      ? Center(
                          child: Text(
                            loc.translate('no_data_short'),
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            return _buildHistoryCard(
                                context, item, index, isDark, pt);
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item,
      int index, bool isDark, Color pt) {
    final statusColor = item['status'] == 'Validé'
        ? Colors.greenAccent
        : (item['status'] == 'En cours' ? Colors.orangeAccent : Colors.grey);

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => GradesDetailScreen(sessionData: item)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.7),
                      blurRadius: 10)
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['date'],
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['class'],
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${item['subject']} - ${item['assignment']}',
              style: TextStyle(
                  color: pt, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  item['status'].toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.blueAccent, size: 20),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideY(begin: 0.1);
  }
}
