import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Attendance {
  String? id;
  String studentId;
  DateTime? date;
  String status; // e.g., Signed In, Signed out,
  DateTime? signInTime;
  DateTime? signOutTime;
  String? currentClass;
  Timestamp? timeStamp;

  Attendance(
      {this.id,
      required this.studentId,
      this.date,
      required this.status,
      this.signInTime,
      this.signOutTime,
      this.currentClass,
      this.timeStamp});

  factory Attendance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Attendance(
        id: doc.id,
        studentId: data['studentId'] ?? '',
        date:
            data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
        status: data['status'] ?? '',
        signInTime: data['signInTime'] != null
            ? (data['signInTime'] as Timestamp).toDate()
            : null,
        signOutTime: data['signOutTime'] != null
            ? (data['signOutTime'] as Timestamp).toDate()
            : null,
        currentClass: data['currentClass'],
        timeStamp: data['timeStamp']);
  }

  Map<String, dynamic> toMap() {
    return {
      'currentClass': currentClass,
      'studentId': studentId,
      'date': date,
      'status': status,
      'signInTime': signInTime,
      'signOutTime': signOutTime,
    };
  }
}

class AttendanceStatus {
  int? present;
  int? absent;
  int? total;

  AttendanceStatus({
    this.present,
    this.absent,
    this.total,
  });

  // Factory method to create an Attendance object from Firestore data
  factory AttendanceStatus.fromMap(Map<String, dynamic> data) {
    return AttendanceStatus(
      present: data['present'] ?? 0,
      absent: data['absent'] ?? 0,
      total: data['total'] ?? 0,
    );
  }

  // Convert the Attendance object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'present': present,
      'absent': absent,
      'total': total,
    };
  }
}

class PerformanceData {
  AttendanceStatus? attendance;
  double? overallAverage;
  int? overallPosition;
  String? studentId;
  int? totalStudents;
  int? totalSubjects;
  int? totalScore;

  PerformanceData({
    this.studentId,
    this.overallAverage,
    this.totalSubjects,
    this.overallPosition,
    this.totalStudents,
    this.attendance,
    this.totalScore,
  });

  // Factory method to create a PerformanceData object from Firestore data
  factory PerformanceData.fromFirestore(Map<String, dynamic> data) {
    return PerformanceData(
      attendance: AttendanceStatus.fromMap(data['attendance']),
      overallAverage: (data['overallAverage'] ?? 0.0).toDouble(),
      overallPosition:
          data['overallPosition'] is int ? data['overallPosition'] as int : 0,
      studentId: data['studentId'] ?? '',
      totalStudents:
          data['totalStudents'] is int ? data['totalStudents'] as int : 0,
      totalSubjects:
          data['totalSubjects'] is int ? data['totalSubjects'] as int : 0,
      totalScore: data['totalScore'] is int ? data['totalScore'] as int : 0,
    );
  }

  // Convert a Firestore map into a PerformanceData object
  factory PerformanceData.fromMap(Map<String, dynamic> data) {
    return PerformanceData(
      attendance: AttendanceStatus.fromMap(data['attendance']),
      overallAverage: (data['overallAverage'] ?? 0.0).toDouble(),
      overallPosition:
          data['overallPosition'] is int ? data['overallPosition'] as int : 0,
      studentId: data['studentId'] ?? '',
      totalStudents:
          data['totalStudents'] is int ? data['totalStudents'] as int : 0,
      totalSubjects:
          data['totalSubjects'] is int ? data['totalSubjects'] as int : 0,
      totalScore: data['totalScore'] is int ? data['totalScore'] as int : 0,
    );
  }

  // Convert the PerformanceData object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'totalScore': totalScore,
      'overallAverage': overallAverage,
      'totalSubjects': totalSubjects,
      'overallPosition': overallPosition,
      'totalStudents': totalStudents,
      'attendance': attendance?.toMap(),
    };
  }
}

class PreviousClass {
  String? classId;
  String? sessionId;

  PreviousClass({
    this.classId,
    this.sessionId,
  });

  // Factory method to create an PreviousClass object from Firestore data
  factory PreviousClass.fromMap(Map<String, dynamic> data) {
    return PreviousClass(
      classId: data['classId'] ?? '',
      sessionId: data['sessionId'] ?? '',
    );
  }

  // Convert the PreviousClass object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'sessionId': sessionId,
    };
  }
}

class SchoolClass {
  late final String id;
  late final String name;
  final DateTime createdAt;

