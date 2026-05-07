// ignore_for_file: non_constant_identifier_names
import '../models/models.dart';

/// Provides rich mock/fallback data for every screen so the UI never looks empty
/// when the real API returns nothing.  IDs all start with 'mock-' so they are
/// easy to distinguish from real backend documents.
class MockDataService {
  MockDataService._();

  // ─── Students ─────────────────────────────────────────────────────────────

  static List<StudentModel> getStudents() {
    return [
      StudentModel(
        id: 'mock-student-1',
        name: 'Yassine Bouazza',
        average: 8.4,
        massarCode: 'M123456',
        attendanceRate: 95.0,
        parentName: 'Hassan Bouazza',
        parentPhone: '0612345678',
        behavior: 'Bon',
        birthDate: '2012-03-15',
        age: 12,
        className: '6APG-1',
        gender: 'M',
      ),
      StudentModel(
        id: 'mock-student-2',
        name: 'Fatima Zahra Idrissi',
        average: 9.1,
        massarCode: 'M123457',
        attendanceRate: 98.0,
        parentName: 'Mohamed Idrissi',
        parentPhone: '0623456789',
        behavior: 'Très bon',
        birthDate: '2012-07-22',
        age: 12,
        className: '6APG-1',
        gender: 'F',
      ),
      StudentModel(
        id: 'mock-student-3',
        name: 'Anas El Fassi',
        average: 7.2,
        massarCode: 'M123458',
        attendanceRate: 89.0,
        parentName: 'Rachid El Fassi',
        parentPhone: '0634567890',
        behavior: 'Assez bon',
        birthDate: '2012-11-05',
        age: 12,
        className: '6APG-1',
        gender: 'M',
      ),
      StudentModel(
        id: 'mock-student-4',
        name: 'Salma Benali',
        average: 8.8,
        massarCode: 'M123459',
        attendanceRate: 96.0,
        parentName: 'Nadia Benali',
        parentPhone: '0645678901',
        behavior: 'Très bon',
        birthDate: '2013-01-18',
        age: 11,
        className: '6APG-1',
        gender: 'F',
      ),
      StudentModel(
        id: 'mock-student-5',
        name: 'Hamza Cherkaoui',
        average: 6.5,
        massarCode: 'M123460',
        attendanceRate: 82.0,
        parentName: 'Khalid Cherkaoui',
        parentPhone: '0656789012',
        behavior: 'Passable',
        birthDate: '2012-09-30',
        age: 12,
        className: '6APG-1',
        gender: 'M',
      ),
      StudentModel(
        id: 'mock-student-6',
        name: 'Nour El Houda Mrani',
        average: 9.5,
        massarCode: 'M123461',
        attendanceRate: 99.0,
        parentName: 'Aziz Mrani',
        parentPhone: '0667890123',
        behavior: 'Excellent',
        birthDate: '2013-04-12',
        age: 11,
        className: '6APG-1',
        gender: 'F',
      ),
    ];
  }

  // ─── Grades ───────────────────────────────────────────────────────────────

