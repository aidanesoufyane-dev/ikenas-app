import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
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
      // Initialize WebSocket for real-time chat
      chatVM.initializeWebSocket();
      // Fallback to polling if WebSocket is not enabled
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
                              backgroundImage: NetworkImage(thread.avatarUrl ??
                                  'https://i.pravatar.cc/150?u=${thread.contactName}'),
                              backgroundColor:
                                  isDark ? Colors.white10 : Colors.white,
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
}

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
        // Send typing indicator if WebSocket is connected
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
      // Only start polling if WebSocket is not connected
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

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    _controller.clear();

    final vm = context.read<ChatViewModel>();
    await vm.sendMessage(widget.thread.id, content);

    if (!mounted) return;

    // Show error if send failed
    if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

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
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.thread.avatarUrl ??
                  'https://i.pravatar.cc/150?u=${widget.thread.contactName}'),
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
                  Text(widget.thread.contactRole,
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

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
                    itemCount: vm.activeMessages.length,
                    itemBuilder: (context, index) {
                      final msg = vm.activeMessages[index];
                      return _MessageBubble(message: msg);
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

  bool get _isGroupChat => widget.thread.contactRole == 'GROUPE';

  Widget _buildInputBar(BuildContext context, ChatViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    // Group chats are always read-only for parents
    // Direct chats are read-only when no message has allowReply=true
    final bool readOnly = _isGroupChat || !vm.canReply;

    if (readOnly) {
      final String notice = _isGroupChat
          ? AppLocalizations.of(context)!.translate('admin_only_banner_msg')
          : AppLocalizations.of(context)!.translate('admin_only_banner_msg');

      return Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
            Text(
              notice,
              style: TextStyle(
                  color: primaryTextColor.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
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
            icon:
                const Icon(Icons.send_rounded, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    bool isMe = message.isMe;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.blueAccent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black),
                  fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.6)
                      : (isDark ? Colors.white38 : Colors.black38),
                  fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
