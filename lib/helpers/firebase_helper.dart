import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceService {
  static Stream<List<Map<String, dynamic>>> fetchFilteredAttendance(
      {required DateTime date, String? classFilter}) {
    final startOfDay = _startOfDay(date);
    final endOfDay = _endOfDay(date);

    Query query = FirebaseFirestore.instance.collection('attendance')
      ..where('timeStamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timeStamp', isLessThanOrEqualTo: endOfDay);

    if (classFilter != null && classFilter.isNotEmpty) {
      query = query.where('currentClass',
          isEqualTo: classFilter); // Filter by class
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList());
  }

  /// If the attendance record exists, it updates the status.
  /// Otherwise, it creates a new attendance record.
  static Future<void> recordAttendance(String studentId) async {
    final today = DateTime.now();
    final dateKey = "${studentId}_${today.toIso8601String().split('T').first}";

    final attendanceDoc =
        FirebaseFirestore.instance.collection('attendance').doc(dateKey);

    final snapshot = await attendanceDoc.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      if (data['signOutTime'] == null) {
        // Sign out the student
        await attendanceDoc.update({
          'signOutTime': Timestamp.now(),
          'status': 'Signed Out',
        });
      } else {
        // Already signed out
        throw Exception("Student has already signed out.");
      }
    } else {
      // Sign in the student
      await attendanceDoc.set({
        'studentId': studentId,
        'date': Timestamp.fromDate(today),
        'signInTime': Timestamp.now(),
        'status': 'Signed In',
        'signOutTime': null,
        'currentClass': 'QBykrlq5m3IUXINQxr1h'
      });
    }
  }

  /// Returns the end of the day for the given date.
  static DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Returns the start of the day for the given date.
  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }
}

class FirebaseHelper {
  Future<void> calculateAndStoreOverallPerformance({
    required String classId,
    required String sessionId,
    required String termId,
  }) async {
    try {
      // Fetch students
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('currentClass', isEqualTo: classId)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        debugPrint('No students found in class $classId');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final termRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .collection('terms')
          .doc(termId);

      for (var studentDoc in studentsSnapshot.docs) {
        final student = Student.fromFirestore(studentDoc);

        final scores = await fetchStudentScores(
          classId: classId,
          sessionId: sessionId,
          termId: termId,
          studentId: student.studentId!,
        );

        if (scores.isNotEmpty) {
          final totalScores =
              scores.map((s) => s.total ?? 0).reduce((a, b) => a + b);
          final overallAverage = totalScores / scores.length;

          final performanceData = PerformanceData(
            studentId: student.studentId,
            totalScore: totalScores,
            overallAverage: double.parse(overallAverage.toStringAsFixed(2)),
            totalSubjects: scores.length,
            attendance: AttendanceStatus(present: 0, absent: 0, total: 0),
          );

          final performanceRef =
              termRef.collection('studentPerformance').doc(student.studentId);
          batch.set(performanceRef, performanceData.toMap());
        } else {
          debugPrint('No scores found for student: ${student.name}');
        }
      }

      await batch.commit();

      // Calculate and update positions
      final performanceSnapshot =
          await termRef.collection('studentPerformance').get();
      final performances = performanceSnapshot.docs.map((doc) {
        final data = PerformanceData.fromMap(doc.data());
        return {
          'regNo': doc.id,
          'average': data.overallAverage,
        };
      }).toList()
        ..sort((a, b) =>
            (b['average'] as double).compareTo(a['average'] as double));

      final positionBatch = FirebaseFirestore.instance.batch();
      for (var i = 0; i < performances.length; i++) {
        final position = i + 1;
        final ref = termRef
            .collection('studentPerformance')
            .doc(performances[i]['regNo'] as String);
        positionBatch.update(ref, {
          'overallPosition': position,
          'totalStudents': performances.length,
        });
      }

      await positionBatch.commit();
    } catch (e, stacktrace) {
      debugPrint('Error: $e\nStacktrace: $stacktrace');
      throw Exception('Failed to calculate overall performance: $e');
    }
  }