  static List<GradeModel> getGrades() {
    return [
      // Arabe
      GradeModel(
        id: 'mock-grade-1',
        subject: 'Arabe',
        grade: 7.5,
        maxGrade: 10,
        coefficient: 3,
        date: '2025-10-15',
        type: 'devoir',
        title: 'Devoir 1',
        semester: '1',
        classAverage: 6.8,
        rank: 8,
        classSize: 28,
      ),
      GradeModel(
        id: 'mock-grade-2',
        subject: 'Arabe',
        grade: 8.0,
        maxGrade: 10,
        coefficient: 3,
        date: '2025-11-20',
        type: 'devoir',
        title: 'Devoir 2',
        semester: '1',
        classAverage: 7.1,
        rank: 6,
        classSize: 28,
      ),
      GradeModel(
        id: 'mock-grade-3',
        subject: 'Arabe',
        grade: 8.5,
        maxGrade: 10,
        coefficient: 3,
        date: '2025-12-10',
        type: 'exam',
        title: 'Examen S1',
        semester: '1',
        classAverage: 7.3,
        rank: 5,
        classSize: 28,
      ),
      // Français
      GradeModel(
        id: 'mock-grade-4',
        subject: 'Français',
        grade: 6.5,
        maxGrade: 10,
        coefficient: 3,
        date: '2025-10-18',
        type: 'devoir',
        title: 'Devoir 1',
        semester: '1',
        classAverage: 6.2,
        rank: 12,
        classSize: 28,
      ),
      GradeModel(
        id: 'mock-grade-5',
        subject: 'Français',
        grade: 7.0,
        maxGrade: 10,
        coefficient: 3,
        date: '2025-11-22',
        type: 'devoir',
        title: 'Devoir 2',
        semester: '1',
        classAverage: 6.5,
        rank: 10,
        classSize: 28,
      ),
      GradeModel(
        id: 'mock-grade-6',
        subject: 'Français',
        grade: 7.5,
        maxGrade: 10,
        coefficient: 3,
        date: '2025-12-12',
        type: 'exam',
        title: 'Examen S1',
        semester: '1',
        classAverage: 6.9,
        rank: 9,
        classSize: 28,
      ),
      // Maths
      GradeModel(
        id: 'mock-grade-7',
        subject: 'Maths',
        grade: 9.0,
        maxGrade: 10,
        coefficient: 4,
        date: '2025-10-20',
        type: 'devoir',
        title: 'Devoir 1',
        semester: '1',
        classAverage: 7.5,
        rank: 3,
        classSize: 28,
      ),
      GradeModel(
        id: 'mock-grade-8',
        subject: 'Maths',
        grade: 8.5,
        maxGrade: 10,
        coefficient: 4,
        date: '2025-11-25',
        type: 'devoir',
        title: 'Devoir 2',
        semester: '1',
        classAverage: 7.2,
        rank: 4,
        classSize: 28,
      ),
      GradeModel(
        id: 'mock-grade-9',
        subject: 'Maths',
        grade: 9.5,
        maxGrade: 10,
        coefficient: 4,
        date: '2025-12-15',
        type: 'exam',
        title: 'Examen S1',
        semester: '1',
        classAverage: 7.8,
        rank: 2,
        classSize: 28,
      ),
      // Sciences
      GradeModel(
        id: 'mock-grade-10',
        subject: 'Sciences',
        grade: 8.0,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-10-22',
        type: 'devoir',
        title: 'Devoir 1',
        semester: '1',
        classAverage: 7.0,
      ),
      GradeModel(
        id: 'mock-grade-11',
        subject: 'Sciences',
        grade: 7.5,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-11-28',
        type: 'devoir',
        title: 'Devoir 2',
        semester: '1',
        classAverage: 6.8,
      ),
      GradeModel(
        id: 'mock-grade-12',
        subject: 'Sciences',
        grade: 8.5,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-12-18',
        type: 'exam',
        title: 'Examen S1',
        semester: '1',
        classAverage: 7.2,
      ),
      // Histoire-Géo
      GradeModel(
        id: 'mock-grade-13',
        subject: 'Histoire-Géo',
        grade: 7.0,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-10-25',
        type: 'devoir',
        title: 'Devoir 1',
        semester: '1',
        classAverage: 6.5,
      ),
      GradeModel(
        id: 'mock-grade-14',
        subject: 'Histoire-Géo',
        grade: 7.5,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-11-30',
        type: 'devoir',
        title: 'Devoir 2',
        semester: '1',
        classAverage: 6.8,
      ),
      GradeModel(
        id: 'mock-grade-15',
        subject: 'Histoire-Géo',
        grade: 8.0,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-12-20',
        type: 'exam',
        title: 'Examen S1',
        semester: '1',
        classAverage: 7.0,
      ),
      // Anglais
      GradeModel(
        id: 'mock-grade-16',
        subject: 'Anglais',
        grade: 9.0,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-10-28',
        type: 'devoir',
        title: 'Devoir 1',
        semester: '1',
        classAverage: 7.5,
      ),
      GradeModel(
        id: 'mock-grade-17',
        subject: 'Anglais',
        grade: 8.5,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-12-02',
        type: 'devoir',
        title: 'Devoir 2',
        semester: '1',
        classAverage: 7.2,
      ),
      GradeModel(
        id: 'mock-grade-18',
        subject: 'Anglais',
        grade: 9.5,
        maxGrade: 10,
        coefficient: 2,
        date: '2025-12-22',
        type: 'exam',
        title: 'Examen S1',
        semester: '1',
        classAverage: 7.8,
      ),
    ];
  }

