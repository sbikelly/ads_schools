import 'package:ads_schools/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseService {
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
            attendance: Attendance(present: 0, absent: 0, total: 0),
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
  double calculateAverageTraitScore(TraitsAndSkills trait) {
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

  String calculateGrade(int total) {
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

  Future<void> calculatePositions({
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

  String calculateRemark(int total) {
    if (total >= 85) return 'Excellent';
    if (total >= 80) return 'Very Good';
    if (total >= 75) return 'Good';
    if (total >= 70) return 'Fair';
    if (total >= 65) return 'Satisfactory';
    if (total >= 50) return 'Pass';
    return 'Fail';
  }

  Future<String> createClass(String name) async {
    final classRef = FirebaseFirestore.instance.collection('classes').doc();

    final schoolClass = SchoolClass(
      id: classRef.id,
      name: name,
      createdAt: DateTime.now(),
    );

    await classRef.set(schoolClass.toMap());
    return classRef.id;
  }

  Future<void> saveStudentScores({
    required String classId,
    required String sessionId,
    required String termId,
    required String subjectId,
    required List<SubjectScore> scores,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
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

      // Add all scores in batch
      for (final score in scores) {
        if (score.regNo.isNotEmpty) {
          final docRef = scoresRef.doc(score.regNo);
          batch.set(docRef, score.toMap(), SetOptions(merge: true));
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error saving scores: $e');
      throw Exception('Failed to save scores: $e');
    }
  }

  Future<void> setupClassStructure({
    required String classId,
    required List<String> sessions,
    required Map<String, List<String>> termsAndSubjects,
  }) async {
    final classRef =
        FirebaseFirestore.instance.collection('classes').doc(classId);
    for (final session in sessions) {
      final sessionRef = classRef.collection('sessions').doc();

      await sessionRef.set(Session(id: sessionRef.id, name: session).toMap());

      for (final term in termsAndSubjects.keys) {
        final termRef = sessionRef.collection('terms').doc();
        await termRef.set(Term(id: termRef.id, name: term).toMap());
        for (final subject in termsAndSubjects[term]!) {
          final subjectRef = termRef.collection('subjects').doc();
          await subjectRef.set(Subject(name: subject).toMap());
        }
      }
    }
  }

  Future<void> updateClass(
    String classId,
    String newName, {
    required List<String> sessions,
    required Map<String, List<String>> termsAndSubjects,
  }) async {
    try {
      // Update class name
      final classRef =
          FirebaseFirestore.instance.collection('classes').doc(classId);
      await classRef.update({'name': newName});

      // Delete existing structure
      final sessionQuery = await classRef.collection('sessions').get();
      for (var session in sessionQuery.docs) {
        await session.reference.delete();
      }

      // Setup new structure
      await setupClassStructure(
        classId: classId,
        sessions: sessions,
        termsAndSubjects: termsAndSubjects,
      );
    } catch (e) {
      debugPrint('Error updating class: $e');
      throw Exception('Failed to update class: $e');
    }
  }

  Future<void> uploadBatchSkillsAndTraits({
    required String classId,
    required String sessionId,
    required String termId,
    required List<TraitsAndSkills> traits,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final traitsRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .collection('terms')
          .doc(termId)
          .collection('skillsAndTraits');

      for (var trait in traits) {
        if (trait.regNo.isNotEmpty) {
          final docRef = traitsRef.doc(trait.regNo);

          final traitsMap = {
            'creativity': trait.creativity ?? 0,
            'sports': trait.sports ?? 0,
            'attentiveness': trait.attentiveness ?? 0,
            'obedience': trait.obedience ?? 0,
            'cleanliness': trait.cleanliness ?? 0,
            'politeness': trait.politeness ?? 0,
            'honesty': trait.honesty ?? 0,
            'punctuality': trait.punctuality ?? 0,
            'music': trait.music ?? 0,
            'averageScore': calculateAverageTraitScore(trait),
          };

          batch.set(docRef, traitsMap, SetOptions(merge: true));
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error uploading batch traits and skills: $e');
      throw Exception('Failed to upload batch traits and skills: $e');
    }
  }

  Future<void> uploadBatchSubjectScores({
    required String classId,
    required String sessionId,
    required String termId,
    required String subjectId,
    required List<SubjectScore> scores,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
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

      for (var score in scores) {
        if (score.regNo.isNotEmpty) {
          final docRef = scoresRef.doc(score.regNo);
          final total = (score.ca1 ?? 0) + (score.ca2 ?? 0) + (score.exam ?? 0);

          final scoreMap = score.toMap();
          scoreMap['total'] = total;
          3;
          scoreMap['grade'] = calculateGrade(total);
          scoreMap['remark'] = calculateRemark(total);
          final classAverage =
              total / 3; // Calculate subject average (CA1 + CA2 + Exam) / 3
          // Save class average
          scoreMap['average'] = double.parse(classAverage.toStringAsFixed(2));

          batch.set(docRef, scoreMap, SetOptions(merge: true));
        }
      }

      await batch.commit();

      // Calculate positions after scores are uploaded
      await calculatePositions(
        classId: classId,
        sessionId: sessionId,
        termId: termId,
        subjectId: subjectId,
      );
    } catch (e) {
      debugPrint('Error uploading batch scores: $e');
      throw Exception('Failed to upload batch scores: $e');
    }
  }

  static Future<DocumentReference?> addDocument<T>({
    required String collection,
    required T document,
    required Map<String, dynamic> Function(T) toJsonOrMap,
  }) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection(collection)
          .add(toJsonOrMap(document));
      return docRef;
    } catch (e) {
      throw Exception('Error adding document: $e');
    }
  }

  static Future<void> deleteDocument(
      String collection, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  static Future<void> deleteDocumentsWhere({
    required String collection,
    required Map<String, dynamic> queryFields,
  }) async {
    try {
      // Build query with multiple conditions
      Query query = FirebaseFirestore.instance.collection(collection);
      queryFields.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No documents found matching criteria in $collection');
        return;
      }

      // Batch delete for better performance
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint(
          '${querySnapshot.docs.length} documents deleted from $collection');
    } catch (e) {
      debugPrint('Error in batch deletion: $e');
      throw Exception('Failed to delete documents: $e');
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
      final subjectsSnapshot = await subjectsRef.get();

      for (var subjectDoc in subjectsSnapshot.docs) {
        // Convert subject document to Subject model
        final subjectData = subjectDoc.data();
        final subject = Subject.fromFirestore(subjectData);
        final scoresRef = subjectsRef
            .doc(subjectDoc.id)
            .collection('scores')
            .where('regNo', isEqualTo: regNo);
        // Fetch the student's score for this subject
        final scoresSnapshot = await scoresRef.get();

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

  static Future<List<DocumentSnapshot>> getAllDocuments(
      String collection) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection(collection).get();
      return querySnapshot.docs;
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  static Stream<List<T>> getDataStream<T>({
    required String collection,
    required T Function(Map<String, dynamic>) fromMap,
    Map<String, dynamic>? queryFields,
  }) {
    try {
      Query query = FirebaseFirestore.instance.collection(collection);
      if (queryFields != null) {
        queryFields.forEach((key, value) {
          query = query.where(key, isEqualTo: value);
        });
      }

      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList());
    } catch (e) {
      throw Exception('Failed to get data stream: $e');
    }
  }

  static Future<DocumentSnapshot> getDocumentById(
      String collection, String documentId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId)
          .get();
      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }
      return docSnapshot;
    } catch (e) {
      throw Exception('Failed to fetch document: $e');
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
      final classDoc = await getDocumentById('classes', classId);
      final schoolClass = SchoolClass.fromFirestore(classDoc);
      final className = schoolClass.name;

      // Fetch student information
      final studentDoc = await getDocumentById('students', studentId);
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
      final traitsAndSkillsDoc = await getDocumentById(
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

  static Future<Map<String, dynamic>> getReportCardData1({
    required String classId,
    required String sessionId,
    required String termId,
    required String studentId,
  }) async {
    try {
      // step 0: Fetch class name
      final classDoc = await getDocumentById('classes', classId);
      final schoolClass = SchoolClass.fromFirestore(classDoc);
      final className = schoolClass.name;
      // Step 1: Fetch student information
      final studentDoc = await getDocumentById('students', studentId);
      final student = Student.fromFirestore(studentDoc);

      student.currentClass = className;

      // Step 2: Fetch subject scores
      final subjectScores = await fetchStudentScores(
        classId: classId,
        sessionId: sessionId,
        termId: termId,
        regNo: student.regNo,
      );

      // Step 3: Fetch traits and skills scores

      final traitsAndSkillsDoc = await getDocumentById(
        'classes/$classId/sessions/$sessionId/terms/$termId/skillsAndTraits',
        student.regNo,
      );

      TraitsAndSkills? traitsAndSkills;
      traitsAndSkills = TraitsAndSkills.fromFirestore(
        traitsAndSkillsDoc.data() as Map<String, dynamic>,
      );
/*
      final traitsAndSkillsQuery = await getWhere(
        collection:
            'classes/$classId/sessions/$sessionId/terms/$termId/skillsAndTraits',
        queryFields: {'regNo': student.regNo},
      );
//using fromFirestore
      final traitsAndSkills = traitsAndSkillsQuery.docs
          .map((doc) =>
              TraitsAndSkills.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
      //using fromMap
    final traitsAndSkills = traitsAndSkillsQuery.docs
        .map((doc) => TraitsAndSkills.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
        
      debugPrint(
          'Retrieved ${traitsAndSkills.length} traits and skills entries');

      for (var skill in traitsAndSkills) {
        debugPrint(
            'RegNo: ${skill.regNo}, Creativity: ${skill.creativity}, Sports: ${skill.sports}, Attentiveness: ${skill.attentiveness}');
      }
*/

// Step 4: Fetch overall performance data (average, position, attendance)
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
      var performanceData = <String, dynamic>{};
      if (performanceDoc.exists) {
        performanceData = performanceDoc.data()!;
      }

      // Step 6: Organize data for report card screen
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

  static Future<QuerySnapshot> getWhere({
    required String collection,
    required Map<String, dynamic> queryFields,
  }) async {
    try {
      Query query = FirebaseFirestore.instance.collection(collection);
      queryFields.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
      return await query.get();
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  static Future<DocumentReference> updateOrAddDocument<T>({
    required String collection,
    required T document,
    required Map<String, dynamic> queryFields,
    required Map<String, dynamic> Function(T) toJsonOrMap,
  }) async {
    try {
      final collectionRef = FirebaseFirestore.instance.collection(collection);
      final query = queryFields.entries.fold(
        collectionRef as Query,
        (query, field) => query.where(field.key, isEqualTo: field.value),
      );

      final querySnapshot = await query.limit(1).get();
      final documentData = toJsonOrMap(document);

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        await docRef.update(documentData);
        return docRef;
      }

      final newDocRef = await collectionRef.add(documentData);
      return newDocRef;
    } catch (e) {
      throw Exception('Error updating or adding document: $e');
    }
  }
}
