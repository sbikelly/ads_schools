import 'package:ads_schools/helpers/firebase_helper.dart';
import 'package:ads_schools/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final startDate;
  final endDate;

  const AttendanceScreen(
      {super.key, required this.classId, this.startDate, this.endDate});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, StudentAttendance> _attendance = {};

  List<Student> allStudents = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance')),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attend')
              .orderBy('date')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              // Display a loading spinner while data is being fetched.
              return const Center(child: CircularProgressIndicator());
            }

            final attendance = snapshot.data!.docs;
            if (attendance.isEmpty) {
              // Display "No Class Available" if no classes exist.
              return const Center(
                child: Text('No Attendance Available'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: attendance.length,
              itemBuilder: (context, index) {
                final attendanceDoc = attendance[index];
                final attendanceData = Attendance1.fromFirestore(attendanceDoc);
                final student = attendanceData.students;
                return ListTile(
                  onTap: () => AttendanceService()
                      .generateAndSharePdf(student.studentId, student.status),
                  title: Text(student!.studentId),
                  trailing: DropdownButton<String>(
                    value: student.status,
                    items: ['Present', 'Absent', 'Late']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _markAttendance(student.studentId, value);
                      }
                    },
                  ),
                );
              },
            );
          }),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final attendanceData = await AttendanceService()
        .fetchAttendance1(widget.classId, widget.startDate, widget.endDate);
    print('fetched');
    setState(() {
      _attendance.addAll(attendanceData);
    });
    print('set');
  }

  // Fetch students
  Future<void> _loadStudents() async {
    try {
      final fetchedStudents = await FirebaseHelper.fetchStudents();
      setState(() {
        allStudents = fetchedStudents;
      });
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }
  }

  Future<void> _markAttendance(String studentId, String status) async {
    final attendance = StudentAttendance(
      studentId: studentId,
      status: status,
      signInTime: status == 'Present' ? DateTime.now() : null,
    );
    await AttendanceService()
        .markAttendance1(widget.classId, widget.startDate, attendance);
    setState(() {
      _attendance[studentId] = attendance;
    });
  }
}
