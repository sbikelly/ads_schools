import 'package:ads_schools/helpers/firebase_helper.dart';
import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceDashboard extends StatefulWidget {
  const AttendanceDashboard({super.key});

  @override
  State<AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStudentId;

  List<Student> allStudents = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text(_startDate != null && _endDate != null
                        ? '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}'
                        : 'Select Date Range'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<List<Student>>(
                    future: FirebaseService.getDataStreamFromFirestore<Student>(
                      collection: 'attendance',
                      fromFirestore: (doc) => Student.fromFirestore(doc),
                    ).first,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        final students = snapshot.data ?? [];
                        return allStudents.isEmpty
                            ? const Text('Loading students...')
                            : DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedStudentId,
                                disabledHint: Text('Select Students'),
                                items: [
                                  DropdownMenuItem(
                                      value: null,
                                      child: const Text('All Students')),
                                  ...allStudents.map((stud) => DropdownMenuItem(
                                      value: stud.studentId,
                                      child: Text(stud.name))),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStudentId = value;
                                  });
                                },
                              );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _fetchAttendanceSummary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final data = snapshot.data ?? {};
                  final present = data['Present']?.toDouble() ?? 0;
                  final absent = data['Absent']?.toDouble() ?? 0;

                  return Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: present,
                            color: Colors.green,
                            title: 'Present: $present',
                          ),
                          PieChartSectionData(
                            value: absent,
                            color: Colors.red,
                            title: 'Absent: $absent',
                          ),
                        ],
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAttendanceDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final records = snapshot.data ?? [];
                  return Expanded(
                    child: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final student = allStudents.firstWhere(
                            (std) => std.studentId == record['userId']);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title:
                                Text('${student.name} - ${record['status']}'),
                            subtitle: Text(
                                'Date: ${DateFormat.yMMMd().format((record['timeStamp'] as Timestamp).toDate())}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (status) {
                                _markAttendance(record['id'], status);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'Present',
                                    child: Text('Mark Present')),
                                const PopupMenuItem(
                                    value: 'Absent',
                                    child: Text('Mark Absent')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<List<Map<String, dynamic>>> _fetchAttendanceDetails() async {
    final query = FirebaseFirestore.instance.collection('attendance');

    if (_startDate != null) {
      query.where('timeStamp', isGreaterThanOrEqualTo: _startDate);
    }
    if (_endDate != null) {
      query.where('timeStamp', isLessThanOrEqualTo: _endDate);
    }
    if (_selectedStudentId != null && _selectedStudentId!.isNotEmpty) {
      query.where('userId', isEqualTo: _selectedStudentId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Map<String, int>> _fetchAttendanceSummary() async {
    final query = FirebaseFirestore.instance.collection('attendance');

    if (_startDate != null) {
      query.where('timeStamp', isGreaterThanOrEqualTo: _startDate);
    }
    if (_endDate != null) {
      query.where('timeStamp', isLessThanOrEqualTo: _endDate);
    }
    if (_selectedStudentId != null && _selectedStudentId!.isNotEmpty) {
      query.where('userId', isEqualTo: _selectedStudentId);
    }

    final snapshot = await query.get();
    int present = 0;
    int absent = 0;

    for (var doc in snapshot.docs) {
      final status = doc['status'] as String;
      if (status == 'Present') {
        present++;
      } else if (status == 'Absent') {
        absent++;
      }
    }

    return {'Present': present, 'Absent': absent};
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

  Future<void> _markAttendance(Attendance attendance, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(attendance.id)
          .update({
        'status': status,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating attendance: $e')),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
