import 'dart:typed_data';

import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:ads_schools/services/pdf_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:universal_html/html.dart' as html;

class AttendanceAdminDashboard extends StatefulWidget {
  const AttendanceAdminDashboard({super.key});

  @override
  State<AttendanceAdminDashboard> createState() =>
      AttendanceAdminDashboardState();
}

class AttendanceAdminDashboardState extends State<AttendanceAdminDashboard> {
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
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      _buildFilters(),
                      Expanded(child: _buildAttendanceView()),
                    ],
                  ),
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
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

    final presentPercentage =
        totalStudents > 0 ? (presentCount / totalStudents * 100).round() : 0;
    final absentPercentage =
        totalStudents > 0 ? (absentCount / totalStudents * 100).round() : 0;

    final signedInCount =
        attendanceRecords.where((record) => record.signOutTime == null).length;
    final signedInPercentage =
        totalStudents > 0 ? (signedInCount / totalStudents * 100).round() : 0;
    final signedOutCount =
        attendanceRecords.where((record) => record.signOutTime != null).length;
    final signedOutPercentage =
        totalStudents > 0 ? (signedOutCount / totalStudents * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 4.0), // Add some horizontal padding for responsiveness
      child: SizedBox(
        height: 250, // Increase height to accommodate titles and indicators
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Attendance Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        flex: 1,
                        child: _buildPieChartWithTitle(
                          "Present vs Absent",
                          Colors.blue,
                          Colors.red,
                          _generatePieChartSections(presentCount, absentCount,
                              presentPercentage, absentPercentage),
                        ),
                      ),
                      const VerticalDivider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                      Flexible(
                        flex: 1,
                        child: _buildPieChartWithTitle(
                          "Sign In vs Sign Out",
                          Colors.green,
                          Colors.orange,
                          _generateSignInOutPieChartSections(
                              signedInCount,
                              signedInPercentage,
                              signedOutCount,
                              signedOutPercentage),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildAttendancePieChart(attendanceRecords)),

                    const SizedBox(width: 8), // Add some spacing between charts
                    Expanded(
                        child: _buildSignInOutLineChart(attendanceRecords)),
                  ],
                )),
            Expanded(child: _buildAttendanceDetails(attendanceRecords)),
          ],
        );
      },
    );
  }

  Widget _buildClassDropdown() {
    return IntrinsicWidth(
      // Removed the surrounding Expanded
      child: DropdownButtonFormField<String>(
        icon: const Icon(Icons.arrow_drop_down),
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

  Widget _buildColorIndicator(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDatePicker() {
    return ElevatedButton.icon(
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
      label: Text(selectedDate.toLocal().toString().split(' ')[0]),
      icon: const Icon(Icons.calendar_today),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDatePicker(),
            Flexible(
              child: SizedBox(
                width: 200,
                child: _buildClassDropdown(),
              ),
            ),
            _buildQrSignInButton(),
            _buildQrSignOutButton(),
            _buildGenerateReportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateReportButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final attendanceRecords =
            await AttendanceService.fetchFilteredAttendance(
          date: selectedDate,
          classFilter: selectedClass,
        ).first;
        _generatePdfReport(attendanceRecords);
      },
      label: const Text('Report'),
      icon: const Icon(Icons.download),
    );
  }

  Widget _buildPieChartWithTitle(
    String title,
    Color color1,
    Color color2,
    List<PieChartSectionData> sections,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildColorIndicator(color1),
            const SizedBox(width: 8),
            _buildColorIndicator(color2),
          ],
        ),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 35,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrSignInButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _qrScanner.getScannedQrBarCode(
          context: context,
          onCode: (code) async {
            final refinedCode = code?.substring(
                15); // removing the default word "Code scanned = " from the scanned result
            await _handleAttendanceRecord(refinedCode!, true);
          },
        );
      },
      label: const Text('Sign In'),
      icon: const Icon(
        Icons.qr_code,
        color: Colors.green,
      ),
    );
  }

  Widget _buildQrSignOutButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _qrScanner.getScannedQrBarCode(
          context: context,
          onCode: (code) async {
            final refinedCode = code?.substring(
                15); // removing the default word "Code scanned = " from the scanned result
            await _handleAttendanceRecord(refinedCode!, false);
          },
        );
      },
      label: const Text('Sign Out'),
      icon: const Icon(
        Icons.qr_code_2,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildSignInOutLineChart(List<Attendance> attendanceRecords) {
    // Define time range for the chart (7 AM to 5 PM)
    final startTime = 7; // 7 AM
    final endTime = 17; // 5 PM (17:00 in 24-hour format)

    // Calculate the number of 10-minute intervals in the given time range
    final intervalDuration = 10; // in minutes
    final totalMinutes = (endTime - startTime) * 60;
    final numberOfIntervals = (totalMinutes / intervalDuration).ceil();

    // Initialize lists to hold the counts for each interval
    List<int> signInCounts = List.generate(numberOfIntervals, (index) => 0);
    List<int> signOutCounts = List.generate(numberOfIntervals, (index) => 0);

    // Populate the counts for each interval
    for (var record in attendanceRecords) {
      // Function to process sign-in or sign-out records
      void processRecord(DateTime? recordTime, List<int> counts) {
        if (recordTime != null) {
          // Convert DateTime to DateTime
          final timeOfDayInMinutes = recordTime.hour * 60 + recordTime.minute;

          // Calculate the interval index based on minutes from the start time
          final minutesFromStart = timeOfDayInMinutes - (startTime * 60);
          final intervalIndex = (minutesFromStart / intervalDuration).floor();

          // Ensure the index is within bounds
          if (intervalIndex >= 0 && intervalIndex < counts.length) {
            counts[intervalIndex]++;
          }
        }
      }

      // Process sign-in and sign-out records

      processRecord(record.signInTime, signInCounts);
      processRecord(record.signOutTime, signOutCounts);
    }

    // Convert the counts into FlSpot data points for the chart
    List<FlSpot> createFlSpots(List<int> counts, bool isSignIn) {
      List<FlSpot> spots = [];
      for (int i = 0; i < counts.length; i++) {
        // Calculate x-coordinate based on interval number
        double x = i * intervalDuration.toDouble();

        spots.add(FlSpot(
            x, isSignIn ? (counts[i].toDouble() + 1) : counts[i].toDouble()));
      }
      return spots;
    }

    final signInSpots = createFlSpots(signInCounts, true);
    final signOutSpots = createFlSpots(signOutCounts, false);
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox(
        height: 250, // Increased height for better visualization
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sign-in and Sign-out Trends from (7AM - 5PM) on ${today.toLocal().toString().split(' ')[0]}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: const Color.fromARGB(100, 100, 100, 100),
                              strokeWidth: 0.5,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: const Color.fromARGB(100, 100, 100, 100),
                              strokeWidth: 0.5,
                            );
                          }),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 60, // one hour in minutes
                            getTitlesWidget: (value, meta) {
                              // Convert minutes from the start to time of day
                              final timeInMinutes = (startTime * 60) +
                                  value; //value is minutes from the start of 7am,
                              final hours = (timeInMinutes / 60).floor();
                              final minutes = (timeInMinutes % 60).round();
                              // Format the time of day
                              return Text(
                                  '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28, //increased reservedSize
                            interval: 1, // Display interval of 1 student count
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      minX: 0,
                      maxX: totalMinutes.toDouble(), // Total minutes in range
                      minY: -1, // Minimum possible number of students
                      maxY: allStudents.length +
                          1.toDouble(), // Maximum possible number of students
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            // Calculate time based on x-coordinate (minutes from 7 AM)
                            final timeInMinutes = (startTime * 60) + spot.x;
                            final hours = (timeInMinutes / 60).floor();
                            final minutes = (timeInMinutes % 60).round();
                            final timeFormatted =
                                '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
                            final event =
                                (spot.barIndex == 0) ? "Sign In" : "Sign Out";
                            return LineTooltipItem(
                              "$event at $timeFormatted: ${spot.y.toInt()} students",
                              const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        }),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: signInSpots,
                          isCurved: true,
                          color: Colors.green, // Consistent green
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green[100],
                          ), // Removed Fill
                        ),
                        LineChartBarData(
                          spots: signOutSpots,
                          isCurved: true,
                          color: Colors.orange, // Consistent Orange
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.orange[100],
                          ), // Removed Fill
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _downloadPdf(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.Url.revokeObjectUrl(url);
    html.document.body?.children.remove(anchor);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toLocal().toString().split(' ')[1];
    } else if (timestamp is DateTime) {
      return timestamp.toLocal().toString().split(' ')[1];
    }
    return 'N/A';
  }

  Future<void> _generatePdfReport(List<Attendance> attendanceRecords) async {
    try {
      final pdfBytes = await PDFService.generateAttendanceReport(
          selectedDate, attendanceRecords, allStudents, classes, selectedClass);
      _downloadPdf(pdfBytes, 'attendance_report.pdf');
    } catch (e) {
      setState(() => errorMessage = 'Error generating PDF: $e');
    }
  }

  List<PieChartSectionData> _generatePieChartSections(
    int presentCount,
    int absentCount,
    int presentPercentage,
    int absentPercentage,
  ) {
    return [
      PieChartSectionData(
        title: "$presentPercentage%",
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        value: presentCount.toDouble(),
        color: Colors.blue,
        radius: 25,
      ),
      PieChartSectionData(
        title: "$absentPercentage%",
        value: absentCount.toDouble(),
        color: Colors.red,
        radius: 25,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  List<PieChartSectionData> _generateSignInOutPieChartSections(
      int signedInCount,
      int signedInPercentage,
      int signedOutCount,
      int signedOutPercentage) {
    return [
      PieChartSectionData(
        title: "$signedInPercentage%",
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        value: signedInCount.toDouble(),
        color: Colors.green,
        radius: 25,
      ),
      PieChartSectionData(
        title: "$signedOutPercentage%",
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        value: signedOutCount.toDouble(),
        color: Colors.orange,
        radius: 25,
      ),
    ];
  }

  Future<void> _handleAttendanceRecord(String studentId, bool isSignIn) async {
    try {
      final studentExists = await AttendanceService.studentExists(studentId);
      if (!studentExists) {
        _showErrorDialog("Student with id $studentId does not exist.");
        return;
      }

      final student = allStudents.firstWhere(
        (std) => std.regNo == studentId,
        orElse: () => Student(
            name: 'Unknown', regNo: '', currentClass: '', personInfo: {}),
      );

      final isAlreadySignedOut =
          await AttendanceService.checkIfStudentIsSignedOut(
              studentId, selectedDate);

      final isAlreadySignedIn =
          await AttendanceService.checkIfStudentIsSignedIn(
              studentId, selectedDate);

      if (isSignIn) {
        if (isAlreadySignedIn) {
          _showErrorDialog("Student is already signed in today");
          return;
        }

        await AttendanceService.recordAttendance(studentId, isSignIn);
        _showSuccessDialog(
            "Attendance recorded for student ${student.name} of class ${student.currentClass} as sign in",
            student);
      } else {
        if (isAlreadySignedOut) {
          _showErrorDialog("Student is already signed out today");
          return;
        }

        if (!isAlreadySignedIn) {
          _showErrorDialog("Student has not signed in for today");
          return;
        }

        await AttendanceService.recordAttendance(studentId, isSignIn);
        _showSuccessDialog(
            "Attendance recorded for student ${student.name} of class ${student.currentClass} as sign out",
            student);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
      debugPrint("Error: $e");
    }
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isPaused = false;

        Future.delayed(const Duration(seconds: 5), () {
          if (!isPaused && mounted) {
            Navigator.of(context).pop();
          }
        });

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text(isPaused ? "Continue" : "Pause"),
                onPressed: () {
                  setState(() => isPaused = !isPaused);
                  if (isPaused == true) {
                  } else {
                    Future.delayed(const Duration(seconds: 5), () {
                      if (!isPaused && mounted) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                },
              ),
              TextButton(
                child: const Text("Close"),
                onPressed: () {
                  isPaused = true;
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  void _showSuccessDialog(String message, Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isPaused = false;
        Future.delayed(const Duration(seconds: 5), () {
          if (!isPaused && mounted) {
            Navigator.of(context).pop();
            _qrScanner.getScannedQrBarCode(
              context: context,
              onCode: (code) async {
                debugPrint("Code scanned = $code");
                final refinedCode = code?.substring(
                    58); // removing the default word "Code scanned = https://adokwebsolutions.com.ng/verify?reg=" from the scanned result
                    debugPrint("Refined code = $refinedCode");
                await _handleAttendanceRecord(refinedCode!, true);
              },
            );
          }
        });

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check, color: Colors.green),
                Text("Success", style: TextStyle(color: Colors.green)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(student.photo!),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  student.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Class: ${student.currentClass}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                )
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text(isPaused ? "Continue" : "Pause"),
                onPressed: () {
                  setState(() => isPaused = !isPaused);

                  if (isPaused == true) {
                  } else {
                    Future.delayed(const Duration(seconds: 5), () {
                      if (!isPaused && mounted) {
                        Navigator.of(context).pop();
                        _qrScanner.getScannedQrBarCode(
                          context: context,
                          onCode: (code) async {
                            final refinedCode = code?.substring(
                                15); // removing the default word "Code scanned = " from the scanned result
                            await _handleAttendanceRecord(refinedCode!, true);
                          },
                        );
                      }
                    });
                  }
                },
              ),
              TextButton(
                child: const Text("Close"),
                onPressed: () {
                  isPaused = true;
                  Navigator.of(context).pop();
                  _qrScanner.getScannedQrBarCode(
                    context: context,
                    onCode: (code) async {
                      final refinedCode = code?.substring(
                          15); // removing the default word "Code scanned = " from the scanned result
                      await _handleAttendanceRecord(refinedCode!, true);
                    },
                  );
                },
              ),
            ],
          );
        });
      },
    );
  }
}

