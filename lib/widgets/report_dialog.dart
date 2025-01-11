import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ReportDialog extends StatefulWidget {
  final Map<String, dynamic> reportCardData;
  const ReportDialog({
    required this.reportCardData,
    super.key,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  @override
  Widget build(BuildContext context) {
    final data = widget.reportCardData;

    final Student student = data['student'];
    final List<SubjectScore> subjectScores = data['subjectScores'];
    final TraitsAndSkills? traitsAndSkills = data['traitsAndSkills'];
    final PerformanceData performanceData = data['performanceData'];

    // Extracting data from reportCardData
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Stack(
        children: [
          /*
          Positioned(
            top: 0,
            right: 2,
            child: IconButton(
              icon: const Icon(
                Icons.close,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),*/
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        SizedBox(
          width: 16.0,
        ),
        ElevatedButton.icon(
          onPressed: () async {
            // Generate and print the report card
            await Printing.layoutPdf(
              onLayout: (format) =>
                  PDFService.generateReportCard(format, widget.reportCardData),
            );
          },
          icon: const Icon(Icons.print),
          label: const Text('Print'),
        ),
      ],
      content: SizedBox(
          width: 800,
          height: 600,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentInfo(student: student, perf: performanceData),
                const SizedBox(height: 20),
                _buildSubjectScoresTable(subjectScores),
                const SizedBox(height: 20),
                _buildTraitsAndSkills(traitsAndSkills),
              ],
            ),
          )),
    );
  }

  Row infoItem(String title, String info) {
    return Row(
      children: [
        Expanded(child: Text('$title ')),
        Expanded(
          child: Text(info,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStudentInfo(
      {required Student student, required PerformanceData perf}) {
    return Card(
      elevation: 4,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoItem('Registration No:', student.regNo),
                  const SizedBox(height: 8),
                  infoItem('Current Class:', student.currentClass),
                  const SizedBox(
                    height: 8,
                  ),
                  infoItem('Number In Class:', '${perf.totalStudents ?? 0}'),
                  const SizedBox(height: 8),
                  infoItem('Number of Subjects:', '${perf.totalSubjects ?? 0}')
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoItem('Attendance:', '${perf.attendance?.present ?? 0}'),
                  const SizedBox(height: 8),
                  infoItem('Total Score:', '${perf.totalScore ?? 0}'),
                  const SizedBox(
                    height: 8,
                  ),
                  infoItem('Average:', '${perf.overallAverage ?? 0.0}'),
                  const SizedBox(height: 8),
                  infoItem('Position:', '${perf.overallPosition ?? 0}')
                ],
              ),
            ),
          ),
        ],
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
