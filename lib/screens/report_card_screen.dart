import 'package:ads_schools/models/models.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';

class ReportCardScreen extends StatelessWidget {
  final String studentId;

  const ReportCardScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /*
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final reportCardData = await FirebaseService.getReportCardData(
                  studentId: studentId,
                  classId: 'ebAiVln37OWZKGWVa91p',
                  sessionId: 'Kf5LOZaxaqlAoKzMSO9R',
                  termId: 'DHujiDF53AOGKiLMLfKh');
              await Printing.layoutPdf(
                onLayout: (format) => PDFService.generateReportCard(
                    format, classId, sessionId, termId, studentId),
              );
            },
          ),
        ],
      */
        title: const Text('Report Card'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchReportCardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reportCardData = snapshot.data!;
          final student = reportCardData['student'];
          final subjectScores = reportCardData['subjectScores'];
          final domainScores = reportCardData['domainScores'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 300),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildSessionInfo(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildStudentInfoSection(student)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAttendanceSection(reportCardData)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSubjectScoreTable(ReportCard.fromMap(subjectScores)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildSkillsTable(
                              ReportCard.fromMap(domainScores))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildTraitsTable(
                              ReportCard.fromMap(reportCardData))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRemarksSection(),
                  const SizedBox(height: 16),
                  _buildGradingKeys(),
                  /*ElevatedButton(
                    onPressed: () async {
                      await Printing.layoutPdf(
                        onLayout: (format) => PDFService.generateReportCard(
                            format, reportCardData as Student),
                      );
                    },
                    child: const Text('Generate Report Card PDF'),
                  ),
                  */
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> fetchReportCardData() async {
    return await FirebaseService.getReportCardData(
        studentId: studentId,
        classId: 'ebAiVln37OWZKGWVa91p',
        sessionId: 'Kf5LOZaxaqlAoKzMSO9R',
        termId: 'DHujiDF53AOGKiLMLfKh');
  }

  Widget _buildAttendanceSection(Map<String, dynamic> data) {
    final attendance = data['attendance'] as Map<String, dynamic>? ?? {};
    final subjectScores = data['subjectScores'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance: ${attendance['present'] ?? 0}'),
          Text('Total Scores: ${_calculateTotalScores(subjectScores)}'),
          Text(
              'Average: ${_calculateAverage(subjectScores).toStringAsFixed(2)}'),
          Text('Position: ${_getPosition(data['position'] ?? 0)}'),
          Text('Class Count: ${data['totalStudents'] ?? 0}'),
          /*
          Text('Position: ${reportCard.getOverallPositionFormatted()}'),
          Text('Average: ${reportCard.overallAverage.toStringAsFixed(2)}'),
          Text('Total Students: ${reportCard.totalStudents}'),
          */
        ],
      ),
    );
  }

  // Updated widget methods to use actual data:

  Widget _buildGradingKeys() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all()),
      child: Wrap(
        spacing: 0.0,
        runSpacing: 0.0,
        alignment: WrapAlignment.spaceAround,
        children: const [
          Text('A: 85-100 (Excellent); ', style: TextStyle(fontSize: 8)),
          Text('B2: 80-84 (Very Good); ', style: TextStyle(fontSize: 8)),
          Text('B3: 75-79 (Good); ', style: TextStyle(fontSize: 8)),
          Text('C4: 70-74 (Upper Credit); ', style: TextStyle(fontSize: 8)),
          Text('C5: 65-69 (Credit); ', style: TextStyle(fontSize: 8)),
          Text('C6: 60-64 (Lower Credit); ', style: TextStyle(fontSize: 8)),
          Text('D7: 50-59 (Pass); ', style: TextStyle(fontSize: 8)),
          Text('D8: 40-49 (Weak Pass); ', style: TextStyle(fontSize: 8)),
          Text('F9: 0-39 (Fail); ', style: TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/badge.png', height: 50, width: 50),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'Adokweb Solutions Academy, Pankshin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Opposite Federal University of Education, Bwarak, Pankshin',
                textAlign: TextAlign.center,
              ),
              Text('E-Mail: info@adokwebsolutions.com.ng'),
              Text('Website: https://adokwebsolutions.com.ng'),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Image.asset('assets/profile.jpg', height: 50, width: 50),
      ],
    );
  }

  Widget _buildRemarksSection() {
    const double average = 81.90;

    String getRemark() {
      if (average >= 85) {
        return 'Excellent performance. Keep up the outstanding work!';
      }
      if (average >= 80) {
        return 'Very good performance. Continue striving for excellence!';
      }
      if (average >= 75) return 'Good performance. Keep improving!';
      if (average >= 70) return 'Upper Credit. Work harder for better results.';
      if (average >= 65) return 'Credit. More effort needed.';
      if (average >= 60) return 'Lower Credit. Need significant improvement.';
      if (average >= 50) return 'Pass. Must work much harder.';
      if (average >= 40) return 'Weak Pass. Serious attention required.';
      return 'Fail. Immediate intervention needed.';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getRemark(),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              fontFamily: 'Roboto',
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.grey[300],
      child: const Center(
        child: Text(
          '1st Term 2024/2025 Result',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSkillsTable(ReportCard reportCard) {
    return Container(
      decoration: BoxDecoration(border: Border.all()),
      child: Table(
        border: TableBorder.all(),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[300]),
            children: const [
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Skill'))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Rating'))),
            ],
          ),
          ...reportCard.skills.map((skill) => TableRow(
                children: [
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4), child: Text(skill.name))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(skill.rating))),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildStudentInfoSection(Map<String, dynamic> reportCard) {
    final student = reportCard['student'];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Text('Student ID: ${student.id}'),
          Text('Reg. No: ${student.regNo}'),
          Text('Name: ${student.name}'),
          Text('Class: Primary 1'),
          Text('Term Start: 2024-09-11'),
          Text('Term Ended: 2024-12-13'),
          Text('Next Resumption: 2025-01-09'),
        ],
      ),
    );
  }

  Widget _buildSubjectScoreTable(ReportCard reportCard) {
    return Container(
      decoration: BoxDecoration(border: Border.all()),
      child: Table(
        border: TableBorder.all(),
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FlexColumnWidth(1),
          6: FlexColumnWidth(1),
          7: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[300]),
            children: const [
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Subject'))),
              TableCell(
                  child:
                      Padding(padding: EdgeInsets.all(4), child: Text('CA1'))),
              TableCell(
                  child:
                      Padding(padding: EdgeInsets.all(4), child: Text('CA2'))),
              TableCell(
                  child:
                      Padding(padding: EdgeInsets.all(4), child: Text('Exam'))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Total'))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Average'))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Position'))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Grade'))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Remark'))),
            ],
          ),
          ...reportCard.subjectScores.map((record) => TableRow(
                children: [
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(record.subjectName ?? ''))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('${record.ca1 ?? 0}'))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('${record.ca2 ?? 0}'))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('${record.exam ?? 0}'))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('${record.total ?? 0}'))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('${record.average ?? 0.0}'))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('${record.grade ?? 0}'))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('${record.remark ?? 0}'))),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildTraitsTable(ReportCard reportCard) {
    return Container(
      decoration: BoxDecoration(border: Border.all()),
      child: Table(
        border: TableBorder.all(),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[300]),
            children: const [
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Trait'))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(4), child: Text('Rating'))),
            ],
          ),
          ...reportCard.traits.map((trait) => TableRow(
                children: [
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4), child: Text(trait.name))),
                  TableCell(
                      child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(trait.rating))),
                ],
              )),
        ],
      ),
    );
  }

  // Helper methods
  double _calculateAverage(List<dynamic> subjectScores) {
    if (subjectScores.isEmpty) return 0.0;
    final total = _calculateTotalScores(subjectScores);
    return total / subjectScores.length;
  }

  int _calculateTotalScores(List<dynamic> subjectScores) {
    return subjectScores.fold<int>(
        0, (sum, score) => sum + (score.total as num).toInt());
  }

  String _getPosition(int position) {
    if (position >= 11 && position <= 13) return '${position}th';
    switch (position % 10) {
      case 1:
        return '${position}st';
      case 2:
        return '${position}nd';
      case 3:
        return '${position}rd';
      default:
        return '${position}th';
    }
  }
}