  // Helper function to calculate average score
  static double calculateAverageTraitScore(TraitsAndSkills trait) {
    final scores = [
      trait.creativity,
      trait.sports,
      trait.attentiveness,
      trait.obedience,
      trait.cleanliness,
      trait.politeness,
      trait.honesty,
      trait.punctuality,
      trait.music,
    ].where((score) => score != null).map((score) => score!);

    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  static String calculateGrade(int total) {
    if (total >= 85) return 'A';
    if (total >= 80) return 'B2';
    if (total >= 75) return 'B3';
    if (total >= 70) return 'C4';
    if (total >= 65) return 'C5';
    if (total >= 60) return 'C6';
    if (total >= 50) return 'D7';
    if (total >= 40) return 'D8';
    return 'F9';
  }

  static Future<void> calculatePositions({
    required String classId,
    required String sessionId,
    required String termId,
    required String subjectId,
  }) async {
    final scoresRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('sessions')
        .doc(sessionId)
        .collection('terms')
        .doc(termId)
        .collection('subjects')
        .doc(subjectId)
        .collection('scores');

    final scoresSnapshot = await scoresRef.get();

    if (scoresSnapshot.docs.isEmpty) return;

    final scores = scoresSnapshot.docs.map((doc) {
      final data = doc.data();
      return SubjectScore(
        studentId: doc.id,
        ca1: data['ca1'],
        ca2: data['ca2'],
        exam: data['exam'],
        total: data['total'],
        position: '',
        grade: data['grade'],
        remark: data['remark'],
      );
    }).toList();

    // Sort scores by total in descending order
    scores.sort((a, b) => (b.total ?? 0).compareTo(a.total ?? 0));

    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < scores.length; i++) {
      int pos = i + 1;
      scores[i].position = pos.toString();
      final docRef = scoresRef.doc(scores[i].studentId);
      batch.update(docRef, {'position': scores[i].position});
    }

    await batch.commit();
  }

  static String calculateRemark(int total) {
    if (total >= 85) return 'Excellent';
    if (total >= 80) return 'Very Good';
    if (total >= 75) return 'Good';
    if (total >= 70) return 'Fair';
    if (total >= 65) return 'Satisfactory';
    if (total >= 50) return 'Pass';
    return 'Fail';
  }

// Fetch classes
  static Future<List<SchoolClass>> fetchClasses() async {
    try {
      final classSnapshots =
          await FirebaseService.getDataStreamFromFirestore<SchoolClass>(
        collection: 'classes',
        fromFirestore: (doc) => SchoolClass.fromFirestore(doc),
      ).first; // Get the first snapshot from the stream
      return classSnapshots;
    } catch (e) {
      throw Exception('Error fetching classes 1 : $e');
    }
  }

// Fetch sessions for a given class
  static Future<List<Session>> fetchSessions(String classId) async {
    try {
      final sessionSnapshots =
          await FirebaseService.getDataStreamFromFirestore<Session>(
        collection: 'classes/$classId/sessions',
        fromFirestore: (doc) => Session.fromFirestore(doc),
      ).first; // Get the first snapshot from the stream
      return sessionSnapshots;
    } catch (e) {
      throw Exception('Error fetching sessions: $e');
    }
  }

// Fetch students
  static Future<List<Student>> fetchStudents() async {
    try {
      final studentSnapshot =
          await FirebaseService.getDataStreamFromFirestore<Student>(
        collection: 'students',
        fromFirestore: (doc) => Student.fromFirestore(doc),
      ).first; // Get the first snapshot from the stream
      return studentSnapshot;
    } catch (e) {
      throw Exception('Error fetching students : $e');
    }
  }