  // ─── Attendance ───────────────────────────────────────────────────────────

  static List<AttendanceRecord> getAttendance() {
    final List<Map<String, dynamic>> raw = [
      // 15 present
      {'date': '2025-09-02', 'status': 'present', 'subject': 'Maths'},
      {'date': '2025-09-09', 'status': 'present', 'subject': 'Arabe'},
      {'date': '2025-09-16', 'status': 'present', 'subject': 'Français'},
      {'date': '2025-09-23', 'status': 'present', 'subject': 'Sciences'},
      {'date': '2025-09-30', 'status': 'present', 'subject': 'Anglais'},
      {'date': '2025-10-07', 'status': 'present', 'subject': 'Maths'},
      {'date': '2025-10-14', 'status': 'present', 'subject': 'Histoire-Géo'},
      {'date': '2025-10-21', 'status': 'present', 'subject': 'Arabe'},
      {'date': '2025-10-28', 'status': 'present', 'subject': 'Sciences'},
      {'date': '2025-11-04', 'status': 'present', 'subject': 'Français'},
      {'date': '2025-11-11', 'status': 'present', 'subject': 'Maths'},
      {'date': '2025-11-18', 'status': 'present', 'subject': 'Anglais'},
      {'date': '2025-11-25', 'status': 'present', 'subject': 'Arabe'},
      {'date': '2025-12-02', 'status': 'present', 'subject': 'Histoire-Géo'},
      {'date': '2025-12-09', 'status': 'present', 'subject': 'Sciences'},
      // 3 late
      {'date': '2025-10-01', 'status': 'late', 'subject': 'Maths', 'startTime': '08:15'},
      {'date': '2025-10-22', 'status': 'late', 'subject': 'Français', 'startTime': '10:05'},
      {'date': '2025-11-12', 'status': 'late', 'subject': 'Arabe', 'startTime': '08:20'},
      // 2 absent
      {
        'date': '2025-11-05',
        'status': 'absent',
        'subject': 'Sciences',
        'motif': 'Maladie',
        'justifiedByStudent': true,
        'approvalStatus': 'approved',
      },
      {
        'date': '2025-12-03',
        'status': 'absent',
        'subject': 'Anglais',
        'motif': '',
        'justifiedByStudent': false,
      },
    ];

    return List<AttendanceRecord>.generate(raw.length, (i) {
      final r = raw[i];
      return AttendanceRecord(
        id: 'mock-att-${i + 1}',
        date: r['date'] as String,
        status: r['status'] as String,
        subjectName: r['subject'] as String?,
        motif: r['motif'] as String?,
        startTime: r['startTime'] as String?,
        justifiedByStudent: (r['justifiedByStudent'] as bool?) ?? false,
        approvalStatus: r['approvalStatus'] as String?,
      );
    });
  }

  // ─── Homework ─────────────────────────────────────────────────────────────

