import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class PaymentViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<MonthPaymentGroup> _monthGroups = [];
  List<PaymentModel> _allPayments = []; // raw list from API
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDownloading = false;

  List<MonthPaymentGroup> get monthGroups => _monthGroups;
  List<PaymentModel> get payments => _allPayments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDownloading => _isDownloading;

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => refreshSilent());
    debugPrint('Payment polling started (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Payment polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> refreshSilent() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchPayments(silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  // Summary statistics (count each type separately)
  int get paidCount => _monthGroups.where((g) => g.allPaid).length;
  int get overdueCount => _monthGroups
      .where((g) => g.overallStatus == PaymentStatus.overdue)
      .length;
  int get pendingCount => _monthGroups
      .where((g) => g.overallStatus == PaymentStatus.pending)
      .length;
  double get progressionRate =>
      _monthGroups.isEmpty ? 0 : (paidCount / _monthGroups.length);

  String get currentMonthName {
    final now = DateTime.now();
    final months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december'
    ];
    return months[now.month - 1];
  }

  static const List<String> _schoolMonths = [
    'september',
    'october',
    'november',
    'december',
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
  ];

  static const Map<String, int> _monthToNumber = {
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
  };

  int _getAcademicMonthIndex(int month) {
    if (month >= 9) return month - 9;
    return month + 3;
  }

  bool _isMonthOverdue(String monthStr) {
    final now = DateTime.now();
    int currentAcademicMonth = _getAcademicMonthIndex(now.month);
    int targetMonthNum = _monthToNumber[monthStr.toLowerCase()] ?? 9;
    int targetAcademicMonth = _getAcademicMonthIndex(targetMonthNum);
    return targetAcademicMonth < currentAcademicMonth;
  }

  PaymentModel _withOverdueStatus(PaymentModel p) {
    return PaymentModel(
      id: p.id,
      month: p.month,
      amount: p.amount,
      status: PaymentStatus.overdue,
      date: p.date,
      childIds: p.childIds,
      invoiceUrl: p.invoiceUrl,
      invoiceNumber: p.invoiceNumber,
      studentName: p.studentName,
      className: p.className,
      paymentMethod: p.paymentMethod,
      year: p.year,
      paymentType: p.paymentType,
    );
  }

  Future<void> fetchPayments({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final apiPayments = await _apiService.getPayments();
      _allPayments = apiPayments;

      // Detect active services for this student across the whole year
      final hasAnyScolarity =
          apiPayments.any((p) => p.paymentType == PaymentType.scolarity);
      final hasAnyTransport =
          apiPayments.any((p) => p.paymentType == PaymentType.transport);

      _monthGroups = _schoolMonths.map((month) {
        final bool isOverdue = _isMonthOverdue(month);

        // Find scolarity payment for this month
        final scoMatches = apiPayments
            .where((p) =>
                p.month.toLowerCase().trim() == month.toLowerCase() &&
                p.paymentType == PaymentType.scolarity)
            .toList();

        // Find transport payment for this month
        final traMatches = apiPayments
            .where((p) =>
                p.month.toLowerCase().trim() == month.toLowerCase() &&
                p.paymentType == PaymentType.transport)
            .toList();

        PaymentModel? sco = scoMatches.isNotEmpty ? scoMatches.first : null;
        PaymentModel? tra = traMatches.isNotEmpty ? traMatches.first : null;

        // Upgrade to overdue if unpaid and month has passed
        if (sco != null && sco.status == PaymentStatus.pending && isOverdue) {
          sco = _withOverdueStatus(sco);
        }
        if (tra != null && tra.status == PaymentStatus.pending && isOverdue) {
          tra = _withOverdueStatus(tra);
        }

        final bool isCurrentMonth = month.toLowerCase() == currentMonthName;

        // Create placeholders for active services that are missing from API for this month
        // FORCE both for current month to ensure visibility of unpaid items
        if (sco == null && (hasAnyScolarity || isCurrentMonth)) {
          sco = PaymentModel(
            id: 'placeholder_sco_$month',
            month: month,
            amount: 0,
            status: isOverdue ? PaymentStatus.overdue : PaymentStatus.pending,
            date: '',
            childIds: [],
            paymentType: PaymentType.scolarity,
          );
        }
        if (tra == null && (hasAnyTransport || isCurrentMonth)) {
          tra = PaymentModel(
            id: 'placeholder_tra_$month',
            month: month,
            amount: 0,
            status: isOverdue ? PaymentStatus.overdue : PaymentStatus.pending,
            date: '',
            childIds: [],
            paymentType: PaymentType.transport,
          );
        }

        return MonthPaymentGroup(
          month: month,
          scolarity: sco,
          transport: tra,
        );
      }).toList();
    } catch (e) {
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      // Always notify listeners so UI updates reflect data changes
      notifyListeners();
    }
  }

  Future<bool> getReceiptUrl(String paymentId, String type) async {
    _isDownloading = true;
    notifyListeners();

    try {
      final endpoint = await _apiService.downloadReceipt(paymentId, type);

      // Get temporary directory to save the file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'receipt_${paymentId}_$type.pdf';
      final savePath = '${tempDir.path}/$fileName';

      // Download the file internally with headers
      final downloadedPath =
          await _apiService.downloadInternalFile(endpoint, savePath);

      if (downloadedPath != null) {
        // Open the file using the local viewer
        final result = await OpenFilex.open(downloadedPath);
        if (result.type != ResultType.done) {
          _errorMessage = 'Could not open PDF: ${result.message}';
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      return false;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<bool> launchURL(String urlString) async {
    if (urlString.isEmpty) return false;
    _isDownloading = true;
    notifyListeners();

    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
}
