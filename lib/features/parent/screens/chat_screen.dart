import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/chat_view_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  int _selectedTab = 0; // 0: Messages, 1: Groupes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatVM = context.read<ChatViewModel>();
      chatVM.initializeWebSocket();
      if (!chatVM.isWebSocketConnected) {
        chatVM.startPolling();
      }
      chatVM.fetchThreads();
    });
  }

  @override
  void dispose() {
    context.read<ChatViewModel>().stopPolling();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        title: _isSearching
            ? Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context)!.translate('search_hint'),
                    hintStyle: TextStyle(color: secondaryTextColor),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: secondaryTextColor.withValues(alpha: 0.1)),
                    ),
                    child: Image.asset('assets/images/image3.png',
                        fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(context)!.translate('messaging_title'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                        fontSize: 22,
                        letterSpacing: -0.8),
                  ),
                ],
              ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  shape: BoxShape.circle),
              child: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: primaryTextColor,
                  size: 22),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildTabSwitcher(context),
              Expanded(
                child: Consumer<ChatViewModel>(
                  builder: (context, vm, child) {
                    if (vm.isLoadingThreads && vm.threads.isEmpty) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.blueAccent));
                    }
                    if (vm.errorMessage != null && vm.threads.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 64,
                                color:
                                    secondaryTextColor.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(
                                AppLocalizations.of(context)!
                                    .translate(vm.errorMessage!),
                                style: TextStyle(
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => vm.fetchThreads(),
                              child: Text(AppLocalizations.of(context)!
                                  .translate('retry')),
                            ),
                          ],
                        ),
                      );
                    }

                    final threads = vm.threads.where((ChatThreadModel t) {
                      final query = _searchQuery.toLowerCase();
                      bool matchesName =
                          t.contactName.toLowerCase().contains(query);
                      bool matchesMessage =
                          t.lastMessage.toLowerCase().contains(query);
                      bool matchesSearch =
                          query.isEmpty || matchesName || matchesMessage;

                      final isGroupType = t.contactRole == 'GROUPE';
                      final matchesTab = (_selectedTab == 0 && !isGroupType) ||
                          (_selectedTab == 1 && isGroupType);
                      return matchesSearch && matchesTab;
                    }).toList();

                    if (threads.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 64,
                                color:
                                    secondaryTextColor.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('no_conversations'),
                              style: TextStyle(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      itemCount: threads.length,
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        return _ChatThreadTile(thread: thread, index: index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryTextColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildTabItem(
              context,
              0,
              AppLocalizations.of(context)!.translate('direct_messages'),
              Icons.chat_outlined),
          const SizedBox(width: 6),
          _buildTabItem(
              context,
              1,
              AppLocalizations.of(context)!.translate('group_messages'),
              Icons.groups_outlined),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      BuildContext context, int index, String label, IconData icon) {
    bool isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? Colors.blueAccent.withValues(alpha: 0.2)
                    : Colors.blueAccent)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black38),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatThreadTile extends StatelessWidget {
  final ChatThreadModel thread;
  final int index;
  const _ChatThreadTile({required this.thread, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(thread: thread)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            thread.contactRole == 'GROUPE'
                                ? Colors.orangeAccent.withValues(alpha: 0.5)
                                : Colors.blueAccent.withValues(alpha: 0.5),
                            Colors.purpleAccent.withValues(alpha: 0.2)
                          ])),
                      child: thread.contactRole == 'GROUPE'
                          ? Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent),
                              child: const Icon(Icons.groups_rounded,
                                  size: 30, color: Colors.orangeAccent),
                            )
                          : CircleAvatar(
                              radius: 30,
                              backgroundImage: thread.avatarUrl != null
                                  ? NetworkImage(thread.avatarUrl!)
                                  : null,
                              backgroundColor:
                                  isDark ? Colors.white10 : Colors.blue.shade50,
                              child: thread.avatarUrl == null
                                  ? Text(
                                      _initials(thread.contactName),
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                    ),
                    if (thread.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.4),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Text('${thread.unreadCount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900)),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                            duration: 1.seconds),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(thread.contactName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: primaryTextColor,
                                      fontSize: 17,
                                      letterSpacing: -0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          Text(thread.lastTime,
                              style: TextStyle(
                                  color: thread.unreadCount > 0
                                      ? Colors.blueAccent
                                      : secondaryTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              thread.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: thread.unreadCount > 0
                                    ? primaryTextColor
                                    : secondaryTextColor,
                                fontSize: 14,
                                fontWeight: thread.unreadCount > 0
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                                thread.contactRole == 'GROUPE'
                                    ? AppLocalizations.of(context)!
                                        .translate('class_tab_label')
                                    : thread.contactRole.toUpperCase(),
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class ChatDetailScreen extends StatefulWidget {
  final ChatThreadModel thread;
  const ChatDetailScreen({super.key, required this.thread});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isWriting = false;
  Timer? _messagePollingTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isWriting = _controller.text.trim().isNotEmpty;
      if (isWriting != _isWriting) {
        setState(() => _isWriting = isWriting);
        if (isWriting) {
          context.read<ChatViewModel>().sendTypingIndicator(widget.thread.id);
        } else {
          context.read<ChatViewModel>().stopTypingIndicator(widget.thread.id);
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ChatViewModel>();
      vm.fetchMessages(widget.thread.id);
      if (!vm.isWebSocketConnected) {
        _startMessagePolling();
      }
    });
  }

  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => context
            .read<ChatViewModel>()
            .fetchMessages(widget.thread.id, silent: true));
  }

  @override
  void dispose() {
    _messagePollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    _controller.clear();

    final vm = context.read<ChatViewModel>();
    await vm.sendMessage(widget.thread.id, content);

    if (!mounted) return;

    if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final isGroup = widget.thread.contactRole == 'GROUPE';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.read<ChatViewModel>().clearActiveChat();
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
        ),
        title: Row(
          children: [
            if (isGroup)
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                child: const Icon(Icons.groups_rounded,
                    size: 20, color: Colors.orangeAccent),
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.thread.avatarUrl != null
                    ? NetworkImage(widget.thread.avatarUrl!)
                    : null,
                backgroundColor:
                    isDark ? Colors.white10 : Colors.blue.shade50,
                child: widget.thread.avatarUrl == null
                    ? Text(
                        _initials(widget.thread.contactName),
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.thread.contactName,
                      style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  Text(
                      isGroup
                          ? AppLocalizations.of(context)!
                              .translate('class_tab_label')
                          : widget.thread.contactRole,
                      style: TextStyle(
                          color: primaryTextColor.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: false,
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatViewModel>(
                builder: (context, vm, child) {
                  if (vm.isLoadingMessages) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.blueAccent));
                  }
                  if (vm.errorMessage != null && vm.activeMessages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48,
                              color: primaryTextColor.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                              AppLocalizations.of(context)!
                                  .translate(vm.errorMessage!),
                              style: TextStyle(
                                  color:
                                      primaryTextColor.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => vm.fetchMessages(widget.thread.id),
                            child: Text(AppLocalizations.of(context)!
                                .translate('retry')),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = vm.activeMessages;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final prevMsg = index > 0 ? messages[index - 1] : null;

                      // Date separator logic
                      Widget? dateSeparator;
                      if (_shouldShowDateSeparator(msg, prevMsg)) {
                        dateSeparator = _buildDateSeparator(context, msg);
                      }

                      return Column(
                        children: [
                          if (dateSeparator != null) dateSeparator,
                          _MessageBubble(
                            message: msg,
                            isGroup: isGroup,
                            onEdit: msg.isMe
                                ? () => _showEditDialog(context, vm, msg)
                                : null,
                            onDelete: msg.isMe
                                ? () => _showDeleteConfirm(context, vm, msg)
                                : null,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Consumer<ChatViewModel>(
              builder: (context, vm, _) => _buildInputBar(context, vm),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowDateSeparator(
      ChatMessageModel current, ChatMessageModel? previous) {
    if (previous == null) return true;
    final currentDate = current.createdAt;
    final prevDate = previous.createdAt;
    if (currentDate == null || prevDate == null) return false;
    return currentDate.year != prevDate.year ||
        currentDate.month != prevDate.month ||
        currentDate.day != prevDate.day;
  }

  Widget _buildDateSeparator(BuildContext context, ChatMessageModel msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = msg.createdAt ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDay == today) {
      label = AppLocalizations.of(context)!.translate('today');
    } else if (msgDay == today.subtract(const Duration(days: 1))) {
      label = AppLocalizations.of(context)!.translate('yesterday');
    } else {
      label = DateFormat('dd MMM yyyy', 'fr').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
              child: Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black12)),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, ChatViewModel vm, ChatMessageModel msg) {
    final editController = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('edit_message')),
        content: TextField(
          controller: editController,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText:
                AppLocalizations.of(context)!.translate('input_message_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty && newContent != msg.content) {
                await vm.editMessage(msg.id, newContent);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.translate('save')),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, ChatViewModel vm, ChatMessageModel msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(AppLocalizations.of(context)!.translate('delete_message')),
        content: Text(AppLocalizations.of(context)!
            .translate('delete_message_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await vm.deleteMessage(msg.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                Text(AppLocalizations.of(context)!.translate('delete')),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get _isGroupChat => widget.thread.contactRole == 'GROUPE';

  Widget _buildInputBar(BuildContext context, ChatViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final bool readOnly = _isGroupChat || !vm.canReply;

    if (readOnly) {
      final String notice =
          AppLocalizations.of(context)!.translate('admin_only_banner_msg');

      return Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 16,
                color: primaryTextColor.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                notice,
                style: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: primaryTextColor),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!
                    .translate('input_message_hint'),
                hintStyle: TextStyle(
                    color: primaryTextColor.withValues(alpha: 0.4)),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isGroup;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    this.isGroup = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMe
        ? Colors.blueAccent
        : (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05));
    final textColor =
        isMe ? Colors.white : (isDark ? Colors.white : Colors.black);
    final timeColor = isMe
        ? Colors.white.withValues(alpha: 0.6)
        : (isDark ? Colors.white38 : Colors.black38);

    // Show avatar for received messages (always in groups, optional in direct)
    final showAvatar = !isMe;
    // Show sender name in group chats for received messages
    final showSenderName = isGroup && !isMe;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 12),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: message.senderAvatar != null &&
                          message.senderAvatar!.isNotEmpty
                      ? NetworkImage(message.senderAvatar!)
                      : null,
                  backgroundColor:
                      isDark ? Colors.white10 : Colors.blue.shade50,
                  child: (message.senderAvatar == null ||
                          message.senderAvatar!.isEmpty)
                      ? Text(
                          _initials(message.senderName),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                          ),
                        )
                      : null,
                ),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (showSenderName && message.senderName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white70
                                : Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    // Attachments (images)
                    if (message.attachments.isNotEmpty)
                      ...message.attachments.map((url) =>
                          _buildAttachment(context, url, isMe)),
                    // Text content
                    if (message.content.isNotEmpty)
                      Text(
                        message.content,
                        style: TextStyle(color: textColor, fontSize: 15),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message),
                      style: TextStyle(color: timeColor, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, String url, bool isMe) {
    final lower = url.toLowerCase();
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');

    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.broken_image_rounded, size: 32),
            ),
          ),
        ),
      );
    }

    // Document/file attachment
    final fileName = Uri.tryParse(url)?.pathSegments.lastOrNull ?? 'Document';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded,
              size: 20,
              color: isMe ? Colors.white70 : Colors.blueAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.blueAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(ChatMessageModel msg) {
    if (msg.createdAt != null) {
      return DateFormat('HH:mm').format(msg.createdAt!);
    }
    return msg.time;
  }

  void _showContextMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(
                  AppLocalizations.of(context)!.translate('copy')),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .translate('message_copied')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(AppLocalizations.of(context)!
                    .translate('edit_message')),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_rounded, color: Colors.redAccent),
                title: Text(
                  AppLocalizations.of(context)!.translate('delete_message'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