  static List<HomeworkModel> getHomework() {
    return [
      HomeworkModel(
        id: 'mock-hw-1',
        subject: 'Maths',
        title: 'Exercices sur les fractions',
        description: 'Faire les exercices 5 à 10 page 47 du manuel.',
        dueDate: '2026-05-10',
        startDate: '2026-05-05',
        status: HomeworkStatus.notStarted,
        teacherName: 'M. Alami',
        type: 'devoir',
      ),
      HomeworkModel(
        id: 'mock-hw-2',
        subject: 'Arabe',
        title: 'Rédaction: ma famille',
        description: 'Écrire un paragraphe de 10 lignes sur ta famille.',
        dueDate: '2026-05-08',
        startDate: '2026-05-03',
        status: HomeworkStatus.done,
        teacherName: 'Mme Benkirane',
        type: 'devoir',
        progressRate: 100,
      ),
      HomeworkModel(
        id: 'mock-hw-3',
        subject: 'Français',
        title: 'Lecture: Le Petit Prince ch.3-4',
        description: 'Lire les chapitres 3 et 4 et répondre aux questions.',
        dueDate: '2026-05-12',
        startDate: '2026-05-06',
        status: HomeworkStatus.inProgress,
        teacherName: 'Mme Ziani',
        type: 'devoir',
        progressRate: 50,
      ),
      HomeworkModel(
        id: 'mock-hw-4',
        subject: 'Sciences',
        title: 'Schéma du système digestif',
        description: 'Dessiner et légender le schéma du système digestif.',
        dueDate: '2026-05-14',
        startDate: '2026-05-07',
        status: HomeworkStatus.notStarted,
        teacherName: 'M. Tahiri',
        type: 'devoir',
      ),
      HomeworkModel(
        id: 'mock-hw-5',
        subject: 'Anglais',
        title: 'Vocabulary Unit 6',
        description: 'Learn the 20 new words and write 5 sentences.',
        dueDate: '2026-05-09',
        startDate: '2026-05-04',
        status: HomeworkStatus.notStarted,
        teacherName: 'Mme Hakimi',
        type: 'devoir',
      ),
    ];
  }

  // ─── Exams ────────────────────────────────────────────────────────────────

  static List<HomeworkModel> getExams() {
    return [
      HomeworkModel(
        id: 'mock-exam-1',
        subject: 'Maths',
        title: 'Examen S2 – Géométrie',
        description: 'Chapitres 4 à 7: périmètres, aires et volumes.',
        dueDate: '2026-05-20',
        startDate: '2026-05-07',
        status: HomeworkStatus.notStarted,
        teacherName: 'M. Alami',
        type: 'exam',
      ),
      HomeworkModel(
        id: 'mock-exam-2',
        subject: 'Arabe',
        title: 'Examen S2 – Compréhension',
        description: 'Compréhension de texte et grammaire.',
        dueDate: '2026-05-22',
        startDate: '2026-05-07',
        status: HomeworkStatus.notStarted,
        teacherName: 'Mme Benkirane',
        type: 'exam',
      ),
      HomeworkModel(
        id: 'mock-exam-3',
        subject: 'Histoire-Géo',
        title: 'Examen S2 – Le Maroc médiéval',
        description: 'Dynasties, villes impériales et commerce.',
        dueDate: '2026-05-25',
        startDate: '2026-05-07',
        status: HomeworkStatus.notStarted,
        teacherName: 'M. Bensouda',
        type: 'exam',
      ),
    ];
  }

  // ─── Timetable ────────────────────────────────────────────────────────────

