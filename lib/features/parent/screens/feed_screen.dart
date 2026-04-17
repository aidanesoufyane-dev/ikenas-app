import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import 'package:intl/intl.dart';
import '../viewmodels/feed_view_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _isSearching = false;
  bool _showSavedOnly = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    context.read<FeedViewModel>().stopPolling();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fetch posts on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userName = context.read<AppState>().currentUser?.name;
      final feedVM = context.read<FeedViewModel>();
      feedVM.startPolling(currentUserName: userName);
      feedVM.fetchPosts(currentUserName: userName);
    });
  }

  void _showPlatinumSnackBar(String message, IconData icon, Color color) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 2),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(PostModel post) {
    final viewModel = context.read<FeedViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<FeedViewModel>(
        builder: (context, vm, child) {
          // Re-fetch the post from VM state
          final currentPost =
              vm.posts.firstWhere((p) => p.id == post.id, orElse: () => post);

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(44)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, -10))
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: secondaryTextColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              AppLocalizations.of(context)!
                                  .translate('comment_btn'),
                              style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          Text(
                              "${currentPost.comments} ${AppLocalizations.of(context)!.translate('comments_count')}",
                              style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: secondaryTextColor.withValues(
                                      alpha: 0.05),
                                  shape: BoxShape.circle),
                              child: Icon(Icons.close_rounded,
                                  color: secondaryTextColor, size: 20))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: currentPost.commentsList.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color:
                                    secondaryTextColor.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                                AppLocalizations.of(context)!
                                    .translate('first_comment'),
                                style: TextStyle(
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w900)),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
                          itemCount: currentPost.commentsList.length,
                          itemBuilder: (context, index) {
                            final comment = currentPost.commentsList.reversed.toList()[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blueAccent
                                          .withValues(alpha: 0.1),
                                      child: Text(comment.authorName[0],
                                          style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontWeight: FontWeight.w900))),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(comment.authorName,
                                                style: TextStyle(
                                                    color: primaryTextColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(_formatPostDate(comment.date),
                                            style: TextStyle(
                                                color: secondaryTextColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: secondaryTextColor
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                const BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(20),
                                                    bottomLeft:
                                                        Radius.circular(20),
                                                    bottomRight:
                                                        Radius.circular(20)),
                                          ),
                                          child: Text(comment.content,
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  fontSize: 14,
                                                  height: 1.5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(24, 20, 24,
                      24 + MediaQuery.of(context).viewInsets.bottom),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, -10))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color:
                                    secondaryTextColor.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            controller: commentController,
                            style: TextStyle(
                                color: primaryTextColor, fontSize: 15),
                            decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!
                                    .translate('type_comment'),
                                hintStyle: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                                border: InputBorder.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          if (commentController.text.trim().isNotEmpty) {
                            final text = commentController.text.trim();
                            final userName =
                                Provider.of<AppState>(context, listen: false)
                                        .currentUser
                                        ?.name ??
                                    "Utilisateur";
                            viewModel.addComment(
                                currentPost.id, userName, text);
                            commentController.clear();
                            _showPlatinumSnackBar(
                                AppLocalizations.of(context)!
                                    .translate('comment_added'),
                                Icons.chat_bubble_rounded,
                                Colors.greenAccent);
                          }
                        },
                        child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Colors.blueAccent,
                                Color(0xFF4F46E5)
                              ]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 22)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatPostDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'À l\'instant';

      return DateFormat("dd MMMM yyyy 'à' HH:mm", 'fr').format(date);
    } catch (e) {
      if (dateStr.toLowerCase() == "à l'instant") return dateStr;
      return dateStr;
    }
  }

  void _showLikesBottomSheet(PostModel post) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, -10))
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: secondaryTextColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          AppLocalizations.of(context)!
                              .translate('likes_title'),
                          style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      Text(
                          "${post.likes} ${AppLocalizations.of(context)!.translate('likes_count')}",
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: secondaryTextColor.withValues(alpha: 0.05),
                              shape: BoxShape.circle),
                          child: Icon(Icons.close_rounded,
                              color: secondaryTextColor, size: 20))),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: post.likedBy.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border_rounded,
                            size: 48,
                            color: secondaryTextColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                            AppLocalizations.of(context)!
                                .translate('no_likes_yet'),
                            style: TextStyle(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w900)),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                      itemCount: post.likedBy.length,
                      itemBuilder: (context, index) {
                        final like = post.likedBy[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    Colors.blueAccent.withValues(alpha: 0.1),
                                backgroundImage: like.userAvatar != null
                                    ? CachedNetworkImageProvider(
                                        like.userAvatar!)
                                    : null,
                                child: like.userAvatar == null
                                    ? Text(like.userName[0],
                                        style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.w900))
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(like.userName,
                                    style: TextStyle(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.favorite_rounded,
                                    color: Colors.redAccent, size: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: _isSearching
            ? Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: secondaryTextColor.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.translate('search'),
                    hintStyle: TextStyle(
                        color: secondaryTextColor, fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded,
                        color: secondaryTextColor, size: 20),
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
                          ? Colors.white.withValues(alpha: 0.08)
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
                    AppLocalizations.of(context)!.translate('news_title'),
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
            icon: Icon(
              _showSavedOnly
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _showSavedOnly ? Colors.blueAccent : secondaryTextColor,
              size: 26,
            ),
            onPressed: () => setState(() => _showSavedOnly = !_showSavedOnly),
          ),
          IconButton(
            icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: secondaryTextColor,
                size: 26),
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
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: Consumer<FeedViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading && vm.posts.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent));
            }

            if (vm.errorMessage != null && vm.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.redAccent.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(vm.errorMessage!,
                        style: TextStyle(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: vm.fetchPosts,
                        child: const Text("Réessayer")),
                  ],
                ),
              );
            }

            final filteredPosts = vm.posts.where((post) {
              final query = _searchQuery.toLowerCase();
              final matchesSearch =
                  post.content.toLowerCase().startsWith(query) ||
                      post.authorName.toLowerCase().startsWith(query);
              final matchesSaved = !_showSavedOnly || post.isSaved;
              return matchesSearch && matchesSaved;
            }).toList();

            if (filteredPosts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 64,
                        color: secondaryTextColor.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.translate('no_results'),
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => vm.fetchPosts(
                  currentUserName: context.read<AppState>().currentUser?.name),
              color: Colors.blueAccent,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];
                  return _buildPostCard(context: context, post: post, vm: vm);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard({
    required BuildContext context,
    required PostModel post,
    required FeedViewModel vm,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    final contentColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 30,
                    offset: const Offset(0, 15))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                  backgroundImage: post.authorAvatar != null
                      ? CachedNetworkImageProvider(post.authorAvatar!)
                      : null,
                  child: post.authorAvatar == null
                      ? Text(
                          post.authorName.isNotEmpty ? post.authorName[0] : "?",
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 18))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: primaryTextColor,
                            letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPostDate(post.date),
                        style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: post.isSaved
                          ? Colors.blueAccent.withValues(alpha: 0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      post.isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color:
                          post.isSaved ? Colors.blueAccent : secondaryTextColor,
                      size: 22,
                    ),
                  ),
                  onPressed: () => vm.toggleSave(post),
                ),
              ],
            ),
          ),

          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    post.content,
                    style: TextStyle(
                        fontSize: 15,
                        color: contentColor,
                        height: 1.6,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 240,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.blueAccent)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 240,
                          width: double.infinity,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF1F5F9),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_rounded,
                                  size: 48,
                                  color: secondaryTextColor.withValues(
                                      alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('image_not_available'),
                                style: TextStyle(
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

          // Interaction Stats Row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (post.likes > 0)
                  GestureDetector(
                    onTap: () => _showLikesBottomSheet(post),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite,
                              color: Colors.white, size: 10),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (post.comments > 0)
                  Text(
                    '${post.comments} ${AppLocalizations.of(context)!.translate('comment_btn')}',
                    style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                height: 1),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildFBActionBtn(
                    context: context,
                    icon: post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: AppLocalizations.of(context)!.translate('btn_like'),
                    color: post.isLiked ? Colors.redAccent : secondaryTextColor,
                    onTap: () {
                      final appState = context.read<AppState>();
                      vm.toggleLike(
                        post,
                        userName: appState.currentUser?.name,
                        userAvatar: appState.currentUser?.avatarUrl,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _buildFBActionBtn(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label:
                        AppLocalizations.of(context)!.translate('comment_btn'),
                    color: secondaryTextColor,
                    onTap: () => _showCommentsBottomSheet(post),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildFBActionBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
