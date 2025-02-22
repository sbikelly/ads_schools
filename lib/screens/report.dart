import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ReportCardScreen1 extends StatelessWidget {
  final Map<String, dynamic> reportCardData;

  const ReportCardScreen1({
    super.key,
    required this.reportCardData,
  });

  @override
  Widget build(BuildContext context) {
    // Extracting data from reportCardData
    final Student student = reportCardData['student'];
    final List<SubjectScore> subjectScores = reportCardData['subjectScores'];
    final TraitsAndSkills? traitsAndSkills = reportCardData['traitsAndSkills'];
    final PerformanceData performanceData = reportCardData['performanceData'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Report Card for ${student.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) =>
                    PDFService.generateReportCard(format, reportCardData),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildStudentInfo(student)),
                const SizedBox(width: 20),
                Expanded(child: _buildAttendance(performanceData)),
              ],
            ),
            const SizedBox(height: 20),
            _buildSubjectScoresTable(subjectScores),
            const SizedBox(height: 20),
            _buildTraitsAndSkills(traitsAndSkills),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendance(PerformanceData student) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance: ${student.attendance?.present}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Total Subjects: ${student.totalSubjects}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Total Score: ${student.totalScore ?? 0}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Average: ${student.overallAverage}',
                style: const TextStyle(fontSize: 16)),
            Text('Position: ${student.overallPosition}',
                style: const TextStyle(fontSize: 16)),
            Text('Class Count: ${student.totalStudents}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo(Student student) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${student.name}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Registration No: ${student.regNo}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Class: ${student.currentClass}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectScoresTable(List<SubjectScore> scores) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subject Scores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Table(
              border: TableBorder.all(color: Colors.grey),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
                6: FlexColumnWidth(1),
                7: FlexColumnWidth(1),
                8: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[300]),
                  children: [
                    _buildTableCell('Subject', true),
                    _buildTableCell('CA1', true),
                    _buildTableCell('CA2', true),
                    _buildTableCell('Exam', true),
                    _buildTableCell('Total', true),
                    _buildTableCell('Average', true),
                    _buildTableCell('Position', true),
                    _buildTableCell('Grade', true),
                    _buildTableCell('Remark', true),
                  ],
                ),
                ...scores.map((score) => TableRow(
                      children: [
                        _buildTableCell(score.subjectName ?? '-'),
                        _buildTableCell(score.ca1.toString()),
                        _buildTableCell(score.ca2.toString()),
                        _buildTableCell(score.exam.toString()),
                        _buildTableCell(score.total.toString()),
                        _buildTableCell(score.average.toString()),
                        _buildTableCell(score.position.toString()),
                        _buildTableCell(score.grade ?? '-'),
                        _buildTableCell(score.remark ?? '-'),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, [bool isHeader = false]) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 16 : 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTraitsAndSkills(TraitsAndSkills? traitsAndSkills) {
    if (traitsAndSkills == null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Text(
            'Traits and Skills data not available',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Split traits and skills into two groups for two horizontal tables
    final Map<String, int?> group1 = {
      'Creativity': traitsAndSkills.creativity,
      'Sports': traitsAndSkills.sports,
      'Attentiveness': traitsAndSkills.attentiveness,
      'Obedience': traitsAndSkills.obedience,
    };

    final Map<String, int?> group2 = {
      'Cleanliness': traitsAndSkills.cleanliness,
      'Politeness': traitsAndSkills.politeness,
      'Honesty': traitsAndSkills.honesty,
      'Punctuality': traitsAndSkills.punctuality,
      'Music': traitsAndSkills.music,
    };

    Widget buildTable(Map<String, int?> data) {
      return Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
        },
        border: TableBorder.all(color: Colors.grey),
        children: data.entries.map((entry) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  entry.value != null ? entry.value.toString() : 'N/A',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Traits and Skills',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Group 1',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            buildTable(group1),
            const SizedBox(height: 20),
            const Text('Group 2',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            buildTable(group2),
          ],
        ),
      ),
    );
  }
}
