import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'suivi_scolaire_screen.dart';
import 'feed_screen.dart';
import 'payment_screen.dart';
import 'chat_screen.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/screens/notifications_screen.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models/models.dart';
import 'location_screen.dart';
import 'homework_screen.dart';
import 'timetable_grid_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/widgets/sprite_avatar.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/feed_view_model.dart';
import '../viewmodels/homework_view_model.dart';
import '../viewmodels/event_view_model.dart';
import '../../common/viewmodels/notification_view_model.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      const _ParentHome(),
      const FeedScreen(),
      const ChatScreen(),
      const PaymentScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: DeepSpaceBackground(
        showOrbs: true,
        child: pages[appState.dashboardIndex],
      ),
      bottomNavigationBar: _buildBottomNav(isDark, appState),
    );
  }

  Widget _buildBottomNav(bool isDark, AppState appState) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                    Icons.home_rounded,
                    AppLocalizations.of(context)!.translate('home'),
                    0,
                    isDark,
                    appState),
                _buildNavItem(
                    Icons.feed_rounded,
                    AppLocalizations.of(context)!.translate('feed_nav'),
                    1,
                    isDark,
                    appState),
                _buildNavItem(
                    Icons.chat_bubble_outline_rounded,
                    AppLocalizations.of(context)!.translate('messages'),
                    2,
                    isDark,
                    appState),
                _buildNavItem(
                    Icons.payment_rounded,
                    AppLocalizations.of(context)!.translate('payments_nav'),
                    3,
                    isDark,
                    appState),
                _buildNavItem(
                    Icons.person_outline_rounded,
                    AppLocalizations.of(context)!.translate('profile_nav'),
                    4,
                    isDark,
                    appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, bool isDark, AppState appState) {
    final isActive = appState.dashboardIndex == index;
    final activeColor = Colors.white;
    final inactiveColor = isDark ? const Color(0xFF64748B) : Colors.black38;

    return GestureDetector(
      onTap: () => appState.setDashboardIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Colors.blueAccent, Color.fromRGBO(83, 109, 254, 1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : inactiveColor,
          size: 24,
        ),
      ),
    );
  }
}

class _ParentHome extends StatefulWidget {
  const _ParentHome();

