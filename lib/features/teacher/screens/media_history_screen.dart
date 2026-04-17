import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/deep_space_background.dart';

class MediaHistoryScreen extends StatefulWidget {
  final String groupName;
  final List<Map<String, dynamic>> messages;

  const MediaHistoryScreen({
    super.key,
    required this.groupName,
    required this.messages,
  });

  @override
  State<MediaHistoryScreen> createState() => _MediaHistoryScreenState();
}

class _MediaHistoryScreenState extends State<MediaHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _mediaMessages => widget.messages
      .where((m) => m['type'] == 'photo' || m['type'] == 'video')
      .toList();
  List<Map<String, dynamic>> get _docMessages => widget.messages
      .where((m) =>
          m['type'] == 'pdf' ||
          (m['content'] is String && m['content'].toString().endsWith('.pdf')))
      .toList();
  List<Map<String, dynamic>> get _linkMessages => widget.messages
      .where((m) =>
          m['content'] is String &&
          (m['content'].toString().startsWith('http') ||
              m['content'].toString().startsWith('www')))
      .toList();

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
        title: Text(loc.translate('media_links_docs'),
            style: TextStyle(
                color: pt, fontWeight: FontWeight.w900, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelColor: pt,
          unselectedLabelColor: isDark ? Colors.white24 : Colors.black26,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          tabs: [
            Tab(text: loc.translate('media_tab_label')),
            Tab(text: loc.translate('docs_tab_label')),
            Tab(text: loc.translate('links_tab_label')),
          ],
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: false,
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMediaGrid(context, _mediaMessages, isDark, pt),
              _buildDocsList(context, _docMessages, isDark, pt),
              _buildLinksList(context, _linkMessages, isDark, pt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context, List<Map<String, dynamic>> items,
      bool isDark, Color pt) {
    if (items.isEmpty) {
      return _buildEmptyState(
          Icons.photo_library_outlined, "Aucun média trouvé");
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(item['content']),
              fit: BoxFit.cover,
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).scale();
      },
    );
  }

  Widget _buildDocsList(BuildContext context, List<Map<String, dynamic>> items,
      bool isDark, Color pt) {
    if (items.isEmpty) {
      return _buildEmptyState(
          Icons.description_outlined, "Aucun document trouvé");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading:
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
          title: Text(item['content'],
              style: TextStyle(color: pt, fontWeight: FontWeight.bold)),
          subtitle: Text(item['time'], style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.download_rounded, size: 20),
        );
      },
    );
  }

  Widget _buildLinksList(BuildContext context, List<Map<String, dynamic>> items,
      bool isDark, Color pt) {
    if (items.isEmpty) {
      return _buildEmptyState(Icons.link_outlined, "Aucun lien trouvé");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const Icon(Icons.link_rounded, color: Colors.blueAccent),
          title: Text(item['content'],
              style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline)),
          subtitle: Text(item['time'], style: const TextStyle(fontSize: 12)),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: Colors.white38, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