  static List<TimetableSessionModel> getTimetable() {
    // dayIndex: 0=Lundi, 1=Mardi, 2=Mercredi, 3=Jeudi, 4=Vendredi
    return [
      // Lundi
      TimetableSessionModel(dayIndex: 0, time: '08:00-09:00', subject: 'Maths', teacher: 'M. Alami', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 0, time: '09:00-10:00', subject: 'Arabe', teacher: 'Mme Benkirane', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 0, time: '10:30-11:30', subject: 'Français', teacher: 'Mme Ziani', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 0, time: '11:30-12:30', subject: 'EPS', teacher: 'M. Raji', room: 'Terrain'),
      TimetableSessionModel(dayIndex: 0, time: '14:00-15:00', subject: 'Sciences', teacher: 'M. Tahiri', room: 'Labo 2'),
      TimetableSessionModel(dayIndex: 0, time: '15:00-16:00', subject: 'Anglais', teacher: 'Mme Hakimi', room: 'Salle 12'),
      // Mardi
      TimetableSessionModel(dayIndex: 1, time: '08:00-09:00', subject: 'Histoire-Géo', teacher: 'M. Bensouda', room: 'Salle 8'),
      TimetableSessionModel(dayIndex: 1, time: '09:00-10:00', subject: 'Maths', teacher: 'M. Alami', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 1, time: '10:30-11:30', subject: 'Arabe', teacher: 'Mme Benkirane', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 1, time: '11:30-12:30', subject: 'Sciences', teacher: 'M. Tahiri', room: 'Labo 2'),
      TimetableSessionModel(dayIndex: 1, time: '14:00-15:00', subject: 'Français', teacher: 'Mme Ziani', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 1, time: '15:00-16:00', subject: 'Anglais', teacher: 'Mme Hakimi', room: 'Salle 12'),
      // Mercredi (demi-journée)
      TimetableSessionModel(dayIndex: 2, time: '08:00-09:00', subject: 'Maths', teacher: 'M. Alami', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 2, time: '09:00-10:00', subject: 'Français', teacher: 'Mme Ziani', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 2, time: '10:30-11:30', subject: 'Histoire-Géo', teacher: 'M. Bensouda', room: 'Salle 8'),
      TimetableSessionModel(dayIndex: 2, time: '11:30-12:30', subject: 'EPS', teacher: 'M. Raji', room: 'Terrain'),
      // Jeudi
      TimetableSessionModel(dayIndex: 3, time: '08:00-09:00', subject: 'Arabe', teacher: 'Mme Benkirane', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 3, time: '09:00-10:00', subject: 'Sciences', teacher: 'M. Tahiri', room: 'Labo 2'),
      TimetableSessionModel(dayIndex: 3, time: '10:30-11:30', subject: 'Anglais', teacher: 'Mme Hakimi', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 3, time: '11:30-12:30', subject: 'Maths', teacher: 'M. Alami', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 3, time: '14:00-15:00', subject: 'Histoire-Géo', teacher: 'M. Bensouda', room: 'Salle 8'),
      TimetableSessionModel(dayIndex: 3, time: '15:00-16:00', subject: 'Français', teacher: 'Mme Ziani', room: 'Salle 12'),
      // Vendredi
      TimetableSessionModel(dayIndex: 4, time: '08:00-09:00', subject: 'Sciences', teacher: 'M. Tahiri', room: 'Labo 2'),
      TimetableSessionModel(dayIndex: 4, time: '09:00-10:00', subject: 'Arabe', teacher: 'Mme Benkirane', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 4, time: '10:30-11:30', subject: 'Anglais', teacher: 'Mme Hakimi', room: 'Salle 12'),
      TimetableSessionModel(dayIndex: 4, time: '11:30-12:30', subject: 'EPS', teacher: 'M. Raji', room: 'Terrain'),
      TimetableSessionModel(dayIndex: 4, time: '14:00-15:00', subject: 'Maths', teacher: 'M. Alami', room: 'Salle 12'),
    ];
  }

  // ─── Behavior ─────────────────────────────────────────────────────────────

  static Map<String, dynamic> getBehaviorSummary() {
    return {
      'positive': 3,
      'negative': 2,
      'total': 5,
      'score': 7.5,
      'appreciation': 'Comportement général satisfaisant.',
    };
  }

  static List<Map<String, dynamic>> getBehaviorHistory() {
    return [
      {
        'id': 'mock-beh-1',
        'date': '2025-10-10',
        'type': 'positive',
        'title': 'Participation active',
        'comment': 'L\'élève a participé activement lors du cours de Maths.',
        'teacher': 'M. Alami',
        'subject': 'Maths',
      },
      {
        'id': 'mock-beh-2',
        'date': '2025-10-25',
        'type': 'negative',
        'title': 'Retard répété',
        'comment': 'L\'élève est arrivé en retard à trois reprises cette semaine.',
        'teacher': 'Mme Benkirane',
        'subject': 'Arabe',
      },
      {
        'id': 'mock-beh-3',
        'date': '2025-11-05',
        'type': 'positive',
        'title': 'Devoir exceptionnel',
        'comment': 'Excellent travail sur le devoir de Français. Très bon niveau rédactionnel.',
        'teacher': 'Mme Ziani',
        'subject': 'Français',
      },
      {
        'id': 'mock-beh-4',
        'date': '2025-11-18',
        'type': 'negative',
        'title': 'Inattention en cours',
        'comment': 'L\'élève a perturbé le cours de Sciences par des bavardages.',
        'teacher': 'M. Tahiri',
        'subject': 'Sciences',
      },
      {
        'id': 'mock-beh-5',
        'date': '2025-12-02',
        'type': 'positive',
        'title': 'Esprit d\'équipe',
        'comment': 'A aidé ses camarades lors des travaux de groupe en Histoire-Géo.',
        'teacher': 'M. Bensouda',
        'subject': 'Histoire-Géo',
      },
    ];
  }

