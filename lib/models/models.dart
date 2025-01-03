import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicRecord {
  final String? subjectId;
  final String subjectName;
  final int ca1;
  final int ca2;
  final int exam;
  final int total;
  final String grade;
  final String remark;
  final int position;
  final int classCount;
  final double classAverage;

  AcademicRecord({
    this.subjectId,
    required this.subjectName,
    required this.ca1,
    required this.ca2,
    required this.exam,
    required this.total,
    required this.grade,
    required this.remark,
    required this.position,
    required this.classCount,
    required this.classAverage,
  });

  factory AcademicRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AcademicRecord(
      subjectId: doc.id,
      subjectName: data['subjectName'] ?? '',
      ca1: data['ca1']?.toInt() ?? 0,
      ca2: data['ca2']?.toInt() ?? 0,
      exam: data['exam']?.toInt() ?? 0,
      total: data['total']?.toInt() ?? 0,
      grade: data['grade'] ?? '',
      remark: data['remark'] ?? '',
      position: data['position']?.toInt() ?? 0,
      classCount: data['classCount']?.toInt() ?? 0,
      classAverage: data['classAverage']?.toDouble() ?? 0.0,
    );
  }

  factory AcademicRecord.fromMap(Map<String, dynamic> map) => AcademicRecord(
        subjectId: map['id'],
        subjectName: map['subjectName'] ?? '',
        ca1: map['ca1']?.toInt() ?? 0,
        ca2: map['ca2']?.toInt() ?? 0,
        exam: map['exam']?.toInt() ?? 0,
        total: map['total']?.toInt() ?? 0,
        grade: map['grade'] ?? '',
        remark: map['remark'] ?? '',
        position: map['position']?.toInt() ?? 0,
        classCount: map['classCount']?.toInt() ?? 0,
        classAverage: map['classAverage']?.toDouble() ?? 0.0,
      );

  String getFormattedPosition() => '$position${getPositionSuffix()}';

  String getPositionSuffix() {
    if (position >= 11 && position <= 13) return 'th';
    switch (position % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': subjectId,
        'subjectName': subjectName,
        'ca1': ca1,
        'ca2': ca2,
        'exam': exam,
        'total': total,
        'grade': grade,
        'remark': remark,
        'position': position,
        'classCount': classCount,
        'classAverage': classAverage,
      };
}

class Assessment {
  final String? id;
  final String type;
  final String name;
  final String rating;

  Assessment({
    this.id,
    required this.type,
    required this.name,
    required this.rating,
  });

  factory Assessment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assessment(
      id: doc.id,
      type: data['type'] ?? '',
      name: data['name'] ?? '',
      rating: data['rating'] ?? '',
    );
  }

  factory Assessment.fromMap(Map<String, dynamic> map) => Assessment(
        id: map['id'] ?? '',
        type: map['type'] ?? '',
        name: map['name'] ?? '',
        rating: map['rating'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'name': name,
        'rating': rating,
      };
}

class ReportCard {
  final String studentId;
  final String term;
  final String session;
  final Map<String, dynamic> attendance;
  final List<SubjectScore> subjectScores;
  final List<Assessment> skills;
  final List<Assessment> traits;
  final int overallPosition;
  final int totalStudents;
  final double overallAverage;

  ReportCard({
    required this.studentId,
    required this.term,
    required this.session,
    required this.attendance,
    required this.subjectScores,
    required this.skills,
    required this.traits,
    required this.overallPosition,
    required this.totalStudents,
    required this.overallAverage,
  });

  factory ReportCard.fromMap(Map<String, dynamic> map) => ReportCard(
        studentId: map['id'] ?? '',
        overallPosition: map['overallPosition']?.toInt() ?? 0,
        totalStudents: map['totalStudents']?.toInt() ?? 0,
        overallAverage: map['overallAverage']?.toDouble() ?? 0.0,
        term: map['term'] ?? '',
        session: map['session'] ?? '',
        attendance: map['attendance'] ?? {},
        subjectScores: List<SubjectScore>.from(
            (map['subjectScores'] ?? []).map((x) => SubjectScore.fromMap(x))),
        skills: List<Assessment>.from(
            (map['skills'] ?? []).map((x) => Assessment.fromMap(x))),
        traits: List<Assessment>.from(
            (map['traits'] ?? []).map((x) => Assessment.fromMap(x))),
      );

  String getOverallPositionFormatted() {
    if (overallPosition >= 11 && overallPosition <= 13) {
      return '${overallPosition}th';
    }
    switch (overallPosition % 10) {
      case 1:
        return '${overallPosition}st';
      case 2:
        return '${overallPosition}nd';
      case 3:
        return '${overallPosition}rd';
      default:
        return '${overallPosition}th';
    }
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'overallPosition': overallPosition,
        'totalStudents': totalStudents,
        'overallAverage': overallAverage,
        'term': term,
        'session': session,
        'attendance': attendance,
        'academics': subjectScores.map((x) => x.toMap()).toList(),
        'skills': skills.map((x) => x.toMap()).toList(),
        'traits': traits.map((x) => x.toMap()).toList(),
      };
}

class SchoolClass {
  final String id;
  final String name;
  final DateTime createdAt;

  SchoolClass({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory SchoolClass.fromFirestore(String id, Map<String, dynamic> data) =>
      SchoolClass(
        id: id,
        name: data['name'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
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

  factory Session.fromFirestore(String id, Map<String, dynamic> data) =>
      Session(
        id: id,
        name: data['name'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
      };
}

class Student {
  final String? studentId;
  final String regNo;
  final String name;
  final String currentClass;
  final String? photoUrl;
  final Map<String, dynamic> personalInfo;

  Student({
    this.studentId,
    required this.regNo,
    required this.name,
    required this.currentClass,
    this.photoUrl,
    required this.personalInfo,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      studentId: doc.id,
      regNo: data['regNo'] ?? '', // Default to an empty string if null
      name: data['name'] ?? '',
      currentClass: data['currentClass'] ?? '',
      photoUrl: data['photoUrl'] ?? 'assets/profile.jpg',
      personalInfo: data['personalInfo'] != null
          ? Map<String, dynamic>.from(data['personalInfo'] as Map)
          : {},
    );
  }

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        studentId: map['id'],
        regNo: map['regNo'] ?? '',
        name: map['name'] ?? '',
        currentClass: map['currentClass'] ?? '',
        photoUrl: map['photoUrl'],
        personalInfo: map['personalInfo'] ?? {},
      );

  Map<String, dynamic> toMap() => {
        'id': studentId,
        'regNo': regNo,
        'name': name,
        'currentClass': currentClass,
        'photoUrl': photoUrl,
        'personalInfo': personalInfo,
      };
}

class Subject {
  final String name;

  Subject({required this.name});

  factory Subject.fromFirestore(Map<String, dynamic> data) => Subject(
        name: data['name'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
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

  factory SubjectScore.fromFirestore(Map<String, dynamic> data) => SubjectScore(
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

  factory Term.fromFirestore(String id, Map<String, dynamic> data) => Term(
        id: id,
        name: data['name'],
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
