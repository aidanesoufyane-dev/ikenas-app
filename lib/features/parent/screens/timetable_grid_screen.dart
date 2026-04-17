import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../viewmodels/timetable_view_model.dart';

class TimetableGridScreen extends StatefulWidget {
  final StudentModel student;
  const TimetableGridScreen({super.key, required this.student});

  @override
  State<TimetableGridScreen> createState() => _TimetableGridScreenState();
}

class _TimetableGridScreenState extends State<TimetableGridScreen> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timetableVM = context.read<TimetableViewModel>();
      timetableVM.startPolling(widget.student.id);
      timetableVM.fetchTimetable(widget.student.id);
    });
  }

  @override
  void dispose() {
    context.read<TimetableViewModel>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      AppLocalizations.of(context)!.translate('mon_short'),
      AppLocalizations.of(context)!.translate('tue_short'),
      AppLocalizations.of(context)!.translate('wed_short'),
      AppLocalizations.of(context)!.translate('thu_short'),
      AppLocalizations.of(context)!.translate('fri_short'),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Consumer<TimetableViewModel>(
      builder: (context, vm, child) {
        // Filter timetable for selected day
        final dayTimetable = vm.timetable
            .where((item) => item.dayIndex == _selectedDayIndex)
            .toList();

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
            title: Text(
                AppLocalizations.of(context)!.translate('timetable_title'),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: primaryTextColor,
                    fontSize: 20,
                    letterSpacing: -0.5)),
            centerTitle: true,
          ),
          body: DeepSpaceBackground(
            showOrbs: true,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(
                      height: 24), // Reduced to bring layout closer to top
                  // Glassmorphic Day Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: days.asMap().entries.map((entry) {
                              int index = entry.key;
                              String dayName = entry.value;
                              final isSelected = _selectedDayIndex == index;
                              final selectedText = Colors.white;
                              final unselectedText =
                                  isDark ? Colors.white54 : Colors.black54;

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDayIndex = index),
                                  behavior: HitTestBehavior.opaque,
                                  child: AnimatedContainer(
                                    duration: 300.ms,
                                    curve: Curves.easeOutCubic,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              colors: [
                                                  Colors.blueAccent,
                                                  Colors.indigoAccent
                                                ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight)
                                          : null,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                  color: Colors.blueAccent
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4))
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        dayName,
                                        style: TextStyle(
                                          color: isSelected
                                              ? selectedText
                                              : unselectedText,
                                          fontWeight: isSelected
                                              ? FontWeight.w900
                                              : FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

                  const SizedBox(height: 24),

                  // Timetable List
                  Expanded(
                    child: vm.isLoading && vm.timetable.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : AnimatedSwitcher(
                            duration: 400.ms,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(0.05, 0),
                                        end: Offset.zero)
                                    .animate(animation),
                                child: child,
                              ),
                            ),
                            child: dayTimetable.isEmpty
                                ? Center(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('no_classes'),
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black38,
                                            fontWeight: FontWeight.bold)))
                                : ListView.builder(
                                    key: ValueKey(_selectedDayIndex),
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 8),
                                    itemCount: dayTimetable.length,
                                    itemBuilder: (context, index) {
                                      final item = dayTimetable[index];
                                      return _TimetableRow(
                                        time: item.time,
                                        subject: item.subject,
                                        teacher: item.teacher,
                                        room: item.room,
                                        isCanceled: item.isCanceled,
                                        isLive: item.isLive,
                                        index: index,
                                        isLast:
                                            index == dayTimetable.length - 1,
                                      )
                                          .animate()
                                          .fadeIn(delay: (index * 80).ms)
                                          .slideX(begin: 0.05);
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimetableRow extends StatelessWidget {
  final String time;
  final String subject;
  final String teacher;
  final String room;
  final bool isCanceled;
  final bool isLive;
  final int index;
  final bool isLast;

  const _TimetableRow({
    required this.time,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.isCanceled,
    required this.isLive,
    required this.index,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.indigoAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.amberAccent
    ];
    final color = colors[index % colors.length];

    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column
          SizedBox(
            width: 55,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    time.split(':')[0],
                    style: TextStyle(
                        color: isLive
                            ? Colors.blueAccent
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1),
                  ),
                  Text(
                    time.split(':')[1],
                    style: TextStyle(
                        color: isLive
                            ? Colors.blueAccent.withValues(alpha: 0.6)
                            : (isDark ? Colors.white38 : Colors.black38),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Timeline dot/line
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCanceled
                      ? Colors.redAccent
                      : (isLive ? Colors.blueAccent : color),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      width: 4),
                  boxShadow: [
                    if (isLive)
                      BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.6),
                          blurRadius: 15,
                          spreadRadius: 2),
                    BoxShadow(
                        color: isCanceled
                            ? Colors.redAccent.withValues(alpha: 0.4)
                            : color.withValues(alpha: 0.4),
                        blurRadius: 8)
                  ],
                ),
              )
                  .animate(
                      target: isLive ? 1 : 0,
                      onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(2)))),
            ],
          ),

          const SizedBox(width: 24),

          // Subject Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isLive
                    ? Colors.blueAccent.withValues(alpha: 0.05)
                    : (isCanceled
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.white)),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isLive
                      ? Colors.blueAccent.withValues(alpha: 0.3)
                      : (isCanceled
                          ? Colors.redAccent.withValues(alpha: 0.3)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.8))),
                  width: isLive ? 2 : 1,
                ),
                boxShadow: isLive
                    ? [
                        BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            blurRadius: 30,
                            spreadRadius: -5)
                      ]
                    : (isDark || isCanceled
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.7),
                                blurRadius: 20,
                                offset: const Offset(0, 5))
                          ]),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isLive
                                    ? Colors.blueAccent.withValues(alpha: 0.2)
                                    : (isCanceled
                                        ? Colors.redAccent
                                            .withValues(alpha: 0.2)
                                        : color.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isLive
                                    ? Icons.sensors_rounded
                                    : (isCanceled
                                        ? Icons.event_busy_rounded
                                        : Icons.menu_book_rounded),
                                color: isLive
                                    ? Colors.blueAccent
                                    : (isCanceled ? Colors.redAccent : color),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isLive) ...[
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('live_now')
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 2),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                subject,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: isCanceled
                                      ? Colors.redAccent
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)),
                                  letterSpacing: -0.5,
                                  decoration: isCanceled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (isCanceled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                    AppLocalizations.of(context)!
                                        .translate('canceled_upper'),
                                    style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                        letterSpacing: 1)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(
                            color: isDark ? Colors.white10 : Colors.white,
                            height: 1),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.person_rounded,
                                size: 16, color: secondaryTextColor),
                            const SizedBox(width: 8),
                            Text(teacher,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                            const Spacer(),
                            Icon(Icons.location_on_rounded,
                                size: 16, color: secondaryTextColor),
                            const SizedBox(width: 8),
                            Text(room,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