  // ─── Posts / Feed ─────────────────────────────────────────────────────────

  static List<PostModel> getPosts() {
    return [
      PostModel(
        id: 'mock-post-1',
        authorName: 'Direction',
        authorRole: 'admin',
        title: 'Rentrée scolaire S2',
        content:
            'Le deuxième semestre démarre le 15 janvier 2026. Tous les élèves sont priés d\'être présents à 8h00.',
        date: '2026-01-10',
        likes: 12,
        comments: 3,
        isEvent: false,
        isUrgent: false,
      ),
      PostModel(
        id: 'mock-post-2',
        authorName: 'Administration',
        authorRole: 'admin',
        title: 'Réunion Parents-Professeurs',
        content:
            'Une réunion parents-professeurs est organisée le 20 mai 2026 à 17h00 dans la salle polyvalente. '
            'Votre présence est vivement souhaitée.',
        date: '2026-05-01',
        likes: 25,
        comments: 7,
        isEvent: true,
        isUrgent: false,
        eventDate: '2026-05-20',
      ),
      PostModel(
        id: 'mock-post-3',
        authorName: 'Direction',
        authorRole: 'admin',
        title: 'Journée sportive annuelle',
        content:
            'La journée sportive annuelle aura lieu le 28 mai 2026. Programme sportif varié: football, '
            'athlétisme, natation. Tenue sportive obligatoire.',
        date: '2026-05-04',
        likes: 40,
        comments: 15,
        isEvent: true,
        isUrgent: false,
        eventDate: '2026-05-28',
      ),
      PostModel(
        id: 'mock-post-4',
        authorName: 'Direction',
        authorRole: 'admin',
        title: 'URGENT: Fermeture exceptionnelle',
        content:
            'En raison de travaux urgents dans le bâtiment principal, l\'établissement sera fermé '
            'vendredi 16 mai 2026. Les cours reprendront normalement lundi.',
        date: '2026-05-07',
        likes: 8,
        comments: 2,
        isEvent: false,
        isUrgent: true,
      ),
    ];
  }

  // ─── Classes ──────────────────────────────────────────────────────────────

  static List<ClassModel> getClasses() {
    return [
      ClassModel(
        id: 'mock-class-1',
        name: '6APG-1',
        level: '6',
        studentCount: 28,
        attendanceRate: 93.5,
        classAverage: 8.1,
        students: getStudents(),
      ),
      ClassModel(
        id: 'mock-class-2',
        name: '5APG-2',
        level: '5',
        studentCount: 25,
        attendanceRate: 91.0,
        classAverage: 7.8,
      ),
    ];
  }

  // ─── Calendar Events ──────────────────────────────────────────────────────

  static List<EventModel> getCalendarEvents() {
    return [
      EventModel(
        id: 'mock-event-1',
        title: 'Réunion Parents-Professeurs',
        description: 'Discussion sur les progrès académiques du S2.',
        date: '2026-05-20',
        time: '17:00',
        type: 'meeting',
        location: 'Salle de conférence A',
      ),
      EventModel(
        id: 'mock-event-2',
        title: 'Journée sportive',
        description: 'Compétitions sportives inter-classes.',
        date: '2026-05-28',
        time: '08:00',
        type: 'sport',
        location: 'Stade de l\'école',
      ),
      EventModel(
        id: 'mock-event-3',
        title: 'Examens de fin d\'année',
        description: 'Examens S2 pour toutes les classes.',
        date: '2026-06-10',
        time: '08:00',
        type: 'exam',
        location: 'Salles de classe',
      ),
    ];
  }

  // ─── Children (parent side) ───────────────────────────────────────────────

  static List<StudentModel> getChildren() {
    return [
      StudentModel(
        id: 'mock-child-1',
        name: 'Yassine Bouazza',
        average: 8.4,
        massarCode: 'M123456',
        attendanceRate: 95.0,
        birthDate: '2012-03-15',
        age: 12,
        className: '6APG-1',
        gender: 'M',
      ),
    ];
  }
}
