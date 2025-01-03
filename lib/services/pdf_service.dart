import 'package:ads_schools/models/models.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFService {
  static Future<Uint8List> generateReportCard(
      PdfPageFormat pageFormat, reportCardData) async {
    final pdf = pw.Document();

    // final badge = pw.MemoryImage((await rootBundle.load('assets/badge.png')).buffer.asUint8List(),);

    //final passport = pw.MemoryImage((await rootBundle.load('assets/profile.jpg')).buffer.asUint8List(),);

    final Student student = reportCardData['student'];
    final List<SubjectScore> subjectScores = reportCardData['subjectScores'];
    final TraitsAndSkills? traitsAndSkills = reportCardData['traitsAndSkills'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20),
        //pageTheme: _buildTheme(pageFormat),
        build: (context) => [
          _buildHeader(
              // badge, /*passport*/
              ),
          pw.SizedBox(height: 5),
          _buildSessionInfo(),
          pw.SizedBox(height: 5),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                  child: _buildStudentInfoSection(student)), // Student Info
              pw.SizedBox(width: 8), // Spacing between sections
              pw.Expanded(
                  child: _buildAttendanceSection(student)), // Attendance
            ],
          ),
          pw.SizedBox(height: 8),
          _buildSubjectScoreTable(subjectScores),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                  child:
                      _buildSkillsTable(traitsAndSkills)), // Psychomotor Domain
              pw.SizedBox(width: 8), // Spacing between tables
              pw.Expanded(
                  child:
                      _buildTraitsTable(traitsAndSkills)), // Affective Domain
            ],
          ),
          pw.SizedBox(height: 5),
          _buildRemarksSection(
              'The student has shown great improvement in his studies and is encouraged to keep it up.'),
          pw.Spacer(),
          _buildGradingKeys(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildAttendanceSection(Student data) {
    const padin = pw.EdgeInsets.all(2);
    return pw.Table(
      border: null,
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: padin,
              child: pw.Text('Attendance:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: padin,
              child: pw.Text('124'),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: padin,
              child: pw.Text('Total Scores:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: padin,
              child: pw.Text('1638'),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: padin,
              child: pw.Text('Average:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: padin,
              child: pw.Text('81.90'),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: padin,
              child: pw.Text('Position:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: padin,
              child: pw.Text('4th'),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: padin,
              child: pw.Text('Class Count:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: padin,
              child: pw.Text('14'),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildGradingKeys() {
    final grades = [
      {'range': '85-100', 'grade': 'A1', 'remark': 'Excellent'},
      {'range': '80-84', 'grade': 'A2', 'remark': 'Very Good'},
      {'range': '75-79', 'grade': 'B1', 'remark': 'Good'},
      {'range': '70-74', 'grade': 'B2', 'remark': 'Upper Credit'},
      {'range': '65-69', 'grade': 'C4', 'remark': 'Credit'},
      {'range': '60-64', 'grade': 'C5', 'remark': 'Lower Credit'},
      {'range': '50-59', 'grade': 'C6', 'remark': 'Pass'},
      {'range': '40-49', 'grade': 'D7', 'remark': 'Weak Pass'},
      {'range': '0-39', 'grade': 'F9', 'remark': 'Fail'},
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey)),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: [
          pw.Text('GRADING SYSTEM:',
              style: pw.TextStyle(
                  fontSize: 10,
                  letterSpacing: 0,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900)),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: grades.map((grade) {
                return pw.Column(
                  children: [
                    pw.Text('${grade['range']}',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('${grade['grade']} (${grade['remark']})',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                  ],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(
      //pw.MemoryImage badge,
      /* pw.MemoryImage passport*/
      ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
            height: 50, width: 50, child: pw.Text('badge') // pw.Image(badge),
            ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'Adokweb Solutions Academy, Pankshin',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Align(
                child: pw.Text(
                  'Opposite Federal University of Education, Bwarak, Pankshin',
                ),
              ),
              pw.Text('E-Mail: info@adokwebsolutions.com.ng'),
              pw.Text('Website: https://adokwebsolutions.com.ng'),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Container(
            height: 50,
            width: 50,
            child: pw.Text('student Passport') //pw.Image(passport),
            ),
      ],
    );
  }

  static pw.Widget _buildRemarksSection(String comment) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'REMARKS & RECOMMENDATIONS',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 2),
          pw.Text(
            comment,
            // Removed pw.Expanded
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSessionInfo() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(color: PdfColors.grey300),
      child: pw.Center(
        child: pw.Text(
          '1st Term 2024/2025 Result',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _buildSkillsTable(TraitsAndSkills? skills) {
    List<Map<String, dynamic>> table2Data = [
      {'Skill': 'Politeness', 'Score': skills!.politeness ?? 0},
      {'Skill': 'Honesty', 'Score': skills.honesty ?? 0},
      {'Skill': 'Punctuality', 'Score': skills.punctuality ?? 0},
      {'Skill': 'Music', 'Score': skills.music ?? 0},
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: table2Data.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(row['Skill']),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(row['Score'].toString()),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _buildStudentInfoSection(Student data) {
    const padin = pw.EdgeInsets.all(2);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Table(
            border: null,
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('Reg. No:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('HKA/2024/001'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('Name:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('Nenwarang Paul Michael'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('Class:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('Primary 1'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('Term Start:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('2024-09-11'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('Term Ended:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('2024-12-13'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('Next Resumption:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: padin,
                    child: pw.Text('2025-01-09'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSubjectScoreTable(List<SubjectScore> subjectScores) {
    const headers = [
      'Subject',
      'CA1',
      'CA2',
      'Exam',
      'Total',
      'Pos',
      'Avg',
      'Grade',
      'Remark',
    ];

    // Map the subjectScores list into a list of lists for table data
    final data = subjectScores.map((score) {
      return [
        score.subjectName ?? '',
        score.ca1?.toString() ?? '0',
        score.ca2?.toString() ?? '0',
        score.exam?.toString() ?? '0',
        score.total?.toString() ?? '0',
        score.position ?? '',
        score.average?.toStringAsFixed(1) ?? '0.0',
        score.grade ?? '',
        score.remark ?? '',
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cognitive Domain:',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            color: PdfColors.black,
          ),
          headerDecoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
            5: pw.Alignment.center,
            6: pw.Alignment.center,
            7: pw.Alignment.center,
            8: pw.Alignment.centerLeft,
          },
        ),
      ],
    );
  }

  static pw.Widget _buildTraitsTable(TraitsAndSkills? traits) {
    List<Map<String, dynamic>> table1Data = [
      {'Trait': 'Creativity', 'Score': traits!.creativity ?? 0},
      {'Trait': 'Sports', 'Score': traits.sports ?? 0},
      {'Trait': 'Attentiveness', 'Score': traits.attentiveness ?? 0},
      {'Trait': 'Obedience', 'Score': traits.obedience ?? 0},
      {'Trait': 'Cleanliness', 'Score': traits.cleanliness ?? 0},
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: table1Data.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(row['Trait']),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(row['Score'].toString()),
            ),
          ],
        );
      }).toList(),
    );
  }
}
