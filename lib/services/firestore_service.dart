import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService<T> {
  final String collectionName;
  final T Function(DocumentSnapshot<Map<String, dynamic>>) fromSnapshot;
  final Map<String, dynamic> Function(T) toJson;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService({
    required this.collectionName,
    required this.fromSnapshot,
    required this.toJson,
  });

  // Add a new document
  Future<void> add(T model) async {
    // the document ID is automatically generated by firebase
    try {
      await _db.collection(collectionName).add(toJson(model));
    } catch (e) {
      debugPrint('Error adding document: $e');
      rethrow;
    }
  }

  Future<DocumentReference<Map<String, dynamic>>> addnReturn(T model) async {
    try {
      return await _db.collection(collectionName).add(toJson(model));
    } catch (e) {
      debugPrint('Error adding and returning document: $e');
      rethrow;
    }
  }

  Future<void> addUser(String docId, T model) async {
    //this method is necessary in order to manually set the document ID
    try {
      await _db.collection(collectionName).doc(docId).set(toJson(model));
    } catch (e) {
      debugPrint('Error adding document with custom ID: $e');
      rethrow;
    }
  }

  // Delete a document by ID
  Future<void> delete(String id) async {
    try {
      await _db.collection(collectionName).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  Future<void> deleteWhere({
    required String field,
    required String isEqualTo,
  }) async {
    try {
      // Fetch documents where the condition matches
      final querySnapshot = await _db
          .collection(collectionName)
          .where(field, isEqualTo: isEqualTo)
          .get();

      // Start a batch for more efficient deletions
      WriteBatch batch = _db.batch();

      // Loop through documents and add them to the batch delete
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch delete
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting documents by $isEqualTo: $e');
      rethrow;
    }
  }

  Future<AggregateQuery> fetchStats() async {
    try {
      return _db.collection(collectionName).count();
    } catch (e) {
      debugPrint('Error fetching $collectionName statistics: $e');
      throw Exception("Error fetching $collectionName statistics");
    }
  }

  // Fetch all documents in the collection
  Stream<List<T>> getAll() {
    try {
      return _db.collection(collectionName).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => fromSnapshot(doc)).toList());
    } catch (e) {
      debugPrint('Error fetching all documents: $e');
      rethrow;
    }
  }

  // Fetch a single document by ID
  Future<T?> getById(String id) async {
    try {
      final docSnapshot = await _db.collection(collectionName).doc(id).get();
      if (docSnapshot.exists) {
        return fromSnapshot(docSnapshot);
      } else {
        debugPrint('Document with ID $id does not exist.');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching document by ID: $e');
      rethrow;
    }
  }

  Stream<List<T>> getStream(String chatId) {
    try {
      return _db
          .collection(collectionName)
          .where('chatId', isEqualTo: chatId)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => fromSnapshot(doc)).toList());
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<List<T>> getWhere(
      {required String field, required String isEqualTo}) async {
    try {
      final docSnapshot = await _db
          .collection(collectionName)
          .where(field, isEqualTo: isEqualTo)
          .get();

      return docSnapshot.docs.map((doc) => fromSnapshot(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching data by $isEqualTo: $e');
      rethrow;
    }
  }

  // Update an existing document by ID
  Future<void> update(String id, T model) async {
    try {
      await _db.collection(collectionName).doc(id).update(toJson(model));
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }
}
