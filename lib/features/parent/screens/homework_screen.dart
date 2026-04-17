import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/homework_view_model.dart';
import '../../../core/providers/app_state.dart';

class HomeworkScreen extends StatefulWidget {
  final String studentId;
  const HomeworkScreen({super.key, required this.studentId});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeworkVM = context.read<HomeworkViewModel>();
      homeworkVM.startPolling(widget.studentId);
      homeworkVM.fetchHomework(widget.studentId).then((_) {
        if (!mounted) return;
        homeworkVM.markAllAsSeen();
      });
    });
  }

  @override
  void dispose() {
    context.read<HomeworkViewModel>().stopPolling();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                shape: BoxShape.circle),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: primaryTextColor, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Devoirs / Examens',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: primaryTextColor,
                letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Consumer<HomeworkViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading && vm.homeworks.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              }

              if (vm.errorMessage != null && vm.homeworks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.orangeAccent.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(vm.errorMessage!,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => vm.fetchHomework(widget.studentId),
                        child: const Text("Réessayer"),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  const SizedBox(height: 16),

                  // ── TAB BAR ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTabBar(isDark),
                  ),

                  const SizedBox(height: 20),

                  // ── TAB VIEWS ──
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => vm.fetchHomework(widget.studentId),
                      color: Colors.blueAccent,
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Tab 1 — Devoirs
                          _buildTabContent(
                            context: context,
                            isDark: isDark,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            label: 'DEVOIRS',
                            icon: Icons.book_outlined,
                            accentColor: Colors.greenAccent,
                            items: vm.devoirsList,
                            emptyIcon: Icons.assignment_turned_in_rounded,
                            emptyLabel: 'Aucun devoir',
                            vm: vm,
                            animationOffset: 0,
                            showProgressHeader: true,
                          ),
                          // Tab 2 — Examens
                          _buildTabContent(
                            context: context,
                            isDark: isDark,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            label: 'EXAMENS',
                            icon: Icons.school_outlined,
                            accentColor: Colors.blueAccent,
                            items: vm.examsList,
                            emptyIcon: Icons.assignment_turned_in_rounded,
                            emptyLabel: 'Aucun examen',
                            vm: vm,
                            animationOffset: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _buildTabPill(0, 'Devoirs', Icons.book_outlined,
                  Colors.greenAccent, isDark),
              _buildTabPill(1, 'Examens', Icons.school_outlined,
                  Colors.blueAccent, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabPill(
      int index, String label, IconData icon, Color accent, bool isDark) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: isDark ? 0.22 : 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: isSelected
                ? Border.all(color: accent.withValues(alpha: 0.45), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: isSelected
                      ? accent
                      : (isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? accent
                      : (isDark ? Colors.white38 : Colors.black38),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required BuildContext context,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required String label,
    required IconData icon,
    required Color accentColor,
    required List<HomeworkModel> items,
    required IconData emptyIcon,
    required String emptyLabel,
    required HomeworkViewModel vm,
    required int animationOffset,
    bool showProgressHeader = false,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      children: [
        if (showProgressHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildProgressHeader(context, isDark, vm),
          ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Icon(emptyIcon,
                    size: 64, color: accentColor.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(emptyLabel,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ],
            ),
          )
        else
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            return _HomeworkListItem(
              homework: item,
              onStatusUpdate: (status, {String? filePath}) => vm.updateStatus(
                  item.id, widget.studentId, status,
                  filePath: filePath),
            ).animate().fadeIn(delay: (entry.key * 100).ms).slideY(begin: 0.06);
          }),
      ],
    );
  }

  Widget _buildProgressHeader(
      BuildContext context, bool isDark, HomeworkViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    final progression = vm.progressionRate;
    final label = vm.progressionLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          AppLocalizations.of(context)!
                              .translate('week_progression')
                              .toUpperCase(),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                          '${progression.toInt()}% ${AppLocalizations.of(context)!.translate('completed_percent')}',
                          style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              letterSpacing: -1)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.3),
                          width: 2),
                    ),
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 2.seconds),
                ],
              ),
              const SizedBox(height: 32),
              LayoutBuilder(builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 12,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: 1.seconds,
                      curve: Curves.easeOutCubic,
                      height: 12,
                      width: constraints.maxWidth * (progression / 100),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.greenAccent, Colors.tealAccent]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.4),
                              blurRadius: 10)
                        ],
                      ),
                    ).animate().slideX(
                        begin: -1,
                        duration: 800.ms,
                        curve: Curves.easeOutQuart),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }
}

class _HomeworkListItem extends StatefulWidget {
  final HomeworkModel homework;
  final Future<bool> Function(HomeworkStatus, {String? filePath})
      onStatusUpdate;

  const _HomeworkListItem(
      {required this.homework, required this.onStatusUpdate});

  @override
  State<_HomeworkListItem> createState() => _HomeworkListItemState();
}

class _HomeworkListItemState extends State<_HomeworkListItem> {
  bool _isMarkingDone = false;

  HomeworkModel get homework => widget.homework;