  static Future<List<SubjectScore>> fetchStudentScores({
    required String classId,
    required String sessionId,
    required String termId,
    required String studentId,
  }) async {
    final List<SubjectScore> studentScores = [];
    try {
      final subjectsRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .collection('terms')
          .doc(termId)
          .collection('subjects');
      // Fetch all subjects in the term
      final collection =
          'classes/$classId/sessions/$sessionId/terms/$termId/subjects';

      final subjectsSnapshot =
          await FirebaseService.getAllDocuments(collection);

      for (var subjectDoc in subjectsSnapshot) {
        // Convert subject document to Subject model
        final subject = Subject.fromFirestore(subjectDoc);
        //'$collection/subjectDoc.id/scores'

        final scoresRef = subjectsRef
            .doc(subjectDoc.id)
            .collection('scores')
            .where('studentId', isEqualTo: studentId);
        // Fetch the student's score for this subject
        final scoresSnapshot = await scoresRef
            .get(); //FirebaseService.getWhere(collection: '$collection/${subjectDoc.id}/scores', queryFields: {'scores': regNo});

        for (var scoreDoc in scoresSnapshot.docs) {
          final data = scoreDoc.data();
          // Convert Firestore document to SubjectScore
          final score = SubjectScore(
            studentId: data['studentId'],
            subjectName: subject.name, // Use subject name from Subject model
            ca1: data['ca1'] ?? 0,
            ca2: data['ca2'] ?? 0,
            exam: data['exam'] ?? 0,
            total: data['total'] ?? 0,
            average: data['average'] ?? 0.0,
            position: data['position'] ?? '',
            grade: data['grade'] ?? '',
            remark: data['remark'] ?? '',
          );
          studentScores.add(score);
        }
      }
      return studentScores;
    } catch (e) {
      debugPrint('Error fetching scores: $e');
      throw Exception('Failed to fetch scores: $e');
    }
  }

  // Fetch terms for a given session
  static Future<List<Term>> fetchTerms(String classId, String sessionId) async {
    try {
      final termSnapshots =
          await FirebaseService.getDataStreamFromFirestore<Term>(
        collection: 'classes/$classId/sessions/$sessionId/terms',
        fromFirestore: (doc) => Term.fromFirestore(doc),
      ).first; // Get the first snapshot from the stream
      return termSnapshots;
    } catch (e) {
      throw Exception('Error fetching terms: $e');
    }
  }

  static Future<Map<String, dynamic>> getReportCardData({
    required String classId,
    required String sessionId,
    required String termId,
    required String studentId,
  }) async {
    try {
      // Fetch class name
      final classDoc =
          await FirebaseService.getDocumentById('classes', classId);
      final schoolClass = SchoolClass.fromFirestore(classDoc);
      final className = schoolClass.name;

      // Fetch student information
      final studentDoc =
          await FirebaseService.getDocumentById('students', studentId);
      final student = Student.fromFirestore(studentDoc);
      student.currentClass = className;

      // Fetch subject scores
      final subjectScores = await fetchStudentScores(
        classId: classId,
        sessionId: sessionId,
        termId: termId,
        studentId: student.studentId!,
      );

      // Fetch traits and skills scores
      final traitsAndSkillsDoc = await FirebaseService.getDocumentById(
        'classes/$classId/sessions/$sessionId/terms/$termId/skillsAndTraits',
        student.studentId!,
      );

      final traitsAndSkills = TraitsAndSkills.fromFirestore(
        traitsAndSkillsDoc.data() as Map<String, dynamic>,
      );

      // Fetch overall performance data
      final performanceDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .collection('terms')
          .doc(termId)
          .collection('studentPerformance')
          .doc(student.studentId)
          .get();

      PerformanceData? performanceData;
      if (performanceDoc.exists) {
        performanceData = PerformanceData.fromMap(performanceDoc.data()!);
      }
      // Organize data for report card screen
      final reportCardData = {
        'student': student,
        'performanceData': performanceData,
        'subjectScores': subjectScores,
        'traitsAndSkills': traitsAndSkills,
      };

      return reportCardData;
    } catch (e) {
      debugPrint('Error fetching report card data: $e');
      throw Exception('Failed to fetch report card data: $e');
    }
  }
}