  @override
  State<_ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<_ParentHome> {
  int _currentPostIndex = 0;
  String _selectedSemester = 'all'; // Default to Both/All
  late PageController _urgentPageController;

  @override
  void dispose() {
    _urgentPageController.dispose();

    // Stop real-time polling
    context.read<DashboardViewModel>().stopPolling();
    context.read<FeedViewModel>().stopPolling();
    context.read<NotificationViewModel>().stopPolling();
    context.read<EventViewModel>().stopPolling();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedSemester = 'all'; // Default to all/both
    _urgentPageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardVM = context.read<DashboardViewModel>();
      final feedVM = context.read<FeedViewModel>();
      final notifVM = context.read<NotificationViewModel>();
      final eventVM = context.read<EventViewModel>();

      // Start real-time polling (1s interval)
      dashboardVM.startPolling();
      feedVM.startPolling(
          currentUserName: context.read<AppState>().currentUser?.name);
      notifVM.startPolling();
      eventVM.startPolling();

      // Initialize viewmodels and load cached data
      dashboardVM.init().then((_) {
        if (!mounted) return;

        // Fetch initial evolution and homework for the first child if available
        if (dashboardVM.children.isNotEmpty) {
          final studentId = dashboardVM.children[0].id;
          dashboardVM.fetchSubjectAverages(semester: _selectedSemester);
          context.read<HomeworkViewModel>().fetchHomework(studentId);
        }
      });

      eventVM.init();
    });
  }

  void _showPostDetails(BuildContext context, dynamic post) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = (post is PostModel && post.isUrgent)
        ? Colors.redAccent
        : Colors.blueAccent;
    final dashVM = context.read<DashboardViewModel>();

    // Load cached participation response from SharedPreferences
    String? currentResponse = post.participationStatus;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStatus = prefs.getString('event_participation_${post.id}');
      if (cachedStatus != null) {
        currentResponse = cachedStatus;
        debugPrint('Loaded cached participation status for ${post.id}: $cachedStatus');
      }
    } catch (e) {
      debugPrint('Error loading cached participation status: $e');
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        bool isSubmitting = false;
        String? successMessage;
        String? errorMessage;
        return StatefulBuilder(builder: (context, setModalState) {

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Stack(
                children: [
                  // Top handle
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 20,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            color: isDark ? Colors.white60 : Colors.black54,
                            size: 20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: accentColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars_rounded,
                                  color: accentColor, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                (post is PostModel && post.isEvent)
                                    ? 'ÉVÉNEMENT'
                                    : 'ÉVÉNTS',
                                style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          post is PostModel
                              ? (post.title.isNotEmpty
                                  ? post.title
                                  : "Information")
                              : (post is EventModel ? post.title : "Événement"),
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Display Date and Location
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 14,
                                color:
                                    isDark ? Colors.white38 : Colors.black38),
                            const SizedBox(width: 8),
                            Text(
                              () {
                                final rawDate = post is PostModel
                                    ? (post.eventDate ?? post.date)
                                    : (post is EventModel ? post.date : "");
                                try {
                                  DateTime? dt = rawDate is DateTime
                                      ? (rawDate as DateTime)
                                      : DateTime.tryParse(rawDate.toString());
                                  if (dt == null) return rawDate.toString();
                                  const months = [
                                    'Janvier',
                                    'Février',
                                    'Mars',
                                    'Avril',
                                    'Mai',
                                    'Juin',
                                    'Juillet',
                                    'Août',
                                    'Septembre',
                                    'Octobre',
                                    'Novembre',
                                    'Décembre'
                                  ];
                                  return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}";
                                } catch (_) {
                                  return rawDate.toString();
                                }
                              }(),
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            if ((post is EventModel && post.location != null) ||
                                (post is PostModel &&
                                    post.content.contains('Salle'))) ...[
                              const SizedBox(width: 20),
                              Icon(Icons.location_on_rounded,
                                  size: 14,
                                  color:
                                      isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 8),
                              Text(
                                post is EventModel
                                    ? (post.location ?? "Salle A")
                                    : "Scolaire",
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 24),
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                post is PostModel
                                    ? post.content
                                    : (post is EventModel
                                        ? post.description
                                        : (post as HomeworkModel).title),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : const Color(0xFF334155),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Participation Section
                        if (post is PostModel && post.isEvent ||
                            post is EventModel)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: accentColor.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Allez-vous participer à cet événement ?",
                                  style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: isSubmitting
                                            ? null
                                            : () async {
                                                setModalState(
                                                    () => isSubmitting = true);
                                                bool ok = false;
                                                if (post is EventModel) {
                                                  ok = await context
                                                      .read<EventViewModel>()
                                                      .respondToEvent(
                                                          post.id, 'going');
                                                } else {
                                                  ok = await dashVM
                                                      .submitParticipation(
                                                          post, 'going');
                                                }
                                                if (ok) {
                                                  setModalState(() {
                                                    currentResponse = 'going';
                                                    successMessage =
                                                        ' ✓ Votre réponse a été enregistrée avec succès !';
                                                    errorMessage = null;
                                                  });
                                                } else {
                                                  setModalState(() {
                                                    errorMessage =
                                                        'Une erreur s\'est produite lors de l\'envoi de la réponse.';
                                                  });
                                                }
                                                setModalState(
                                                    () => isSubmitting = false);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: currentResponse ==
                                                      'going' ||
                                                  currentResponse == 'oui' ||
                                                  currentResponse ==
                                                      'present' ||
                                                  currentResponse == 'yes'
                                              ? Colors.green
                                              : (isDark
                                                  ? Colors.white10
                                                  : Colors.black
                                                      .withValues(alpha: 0.05)),
                                          foregroundColor: currentResponse ==
                                                      'going' ||
                                                  currentResponse == 'oui' ||
                                                  currentResponse ==
                                                      'present' ||
                                                  currentResponse == 'yes'
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        child: isSubmitting &&
                                                currentResponse == null
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                            : const Text("OUI, JE PARTICIPE",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: isSubmitting
                                            ? null
                                            : () async {
                                                setModalState(
                                                    () => isSubmitting = true);
                                                bool ok = false;
                                                if (post is EventModel) {
                                                  ok = await context
                                                      .read<EventViewModel>()
                                                      .respondToEvent(
                                                          post.id, 'not_going');
                                                } else {
                                                  ok = await dashVM
                                                      .submitParticipation(
                                                          post, 'not_going');
                                                }
                                                if (ok) {
                                                  setModalState(() {
                                                    currentResponse =
                                                        'not_going';
                                                    successMessage =
                                                        '✓ Votre réponse a été enregistrée avec succès !';
                                                    errorMessage = null;
                                                  });
                                                } else {
                                                  setModalState(() {
                                                    errorMessage =
                                                        'Une erreur s\'est produite lors de l\'envoi de la réponse.';
                                                  });
                                                }
                                                setModalState(
                                                    () => isSubmitting = false);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: currentResponse ==
                                                      'not_going' ||
                                                  currentResponse == 'non' ||
                                                  currentResponse ==
                                                      'not_going' ||
                                                  currentResponse == 'absent' ||
                                                  currentResponse == 'no'
                                              ? Colors.redAccent
                                              : (isDark
                                                  ? Colors.white10
                                                  : Colors.black
                                                      .withValues(alpha: 0.05)),
                                          foregroundColor: currentResponse ==
                                                      'not_going' ||
                                                  currentResponse == 'non' ||
                                                  currentResponse ==
                                                      'not_going' ||
                                                  currentResponse == 'absent' ||
                                                  currentResponse == 'no'
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        child: const Text("NON",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                                if (errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.redAccent, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: Colors.redAccent,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              errorMessage!,
                                              style: const TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (successMessage != null &&
                                    errorMessage == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.green, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline,
                                              color: Colors.green, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              successMessage!,
                                              style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (currentResponse != null &&
                                    successMessage == null &&
                                    errorMessage == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      "Ton état: ${(currentResponse == 'going' || currentResponse == 'oui' || currentResponse == 'present' || currentResponse == 'yes') ? ' ✓ Présent' : ' ✗ Absence'}",
                                      style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (post is PostModel) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: accentColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.authorName,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        post.authorRole,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black45,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer3<FeedViewModel, DashboardViewModel, EventViewModel>(
      builder: (context, feedVM, dashVM, eventVM, child) {
        final appState = Provider.of<AppState>(context);

        // Sort events from newest to oldest
        final List<dynamic> dashboardEvents = List.from(eventVM.events);
        dashboardEvents.sort((a, b) {
          DateTime? dateA;
          DateTime? dateB;

          if (a is EventModel) {
            dateA = a.createdAt != null
                ? DateTime.tryParse(a.createdAt.toString())
                : null;
          } else if (a is PostModel) {
            // Mixed fallback if they are PostModels
            dateA = a.date is DateTime
                ? a.date as DateTime
                : DateTime.tryParse(a.date.toString());
          }

          if (b is EventModel) {
            dateB = b.createdAt != null
                ? DateTime.tryParse(b.createdAt.toString())
                : null;
          } else if (b is PostModel) {
            dateB = b.date is DateTime
                ? b.date as DateTime
                : DateTime.tryParse(b.date.toString());
          }

          dateA ??= DateTime.fromMillisecondsSinceEpoch(0);
          dateB ??= DateTime.fromMillisecondsSinceEpoch(0);

          return dateB.compareTo(dateA);
        });
        final isOffline = appState.isOffline;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: (dashVM.isLoading && dashVM.children.isEmpty)
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent))
              : dashVM.errorMessage != null && dashVM.children.isEmpty
                  ? _buildErrorPlaceholder(
                      context, dashVM.errorMessage!, dashVM.init)
                  : SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          if (isOffline) _buildOfflineBanner(context),
                          _buildHeader(context, isDark)
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: -0.2),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 40),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          AppLocalizations.of(context)!
                                              .translate('hello'),
                                          style: TextStyle(
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.5)),
                                      const SizedBox(height: 4),
                                      Consumer2<AppState, DashboardViewModel>(
                                        builder:
                                            (context, appState, dashVM, child) {
                                          final user = appState.currentUser;
                                          final firstChild =
                                              dashVM.children.isNotEmpty
                                                  ? dashVM.children[0]
                                                  : null;
                                          String displayName = user?.name ?? '';
                                          if (displayName.isEmpty ||
                                              displayName
                                                  .toLowerCase()
                                                  .contains('parent')) {
                                            if (firstChild != null) {
                                              displayName =
                                                  'Parent de ${firstChild.name.split(' ')[0]}';
                                            } else {
                                              displayName = 'Parent';
                                            }
                                          }
                                          return Text('$displayName 👋',
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 32,
                                                  letterSpacing: -1,
                                                  shadows: [
                                                    if (isDark)
                                                      Shadow(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 15,
                                                      )
                                                  ]));
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  if (dashboardEvents.isNotEmpty)
                                    _buildUrgentCarouselContainer(
                                        context, dashboardEvents, isDark),
                                  const SizedBox(height: 48),
                                  _buildQuickActions(context, isDark),
                                  const SizedBox(height: 48),
                                  _buildComparisonChart(context, isDark),
                                  const SizedBox(height: 48),
                                  _buildRecentActivities(context, isDark),
                                  const SizedBox(height: 120),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildRecentActivities(BuildContext context, bool isDark) {
    final dashVM = context.watch<DashboardViewModel>();
    final agenda = dashVM.todayAgenda;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "L'AGENDA D'AUJOURD'HUI",
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2),
            ),
            if (agenda.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${agenda.length} AU PROGRAMME",
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (agenda.isEmpty)
          _buildEmptyAgenda(context, isDark)
        else
          Stack(
            children: [
              // Vertical Timeline Line
              Positioned(
                left: 31,
                top: 40,
                bottom: 40,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0),
                        Colors.blueAccent.withValues(alpha: 0.2),
                        Colors.blueAccent.withValues(alpha: 0)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Column(
                children: List.generate(agenda.length, (index) {
                  return _ActivityPlatinumTile(
                      activity: agenda[index], isDark: isDark);
                }),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyAgenda(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 48,
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            "Rien de prévu pour aujourd'hui",
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Profitez d'une journée tranquille !",
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.orangeAccent,
          Colors.deepOrangeAccent.withValues(alpha: 0.8)
        ]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.translate('offline_mode'),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 2),
          ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0);
  }

  Widget _buildErrorPlaceholder(
      BuildContext context, String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 80, color: Colors.blueAccent.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.translate(message),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.translate('check_connection'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                  AppLocalizations.of(context)!
                      .translate('retry_btn')
                      .toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.02);
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: Image.asset(
                  'assets/images/image3.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text('Ikenas',
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: secondaryBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderCol),
                      ),
                      child: Icon(Icons.notifications_none_rounded,
                          color: primaryColor, size: 20),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.5),
                        width: 1.5),
                  ),
                  child: user?.avatarIndex != null
                      ? SpriteAvatar(index: user!.avatarIndex!, size: 34)
                      : CircleAvatar(
                          radius: 17,
                          backgroundColor: secondaryBg,
                          child: Icon(Icons.person_rounded,
                              color: primaryColor.withValues(alpha: 0.6),
                              size: 20),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentCarouselContainer(
      BuildContext context, List<dynamic> events, bool isDark) {
    if (events.isEmpty) return const SizedBox.shrink();
    final totalPosts = events.length;

    String formatAdminDate(dynamic dateVal) {
      if (dateVal == null || dateVal.toString().isEmpty) return "";
      try {
        DateTime? dt = dateVal is DateTime
            ? dateVal
            : DateTime.tryParse(dateVal.toString());
        if (dt == null) return dateVal.toString().substring(0, 5);
        const months = [
          'Janvier',
          'Février',
          'Mars',
          'Avril',
          'Mai',
          'Juin',
          'Juillet',
          'Août',
          'Septembre',
          'Octobre',
          'Novembre',
          'Décembre'
        ];
        return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}";
      } catch (_) {
        return "";
      }
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF38222A) : const Color(0xFFFBE4EA),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF452431), const Color(0xFF301B22)]
              : [
                  Colors.redAccent.withValues(alpha: 0.15),
                  Colors.pinkAccent.withValues(alpha: 0.05)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: isDark ? 0.05 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                setState(() {
                  _currentPostIndex = (_currentPostIndex + 1) % totalPosts;
                });
              } else if (details.primaryVelocity! > 0) {
                setState(() {
                  _currentPostIndex = _currentPostIndex > 0
                      ? _currentPostIndex - 1
                      : totalPosts - 1;
                });
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale:
                        Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Builder(
                key: ValueKey<int>(_currentPostIndex),
                builder: (context) {
                  final item = events[_currentPostIndex];
                  final currentIndex = _currentPostIndex;

                  final String category = (item is PostModel && item.isUrgent)
                      ? 'URGENT'
                      : (item is HomeworkModel ? 'EXAMEN' : 'ÉVÉNEMENT');

                  final String adminSentDate = formatAdminDate(item is PostModel
                      ? item.date
                      : (item is EventModel ? item.createdAt : ""));

                  final String title = item is PostModel
                      ? (item.title.isNotEmpty ? item.title : item.content)
                      : (item is EventModel
                          ? item.title
                          : (item is HomeworkModel ? item.title : ""));

                  return GestureDetector(
                    onTap: () => _showPostDetails(context, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                        category == 'URGENT'
                                            ? Icons.warning_rounded
                                            : Icons.event_note_rounded,
                                        color: Colors.redAccent,
                                        size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      category,
                                      style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${currentIndex + 1}/$totalPosts',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    adminSentDate,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: -0.7,
                                  height: 1.1),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (totalPosts > 1)
                                  Row(
                                    children: [
                                      Visibility(
                                        visible: currentIndex > 0,
                                        maintainSize: true,
                                        maintainAnimation: true,
                                        maintainState: true,
                                        child: _buildNavArrow(
                                          icon: Icons.chevron_left_rounded,
                                          onTap: () {
                                            setState(() {
                                              _currentPostIndex =
                                                  _currentPostIndex > 0
                                                      ? _currentPostIndex - 1
                                                      : totalPosts - 1;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Visibility(
                                        visible: currentIndex < totalPosts - 1,
                                        maintainSize: true,
                                        maintainAnimation: true,
                                        maintainState: true,
                                        child: _buildNavArrow(
                                          icon: Icons.chevron_right_rounded,
                                          onTap: () {
                                            setState(() {
                                              _currentPostIndex =
                                                  (_currentPostIndex + 1) %
                                                      totalPosts;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox.shrink(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.1)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .translate('view_details')
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            letterSpacing: 1.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          size: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms);
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.translate('quick_nav').toUpperCase(),
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionIcon(
                context,
                AppLocalizations.of(context)!.translate('timetable'),
                Icons.grid_view_rounded,
                Colors.purpleAccent,
                null,
                isDark, onTap: () {
              final children = context.read<DashboardViewModel>().children;
              if (children.isNotEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            TimetableGridScreen(student: children[0])));
              }
            }),
            Consumer<HomeworkViewModel>(
              builder: (context, homeworkVM, child) => _buildActionIcon(
                  context,
                  'Devoir/Examen',
                  Icons.assignment_rounded,
                  Colors.orangeAccent,
                  null,
                  isDark,
                  showBadge: homeworkVM.hasNewAssignments, onTap: () {
                final dashVM = context.read<DashboardViewModel>();
                if (dashVM.children.isNotEmpty) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => HomeworkScreen(
                              studentId: dashVM.children[0].id)));
                }
              }),
            ),
            _buildActionIcon(
                context,
                AppLocalizations.of(context)!.translate('trip'),
                Icons.location_on_rounded,
                Colors.blueAccent,
                null,
                isDark, onTap: () {
              final children = context.read<DashboardViewModel>().children;
              if (children.isNotEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LocationScreen(student: children[0])));
              }
            }),
            _buildActionIcon(
                context,
                AppLocalizations.of(context)!.translate('Suivi scolaire'),
                Icons.bar_chart_rounded,
                Colors.greenAccent,
                null,
                isDark, onTap: () {
              final children = context.read<DashboardViewModel>().children;
              if (children.isEmpty) return;
              final student = children[0];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SuiviScolaireScreen(
                    student: student,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(BuildContext context, String label, IconData icon,
      Color color, Widget? screen, bool isDark,
      {VoidCallback? onTap, bool showBadge = false}) {
    return GestureDetector(
      onTap: onTap ??
          () {
            if (screen != null) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => screen));
            }
          },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ),
              if (showBadge)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ],
      ),
    ).animate().scale();
  }

  Widget _buildComparisonChart(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white54 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Évolution Globale',
                style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            const Spacer(),
            _buildChartSelector(
              _selectedSemester == 'all'
                  ? 'Année Complète'
                  : (_selectedSemester == 'S1' ? 'Semestre 1' : 'Semestre 2'),
              ['S1', 'S2', 'all'],
              (val) {
                setState(() => _selectedSemester = val);
                context
                    .read<DashboardViewModel>()
                    .fetchSubjectAverages(semester: val);
              },
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 320,
          padding: const EdgeInsets.fromLTRB(16, 40, 24, 20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 10,
                    gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.black.withValues(alpha: 0.03),
                            strokeWidth: 1,
                            dashArray: [10, 5])),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(value.toInt().toString(),
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900)),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value != value.toInt())
                              return const SizedBox.shrink();
                            final avgs = context
                                .read<DashboardViewModel>()
                                .subjectAverages;
                            if (value.toInt() >= 0 &&
                                value.toInt() < avgs.length) {
                              final subject =
                                  avgs[value.toInt()]['subject'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  subject.toUpperCase().replaceAll(' ', '\n'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            isDark ? const Color(0xFF0F172A) : Colors.white,
                        tooltipBorderRadius: BorderRadius.circular(16),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final avgs = context
                                .read<DashboardViewModel>()
                                .subjectAverages;
                            final index = touchedSpot.x.toInt();
                            if (index < 0 || index >= avgs.length) return null;
                            final subject = avgs[index]['subject'] as String;
                            final grade = touchedSpot.y.toStringAsFixed(2);
                            return LineTooltipItem(
                              '$subject\n',
                              TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              children: [
                                TextSpan(
                                  text: grade,
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: context
                                .watch<DashboardViewModel>()
                                .subjectAverages
                                .isEmpty
                            ? const [FlSpot(0, 0)]
                            : context
                                .watch<DashboardViewModel>()
                                .subjectAverages
                                .map((e) => FlSpot(
                                    (e['index'] as num).toDouble(),
                                    (e['grade'] as num).toDouble()))
                                .toList(),
                        isCurved: true,
                        curveSmoothness: 0.4,
                        gradient: const LinearGradient(
                          colors: [
                            Colors.cyanAccent,
                            Colors.blueAccent,
                          ],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Colors.blueAccent,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent.withValues(alpha: 0.15),
                              Colors.blueAccent.withValues(alpha: 0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: context
                    .read<DashboardViewModel>()
                    .children
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final child = entry.value;
                  const color = Colors.blueAccent;
                  return Row(
                    children: [
                      _buildLegendItem(child.name.split(' ')[0], color, isDark),
                      if (index <
                          context.read<DashboardViewModel>().children.length -
                              1)
                        const SizedBox(width: 40),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildChartSelector(String value, List<String> options,
      Function(String) onChanged, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => options.map((opt) {
        String label = opt == 'all'
            ? 'Année Complète'
            : (opt == 'S1' ? 'Semestre 1' : 'Semestre 2');
        return PopupMenuItem(
          value: opt,
          child: Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(value,
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.w900)),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: isDark ? Colors.white38 : Colors.black38)
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String name, Color color, bool isDark) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)
                ])),
        const SizedBox(width: 8),
        Text(name,
            style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ActivityPlatinumTile extends StatelessWidget {
  final dynamic activity;
  final bool isDark;
  const _ActivityPlatinumTile({required this.activity, required this.isDark});

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'session':
        return 'SÉANCE';
      case 'exam':
      case 'exam_result':
        return 'EXAMEN';
      case 'absence':
        return 'ABSENCE';
      case 'homework':
        return 'DEVOIR';
      case 'event':
        return 'ÉVÉNEMENT';
      default:
        return 'ACTIVITÉ';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'session':
        return Icons.schedule_rounded;
      case 'exam':
      case 'exam_result':
        return Icons.assignment_turned_in_rounded;
      case 'absence':
        return Icons.event_busy_rounded;
      case 'homework':
        return Icons.menu_book_rounded;
      case 'event':
        return Icons.event_available_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final color = (activity['color'] as Color?) ?? Colors.blueAccent;
    final location = activity['location'] as String?;
    final type = activity['type'] as String? ?? 'activity';

    return GestureDetector(
      // onTap: () => _showDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A).withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getTypeIcon(type),
                color: color,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTypeLabel(type),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      if (activity['time'] != null)
                        Text(
                          activity['time'],
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activity['title'] ?? '',
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3),
                  ),
                  if ((activity['content'] as String?)?.isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 4),
                    Text(
                      activity['content']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12,
                            color: isDark ? Colors.white24 : Colors.black26),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(
                            color: isDark ? Colors.white24 : Colors.black26,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