class AttendanceService {
  static Future<bool> checkIfStudentIsSignedIn(
      String studentId, DateTime date) async {
    final startOfDay = _startOfDay(date);
    final endOfDay = _endOfDay(date);

    Query query = FirebaseFirestore.instance
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('timeStamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timeStamp', isLessThanOrEqualTo: endOfDay)
        .where('status', isEqualTo: 'Signed In');

    final snapshot = await query.get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> checkIfStudentIsSignedOut(
      String studentId, DateTime date) async {
    final startOfDay = _startOfDay(date);
    final endOfDay = _endOfDay(date);

    Query query = FirebaseFirestore.instance
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('timeStamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timeStamp', isLessThanOrEqualTo: endOfDay)
        .where('status', isEqualTo: 'Signed Out');

    final snapshot = await query.get();
    return snapshot.docs.isNotEmpty;
  }

  static Stream<List<Attendance>> fetchFilteredAttendance({
    required DateTime date,
    String? classFilter,
  }) {
    final startOfDay = _startOfDay(date);
    final endOfDay = _endOfDay(date);

    Query query = FirebaseFirestore.instance
        .collection('attendance')
        .where('timeStamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timeStamp', isLessThanOrEqualTo: endOfDay);

    if (classFilter != null && classFilter.isNotEmpty) {
      query = query.where('currentClass',
          isEqualTo: classFilter); // Filter by class
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Attendance.fromFirestore(doc)).toList());
  }

