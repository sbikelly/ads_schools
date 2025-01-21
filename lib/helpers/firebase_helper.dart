import 'dart:io';
import 'dart:typed_data';

import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> countAttendance(
      String classId, String status, String startDate, String endDate) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Attendance')
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    int count = 0;
    for (var doc in querySnapshot.docs) {
      final students = doc.data()['students'] as Map<String, dynamic>;
      count += students.values
          .where((student) => student['status'] == status)
          .length;
    }
    return count;
  }

  Future<List<Map<String, dynamic>>> fetchAttendance(
      {DateTime? startDate, DateTime? endDate, String? studentId}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('attendance');

      if (startDate != null) {
        query = query.where('timeStamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timeStamp', isLessThanOrEqualTo: endDate);
      }
      if (studentId != null) {
        query = query.where('studentId', isEqualTo: studentId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on Exception catch (e) {
      debugPrint('error fetching attendance $e');
      return [];
    }
  }

  Future<Map<String, StudentAttendance>> fetchAttendance1(
      String classId, String date,
      [endDate]) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('Attendance').doc(classId);
      //.doc('$classId-$date');

      final snapshot = await docRef.get();

      if (!snapshot.exists) return {};

      final data = snapshot.data()?['students'] as Map<String, dynamic>? ?? {};
      return data.map((id, details) => MapEntry(
            id,
            StudentAttendance.fromMap({...details, 'studentId': id}),
          ));
    } on Exception catch (e) {
      throw Exception('Error fetching Attendance 1 ====: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchStudentAttendance(
      String studentId) async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('Attendance').get();

    List<Map<String, dynamic>> records = [];

    for (var doc in querySnapshot.docs) {
      final students = doc['students'] as Map<String, dynamic>?;
      if (students != null && students.containsKey(studentId)) {
        records.add({
          'date': doc['date'],
          ...students[studentId],
        });
      }
    }
    return records;
  }

  void generateAndSharePdf(String studentId, String studentName) async {
    final attendanceRecords = await fetchStudentAttendance(studentId);
    final pdfBytes =
        await generateAttendanceReportPdf(studentName, attendanceRecords);

    // Use Printing to preview and share
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);

    // Save to file (optional)
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/$studentName-attendance-report.pdf');
    await file.writeAsBytes(pdfBytes);
    print('Saved PDF to ${file.path}');
  }

  Future<void> generateAttendanceReport(List<Map<String, dynamic>> data) async {
    // Implement PDF generation using flutter_pdf
  }

  Future<Uint8List> generateAttendanceReportPdf(
      String studentName, List<Map<String, dynamic>> attendanceRecords) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Attendance Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Student Name: $studentName',
              style: pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  children: [
                    pw.Text('Date',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Status',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Sign-In Time',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Sign-Out Time',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                // Table Rows
                ...attendanceRecords.map((record) {
                  return pw.TableRow(
                    children: [
                      pw.Text(record['date'] ?? ''),
                      pw.Text(record['status'] ?? ''),
                      pw.Text(
                        record['signInTime'] != null
                            ? (record['signInTime'] as Timestamp)
                                .toDate()
                                .toLocal()
                                .toString()
                            : 'N/A',
                      ),
                      pw.Text(
                        record['signOutTime'] != null
                            ? (record['signOutTime'] as Timestamp)
                                .toDate()
                                .toLocal()
                                .toString()
                            : 'N/A',
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> markAttendance1(
      String classId, String date, StudentAttendance attendance) async {
    final docRef = FirebaseFirestore.instance
        .collection('Attendance')
        .doc('$classId-$date');

    await docRef.set({
      'classId': classId,
      'date': date,
      'students.${attendance.studentId}': attendance.toMap(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAttendance(String id, String status) async {
    await _firestore
        .collection('attendance')
        .doc(id)
        .update({'status': status});
  }

  /// Marks attendance for a specific user on a specific date.
  /// If the attendance record exists, it updates the status.
  /// Otherwise, it creates a new attendance record.
  static Future<void> markAttendance({
    required String userId,
    required String status,
    required DateTime date,
  }) async {
    try {
      // Reference to the attendance collection
      final attendanceRef = _firestore.collection('attendance');

      // Query to find an existing record for the user and date
      final query = await attendanceRef
          .where('userId', isEqualTo: userId)
          .where('timeStamp', isGreaterThanOrEqualTo: _startOfDay(date))
          .where('timeStamp', isLessThanOrEqualTo: _endOfDay(date))
          .get();
      debugPrint("quer finished $query");

      if (!query.docs.isNotEmpty) {
        // Record does not exist, create it
        await attendanceRef.add({
          'userId': userId,
          'status': status,
          'timeStamp': date,
        });
        debugPrint('Attendance created for user $userId on $date');
      } else {
        // Record exists, update it
        final docId = query.docs.first.id;
        await attendanceRef.doc(docId).update({'status': status});
        print('Attendance updated for user $userId on $date');
      }
    } catch (e) {
      print('Error marking attendance: $e');
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
          regNo: student.regNo,
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
              termRef.collection('studentPerformance').doc(student.regNo);
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
        regNo: doc.id,
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
      final docRef = scoresRef.doc(scores[i].regNo);
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

  static Future<List<Attendance>> fetchAttendance() async {
    try {
      final attendanceSnapshot =
          await FirebaseService.getDataStreamFromFirestore<Attendance>(
        collection: 'attendance',
        fromFirestore: (doc) => Attendance.fromFirestore(doc),
      ).first; // Get the first snapshot from the stream
      return attendanceSnapshot;
    } catch (e) {
      throw Exception('Error fetching attendance : $e');
    }
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
    required String regNo,
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
            .where('regNo', isEqualTo: regNo);
        // Fetch the student's score for this subject
        final scoresSnapshot = await scoresRef
            .get(); //FirebaseService.getWhere(collection: '$collection/${subjectDoc.id}/scores', queryFields: {'scores': regNo});

        for (var scoreDoc in scoresSnapshot.docs) {
          final data = scoreDoc.data();
          // Convert Firestore document to SubjectScore
          final score = SubjectScore(
            regNo: data['regNo'],
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
        regNo: student.regNo,
      );

      // Fetch traits and skills scores
      final traitsAndSkillsDoc = await FirebaseService.getDocumentById(
        'classes/$classId/sessions/$sessionId/terms/$termId/skillsAndTraits',
        student.regNo,
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
          .doc(student.regNo)
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
