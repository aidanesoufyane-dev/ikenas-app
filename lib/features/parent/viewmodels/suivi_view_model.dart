import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class SuiviViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<GradeModel> _grades = [];
  final List<AttendanceRecord> _absences = [];
  Map<String, List<dynamic>> _evolutionData =
      {}; // Map of subject -> list of FlSpot-like data
  bool _isLoading = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;
  String? _lastStudentId;
  String? _forcedKeysLoadedForStudentId;
  Map<String, String> _localJustifications = {};

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling(String studentId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => refreshSilent(studentId));
    debugPrint('Suivi polling started (1s interval) for student: $studentId');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Suivi polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> refreshSilent(String studentId) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchSuiviData(studentId, silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  String _attendanceKey(AttendanceRecord a) {
    if (a.id.isNotEmpty && a.id != 'null' && a.id != '0') {
      return 'id|${a.id}';
    }

    String dateString = a.date.trim();
    String normalizedDate =
        dateString.length >= 10 ? dateString.substring(0, 10) : dateString;

    if (a.scheduleId != null &&
        a.scheduleId!.isNotEmpty &&
        a.scheduleId != 'null') {
      return 'schedule|$normalizedDate|${a.scheduleId}';
    }

    final subject = (a.subjectName ?? a.sessionName ?? '').trim().toLowerCase();
    final start = (a.startTime ?? '').trim().toLowerCase();
    return 'content|$normalizedDate|$subject|$start';
  }

  List<GradeModel> get grades => _grades;
  List<AttendanceRecord> get absences => _absences;
  Map<String, List<dynamic>> get evolutionData => _evolutionData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;

  // Group grades by subject for UI display
  Map<String, List<GradeModel>> get groupedGrades {
    final Map<String, List<GradeModel>> grouped = {};
    for (var g in _grades) {
      if (!grouped.containsKey(g.subject)) {
        grouped[g.subject] = [];
      }
      grouped[g.subject]!.add(g);
    }
    return grouped;
  }

  List<TimetableSessionModel> _schedule = [];
  List<TimetableSessionModel> get schedule => _schedule;

  String _forcedKeysStorageKey(String studentId) =>
      'suivi_forced_justified_keys_$studentId';

  Future<void> _loadForcedJustifiedKeys(String studentId) async {
    if (_forcedKeysLoadedForStudentId == studentId) return;
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_forcedKeysStorageKey(studentId));
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        _localJustifications =
            decoded.map((key, value) => MapEntry(key, value.toString()));
      } catch (_) {
        _localJustifications = {};
      }
    } else {
      _localJustifications = {};
    }
    _forcedKeysLoadedForStudentId = studentId;
  }

  Future<void> _persistForcedJustifiedKeys(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _forcedKeysStorageKey(studentId),
      json.encode(_localJustifications),
    );
  }

  Future<void> fetchSuiviData(String studentId, {bool silent = false}) async {
    _lastStudentId = studentId;
    await _loadForcedJustifiedKeys(studentId);
    
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      debugPrint('Fetching suivi data for student: $studentId');
      final results = await Future.wait([
        _apiService.getGrades(studentId),
        _apiService.getAbsences(studentId),
        _apiService
            .getTimetable(studentId)
            .catchError((_) => <TimetableSessionModel>[]),
      ]);

      _grades = results[0] as List<GradeModel>;
      final fetchedAbsences = results[1] as List<AttendanceRecord>;
      _schedule = results[2] as List<TimetableSessionModel>;

      // Preserve optimistic justifications when backend propagation is delayed.
      final optimisticById = <String, AttendanceRecord>{
        for (final a in _absences)
          if (a.isJustified) a.id: a,
      };
      final mergedAbsences = fetchedAbsences.map((fetched) {
        final optimistic = optimisticById[fetched.id];

        // Comprehensive key checking for reliability
        final idKey = (fetched.id.isNotEmpty && fetched.id != 'null')
            ? 'id|${fetched.id}'
            : null;
        final dateStr = (fetched.date.length >= 10)
            ? fetched.date.substring(0, 10)
            : fetched.date.trim();
        final schedKey = (fetched.scheduleId != null &&
                fetched.scheduleId!.isNotEmpty &&
                fetched.scheduleId != 'null')
            ? 'schedule|$dateStr|${fetched.scheduleId}'
            : null;

        String? localSavedJson;
        if (idKey != null && _localJustifications.containsKey(idKey)) {
          localSavedJson = _localJustifications[idKey];
        } else if (schedKey != null &&
            _localJustifications.containsKey(schedKey)) {
          localSavedJson = _localJustifications[schedKey];
        } else {
          localSavedJson = _localJustifications[_attendanceKey(fetched)];
        }

        AttendanceRecord? localRecord;
        if (localSavedJson != null) {
          try {
            localRecord =
                AttendanceRecord.fromJson(json.decode(localSavedJson));
          } catch (e) {
            debugPrint('Failed to parse local record: $e');
          }
        }

        final shouldForceJustified =
            localRecord != null || (optimistic != null && !fetched.isJustified);
        if (shouldForceJustified) {
          return AttendanceRecord(
            id: fetched.id,
            date: fetched.date.isNotEmpty
                ? fetched.date
                : (localRecord?.date ?? ''),
            status: localRecord?.status ?? optimistic?.status ?? fetched.status,
            motif: (localRecord?.motif != null &&
                    localRecord!.motif!.isNotEmpty &&
                    localRecord.motif != 'null')
                ? localRecord.motif
                : ((optimistic?.motif != null && optimistic!.motif!.isNotEmpty)
                    ? optimistic.motif
                    : fetched.motif),
            attachment: (localRecord?.attachment != null &&
                    localRecord!.attachment!.isNotEmpty &&
                    localRecord.attachment != 'null')
                ? localRecord.attachment
                : ((optimistic?.attachment != null &&
                        optimistic!.attachment!.isNotEmpty)
                    ? optimistic.attachment
                    : fetched.attachment),
            rawStatus: localRecord?.rawStatus ??
                optimistic?.rawStatus ??
                fetched.rawStatus,
            startTime: fetched.startTime,
            endTime: fetched.endTime,
            subjectName: fetched.subjectName,
            sessionName: fetched.sessionName,
            justifiedByStudent: true, // Safely forced true
            approvalStatus: localRecord?.approvalStatus ??
                optimistic?.approvalStatus ??
                fetched.approvalStatus ??
                'pending',
            recordedBy: fetched.recordedBy,
            scheduleId: fetched.scheduleId,
          );
        }
        return fetched;
      }).toList();

      final fetchedIdentifiers = <String>{
        ...fetchedAbsences.map((a) => a.id),
        ...fetchedAbsences.where((a) => a.id.isNotEmpty).map((a) => a.id),
      };

      final finalAbsences = List<AttendanceRecord>.from(mergedAbsences);

      for (final localJson in _localJustifications.values) {
        try {
          final localRecord = AttendanceRecord.fromJson(json.decode(localJson));
          if (localRecord.id.isNotEmpty &&
              !fetchedIdentifiers.contains(localRecord.id)) {
            // It was wiped from server response! Bring it back from local persistence
            finalAbsences.add(localRecord);
          }
        } catch (_) {}
      }

      // Sort by date descending to ensure chronological order in UI
      finalAbsences.sort((a, b) {
        try {
          return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
        } catch (_) {
          return 0;
        }
      });

      _absences.clear();
      _absences.addAll(finalAbsences);

      debugPrint(
          'Parsed ${_grades.length} grades, ${_absences.length} absences, ${_schedule.length} schedule slots');

      // Diagnostic logging for persistence and justification issues
      for (var a in _absences) {
        if (a.status != 'present' || a.isJustified) {
          debugPrint(
              'Absence ID: ${a.id}, Status: ${a.status}, Justified: ${a.isJustified}, Flag: ${a.justifiedByStudent}, Approval: ${a.approvalStatus}, Motif: ${a.motif}');
        }
      }

      // Generate evolution data from local grades chronologically
      _processEvolutionDataFromGrades();
    } catch (e) {
      debugPrint('Error fetching suivi data: $e');
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      // Always notify listeners so UI updates reflect data changes
      notifyListeners();
    }
  }

  /// Find a matching schedule slot for a given attendance record
  /// Matches by day of week and subject name
  TimetableSessionModel? getScheduleForAttendance(AttendanceRecord a) {
    try {
      final dt = DateTime.parse(a.date);
      // weekday: 1=Monday, 2=Tuesday,...,7=Sunday
      // dayIndex in model: 0=Monday, 1=Tuesday, ...
      final dayOfWeekIndex = dt.weekday - 1;

      for (final slot in _schedule) {
        if (slot.dayIndex != dayOfWeekIndex) continue;

        // Try to match by subject name
        if (a.subjectName != null) {
          final slotSubject = slot.subject.toLowerCase();
          if (slotSubject.contains(a.subjectName!.toLowerCase()) ||
              a.subjectName!.toLowerCase().contains(slotSubject)) {
            return slot;
          }
        } else {
          // Return first slot for that day
          return slot;
        }
      }
    } catch (_) {}
    return null;
  }

  Map<String, Map<String, List<Map<String, double>>>> _evolutionDataBySemester =
      {};
  Map<String, Map<String, List<Map<String, double>>>>
      get evolutionDataBySemester => _evolutionDataBySemester;

  // New labels mapping: Subject -> Semester -> Index -> Label (e.g. "D1")
  Map<String, Map<String, Map<int, String>>> _evolutionLabels = {};

  String getLabelForPoint(String subjectId, String semester, int xIndex) {
    return _evolutionLabels[subjectId]?[semester]?[xIndex] ?? "D${xIndex + 1}";
  }

  String _extractTestNumber(String title, int fallbackIndex) {
    if (title.isEmpty) return (fallbackIndex + 1).toString();

    // Look for digits in the title
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(title);
    if (match != null) {
      return match.group(1)!;
    }

    return (fallbackIndex + 1).toString();
  }

  void _processEvolutionDataFromGrades() {
    _evolutionDataBySemester = {};
    _evolutionData = {}; // legacy flat map for fallback
    _evolutionLabels = {};

    final grouped = groupedGrades;
    for (var entry in grouped.entries) {
      final subject = entry.key;
      final chronologicalGrades = List<GradeModel>.from(entry.value);

      // Sort by test number (D1, D2, D3...) instead of date
      chronologicalGrades.sort((a, b) {
        final titleA = a.title ?? "";
        final titleB = b.title ?? "";

        final numA = int.tryParse(_extractTestNumber(titleA, 0)) ?? 999;
        final numB = int.tryParse(_extractTestNumber(titleB, 0)) ?? 999;

        if (numA != numB) {
          return numA.compareTo(numB);
        }

        // Fallback to date if numbers are the same
        return a.date.compareTo(b.date);
      });

      List<Map<String, double>> s1Points = [];
      List<Map<String, double>> s2Points = [];
      List<Map<String, double>> allPoints = [];

      Map<int, String> s1Labels = {};
      Map<int, String> s2Labels = {};

      int s1Index = 0;
      int s2Index = 0;

      for (int i = 0; i < chronologicalGrades.length; i++) {
        final g = chronologicalGrades[i];
        double score = (g.grade / (g.maxGrade > 0 ? g.maxGrade : 10.0)) * 10.0;
        final isS2 = g.semester?.toUpperCase().contains('2') ?? false;

        final title = g.title ?? "";
        final testNum = _extractTestNumber(title, isS2 ? s2Index : s1Index);
        final label = "D$testNum";

        if (isS2) {
          s2Points.add({'x': s2Index.toDouble(), 'y': score});
          s2Labels[s2Index] = label;
          s2Index++;
        } else {
          // default to S1
          s1Points.add({'x': s1Index.toDouble(), 'y': score});
          s1Labels[s1Index] = label;
          s1Index++;
        }
        allPoints.add({'x': i.toDouble(), 'y': score});
      }

      _evolutionDataBySemester[subject] = {'1': s1Points, '2': s2Points};
      _evolutionLabels[subject] = {'1': s1Labels, '2': s2Labels};

      if (allPoints.isNotEmpty) {
        _evolutionData[subject] = allPoints;
      }
    }
  }

  double get generalAverage {
    final grouped = groupedGrades;
    if (grouped.isEmpty) return gradeAverage; // fallback
    double sum = 0;
    for (var sub in grouped.keys) {
      sum += calculateSubjectAverage(sub);
    }
    return sum / grouped.length;
  }

  int get totalAttendanceDays => _absences.length;

  int get unjustifiedAbsences =>
      _absences.where((a) => a.status == 'absent' && !a.isJustified).length;
  int get justifiedAbsences => _absences.where((a) => a.isJustified).length;
  int get delays => _absences.where((a) => a.status == 'late').length;
  int get presentDays => _absences.where((a) => a.status == 'present').length;

  double get attendanceRate {
    if (totalAttendanceDays == 0) return 100.0;
    return (presentDays / totalAttendanceDays) * 100;
  }

  double get gradeAverage {
    if (_grades.isEmpty) return 0.0;
    final total = _grades.fold<double>(
        0,
        (sum, g) =>
            sum + (g.grade / (g.maxGrade > 0 ? g.maxGrade : 20.0)) * 10.0);
    return total / _grades.length;
  }

  double calculateSubjectAverage(String subjectId) {
    final subjectGrades = _grades.where((g) => g.subject == subjectId);
    if (subjectGrades.isEmpty) return 0.0;
    final total = subjectGrades.fold<double>(
        0,
        (sum, g) =>
            sum + (g.grade / (g.maxGrade > 0 ? g.maxGrade : 10.0)) * 10.0);
    return total / subjectGrades.length;
  }

  // Returns the trend (change) between the current general average and the previous state
  double getGeneralTrend() {
    if (_grades.length < 2) return 0.0;

    // Calculate current average
    double currentSum = 0;
    for (var g in _grades) {
      currentSum += (g.grade / (g.maxGrade > 0 ? g.maxGrade : 10.0)) * 10.0;
    }
    double currentAvg = currentSum / _grades.length;

    // Calculate previous average (all but the most recent grade by date)
    final sorted = List<GradeModel>.from(_grades);
    sorted.sort((a, b) => b.date.compareTo(a.date));

    if (sorted.length < 2) return 0.0;

    final withoutLatest = sorted.sublist(1);
    double prevSum = 0;
    for (var g in withoutLatest) {
      prevSum += (g.grade / (g.maxGrade > 0 ? g.maxGrade : 10.0)) * 10.0;
    }
    double prevAvg = prevSum / withoutLatest.length;

    return currentAvg - prevAvg;
  }

  // Returns latest rank for the subject, or null if not available
  int? getSubjectRank(String subjectId) {
    final subjectGrades =
        _grades.where((g) => g.subject == subjectId && g.rank != null).toList();
    if (subjectGrades.isEmpty) return null;
    // Sort by date to get the most recent rank
    subjectGrades.sort((a, b) => b.date.compareTo(a.date));
    return subjectGrades.first.rank;
  }

  int? getSubjectClassSize(String subjectId) {
    final subjectGrades = _grades
        .where((g) => g.subject == subjectId && g.classSize != null)
        .toList();
    if (subjectGrades.isEmpty) return null;
    subjectGrades.sort((a, b) => b.date.compareTo(a.date));
    return subjectGrades.first.classSize;
  }

  // Returns overall class rank if available in any grade entry (e.g., from a semester average)
  int? getOverallRank() {
    final rankedGrades = _grades.where((g) => g.rank != null).toList();
    if (rankedGrades.isEmpty) return null;

    // Prioritize those that look like general averages or the most recent overall
    rankedGrades.sort((a, b) => b.date.compareTo(a.date));
    return rankedGrades.first.rank;
  }

  int? getOverallClassSize() {
    final sizedGrades = _grades.where((g) => g.classSize != null).toList();
    if (sizedGrades.isEmpty) return null;
    sizedGrades.sort((a, b) => b.date.compareTo(a.date));
    return sizedGrades.first.classSize;
  }

  // Helper to find attendance record for a specific date
  AttendanceRecord? getAttendanceForDate(DateTime dt) {
    for (var a in _absences) {
      try {
        final attendanceDate = DateTime.parse(a.date);
        if (attendanceDate.year == dt.year &&
            attendanceDate.month == dt.month &&
            attendanceDate.day == dt.day) {
          return a;
        }
      } catch (e) {
        // Fallback for non-standard formats if possible
        if (a.date.contains(
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}')) {
          return a;
        }
      }
    }
    return null;
  }

  Future<bool> submitJustification(
    String attendanceId, {
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    String reason = '',
  }) async {
    // Find original record BEFORE any API call
    int index = _absences.indexWhere((a) => a.id == attendanceId);
    if (index == -1) {
      index =
          _absences.indexWhere((a) => _attendanceKey(a).contains(attendanceId));
    }

    final AttendanceRecord? originalRecord =
        index != -1 ? _absences[index] : null;

    // Build final reason: fallback to old motif if user left it empty
    final String finalReason = (reason.trim().isEmpty &&
            originalRecord?.motif != null &&
            originalRecord!.motif!.isNotEmpty)
        ? originalRecord.motif!
        : reason;

    // OPTIMISTIC UPDATE: Show justified status immediately for better UX
    if (index != -1 && originalRecord != null) {
      final optimistic = AttendanceRecord(
        id: originalRecord.id,
        date: originalRecord.date,
        status: originalRecord.status,
        motif: finalReason.isNotEmpty ? finalReason : originalRecord.motif,
        attachment: originalRecord.attachment,
        rawStatus: originalRecord.rawStatus,
        startTime: originalRecord.startTime,
        endTime: originalRecord.endTime,
        subjectName: originalRecord.subjectName,
        sessionName: originalRecord.sessionName,
        justifiedByStudent: true,
        approvalStatus: originalRecord.approvalStatus ?? 'pending',
        recordedBy: originalRecord.recordedBy,
        scheduleId: originalRecord.scheduleId,
      );
      _absences[index] = optimistic;
      notifyListeners();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedRecord = await _apiService.submitJustification(
        attendanceId: attendanceId,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        reason: finalReason,
        oldAttachmentUrl: originalRecord?.attachment,
        onProgress: (sent, total) {},
      );

      // Re-locate after async gap (index might shift if list was rebuilt)
      int finalIndex = _absences.indexWhere((a) => a.id == attendanceId);
      if (finalIndex == -1 && originalRecord != null) {
        finalIndex = _absences.indexWhere(
            (a) => _attendanceKey(a) == _attendanceKey(originalRecord));
      }

      if (finalIndex != -1) {
        final current = _absences[finalIndex]; // This is the optimistic version

        // Merge: server data takes priority, fallback to optimistic/original
        final merged = AttendanceRecord(
          // Prefer original ID to avoid doublon issues when server returns new justification object
          id: current.id,
          date: current.date.isNotEmpty
              ? current.date
              : (originalRecord?.date ?? ''),
          status: updatedRecord?.status ?? current.status,
          motif: _pickBest([
            updatedRecord?.motif,
            finalReason,
            current.motif,
            originalRecord?.motif,
          ]),
          attachment: _pickBest([
            updatedRecord?.attachment,
            current.attachment,
            originalRecord?.attachment,
          ]),
          rawStatus: updatedRecord?.rawStatus ?? current.rawStatus,
          startTime: current.startTime ?? originalRecord?.startTime,
          endTime: current.endTime ?? originalRecord?.endTime,
          subjectName: current.subjectName ?? originalRecord?.subjectName,
          sessionName: current.sessionName ?? originalRecord?.sessionName,
          justifiedByStudent: true,
          approvalStatus: updatedRecord?.approvalStatus ??
              current.approvalStatus ??
              'pending',
          recordedBy: current.recordedBy ?? originalRecord?.recordedBy,
          scheduleId: current.scheduleId ?? originalRecord?.scheduleId,
        );

        _absences[finalIndex] = merged;

        // Persist clean merged state to local DB
        final key = _attendanceKey(merged);
        _localJustifications[key] = json.encode(merged.toJson());
        debugPrint(
            '>>> JUSTIFIED & PERSISTED: key=$key, motif=${merged.motif}, attachment=${merged.attachment}');

        if (_lastStudentId != null) {
          await _persistForcedJustifiedKeys(_lastStudentId!);
        }
      }

      return true;
    } catch (e) {
      debugPrint('>>> submitJustification ERROR: $e');
      _errorMessage = _apiService.getLocalizedErrorMessage(e);

      // ROLLBACK on error: revert to original record
      if (index != -1 && originalRecord != null) {
        _absences[index] = originalRecord;
      }
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Returns the first non-null, non-empty, non-'null' string from a list
  String? _pickBest(List<String?> candidates) {
    for (final c in candidates) {
      if (c != null && c.isNotEmpty && c != 'null' && c != '{}') return c;
    }
    return null;
  }
}
