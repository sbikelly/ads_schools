import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firestore_service.dart';

class Services {
  // Singleton pattern
  static final Services _instance = Services._internal();

  final FirestoreService<UserModel> userService = FirestoreService<UserModel>(
    collectionName: 'users',
    fromSnapshot: (snapshot) => UserModel.fromSnapshot(snapshot),
    toJson: (model) => model.toJson(),
  );

  final FirestoreService<Student> studentService = FirestoreService<Student>(
    collectionName: 'students',
    fromSnapshot: (snapshot) => Student.fromFirestore(snapshot),
    toJson: (model) => model.toMap(),
  );

  final FirestoreService<Subject> subjectService = FirestoreService<Subject>(
    collectionName: 'subjects',
    fromSnapshot: (snapshot) => Subject.fromFirestore(snapshot),
    toJson: (model) => model.toMap(),
  );

  final FirestoreService<SchoolClass> classService =
      FirestoreService<SchoolClass>(
    collectionName: 'classes',
    fromSnapshot: (snapshot) => SchoolClass.fromFirestore(snapshot),
    toJson: (model) => model.toMap(),
  );

  factory Services() {
    return _instance;
  }

  Services._internal();
/*
  Stream<List<MessageModel>> getMessages(String chatId) {
    return messageService.getStream(chatId);
  }
  */
}
