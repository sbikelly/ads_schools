import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' as html;

class ExcelTemplateService {
  Future<String> generateReportCardTemplate() async {
    final Workbook workbook = Workbook();

    // Create sheets
    final studentSheet = workbook.worksheets[0];
    studentSheet.name = 'Student Info';
    final academicSheet = workbook.worksheets.add();
    academicSheet.name = 'Academic Records';
    final assessmentSheet = workbook.worksheets.add();
    assessmentSheet.name = 'Skills & Traits';

    // Setup Student Info Sheet
    _setupStudentInfoSheet(studentSheet);

    // Setup Academic Records Sheet
    _setupAcademicSheet(academicSheet);

    // Setup Skills & Traits Sheet
    _setupAssessmentSheet(assessmentSheet);

    // Save workbook
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    if (kIsWeb) {
      html.AnchorElement(
          href:
              'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}')
        ..setAttribute('download',
            'report_card_template_${DateTime.now().millisecondsSinceEpoch}.xlsx')
        ..click();
      return 'Downloaded';
    } else {
      // For non-web platforms
      final String path = (await getApplicationDocumentsDirectory()).path;
      final String fileName =
          'report_card_template_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final String filePath = '$path\\$fileName';

      File(filePath).writeAsBytes(bytes);
      return filePath;
    }
  }

  void _setupAcademicSheet(Worksheet sheet) {
    // Headers
    final headers = [
      'Reg No',
      'Subject',
      'CA1',
      'CA2',
      'Exam',
      'Total',
      'Grade',
      'Position',
      'Class Count',
      'Class Average'
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    // Sample data row
    final sampleData = [
      '2024/001',
      'Mathematics',
      '20',
      '20',
      '45',
      '85',
      'A',
      '1',
      '30',
      '75.5'
    ];

    for (var i = 0; i < sampleData.length; i++) {
      sheet.getRangeByIndex(2, i + 1).setText(sampleData[i]);
    }

    // Format headers
    // Format headers
    final Style headerStyle = sheet.workbook.styles.add('AcademicHeaderStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#D3D3D3';
    sheet.getRangeByName('A1:J1').cellStyle = headerStyle;
    // Add grade validation
    final validation = sheet.getRangeByName('G2:G1000').dataValidation;
    validation.listOfValues = [
      'A',
      'B2',
      'B3',
      'C4',
      'C5',
      'C6',
      'D7',
      'D8',
      'F9'
    ];
  }

  void _setupAssessmentSheet(Worksheet sheet) {
    // Headers
    sheet.getRangeByName('A1').setText('Reg No');
    sheet.getRangeByName('B1').setText('Type');
    sheet.getRangeByName('C1').setText('Name');
    sheet.getRangeByName('D1').setText('Rating');

    // Sample Skills data
    sheet.getRangeByName('A2').setText('2024/001');
    sheet.getRangeByName('B2').setText('skill');
    sheet.getRangeByName('C2').setText('Handwriting');
    sheet.getRangeByName('D2').setText('A');

    // Sample Traits data
    sheet.getRangeByName('A3').setText('2024/001');
    sheet.getRangeByName('B3').setText('trait');
    sheet.getRangeByName('C3').setText('Punctuality');
    sheet.getRangeByName('D3').setText('A');

    // Format headers
    // Format headers
    final Style headerStyle =
        sheet.workbook.styles.add('AssessmentHeaderStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#D3D3D3';
    sheet.getRangeByName('A1:D1').cellStyle = headerStyle;
    // Add type validation
    final typeValidation = sheet.getRangeByName('B2:B1000').dataValidation;
    typeValidation.listOfValues = ['skill', 'trait'];

    // Add rating validation
    final ratingValidation = sheet.getRangeByName('D2:D1000').dataValidation;
    ratingValidation.listOfValues = ['A', 'B', 'C', 'D', 'E'];
  }

  void _setupStudentInfoSheet(Worksheet sheet) {
    // Headers
    sheet.getRangeByName('A1').setText('Student Information');
    sheet.getRangeByName('A2').setText('Reg No');
    sheet.getRangeByName('B2').setText('Student Name');
    sheet.getRangeByName('C2').setText('Class');
    sheet.getRangeByName('D2').setText('Term');
    sheet.getRangeByName('E2').setText('Session');

    // Sample data
    sheet.getRangeByName('A3').setText('2024/001');
    sheet.getRangeByName('B3').setText('John Doe');
    sheet.getRangeByName('C3').setText('Primary 1');
    sheet.getRangeByName('D3').setText('First');
    sheet.getRangeByName('E3').setText('2024/2025');

    // Format headers
    // Format headers
    final Style headerStyle =
        sheet.workbook.styles.add('StudentInfoHeaderStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#D3D3D3';
    sheet.getRangeByName('A1:E2').cellStyle = headerStyle;
  }
}
