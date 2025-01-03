/*import 'package:ads_schools/models/models.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Document generateReportCard1({
  required Map<String, dynamic> reportCardData,
}) {
  final Student student = reportCardData['student'];
  debugPrint('Student: ${student.name}');
  final TraitsAndSkills? traitsAndSkills = reportCardData['traitsAndSkills'];
  debugPrint('Traits and Skills: ${traitsAndSkills.toString()}');
  final SubjectScore subjectScores = reportCardData['subjectScores'];
  final attendance = reportCardData['attendance'];
  final remarks = reportCardData['remarks'];
  final term = reportCardData['term'];
  final session = reportCardData['session'];
  final schoolDetails = reportCardData['schoolDetails'];

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title Section
          pw.Text(
            schoolDetails?['name'] ?? "School Name",
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            schoolDetails?['address'] ?? "School Address",
            style: pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),

          // Report Info
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              "Report Card - $term Term, $session Session",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Student Info Section
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            padding: pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Student Information",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text("Name: ${student.name}"),
                pw.Text("Registration No: ${student.regNo}"),
                pw.Text("Class: ${student.currentClass}"),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Attendance Section
          if (attendance != null)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              padding: pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Attendance",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text("Total Days: ${attendance['totalDays']}"),
                  pw.Text("Days Present: ${attendance['daysPresent']}"),
                  pw.Text("Days Absent: ${attendance['daysAbsent']}"),
                ],
              ),
            ),
          pw.SizedBox(height: 20),

          // Traits and Skills Section
          if (traitsAndSkills != null)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              padding: pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Traits and Skills",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...traitsAndSkills.entries.map(
                    (entry) => pw.Text(
                      "${entry.key.capitalize()}: ${entry.value ?? 'N/A'}",
                    ),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 20),

          // Subject Scores (Cognitive Domain) Section
          if (subjectScores.isNotEmpty)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              padding: pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Subject Scores (Cognitive Domain)",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Table Header
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Subject",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Score",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Grade",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Dynamic Rows
                      ...subjectScores.map<pw.TableRow>((score) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Text(score['subject'] ?? 'N/A'),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Text(score['score'].toString()),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(4),
                              child: pw.Text(score['grade'] ?? 'N/A'),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 20),

          // Remarks Section
          if (remarks != null)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              padding: pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Remarks",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text("Teacher's Comment: ${remarks['teacherComment']}"),
                  pw.Text(
                      "Principal's Comment: ${remarks['principalComment']}"),
                ],
              ),
            ),
          pw.SizedBox(height: 20),

          // Footer
          pw.Text(
            "This is a true reflection of the student's performance.",
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  );

  return pdf;
}
*/