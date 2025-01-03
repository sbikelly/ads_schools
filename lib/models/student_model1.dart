// Student model
import 'package:cloud_firestore/cloud_firestore.dart';

// Domain Scores model (for both Affective and Psychomotor)
class DomainScores {
  final String regNo;
  final String term;
  final String session;
  final String trait;
  final List<Rating> ratings;

  DomainScores({
    required this.regNo,
    required this.term,
    required this.session,
    required this.trait,
    required this.ratings,
  });

  factory DomainScores.fromFirestore(Map<String, dynamic> data) {
    return DomainScores(
      regNo: data['regNo'] ?? '',
      term: data['term'] ?? '',
      session: data['session'] ?? '',
      trait: data['trait'] ?? '',
      ratings: List<Rating>.from(
        (data['ratings'] as List<dynamic>? ?? [])
            .map((x) => Rating.fromMap(x as Map<String, dynamic>)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'regNo': regNo,
      'term': term,
      'session': session,
      'trait': trait,
      'ratings': ratings.map((rating) => rating.toMap()).toList(),
    };
  }
}

// Generic Rating class for both Skill and Trait ratings
class Rating {
  final String name; // skill or trait name
  final String rating;

  Rating({
    required this.name,
    required this.rating,
  });

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      name: map['name'] ?? '',
      rating: map['rating'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rating': rating,
    };
  }
}

class Student {
  final String regNo;
  final String name;
  final String currentClass;
  final String? photoUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? parentName;
  final String? parentPhone;
  final String? address;
  final String? bloodGroup;
  final DateTime? dateJoined;

  Student({
    required this.regNo,
    required this.name,
    required this.currentClass,
    this.photoUrl,
    this.gender,
    this.dateOfBirth,
    this.parentName,
    this.parentPhone,
    this.address,
    this.bloodGroup,
    this.dateJoined,
  });

  factory Student.fromFirestore(Map<String, dynamic> data) {
    return Student(
      regNo: data['regNo'] ?? '',
      name: data['name'] ?? '',
      currentClass: data['currentClass'] ?? '',
      photoUrl: data['photoUrl'],
      gender: data['gender'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      parentName: data['parentName'],
      parentPhone: data['parentPhone'],
      address: data['address'],
      bloodGroup: data['bloodGroup'],
      dateJoined: data['dateJoined'] != null
          ? (data['dateJoined'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'regNo': regNo,
      'name': name,
      'currentClass': currentClass,
      'photoUrl': photoUrl,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth ?? DateTime.now()),
      'parentName': parentName,
      'parentPhone': parentPhone,
      'address': address,
      'bloodGroup': bloodGroup,
      'dateJoined': Timestamp.fromDate(dateJoined ?? DateTime.now()),
    };
  }
}

// Subject Scores model
class SubjectScore {
  final String? grade;
  final String regNo;
  final String term;
  final String session;
  final String subjectName;
  final String currentClass;
  final double? ca1;
  final double? ca2;
  final double? exam;
  final double? total;
  final int? position;
  final double? average;
  final String? remark;

  SubjectScore({
    required this.regNo,
    required this.term,
    required this.session,
    required this.subjectName,
    required this.currentClass,
    this.ca1,
    this.ca2,
    this.grade,
    this.exam,
    this.total,
    this.position,
    this.average,
    this.remark,
  });

  factory SubjectScore.fromFirestore(Map<String, dynamic> data) {
    return SubjectScore(
      regNo: data['regNo'] ?? '',
      grade: data['grade'] ?? '',
      term: data['term'] ?? '',
      session: data['session'] ?? '',
      subjectName: data['subjectName'] ?? '',
      currentClass: data['currentClass'] ?? '',
      ca1: data['ca1']?.toDouble(),
      ca2: data['ca2']?.toDouble(),
      exam: data['exam']?.toDouble(),
      total: data['total']?.toDouble(),
      position: data['position'],
      average: data['average']?.toDouble(),
      remark: data['remark'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'regNo': regNo,
      'grade': grade,
      'term': term,
      'session': session,
      'subjectName': subjectName,
      'currentClass': currentClass,
      'ca1': ca1,
      'ca2': ca2,
      'exam': exam,
      'total': total,
      'position': position,
      'average': average,
      'remark': remark,
    };
  }
}
