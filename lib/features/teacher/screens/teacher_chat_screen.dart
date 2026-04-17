import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/models.dart';
import '../../chat/chat_api_service.dart';
import '../../chat/chat_service.dart';
import 'group_info_screen.dart';

// ─────────────────────────────────────────────────────────────
// Simple data class representing a grouped conversation entry
// ─────────────────────────────────────────────────────────────
class _Conversation {
  final String partnerId;
  final String partnerName;
  final String partnerRole;
  final String lastMsg;
  final DateTime lastTime;
  final int unread;

  const _Conversation({
    required this.partnerId,
    required this.partnerName,
    required this.partnerRole,
    required this.lastMsg,
    required this.lastTime,
    required this.unread,
  });

  _Conversation copyWith({int? unread}) => _Conversation(
        partnerId: partnerId,
        partnerName: partnerName,
        partnerRole: partnerRole,
        lastMsg: lastMsg,
        lastTime: lastTime,
        unread: unread ?? this.unread,
      );
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
String _extractId(dynamic v) {
  if (v == null) return '';
  if (v is Map) return (v['_id'] ?? v['id'])?.toString() ?? '';
  return v.toString();
}

String _extractFullName(dynamic v) {
  if (v == null) return 'Unknown';
  if (v is Map) {
    final first = v['firstName']?.toString() ?? '';
    final last = v['lastName']?.toString() ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return (v['fullName'] ?? v['name'] ?? 'Unknown').toString();
  }
  return v.toString();
}

String _extractRole(dynamic v) {
  if (v == null) return '';
  if (v is Map) return v['role']?.toString() ?? '';
  return '';
}

bool _isUnread(Map<String, dynamic> msg) {
  final readBy = msg['readBy'];
  return readBy is List && readBy.isEmpty;
}

String _formatTime(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final d = DateTime(t.year, t.month, t.day);
  if (d == today) return DateFormat('HH:mm').format(t);
  if (d == yesterday) return 'Hier';
  return DateFormat('dd/MM').format(t);
}

// ─────────────────────────────────────────────────────────────
// Main Teacher Chat Screen (shown via Bottom Nav)
// ─────────────────────────────────────────────────────────────
class TeacherChatScreen extends StatefulWidget {
  const TeacherChatScreen({super.key});

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<_Conversation> _conversations = [];
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await AuthService.instance.init();
      final user = AuthService.instance.getStoredUser();
      final token = AuthService.instance.getStoredToken();
      _currentUserId = user?.id;

      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));
      final chatApi = ChatApiService(dio);

      final results = await Future.wait([
        chatApi.fetchMessages().catchError((_) => <Map<String, dynamic>>[]),
        ApiService.instance.getMyClasses().catchError((_) => <ClassModel>[]),
      ]);

      final msgs = results[0] as List<Map<String, dynamic>>;
      final classes = results[1] as List<ClassModel>;

      // Group individual messages into conversations
      final Map<String, _Conversation> convMap = {};
      for (final msg in msgs) {
        if (msg['recipientType'] != 'individual') continue;

        final senderId = _extractId(msg['sender']);
        final targetId = _extractId(msg['targetUser']);
        final isOwn = senderId == _currentUserId;
        final partnerId = isOwn ? targetId : senderId;
        if (partnerId.isEmpty) continue;

        final partnerName =
            isOwn ? _extractFullName(msg['targetUser']) : _extractFullName(msg['sender']);
        final partnerRole = _extractRole(isOwn ? msg['targetUser'] : msg['sender']);
        final createdAt =
            DateTime.tryParse(msg['createdAt']?.toString() ?? '') ?? DateTime.now();
        final content = msg['content']?.toString() ?? '';

        final existing = convMap[partnerId];
        if (existing == null || createdAt.isAfter(existing.lastTime)) {
          convMap[partnerId] = _Conversation(
            partnerId: partnerId,
            partnerName: partnerName,
            partnerRole: partnerRole,
            lastMsg: content,
            lastTime: createdAt,
            unread: (!isOwn && _isUnread(msg)) ? 1 : 0,
          );
        } else if (!isOwn && _isUnread(msg)) {
          convMap[partnerId] =
              existing.copyWith(unread: existing.unread + 1);
        }
      }

      final conversations = convMap.values.toList()
        ..sort((a, b) => b.lastTime.compareTo(a.lastTime));

      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _classes = classes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
        automaticallyImplyLeading: false,
        title: Text(
          loc.translate('messages_teacher'),
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: primaryTextColor,
              fontSize: 22,
              letterSpacing: -0.5),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark
                    ? Colors.blueAccent.withValues(alpha: 0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                            color: Colors.white,
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
              ),
              labelColor: isDark ? Colors.white : Colors.blueAccent,
              unselectedLabelColor: secondaryTextColor,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5),
              tabs: [
                Tab(text: loc.translate('tab_individuel')),
                Tab(text: loc.translate('tab_classes')),
              ],
            ),
          ),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMessagesTab(
                        context, isDark, primaryTextColor, secondaryTextColor),
                    _buildGroupsTab(
                        context, isDark, primaryTextColor, secondaryTextColor),
                  ],
                ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NewChatSearchScreen(classes: _classes)));
            // Refresh after returning from a new chat
            _loadData();
          },
          backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.edit_note_rounded, size: 28),
        ).animate().scale(
            delay: const Duration(milliseconds: 400), curve: Curves.elasticOut),
      ),
    );
  }

  Widget _buildMessagesTab(BuildContext context, bool isDark,
      Color primaryTextColor, Color secondaryTextColor) {
    if (_conversations.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_results_found'),
          style: TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return _ChatTile(
          name: conv.partnerName,
          lastMsg: conv.lastMsg,
          time: _formatTime(conv.lastTime),
          unread: conv.unread,
          role: conv.partnerRole,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  name: conv.partnerName,
                  avatarUrl: 'https://i.pravatar.cc/150?u=${conv.partnerId}',
                  targetUserId: conv.partnerId,
                ),
              ),
            );
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildGroupsTab(BuildContext context, bool isDark,
      Color primaryTextColor, Color secondaryTextColor) {
    if (_classes.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_results_found'),
          style: TextStyle(
              color: secondaryTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final cls = _classes[index];
        final cardBg =
            isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                        color: Colors.white.withValues(alpha: 0.7),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ],
          ),
          child: ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    name: cls.name,
                    avatarUrl:
                        'https://img.icons8.com/clouds/150/000000/groups.png',
                    classModel: cls,
                  ),
                ),
              );
              _loadData();
            },
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.blueAccent,
                      Colors.blueAccent.withValues(alpha: 0.7)
                    ]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: Colors.white, size: 28),
                ),
                Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBg, width: 2)))),
              ],
            ),
            title: Text(cls.name,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: primaryTextColor)),
            subtitle: Text(
                '${cls.studentCount} ${AppLocalizations.of(context)!.translate('students')}',
                style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.bold)),
            trailing:
                Icon(Icons.chevron_right_rounded, color: secondaryTextColor),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: (index * 80)))
            .slideY(begin: 0.1);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chat Tile widget
