import 'package:ads_schools/helpers/firebase_helper.dart';
import 'package:ads_schools/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseService {
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
            'averageScore': FirebaseHelper.calculateAverageTraitScore(trait),
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
          scoreMap['grade'] = FirebaseHelper.calculateGrade(total);
          scoreMap['remark'] = FirebaseHelper.calculateRemark(total);
          final classAverage =
              total / 3; // Calculate subject average (CA1 + CA2 + Exam) / 3
          // Save class average
          scoreMap['average'] = double.parse(classAverage.toStringAsFixed(2));

          batch.set(docRef, scoreMap, SetOptions(merge: true));
        }
      }

      await batch.commit();

      // Calculate positions after scores are uploaded
      await FirebaseHelper.calculatePositions(
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

  /// Batch write: Add multiple documents to a collection.
  static Future<void> batchAddDocuments(
    String collectionPath,
    List<Map<String, dynamic>> documents,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection(collectionPath);

    for (var doc in documents) {
      batch.set(collection.doc(), doc);
    }

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Batch write failed: $e');
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

  static Stream<List<T>> getDataStreamFromFirestore<T>({
    required String collection,
    required T Function(DocumentSnapshot doc) fromFirestore,
    Map<String, dynamic>? queryFields,
  }) {
    try {
      Query query = FirebaseFirestore.instance.collection(collection);
      if (queryFields != null) {
        queryFields.forEach((key, value) {
          query = query.where(key, isEqualTo: value);
        });
      }

      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => fromFirestore(doc)).toList());
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

  static Future<QuerySnapshot> getSubCollection({
    required String collection,
    required String docId,
    required String subCollection,
  }) {
    try {
      return FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .collection(subCollection)
          .get();
    } on Exception catch (e) {
      throw Exception('Failed to fetch sub-collection: $e');
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
