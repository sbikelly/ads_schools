class SchoolData {
  final String session;
  final String schoolPhone;
  final String termStart;
  final String termEnd;
  final String nextTermStart;
  final String schoolName;
  final String schoolAddress;
  final String schoolEmail;
  final String schoolWebsite;

  SchoolData({
    required this.session,
    required this.schoolPhone,
    required this.termStart,
    required this.termEnd,
    required this.nextTermStart,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolEmail,
    required this.schoolWebsite,
  });

  factory SchoolData.fromJson(Map<String, dynamic> json) {
    return SchoolData(
      session: json['session'],
      schoolPhone: json['schoolPhone'],
      termStart: json['termStart'],
      termEnd: json['termEnd'],
      nextTermStart: json['nextTermStart'],
      schoolName: json['schoolName'],
      schoolAddress: json['schoolAddress'],
      schoolEmail: json['schoolEmail'],
      schoolWebsite: json['schoolWebsite'],
    );
  }
}