// ─────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String name;
  final String lastMsg;
  final String time;
  final int unread;
  final String role;
  final bool isSpecial;
  final VoidCallback? onTap;

  const _ChatTile({
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.role,
    this.isSpecial = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.7),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(20),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSpecial
                          ? Colors.orangeAccent
                          : Colors.blueAccent.withValues(alpha: 0.2))),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.7),
                child: Text(
                  name.contains(' ')
                      ? name.split(' ').last.substring(0, 1)
                      : name.substring(0, 1),
                  style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.blueAccent, shape: BoxShape.circle),
                  child: Text(unread.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: primaryTextColor,
                    letterSpacing: -0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (role.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isSpecial ? Colors.orangeAccent : Colors.blueAccent)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                      color: isSpecial ? Colors.orangeAccent : Colors.blueAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            lastMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: unread > 0
                  ? (isDark ? Colors.white70 : Colors.black87)
                  : secondaryTextColor,
              fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ),
        trailing: Text(
          time,
          style: TextStyle(
              color: secondaryTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2),
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.05);
  }
}

// ─────────────────────────────────────────────────────────────
// New Chat Search Screen — pick a recipient or class
// ─────────────────────────────────────────────────────────────
class NewChatSearchScreen extends StatefulWidget {
  final List<ClassModel> classes;
  const NewChatSearchScreen({super.key, this.classes = const []});

