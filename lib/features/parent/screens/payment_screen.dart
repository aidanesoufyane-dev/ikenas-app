import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/models/models.dart';
import '../viewmodels/payment_view_model.dart';

// ─── Main Screen ──────────────────────────────────────────────────────────────
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentVM = context.read<PaymentViewModel>();
      paymentVM.startPolling();
      paymentVM.fetchPayments();
    });
  }

  @override
  void dispose() {
    context.read<PaymentViewModel>().stopPolling();
    super.dispose();
  }

  // ── Yearly Summary Card ─────────────────────────────────────────────────────
  Widget _buildYearlySummary(PaymentViewModel vm) {
    final paid = vm.paidCount;
    final total = vm.monthGroups.length;
    final progress = vm.progressionRate;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E3A5F).withValues(alpha: 0.9),
                  const Color(0xFF0D1B2A).withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate('year_summary_range'),
                          style: TextStyle(
                            color: Colors.blueAccent.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$paid / $total ${AppLocalizations.of(context)!.translate('months_paid_count')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          Colors.blueAccent.withValues(alpha: 0.3),
                          Colors.blueAccent.withValues(alpha: 0.05),
                        ]),
                        border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.blueAccent, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    LayoutBuilder(builder: (context, constraints) {
                      return AnimatedContainer(
                        duration: 1200.ms,
                        curve: Curves.easeOutCubic,
                        height: 6,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF60A5FA), Color(0xFF34D399)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statPill(AppLocalizations.of(context)!.translate('paid'),
                        '$paid', Colors.greenAccent),
                    _statPill(
                        AppLocalizations.of(context)!.translate('overdue'),
                        '${vm.overdueCount}',
                        Colors.redAccent),
                    _statPill(
                        AppLocalizations.of(context)!.translate('pending'),
                        '${vm.pendingCount}',
                        Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }

  Widget _statPill(String label, String value, Color color) {
    return Row(
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── Month Card ──────────────────────────────────────────────────────────────
  Widget _buildMonthCard(
      MonthPaymentGroup group, int index, bool isDark, PaymentViewModel vm) {
    final loc = AppLocalizations.of(context)!;

    // Logic for identifying specifically the color theme
    final isCurrentMonth = group.month.toLowerCase() == vm.currentMonthName;

    // Check for mixed state (for Orange)
    // Mixed means: at least one service exists AND (one is paid while other is not)
    bool isMixed = false;
    if (group.scolarity != null && group.transport != null) {
      if (group.scolarityPaid != group.transportPaid) {
        isMixed = true;
      }
    }

    // All existing items are overdue (for Red)
    bool allOverdue = true;
    if (group.scolarity != null && !group.scolarityOverdue) allOverdue = false;
    if (group.transport != null && !group.transportOverdue) allOverdue = false;
    if (group.scolarity == null && group.transport == null) allOverdue = false;

    // Colors base setup
    Color glowColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7);
    Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.9);
    Color labelColor = isDark ? Colors.white60 : Colors.black54;

    if (isCurrentMonth) {
      // 1. Current Month (Blue - Priority 1)
      glowColor = isDark
          ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
          : const Color(0xFFDBEAFE);
      borderColor = isDark
          ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
          : const Color(0xFF3B82F6).withValues(alpha: 0.3);
      labelColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    } else if (group.allPaid) {
      // 2. All Paid (Green - Priority 2)
      glowColor = isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.3)
          : const Color(0xFFD1FAE5);
      borderColor = isDark
          ? const Color(0xFF10B981).withValues(alpha: 0.4)
          : const Color(0xFF10B981).withValues(alpha: 0.3);
      labelColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    } else if (allOverdue) {
      // 3. All Overdue (Red - Priority 3)
      glowColor = isDark
          ? const Color(0xFF450A0A).withValues(alpha: 0.3)
          : const Color(0xFFFEE2E2);
      borderColor = isDark
          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
          : const Color(0xFFEF4444).withValues(alpha: 0.3);
      labelColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    } else if (isMixed || group.anyPaid) {
      // 4. Mixed (Orange - Priority 4)
      glowColor = isDark
          ? const Color(0xFF431407).withValues(alpha: 0.3)
          : const Color(0xFFFFF7ED);
      borderColor = isDark
          ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
          : const Color(0xFFF59E0B).withValues(alpha: 0.3);
      labelColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (group.anyPaid) {
          _showReceiptTypeSelection(group, vm);
        }
      },
      child: AnimatedContainer(
        duration: 300.ms,
        decoration: BoxDecoration(
          color: glowColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate(group.month).substring(0, 3).toUpperCase(),
                style: TextStyle(
                  color: labelColor.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              // Type status indicators (Smart: only show if exists)
              Row(
                children: [
                  if (group.scolarity != null)
                    _typeStatusDot(
                      Icons.school_rounded,
                      group.scolarityPaid,
                      true,
                      isDark,
                    ),
                  if (group.scolarity != null && group.transport != null)
                    const SizedBox(width: 8),
                  if (group.transport != null)
                    _typeStatusDot(
                      Icons.directions_bus_rounded,
                      group.transportPaid,
                      true,
                      isDark,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                loc.translate(group.month),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              if (group.allPaid)
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: labelColor, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      loc.translate('paid'),
                      style: TextStyle(
                          color: labelColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                )
              else if (isCurrentMonth)
                Row(
                  children: [
                    Text(
                      '${loc.translate('pay_now')} >',
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              else ...[
                // Specific labels for past/future unpaid months
                if (group.anyPaid)
                  Text(
                    'Partiel',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                else if (allOverdue)
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: labelColor, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        loc.translate('overdue'),
                        style: TextStyle(
                            color: labelColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  )
                else
                  Text(
                    loc.translate('pending'),
                    style: TextStyle(
                      color: labelColor.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (30 * index).ms)
        .scale(begin: const Offset(0.93, 0.93));
  }

  Widget _typeStatusDot(IconData icon, bool isPaid, bool exists, bool isDark) {
    if (!exists) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 16,
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)),
      );
    }
    final Color bg = isPaid
        ? const Color(0xFF10B981).withValues(alpha: 0.2)
        : const Color(0xFFEF4444).withValues(alpha: 0.2);
    final Color border = isPaid
        ? const Color(0xFF10B981).withValues(alpha: 0.6)
        : const Color(0xFFEF4444).withValues(alpha: 0.6);
    final Color iconColor =
        isPaid ? const Color(0xFF34D399) : const Color(0xFFF87171);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                .withValues(alpha: 0.25),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }

  // ── Receipt Type Selection ──────────────────────────────────────────────────
  void _showReceiptTypeSelection(MonthPaymentGroup group, PaymentViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bgColor = isDark ? const Color(0xFF0F1D2E) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocalizations.of(context)!
                    .translate('receipt_type')
                    .toUpperCase(),
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              // Scolarité option
              if (group.scolarity != null)
                _buildTypeOption(
                  title: AppLocalizations.of(context)!
                      .translate('scolarity_receipt'),
                  icon: Icons.school_rounded,
                  color: Colors.blueAccent,
                  isPaid: group.scolarityPaid,
                  onTap: () {
                    Navigator.pop(context);
                    _showReceiptSheet(group.scolarity!, vm, isTransport: false);
                  },
                ),
              if (group.scolarity != null && group.transport != null)
                const SizedBox(height: 16),
              // Transport option
              if (group.transport != null)
                _buildTypeOption(
                  title: AppLocalizations.of(context)!
                      .translate('transport_receipt'),
                  icon: Icons.directions_bus_rounded,
                  color: Colors.orangeAccent,
                  isPaid: group.transportPaid,
                  onTap: () {
                    Navigator.pop(context);
                    _showReceiptSheet(group.transport!, vm, isTransport: true);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeOption({
    required String title,
    required IconData icon,
    required Color color,
    required bool isPaid,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPaid ? 'Payé ✓' : 'Non payé',
                    style: TextStyle(
                      color: isPaid ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: primaryTextColor.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  // ── Receipt Bottom Sheet ──────────────────────────────────────────────────────
  void _showReceiptSheet(PaymentModel payment, PaymentViewModel vm,
      {bool isTransport = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF64748B);
    final bgColor = isDark ? const Color(0xFF0F1D2E) : Colors.white;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);

    // Format payment date
    String formattedDate = payment.date;
    try {
      if (payment.date.isNotEmpty) {
        final dt = DateTime.parse(payment.date);
        formattedDate =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    } catch (_) {}

    // Month + Year label
    final loc = AppLocalizations.of(context)!;
    final monthLabel =
        payment.month.isNotEmpty ? loc.translate(payment.month) : '--';
    final yearLabel = payment.year?.toString() ?? '';
    final monthYearLabel =
        '$monthLabel${yearLabel.isNotEmpty ? ' $yearLabel' : ''}';

    // Invoice number
    final invoiceNum = payment.invoiceNumber ?? '--';

    // Payment method
    String methodLabel = '--';
    if (payment.paymentMethod != null) {
      final m = payment.paymentMethod!.toLowerCase();
      if (m.contains('espece') || m.contains('cash') || m.contains('espèce')) {
        methodLabel = 'Espèces';
      } else if (m.contains('virement') ||
          m.contains('bank') ||
          m.contains('transfer')) {
        methodLabel = 'Virement bancaire';
      } else if (m.contains('cheque') || m.contains('chèque')) {
        methodLabel = 'Chèque';
      } else if (m.contains('carte') || m.contains('card')) {
        methodLabel = 'Carte bancaire';
      } else {
        methodLabel = payment.paymentMethod!;
      }
    }

    // Receipt type from invoice number prefix
    String receiptType = isTransport ? 'Transport' : 'Scolarité';
    if (invoiceNum != '--') {
      if (invoiceNum.toUpperCase().startsWith('INV-TRA')) {
        receiptType = 'Transport';
      } else if (invoiceNum.toUpperCase().startsWith('INV-SCO')) {
        receiptType = 'Scolarité';
      } else if (invoiceNum.toUpperCase().startsWith('INV-INS')) {
        receiptType = 'Inscription';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ListenableBuilder(
            listenable: vm,
            builder: (context, child) {
              bool isDownloading = vm.isDownloading;

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(36)),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.transparent),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Header Row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Facture du mois',
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            // Download Button
                            GestureDetector(
                              onTap: () async {
                                if (isDownloading) return;
                                HapticFeedback.mediumImpact();

                                // Generate local PDF receipt directly from the payment model
                                final success = await vm.generateLocalReceipt(payment);

                                if (success) {
                                  HapticFeedback.heavyImpact();
                                  if (context.mounted) Navigator.pop(context);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            vm.errorMessage ?? 'Erreur lors du téléchargement du reçu.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF6366F1)
                                  ]),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF3B82F6)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isDownloading)
                                      const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white)))
                                    else
                                      const Icon(Icons.download_rounded,
                                          color: Colors.white, size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      isDownloading
                                          ? 'Chargement...'
                                          : 'Télécharger',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : const Color(0xFFE2E8F0)),
                                ),
                                child: Text('Fermer',
                                    style: TextStyle(
                                        color: primaryTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Divider(color: dividerColor, height: 1),
                        const SizedBox(height: 20),

                        // Receipt fields
                        _receiptGrid([
                          _ReceiptField('N° Facture', invoiceNum),
                          _ReceiptField('Type', receiptType),
                          _ReceiptField('Nom et prénom de l\'élève',
                              payment.studentName ?? '--'),
                          _ReceiptField('Classe', payment.className ?? '--'),
                          _ReceiptField('Mois', monthYearLabel),
                          _ReceiptField(
                              'Statut',
                              payment.status == PaymentStatus.paid
                                  ? 'Payé'
                                  : (payment.status == PaymentStatus.overdue
                                      ? 'En retard'
                                      : 'En attente'),
                              isGreen: payment.status == PaymentStatus.paid),
                          _ReceiptField('Date de paiement',
                              formattedDate.isNotEmpty ? formattedDate : '--'),
                          _ReceiptField('Mode de paiement', methodLabel),
                        ], isDark, primaryTextColor, secondaryTextColor),

                        const SizedBox(height: 20),

                        // Total
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    Colors.blueAccent.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL PAYÉ',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.blueAccent.shade100
                                      : Colors.blueAccent.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                payment.amount > 0
                                    ? '${payment.amount.toStringAsFixed(payment.amount == payment.amount.roundToDouble() ? 0 : 2)} DH'
                                    : '--',
                                style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
      },
    );
  }

  Widget _receiptGrid(List<_ReceiptField> fields, bool isDark,
      Color primaryTextColor, Color secondaryTextColor) {
    return Column(
      children: fields.map((f) {
        final valueColor =
            f.isGreen ? Colors.greenAccent.shade400 : primaryTextColor;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: Text(f.label,
                    style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(f.value,
                    style: TextStyle(
                        color: valueColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white),
              ),
              child:
                  Image.asset('assets/images/image3.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 14),
            Text(
              AppLocalizations.of(context)!.translate('payments_title'),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 22,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: Consumer<PaymentViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading && vm.monthGroups.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent));
            }

            if (vm.errorMessage != null && vm.monthGroups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.redAccent.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                        AppLocalizations.of(context)!
                            .translate(vm.errorMessage!),
                        style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => vm.fetchPayments(),
                      child: Text(
                          AppLocalizations.of(context)!.translate('retry')),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildYearlySummary(vm),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate('monthly_payments')
                              .toUpperCase(),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : const Color(0xFF0F172A)
                                    .withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: vm.monthGroups.length,
                      itemBuilder: (ctx, i) =>
                          _buildMonthCard(vm.monthGroups[i], i, isDark, vm),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Helper model for receipt fields ──────────────────────────────────────────
class _ReceiptField {
  final String label;
  final String value;
  final bool isGreen;

  const _ReceiptField(this.label, this.value, {this.isGreen = false});
}