  Future<void> _markAsDone() async {
    if (_isMarkingDone) return;
    setState(() => _isMarkingDone = true);
    final success = await widget.onStatusUpdate(HomeworkStatus.done);
    if (!mounted) return;
    setState(() => _isMarkingDone = false);
    final msg = success
        ? 'Devoir marqué comme terminé !'
        : 'Erreur, veuillez réessayer';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: success ? Colors.greenAccent.shade700 : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    Color statusColor;
    String statusLabel;
    switch (homework.status) {
      case HomeworkStatus.notStarted:
        statusColor = isDark ? Colors.white38 : Colors.black38;
        statusLabel = homework.type == 'exam'
            ? 'NON VU'
            : AppLocalizations.of(context)!.translate('not_started');
        break;
      case HomeworkStatus.inProgress:
        statusColor = Colors.orangeAccent;
        statusLabel = AppLocalizations.of(context)!.translate('in_progress');
        break;
      case HomeworkStatus.done:
        statusColor = Colors.greenAccent;
        statusLabel = homework.type == 'exam'
            ? 'VU'
            : AppLocalizations.of(context)!.translate('done_status');
        break;
      case HomeworkStatus.late:
        statusColor = Colors.redAccent;
        statusLabel = AppLocalizations.of(context)!.translate('late_status');
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: 400.ms,
          curve: Curves.easeOutQuart,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.8),
            gradient: homework.type == 'exam' && isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blueAccent.withValues(alpha: 0.05),
                      Colors.purpleAccent.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
                color: homework.type == 'exam'
                    ? Colors.blueAccent.withValues(alpha: 0.5)
                    : statusColor.withValues(alpha: 0.3),
                width: (homework.status == HomeworkStatus.done ||
                        homework.type == 'exam')
                    ? 2
                    : 1),
            boxShadow: homework.type == 'exam'
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (homework.type != 'exam')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusLabel.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.5),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: secondaryTextColor),
                          const SizedBox(width: 6),
                          Text(homework.startDate,
                              style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text(
                  homework.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: homework.status == HomeworkStatus.done
                        ? secondaryTextColor
                        : primaryTextColor,
                    decoration: homework.status == HomeworkStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(homework.subject,
                    style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 14,
                        color: secondaryTextColor.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text(
                      "Prof: ${homework.teacherName == 'Unknown' ? AppLocalizations.of(context)!.translate('unknown_prof') : homework.teacherName}",
                      style: TextStyle(
                          color: secondaryTextColor.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          AppLocalizations.of(context)!
                              .translate('instructions_desc'),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(
                        homework.description,
                        style: TextStyle(
                          color: primaryTextColor.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (homework.attachment != null &&
                          homework.attachment!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final url = Uri.parse(homework.attachment!);
                            try {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } catch (e) {
                              debugPrint('Error launching URL: $e');
                              // Fallback
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attach_file,
                                    color: Colors.blueAccent, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                    AppLocalizations.of(context)!
                                        .translate('view_attachment'),
                                    style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // --- ACTION BUTTONS ---
                if (homework.status == HomeworkStatus.done) ...[
                  // ── Already done ──
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                          AppLocalizations.of(context)!
                              .translate('verified_status'),
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ] else if (homework.type != 'exam') ...[
                  const SizedBox(height: 24),
                  if (Provider.of<AppState>(context, listen: false).isParent)
                    // ── Parent: simple "Terminé" button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isMarkingDone ? null : _markAsDone,
                        icon: _isMarkingDone
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline_rounded,
                                size: 18, color: Colors.white),
                        label: Text(
                          _isMarkingDone ? 'Envoi...' : 'Terminé',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMarkingDone
                              ? Colors.greenAccent.withValues(alpha: 0.4)
                              : Colors.greenAccent.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    )
                  else ...[
                    // ── Teacher/student: upload dialog + in-progress ──
                    Row(
                      children: [
                        _buildActionButton(
                          context,
                          AppLocalizations.of(context)!
                              .translate('done_status'),
                          Icons.check_circle_outline_rounded,
                          Colors.greenAccent,
                          () => _showUploadDialog(context, isDark),
                        ),
                        if (homework.status == HomeworkStatus.notStarted) ...[
                          const SizedBox(width: 16),
                          _buildActionButton(
                            context,
                            AppLocalizations.of(context)!
                                .translate('in_progress'),
                            Icons.pending_actions_rounded,
                            Colors.orangeAccent,
                            () => widget
                                .onStatusUpdate(HomeworkStatus.inProgress),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, bool isDark) {
    final loc = AppLocalizations.of(context)!;
    String? pickedFilePath;
    String? pickedFileName;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(36)),
            ),
            padding: EdgeInsets.fromLTRB(
                32, 24, 32, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 32),
                const Icon(Icons.cloud_upload_outlined,
                    size: 64, color: Colors.blueAccent),
                const SizedBox(height: 16),
                Text(
                  loc.translate('submit_homework_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.translate('submit_homework_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 13),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'pdf', 'doc', 'png', 'jpeg'],
                    );
                    if (result != null) {
                      setState(() {
                        pickedFilePath = result.files.single.path;
                        pickedFileName = result.files.single.name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Icon(
                            pickedFileName != null
                                ? Icons.check_circle_outline
                                : Icons.add_photo_alternate_outlined,
                            color: pickedFileName != null
                                ? Colors.green
                                : Colors.blueAccent,
                            size: 32),
                        const SizedBox(height: 12),
                        Text(
                          pickedFileName ?? loc.translate('add_file_hint'),
                          style: TextStyle(
                              color: pickedFileName != null
                                  ? Colors.green
                                  : Colors.blueAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          setState(() {
                            isUploading = true;
                          });

                          final success = await widget.onStatusUpdate(
                              HomeworkStatus.done,
                              filePath: pickedFilePath);

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  loc.translate('homework_sent_success'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.greenAccent.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          } else {
                            final errorMsg = context
                                    .read<HomeworkViewModel>()
                                    .errorMessage ??
                                'Erreur lors de l\'envoi du devoir';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Erreur: $errorMsg',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUploading
                        ? Colors.blueAccent.withValues(alpha: 0.5)
                        : Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          loc.translate('send_finish_button'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1)),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