  @override
  State<NewChatSearchScreen> createState() => _NewChatSearchScreenState();
}

class _NewChatSearchScreenState extends State<NewChatSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> _recipients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController
        .addListener(() => setState(() => _query = _searchController.text.toLowerCase()));
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    try {
      await AuthService.instance.init();
      final token = AuthService.instance.getStoredToken();
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));
      final chatApi = ChatApiService(dio);
      final recipients = await chatApi.getRecipients();
      if (!mounted) return;
      setState(() {
        _recipients = recipients;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final loc = AppLocalizations.of(context)!;

    final filteredRecipients = _recipients.where((r) {
      final first = r['firstName']?.toString().toLowerCase() ?? '';
      final last = r['lastName']?.toString().toLowerCase() ?? '';
      final full = '$first $last';
      return full.contains(_query);
    }).toList();

    final filteredClasses = widget.classes
        .where((c) => c.name.toLowerCase().contains(_query))
        .toList();

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
        title: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  '${loc.translate('tab_individuel')} / ${loc.translate('tab_classes')}...',
              hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded,
                  color: secondaryTextColor, size: 20),
              isDense: true,
            ),
          ),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: false,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Colors.blueAccent))
              : Column(
                  children: [
                    _buildSection(
                        loc.translate('tab_individuel'),
                        filteredRecipients,
                        Colors.blueAccent,
                        isDark,
                        primaryTextColor,
                        secondaryTextColor,
                        loc),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSection(
                        loc.translate('tab_classes'),
                        filteredClasses,
                        Colors.purpleAccent,
                        isDark,
                        primaryTextColor,
                        secondaryTextColor,
                        loc,
                        isGroup: true),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, Color color,
      bool isDark, Color pt, Color st, AppLocalizations loc,
      {bool isGroup = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(title.toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.5)),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('—', style: TextStyle(color: st)))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      if (isGroup) {
                        final cls = items[i] as ClassModel;
                        return _SearchResultTile(
                          name: cls.name,
                          initial: cls.name[0],
                          accentColor: color,
                          isDark: isDark,
                          primaryTextColor: pt,
                          secondaryTextColor: st,
                          isGroup: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                name: cls.name,
                                avatarUrl:
                                    'https://img.icons8.com/clouds/150/000000/groups.png',
                                classModel: cls,
                              ),
                            ),
                          ),
                        );
                      } else {
                        final r = items[i] as Map<String, dynamic>;
                        final first = r['firstName']?.toString() ?? '';
                        final last = r['lastName']?.toString() ?? '';
                        final name = '$first $last'.trim();
                        final id = (r['_id'] ?? r['id'])?.toString() ?? '';
                        return _SearchResultTile(
                          name: name,
                          initial: name.isNotEmpty ? name[0] : '?',
                          accentColor: color,
                          isDark: isDark,
                          primaryTextColor: pt,
                          secondaryTextColor: st,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                name: name,
                                avatarUrl: 'https://i.pravatar.cc/150?u=$id',
                                targetUserId: id,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final String name;
  final String initial;
  final Color accentColor;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isGroup;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.name,
    required this.initial,
    required this.accentColor,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accentColor.withValues(alpha: 0.1),
              child: isGroup
                  ? Icon(Icons.groups_rounded, color: accentColor, size: 20)
                  : Text(initial,
                      style: TextStyle(
                          color: accentColor, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(name,
                    style: TextStyle(
                        color: primaryTextColor, fontWeight: FontWeight.bold))),
            Icon(Icons.chevron_right_rounded,
                color: secondaryTextColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chat Detail Screen — individual or class conversation
// ─────────────────────────────────────────────────────────────
class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String avatarUrl;
  final ClassModel? classModel;
  final String? targetUserId;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.classModel,
    this.targetUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final Set<int> _selectedIndices = {};

  // Messages stored as [{isMe, content, time, type, _id?}]
  final List<Map<String, dynamic>> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  ChatApiService? _chatApi;
  ChatService? _chatService;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  bool get _isSelectionMode => _selectedIndices.isNotEmpty;
  bool get _isClassChat => widget.classModel != null;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      await AuthService.instance.init();
      final user = AuthService.instance.getStoredUser();
      final token = AuthService.instance.getStoredToken();
      _currentUserId = user?.id;

      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));
      _chatApi = ChatApiService(dio);

      // Load message history
      await _loadMessages();

      // Connect Socket.io for real-time updates
      _chatService = ChatService(AppConfig.serverUrl, token);
      _chatService!.connect();
      _socketSub = _chatService!.onMessage.listen(_handleSocketEvent);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_chatApi == null) return;
    try {
      final all = await _chatApi!.fetchMessages();
      final List<Map<String, dynamic>> filtered = [];

      for (final msg in all) {
        final senderId = _extractId(msg['sender']);
        final targetId = _extractId(msg['targetUser']);
        final targetClassId = _extractId(msg['targetClass']);
        final isOwn = senderId == _currentUserId;

        if (_isClassChat) {
          if (targetClassId == widget.classModel!.id ||
              (msg['targetClass'] is Map &&
                  _extractId(msg['targetClass']) == widget.classModel!.id)) {
            filtered.add(_toLocal(msg, isOwn));
          }
        } else if (widget.targetUserId != null) {
          final partnerId = widget.targetUserId!;
          final involves = (isOwn && targetId == partnerId) ||
              (!isOwn && senderId == partnerId);
          if (involves) filtered.add(_toLocal(msg, isOwn));
        }
      }

      // Sort oldest first
      filtered.sort((a, b) {
        final ta = DateTime.tryParse(a['_createdAt']?.toString() ?? '') ??
            DateTime.now();
        final tb = DateTime.tryParse(b['_createdAt']?.toString() ?? '') ??
            DateTime.now();
        return ta.compareTo(tb);
      });

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(filtered);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _toLocal(Map<String, dynamic> msg, bool isOwn) {
    return {
      'isMe': isOwn,
      'content': msg['content']?.toString() ?? '',
      'time': DateFormat('HH:mm').format(
          DateTime.tryParse(msg['createdAt']?.toString() ?? '') ??
              DateTime.now()),
      'type': 'text',
      '_id': (msg['_id'] ?? msg['id'])?.toString() ?? '',
      '_createdAt': msg['createdAt'],
    };
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final data = event['data'];
    if (data == null) return;
    final msg = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);

    if (event['event'] == 'new-message') {
      final senderId = _extractId(msg['sender']);
      final targetId = _extractId(msg['targetUser']);
      final targetClassId = _extractId(msg['targetClass']);
      final isOwn = senderId == _currentUserId;

      bool relevant = false;
      if (_isClassChat) {
        relevant = targetClassId == widget.classModel!.id;
      } else if (widget.targetUserId != null) {
        final partnerId = widget.targetUserId!;
        relevant = (isOwn && targetId == partnerId) ||
            (!isOwn && senderId == partnerId);
      }

      if (relevant && mounted) {
        setState(() => _messages.add(_toLocal(msg, isOwn)));
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending || _chatApi == null) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      final sent = await _chatApi!.sendMessage(
        content: text,
        recipientType: _isClassChat ? 'class' : 'individual',
        targetClassId: _isClassChat ? widget.classModel!.id : null,
        targetUserId: _isClassChat ? null : widget.targetUserId,
      );

      if (mounted && sent.isNotEmpty) {
        final createdAt = sent['createdAt']?.toString() ??
            DateTime.now().toIso8601String();
        setState(() => _messages.add({
              'isMe': true,
              'content': text,
              'time': DateFormat('HH:mm')
                  .format(DateTime.tryParse(createdAt) ?? DateTime.now()),
              'type': 'text',
              '_id': (sent['_id'] ?? sent['id'])?.toString() ?? '',
              '_createdAt': createdAt,
            }));
        _scrollToBottom();
      }
    } catch (_) {
      // Optimistically add even on failure so the user sees their own message
      if (mounted) {
        setState(() => _messages.add({
              'isMe': true,
              'content': text,
              'time': DateFormat('HH:mm').format(DateTime.now()),
              'type': 'text',
              '_id': '',
              '_createdAt': DateTime.now().toIso8601String(),
            }));
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessageById(String msgId, int index) async {
    if (msgId.isEmpty || _chatApi == null) {
      setState(() => _messages.removeAt(index));
      return;
    }
    await _chatApi!.deleteMessage(msgId).catchError((_) => false);
    if (mounted) setState(() => _messages.removeAt(index));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _socketSub?.cancel();
    _chatService?.disconnect();
    super.dispose();
  }

  void _startRecordingTimer() {
    setState(() {
      _recordingSeconds = 0;
      _isRecording = true;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    if (mounted) setState(() => _isRecording = false);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  void _showChatSettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            if (widget.classModel != null)
              _buildSettingsItem(
                Icons.info_outline_rounded,
                loc.translate('voir_details'),
                Colors.blueAccent,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GroupInfoScreen(
                                groupName: widget.name,
                                classModel: widget.classModel,
                                messages: _messages,
                              )));
                },
              ),
            _buildSettingsItem(
              appState.mutedChatIds.contains(widget.name)
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              appState.mutedChatIds.contains(widget.name)
                  ? 'Unmute'
                  : loc.translate('mute_notifications'),
              Colors.orangeAccent,
              () {
                appState.toggleMuteChat(widget.name);
                Navigator.pop(context);
              },
            ),
            _buildSettingsItem(
                Icons.delete_outline_rounded,
                loc.translate('clear_chat'),
                Colors.redAccent, () {
              Navigator.pop(context);
              _confirmDeleteAll();
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAll() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.translate('clear_chat'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.translate('confirm_delete_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel_uppercase'))),
          ElevatedButton(
            onPressed: () {
              setState(() => _messages.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: Text(loc.translate('clear_chat')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
            '${_selectedIndices.length} ${_selectedIndices.length > 1 ? loc.translate('messages').toLowerCase() : loc.translate('message').toLowerCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.translate('confirm_delete_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel_uppercase'))),
          ElevatedButton(
            onPressed: () {
              final sorted = _selectedIndices.toList()
                ..sort((a, b) => b.compareTo(a));
              for (final idx in sorted) {
                if (idx < _messages.length) {
                  final id = _messages[idx]['_id']?.toString() ?? '';
                  _deleteMessageById(id, idx);
                }
              }
              setState(() => _selectedIndices.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: Text(loc.translate('delete_selected_btn')),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _showAttachmentMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 20,
              crossAxisSpacing: 10,
              children: [
                _buildAttachmentIcon(Icons.photo_library_rounded,
                    loc.translate('camera_roll'), Colors.purpleAccent,
                    () => Navigator.pop(context)),
                _buildAttachmentIcon(Icons.camera_alt_rounded,
                    loc.translate('selfie'), Colors.blueAccent,
                    () => Navigator.pop(context)),
                _buildAttachmentIcon(Icons.video_collection_rounded,
                    loc.translate('video_label'), Colors.orangeAccent,
                    () => Navigator.pop(context)),
                _buildAttachmentIcon(Icons.picture_as_pdf_rounded,
                    loc.translate('pdf_label'), Colors.redAccent,
                    () => Navigator.pop(context)),
                _buildAttachmentIcon(Icons.mic_rounded,
                    loc.translate('audio_recording'), Colors.greenAccent,
                    () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentIcon(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = isDark ? Colors.white : const Color(0xFF0F172A);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 4,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.blueAccent),
                onPressed: () => setState(() => _selectedIndices.clear()),
              ),
              title: Text(
                '${_selectedIndices.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: Colors.blueAccent),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  onPressed: _confirmDeleteSelected,
                ),
                const SizedBox(width: 8),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: pt, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(widget.avatarUrl)),
                  const SizedBox(width: 12),
                  Text(widget.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: pt,
                          fontSize: 16)),
                ],
              ),
              actions: [
                IconButton(
                    icon: Icon(Icons.settings_outlined, color: pt),
                    onPressed: _showChatSettings),
                const SizedBox(width: 8),
              ],
            ),
      body: DeepSpaceBackground(
        showOrbs: false,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.blueAccent)),
                    )
                  else
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Text(
                                loc.translate('no_messages_yet') !=
                                        'no_messages_yet'
                                    ? loc.translate('no_messages_yet')
                                    : 'Démarrez la conversation…',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black26,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(20),
                              itemCount: _messages.length,
                              itemBuilder: (context, i) =>
                                  _buildBubble(_messages[i], i, isDark),
                            ),
                    ),
                  Consumer<AppState>(builder: (context, appState, _) {
                    final isAdminOnly =
                        appState.groupAdminOnlyMessaging.contains(widget.name);
                    if (!isAdminOnly) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              color: Colors.blueAccent, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            loc.translate('admin_only_banner_msg'),
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  _buildInput(isDark, pt, loc),
                ],
              ),
              if (_isRecording)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                            blurRadius: 20)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic_rounded, color: Colors.white)
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                duration: const Duration(milliseconds: 600)),
                        const SizedBox(width: 16),
                        Text(loc.translate('audio_recording'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(_formatDuration(_recordingSeconds),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, int index, bool isDark) {
    final isMe = msg['isMe'] as bool? ?? false;
    final type = msg['type']?.toString() ?? 'text';
    final isSelected = _selectedIndices.contains(index);

    return GestureDetector(
      onLongPress: () => _toggleSelection(index),
      onTap: () {
        if (_isSelectionMode) _toggleSelection(index);
      },
      child: Container(
        color: isSelected
            ? Colors.blueAccent.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(type == 'photo' ? 4 : 12),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.blueAccent
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isMe
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
              border: isSelected
                  ? Border.all(color: Colors.blueAccent, width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (type == 'text')
                  Text(msg['content']?.toString() ?? '',
                      style: TextStyle(
                          color: isMe || isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600)),
                if (type == 'audio')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_filled_rounded,
                          color:
                              isMe || isDark ? Colors.white : Colors.blueAccent,
                          size: 32),
                      const SizedBox(width: 12),
                      Container(
                        width: 100,
                        height: 3,
                        decoration: BoxDecoration(
                            color: (isMe || isDark
                                    ? Colors.white
                                    : Colors.blueAccent)
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 12),
                      Text(msg['duration']?.toString() ?? '0:00',
                          style: TextStyle(
                              color: isMe || isDark
                                  ? Colors.white70
                                  : Colors.black45,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(msg['time']?.toString() ?? '',
                    style: TextStyle(
                        color: (isMe || isDark ? Colors.white : Colors.black54)
                            .withValues(alpha: 0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ).animate().fadeIn().slideX(begin: isMe ? 0.1 : -0.1),
        ),
      ),
    );
  }

  Widget _buildInput(bool isDark, Color pt, AppLocalizations loc) {
    return Consumer<AppState>(builder: (context, appState, _) {
      final isAdminOnly =
          appState.groupAdminOnlyMessaging.contains(widget.name);

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
              top: BorderSide(color: isDark ? Colors.white10 : Colors.white)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                  isAdminOnly
                      ? Icons.lock_outline_rounded
                      : Icons.add_circle_outline_rounded,
                  color: isAdminOnly
                      ? Colors.amber
                      : (isDark ? Colors.white38 : Colors.black38)),
              onPressed: isAdminOnly ? null : _showAttachmentMenu,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: isDark ? Colors.white10 : Colors.white),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                      color: pt, fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: InputDecoration(
                      hintText: isAdminOnly
                          ? loc.translate('admin_only_chat_setting')
                          : loc.translate('input_message_hint'),
                      hintStyle: TextStyle(
                          color: isAdminOnly
                              ? Colors.amber.withValues(alpha: 0.5)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3))),
                      border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_controller.text.isEmpty)
              GestureDetector(
                onLongPressStart:
                    isAdminOnly ? null : (_) => _startRecordingTimer(),
                onLongPressEnd: isAdminOnly
                    ? null
                    : (_) {
                        _stopRecordingTimer();
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_isRecording ? 16 : 12),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.redAccent
                        : Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 5)
                          ]
                        : [],
                  ),
                  child: Icon(Icons.mic_rounded,
                      color: isAdminOnly
                          ? Colors.grey
                          : (_isRecording ? Colors.white : Colors.blueAccent),
                      size: _isRecording ? 28 : 24),
                ),
              )
            else
              _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.blueAccent, strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon:
                          const Icon(Icons.send_rounded, color: Colors.blueAccent),
                      onPressed: isAdminOnly ? null : _sendTextMessage,
                    ),
          ],
        ),
      );
    });
  }
}