  SchoolClass({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory SchoolClass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolClass(
      id: doc.id,
      name: data['name'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  factory SchoolClass.fromMap(Map<String, dynamic> map) => SchoolClass(
        id: map['id'],
        name: map['name'],
        createdAt: map['createdAt'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'createdAt': createdAt,
      };
}

class Session {
  final String id;
  final String name;

  Session({required this.id, required this.name});

  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      name: data['name'],
    );
  }

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'],
        name: map['name'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
      };
}

class Student {
  final String? studentId;
  final String regNo;
  final String name;
  String currentClass;
  String? photo;
  PreviousClass? previousClass;
  Map<String, dynamic> personInfo;
  String? gender;
  DateTime? dob;
  String? parentName;
  String? parentPhone;
  String? address;
  String? bloodGroup;
  DateTime? dateJoined;

  Student({
    this.previousClass,
    this.studentId,
    required this.regNo,
    required this.name,
    required this.currentClass,
    this.photo,
    required this.personInfo,
    this.gender,
    this.dob,
    this.parentName,
    this.parentPhone,
    this.address,
    this.bloodGroup,
    this.dateJoined,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      studentId: doc.id,
      regNo: data['regNo'] ?? '', // Default to an empty string if null
      name: data['name'] ?? '',
      //previousClass: PreviousClass.fromMap(data['previousClass']),
      currentClass: data['currentClass'] ?? '',
      photo: data['photo'] ?? 'assets/profile.jpg',
      personInfo: data['personalInfo'] != null
          ? Map<String, dynamic>.from(data['personalInfo'] as Map)
          : {},
      gender: data['gender'] ?? '',
      dob: data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
      parentName: data['parentName'] ?? '',
      parentPhone: data['parentPhone'] ?? '',
      address: data['address'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      dateJoined: data['dateJoined'] != null
          ? (data['dateJoined'] as Timestamp).toDate()
          : null,
    );
  }

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        studentId: map['id'],
        regNo: map['regNo'] ?? '',
        name: map['name'] ?? '',
        currentClass: map['currentClass'] ?? '',
        photo: map['photo'],
        personInfo: map['personalInfo'] ?? {},
        gender: map['gender'] ?? '',
        dob: map['dob'] != null ? (map['dob'] as Timestamp).toDate() : null,
        parentName: map['parentName'] ?? '',
        parentPhone: map['parentPhone'] ?? '',
        address: map['address'] ?? '',
        bloodGroup: map['bloodGroup'] ?? '',
        dateJoined: map['dateJoined'] != null
            ? (map['dateJoined'] as Timestamp).toDate()
            : null,
        previousClass: PreviousClass.fromMap(map['previousClass']),
      );

  Map<String, dynamic> toMap() => {
        'id': studentId,
        'regNo': regNo,
        'name': name,
        'previousClass': previousClass?.toMap(),
        'currentClass': currentClass,
        'photoUrl': photo,
        'personalInfo': personInfo,
        'gender': gender,
        'dob': Timestamp.fromDate(dob ?? DateTime.now()),
        'parentName': parentName,
        'parentPhone': parentPhone,
        'address': address,
        'bloodGroup': bloodGroup,
        'dateJoined': Timestamp.fromDate(dateJoined ?? DateTime.now()),
      };
}

class Subject {
  String? id;
  final String name;
  final String? materialUrl;

  Subject({
    this.id,
    required this.name,
    this.materialUrl,
  });

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      name: data['name'],
      materialUrl: data['materialUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'materialUrl': materialUrl,
      };
}

class SubjectScore {
  final String regNo;
  final int? ca1;
  final int? ca2;
  final int? exam;
  final int? total;
  String? position;
  final double? average;
  final String? grade;
  final String? remark;

  final String? subjectName;

  SubjectScore({
    required this.regNo,
    this.subjectName,
    this.ca1,
    this.ca2,
    this.exam,
    this.total,
    this.average,
    this.position,
    this.grade,
    this.remark,
  });

  factory SubjectScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectScore(
      regNo: data['regNo'],
      subjectName: data['subjectName'] ?? '',
      ca1: data['ca1']?.toInt(),
      ca2: data['ca2']?.toInt(),
      exam: data['exam']?.toInt(),
      total: data['total']?.toInt(),
      average: data['average']?.toDouble(),
      position: data['position'] ?? '',
      grade: data['grade'] ?? '',
      remark: data['remark'] ?? '',
    );
  }

  factory SubjectScore.fromMap(Map<String, dynamic> map) => SubjectScore(
        regNo: map['regNo'] ?? '',
        subjectName: map['subjectName'] ?? '',
        ca1: map['ca1']?.toInt() ?? 0,
        ca2: map['ca2']?.toInt() ?? 0,
        exam: map['exam']?.toInt() ?? 0,
        total: map['total']?.toInt() ?? 0,
        average: map['average']?.toDouble() ?? 0.0,
        position: map['position'] ?? '',
        grade: map['grade'] ?? '',
        remark: map['remark'] ?? '',
      );
  Map<String, dynamic> toMap() => {
        "regNo": regNo,
        'subjectName': subjectName,
        "ca1": ca1 ?? '',
        "ca2": ca2 ?? '',
        "exam": exam ?? '',
        "total": total ?? '',
        "average": average ?? '',
        "position": position ?? '',
        "grade": grade ?? '',
        "remark": remark ?? '',
      };
}

class Term {
  final String id;
  final String name;

  Term({required this.id, required this.name});

  factory Term.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Term(
      id: doc.id,
      name: data['name'],
    );
  }
  factory Term.fromMap(Map<String, dynamic> map) => Term(
        id: map['id'],
        name: map['name'],
      );
  Map<String, dynamic> toMap() => {
        'name': name,
      };
}

class TraitsAndSkills {
  final String regNo;
  final int? creativity;
  final int? sports;
  final int? attentiveness;
  final int? obedience;
  final int? cleanliness;
  final int? politeness;
  final int? honesty;
  final int? punctuality;
  final int? music;

