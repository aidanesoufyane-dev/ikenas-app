import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../viewmodels/notification_view_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifVM = context.read<NotificationViewModel>();
      final userId = context.read<AppState>().currentUser?.id;
      notifVM.setCurrentUserId(userId);
      notifVM.startPolling();
      notifVM.fetchNotifications();
    });
  }

  @override
  void dispose() {
    context.read<NotificationViewModel>().stopPolling();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).currentUser;
    final isTeacher = user?.role == UserRole.teacher;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black45;

    final List<String> filters = [
      'all',
      'exams',
      'notes',
      'devoirs',
      'evenements',
      'payment',
      'message'
    ];
    if (isTeacher) filters.add('request');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DeepSpaceBackground(
        showOrbs: true,
        child: Consumer<NotificationViewModel>(
          builder: (context, vm, child) {
            final filteredNotifications = vm.notifications.where((n) {
              // Category filter
              bool categoryMatch = true;
              final String tType = n.type.toLowerCase();
              final String tTitle = n.title.toLowerCase();
              final String tBody = n.body.toLowerCase();
              
              if (_selectedFilter == 'exams') {
                categoryMatch = tType.contains('exam') || tTitle.contains('exam') || tBody.contains('exam');
              } else if (_selectedFilter == 'notes') {
                categoryMatch = tType.contains('note') || tType.contains('grade') || tTitle.contains('note') || tTitle.contains('bulletin') || tBody.contains('note') || tBody.contains('bulletin') || tBody.contains('résultat');
              } else if (_selectedFilter == 'devoirs') {
                categoryMatch = tType.contains('devoir') || tType.contains('assignment') || tTitle.contains('devoir') || tBody.contains('devoir');
              } else if (_selectedFilter == 'evenements') {
                categoryMatch = tType.contains('event') || tType.contains('evenement') || tTitle.contains('evenement') || tTitle.contains('événement') || tBody.contains('event') || tBody.contains('evenement') || tBody.contains('événement');
              } else if (_selectedFilter == 'payment') {
                categoryMatch = tType.contains('payment') || tType.contains('paiement') || tTitle.contains('paiement') || tTitle.contains('payement') || tBody.contains('payment') || tBody.contains('paiement');
              } else if (_selectedFilter == 'message') {
                categoryMatch = tType.contains('message') || tTitle.contains('message') || tBody.contains('message');
              } else if (_selectedFilter != 'all') {
                categoryMatch = false;
              }

              // Search filter
              final query = _searchQuery.toLowerCase().trim();
              bool searchMatch = query.isEmpty ||
                  n.title.toLowerCase().contains(query) ||
                  n.body.toLowerCase().contains(query);

              return categoryMatch && searchMatch;
            }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 140,
                  pinned: true,
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: primaryTextColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (vm.unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ConfirmationDialog.show(
                            context,
                            title: AppLocalizations.of(context)!
                                .translate('mark_all_read_btn'),
                            message:
                                'Voulez-vous marquer toutes les notifications comme lues ?',
                            onConfirm: () => vm.markAllAsRead(),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('mark_all_read_btn')
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 10),
                        ),
                      ),
                    if (vm.notifications.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded,
                            color: Colors.redAccent, size: 22),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ConfirmationDialog.show(
                            context,
                            title: 'Supprimer tout',
                            message:
                                'Voulez-vous vraiment supprimer toutes vos notifications ?',
                            onConfirm: () => vm.deleteAllNotifications(),
                          );
                        },
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                        AppLocalizations.of(context)!
                            .translate('notifications_center'),
                        style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildSearchField(
                            isDark, primaryTextColor, secondaryTextColor),
                      ),
                      const SizedBox(height: 24),
                      _buildFilterList(filters, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                if (vm.isLoading && vm.notifications.isEmpty)
                  const SliverFillRemaining(
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.blueAccent))),
                if (!vm.isLoading && filteredNotifications.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_rounded,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 16),
                          Text(
                              AppLocalizations.of(context)!
                                  .translate('no_alerts_found'),
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final n = filteredNotifications[index];
                          return Dismissible(
                            key: ValueKey(n.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              HapticFeedback.mediumImpact();
                              return await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                                    content: Text('Voulez-vous vraiment supprimer cette notification ?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text('Annuler', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontWeight: FontWeight.bold)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              vm.deleteNotification(n.id);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
                            ),
                            child: InkWell(
                              onTap: () {
                                vm.markAsRead(n.id);
                              },
                              child: _NotificationCard(notification: n),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (index * 50).ms)
                              .slideX(begin: 0.05);
                        },
                        childCount: filteredNotifications.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark, Color primary, Color secondary) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.white),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
            color: primary, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.translate('search_alerts'),
          prefixIcon: Icon(Icons.search_rounded, color: secondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildFilterList(List<String> filters, bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: 300.ms,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _getFilterLabel(context, filter),
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                        : (isDark ? Colors.white60 : Colors.black54),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getFilterLabel(BuildContext context, String filter) {
    final loc = AppLocalizations.of(context)!;
    switch (filter) {
      case 'all':
        return loc.translate('all_filter');
      case 'exams':
        return "Examens";
      case 'notes':
        return "Notes";
      case 'devoirs':
        return "Devoirs";
      case 'evenements':
        return "Événements";
      case 'payment':
        return loc.translate('payments_nav');
      case 'message':
        return loc.translate('messages');
      default:
        return filter;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final typeColor = _getTypeColor(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : typeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(_getIcon(notification.iconType),
                color: typeColor, size: 24),
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
                        child: Text(notification.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: primaryTextColor))),
                    Text(_formatDate(notification.time),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(notification.body,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(IconType type) {
    switch (type) {
      case IconType.location:
        return Icons.location_on_rounded;
      case IconType.grade:
        return Icons.school_rounded;
      case IconType.absence:
        return Icons.event_busy_rounded;
      case IconType.payment:
        return Icons.payments_rounded;
      case IconType.message:
        return Icons.message_rounded;
      case IconType.exam:
        return Icons.assignment_late_rounded;
      case IconType.devoir:
        return Icons.menu_book_rounded;
      case IconType.event:
        return Icons.event_available_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

Color _getTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'exam':
    case 'examen':
      return Colors.purpleAccent;
    case 'devoir':
    case 'assignment':
      return Colors.indigoAccent;
    case 'event':
    case 'evenement':
      return Colors.orangeAccent;
    case 'payment':
      return Colors.greenAccent;
    case 'message':
      return Colors.blueAccent;
    case 'location':
      return Colors.redAccent;
    default:
      return Colors.blueGrey;
  }
}

String _formatDate(String time) {
  try {
    final date = DateTime.parse(time);
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  } catch (e) {
    return time;
  }
}
