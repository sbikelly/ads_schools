import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';

class AttendanceAdminDashboard extends StatefulWidget {
  const AttendanceAdminDashboard({super.key});

  @override
  _AttendanceAdminDashboardState createState() =>
      _AttendanceAdminDashboardState();
}

class AttendanceService {
  static Stream<List<Attendance>> fetchFilteredAttendance(
      {required DateTime date, String? classFilter}) {
    final startOfDay = _startOfDay(date);
    final endOfDay = _endOfDay(date);

    Query query = FirebaseFirestore.instance.collection('attendance')
      ..where('timeStamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timeStamp', isLessThanOrEqualTo: endOfDay);

    if (classFilter != null && classFilter.isNotEmpty) {
      query = query.where('currentClass',
          isEqualTo: classFilter); // Filter by class
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Attendance.fromFirestore(doc)).toList());
  }
static Future<void> recordAttendance(String studentId) async {
    final today = DateTime.now();
    final dateKey = "${studentId}_${today.toIso8601String().split('T').first}";

    final attendanceDoc =
        FirebaseFirestore.instance.collection('attendance').doc(dateKey);

    final snapshot = await attendanceDoc.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      if (data['signOutTime'] == null) {
        // Sign out the student
        await attendanceDoc.update({
          'signOutTime': Timestamp.now(),
          'status': 'Signed Out',
        });
      } else {
        // Already signed out
        throw Exception("Student has already signed out.");
      }
    } else {
      // Sign in the student
      await attendanceDoc.set({
        'studentId': studentId,
        'date': Timestamp.fromDate(today),
        'signInTime': Timestamp.now(),
        'status': 'Signed In',
        'signOutTime': null,
        'currentClass': 'QBykrlq5m3IUXINQxr1h'
      });
    }
  }

  static Future<void> recordAttendance1(String studentId) async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        throw Exception('Student not found');
      }

      final student = Student.fromFirestore(studentDoc);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Query existing attendance for today
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date',
              isLessThan:
                  Timestamp.fromDate(today.add(const Duration(days: 1))))
          .get();

      if (attendanceQuery.docs.isEmpty) {
        // Create new attendance record
        await FirebaseFirestore.instance.collection('attendance').add({
          'studentId': studentId,
          'date': Timestamp.fromDate(today),
          'signInTime': Timestamp.now(),
          'status': 'Signed In',
          'signOutTime': null,
          'currentClass': student.currentClass,
          'timeStamp': Timestamp.now(),
        });
        return;
      }

      final existingAttendance = attendanceQuery.docs.first;
      if (existingAttendance.data()['signOutTime'] == null) {
        // Sign out
        await existingAttendance.reference.update({
          'signOutTime': Timestamp.now(),
          'status': 'Signed Out',
          'timeStamp': Timestamp.now(),
        });
      } else {
        throw Exception('Student has already completed attendance for today');
      }
    } catch (e) {
      throw Exception('Failed to record attendance: $e');
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

class _AttendanceAdminDashboardState extends State<AttendanceAdminDashboard> {
  final _qrScanner = QrBarCodeScannerDialog();
  DateTime selectedDate = DateTime.now();
  String? selectedClass;

  List<SchoolClass> classes = [];
  List<Student> allStudents = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Admin Dashboard')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Column(
                  children: [
                    _buildFilters(),
                    Expanded(child: _buildAttendanceView()),
                  ],
                ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Widget _buildAttendanceDetails(List<Attendance> attendanceRecords) {
    return ListView.builder(
      itemCount: attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = attendanceRecords[index];
        final student = allStudents.firstWhere(
          (std) => std.regNo == record.studentId,
          orElse: () => Student(
              name: 'Unknown', regNo: '', currentClass: '', personInfo: {}),
        );
        final schoolClass = classes.firstWhere(
          (cls) => cls.id == record.currentClass,
          orElse: () => SchoolClass(
              id: 'Unknown', name: 'Unknown', createdAt: DateTime.now()),
        );

        return Card(
          child: ListTile(
            title: Text(student.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle:
                Text('Status: ${record.status} | Class: ${schoolClass.name}'),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Sign In: ${_formatTimestamp(record.signInTime)}'),
                Text('Sign Out: ${_formatTimestamp(record.signOutTime)}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendancePieChart(List<Attendance> attendanceRecords) {
    // Count present and absent students
    final presentCount = attendanceRecords.length;
    final totalStudents = allStudents
        .where((student) =>
            selectedClass == null || student.currentClass == selectedClass)
        .length;
    final absentCount = totalStudents - presentCount;

    //prepare the pie chart
    final sections = <PieChartSectionData>[
      PieChartSectionData(
        title: 'Present ($presentCount)',
        value: presentCount.toDouble(),
        color: Colors.green,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        title: 'Absent ($absentCount)',
        value: absentCount.toDouble(),
        color: Colors.red,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 80,
            sectionsSpace: 2,
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceView() {
    return StreamBuilder<List<Attendance>>(
      stream: AttendanceService.fetchFilteredAttendance(
        date: selectedDate,
        classFilter: selectedClass,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint(
              'Error in fetching the filtered attendance:  ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final attendanceRecords = snapshot.data ?? [];
        if (attendanceRecords.isEmpty) {
          return const Center(child: Text('No records found.'));
        }
        return Column(
          children: [
            _buildAttendancePieChart(attendanceRecords),
            _buildSignInOutLineChart(attendanceRecords),
            Expanded(child: _buildAttendanceDetails(attendanceRecords)),
          ],
        );
      },
    );
  }

  Widget _buildClassDropdown() {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedClass,
        items: [
          const DropdownMenuItem(value: null, child: Text('All Classes')),
          ...classes
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
        ],
        onChanged: (value) => setState(() => selectedClass = value),
        decoration: const InputDecoration(
          labelText: 'Class',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ElevatedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      child: Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDatePicker(),
          _buildClassDropdown(),
          _buildQrScannerButton(),
        ],
      ),
    );
  }

  Widget _buildQrScannerButton() {
    return ElevatedButton(
      onPressed: () {
        _qrScanner.getScannedQrBarCode(
          context: context,
          onCode: (code) async {
            final refinedCode = code?.substring(
                15); // removing the default word "Code scanned = " from the scanned result
            await AttendanceService.recordAttendance(refinedCode!);
          },
        );
      },
      child: const Text('Scan QR'),
    );
  }

  Widget _buildSignInOutLineChart(List<Attendance> attendanceRecords) {
    // Prepare data for the line chart
    final signInPoints = <FlSpot>[];
    final signOutPoints = <FlSpot>[];
/*
    if (attendanceRecords.isNotEmpty) {
      final firstRecordTime = attendanceRecords.first.signInTime!
          .toLocal(); // Assuming there will be at least one record, and all record dates are the same
      final startOfDay = DateTime(firstRecordTime.year, firstRecordTime.month,
          firstRecordTime.day, 0, 0, 0);

      for (var record in attendanceRecords) {
        if (record.signInTime != null) {
          final signInTime = record.signInTime!.toLocal();
          final signInX =
              signInTime.difference(startOfDay).inMinutes.toDouble();
          signInPoints.add(FlSpot(
              signInX, 1)); // Use '1' as constant to represent a sign in event
        }
        if (record.signOutTime != null) {
          final signOutTime = record.signOutTime!.toLocal();
          final signOutX =
              signOutTime.difference(startOfDay).inMinutes.toDouble();
          signOutPoints.add(FlSpot(signOutX,
              -1)); // Use '-1' as a constant to represent a sign out event
        }
      }
    }*/
    //sort the points to maintain correct order of the line
    signInPoints.sort((a, b) => a.x.compareTo(b.x));
    signOutPoints.sort((a, b) => a.x.compareTo(b.x));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
                show: true, drawVerticalLine: true, horizontalInterval: 1),
            titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 60,
                    getTitlesWidget: (value, meta) {
                      final hours = (value / 60).floor();
                      final minutes = (value % 60).round();
                      return Text(
                        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: 0,
            maxX: 1440, // Full day in minutes
            minY: -2,
            maxY: 2,
            lineBarsData: [
              LineChartBarData(
                spots: signInPoints,
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: signOutPoints,
                isCurved: true,
                color: Colors.orange,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toLocal().toString().split(' ')[1];
    } else if (timestamp is DateTime) {
      return timestamp.toLocal().toString().split(' ')[1];
    }
    return 'N/A';
  }

  Future<void> _initializeData() async {
    try {
      final fetchedClasses =
          await FirebaseService.getDataStreamFromFirestore<SchoolClass>(
        collection: 'classes',
        fromFirestore: (doc) => SchoolClass.fromFirestore(doc),
      ).first;
      final fetchedStudents =
          await FirebaseService.getDataStreamFromFirestore<Student>(
        collection: 'students',
        fromFirestore: (doc) => Student.fromFirestore(doc),
      ).first;

      setState(() {
        classes = fetchedClasses;
        allStudents = fetchedStudents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }
}