  static Future<void> recordAttendance(String studentId, bool isSignIn) async {
    final today = DateTime.now();
    final dateKey = "${studentId}_${today.toIso8601String().split('T').first}";
    final attendanceDoc =
        FirebaseFirestore.instance.collection('attendance').doc(dateKey);

    final snapshot = await attendanceDoc.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      if (data['studentId'] == studentId &&
          isSignIn == false &&
          data['signOutTime'] == null) {
        await attendanceDoc.update({
          'signOutTime': Timestamp.now(),
          'status': 'Signed Out',
        });
      } else if (data['studentId'] == studentId &&
          data['signOutTime'] != null &&
          isSignIn == false) {
        throw Exception("Student has already signed out.");
      } else if (data['studentId'] == studentId &&
          data['signOutTime'] == null &&
          isSignIn == true) {
        throw Exception("Student is already Signed In.");
      }
    } else {
      await attendanceDoc.set({
        'studentId': studentId,
        'date': Timestamp.fromDate(today),
        'signInTime': isSignIn ? Timestamp.now() : null,
        'status': isSignIn ? 'Signed In' : 'Signed Out',
        'signOutTime': isSignIn ? null : Timestamp.now(),
        'currentClass': 'QBykrlq5m3IUXINQxr1h',
        'timeStamp': Timestamp.now(),
      });
    }
  }

  static Future<bool> studentExists(String studentId) async {
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .where('regNo', isEqualTo: studentId)
        .get();
    return studentDoc.docs.isNotEmpty;
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