  TraitsAndSkills({
    required this.regNo,
    this.creativity,
    this.sports,
    this.attentiveness,
    this.obedience,
    this.cleanliness,
    this.politeness,
    this.honesty,
    this.punctuality,
    this.music,
  });
  factory TraitsAndSkills.fromFirestore(Map<String, dynamic> data) {
    return TraitsAndSkills(
      regNo: data['regNo'] ?? '',
      creativity: data['creativity'] != null ? data['creativity'] as int : null,
      sports: data['sports'] != null ? data['sports'] as int : null,
      attentiveness:
          data['attentiveness'] != null ? data['attentiveness'] as int : null,
      obedience: data['obedience'] != null ? data['obedience'] as int : null,
      cleanliness:
          data['cleanliness'] != null ? data['cleanliness'] as int : null,
      politeness: data['politeness'] != null ? data['politeness'] as int : null,
      honesty: data['honesty'] != null ? data['honesty'] as int : null,
      punctuality:
          data['punctuality'] != null ? data['punctuality'] as int : null,
      music: data['music'] != null ? data['music'] as int : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'regNo': regNo,
      'creativity': creativity,
      'sports': sports,
      'attentiveness': attentiveness,
      'obedience': obedience,
      'cleanliness': cleanliness,
      'politeness': politeness,
      'honesty': honesty,
      'punctuality': punctuality,
      'music': music,
    };
  }
}

class UserModel {
  late String? userId;
  final String? firstName;
  final String? otherNames;
  final String? gender;
  final String? dob;
  final String? email;
  final String? phone;
  final String? address;
  final String? role;
  late final String? photo;

  UserModel(
      {this.userId,
      this.firstName,
      this.otherNames,
      this.gender,
      this.dob,
      this.role,
      this.email,
      this.phone,
      this.address,
      this.photo});

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      firstName: data['firstName'] ?? '',
      otherNames: data['otherNames'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      dob: data['dob'] ?? '',
      role: data['role'] ?? '',
      photo: data['photo'] ?? '',
      gender: data['gender'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": userId,
      "email": email,
      "phone": phone,
      "address": address,
      "firstName": firstName,
      "otherNames": otherNames,
      "gender": gender,
      "dob": dob,
      "role": role,
      "photo": photo,
    };
  }

  static UserModel fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    try {
      final data = snapshot.data()!;
      return UserModel(
        email: data['email'] as String?,
        phone: data['phone'] as String?,
        address: data['address'] as String?,
        firstName: data['firstName'] as String?,
        otherNames: data['otherNames'] as String?,
        gender: data['gender'] as String?,
        dob: data['dob'] as String?,
        role: data['role'] as String?,
        photo: data['photo'] as String?,
        userId: data['id'] as String?,
      );
    } catch (e) {
      debugPrint('Error parsing user data from snapshot: $e');
      return UserModel();
    }
  }
}
