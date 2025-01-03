import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' as html;

import '../models/models.dart';

class SubjectTemplate {
  static Future<String> generateSubjectTemplate() async {
    try {
      // Create a new Excel Document
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      // Set headers
      sheet.getRangeByIndex(1, 1).setText('Registration Number');
      sheet.getRangeByIndex(1, 2).setText('CA1 (20)');
      sheet.getRangeByIndex(1, 3).setText('CA2 (20)');
      sheet.getRangeByIndex(1, 4).setText('Exam (60)');

      // Add sample data
      final sampleData = [
        ['STD001', '15', '18', '45'],
        ['STD002', '17', '16', '50'],
        ['STD003', '14', '19', '48'],
      ];

      // Insert sample data
      for (var i = 0; i < sampleData.length; i++) {
        for (var j = 0; j < sampleData[i].length; j++) {
          sheet.getRangeByIndex(i + 2, j + 1).setText(sampleData[i][j]);
        }
      }

      // Auto-fit columns
      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);

      // Save the document
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      if (kIsWeb) {
        // Download for web platform
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'subject_scores_template.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        return anchor.toString();
      } else {
        // Save file for other platforms
        final String? path = await FilePicker.platform.getDirectoryPath();
        if (path != null) {
          final File file = File('$path/subject_scores_template.xlsx');
          await file.writeAsBytes(bytes);
          debugPrint('Template saved at: ${file.path}');
        }
        return path ?? '';
      }
    } catch (e) {
      debugPrint('Error generating template: $e');
      throw Exception('Failed to generate template: $e');
    }
  }

  static Future<List<SubjectScore>> parseExcelFile() async {
    try {
      // Pick file with validation
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Ensure we get the file data for web
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      // Get file bytes
      final bytes = kIsWeb
          ? result.files.first.bytes!
          : await File(result.files.single.path!).readAsBytes();

      final excel = Excel.decodeBytes(bytes);
      var scores = <SubjectScore>[];

      // Validate if excel file has any sheets
      if (excel.tables.isEmpty) {
        throw Exception('Excel file has no sheets');
      }

      final sheet = excel.tables[excel.tables.keys.first]!;

      // Validate minimum required columns
      if (sheet.maxColumns < 4) {
        throw Exception('Invalid template format - missing required columns');
      }

      // Process rows with validation
      for (var row = 1; row < sheet.maxRows; row++) {
        var rowData = sheet.row(row);

        // Skip empty or invalid rows
        if (rowData.isEmpty || rowData[0]?.value == null) continue;

        try {
          // Validate and parse scores
          final regNo = rowData[0]?.value.toString().trim() ?? '';
          final ca1 = _parseScore(rowData[1]?.value, 20);
          final ca2 = _parseScore(rowData[2]?.value, 20);
          final exam = _parseScore(rowData[3]?.value, 60);

          if (regNo.isNotEmpty) {
            scores.add(SubjectScore(
              regNo: regNo,
              ca1: ca1,
              ca2: ca2,
              exam: exam,
            ));
          }
        } catch (e) {
          debugPrint('Warning: Error parsing row $row: $e');
        }
      }

      if (scores.isEmpty) {
        throw Exception('No valid scores found in the file');
      }

      debugPrint('Successfully parsed ${scores.length} scores from Excel');
      return scores;
    } catch (e) {
      debugPrint('Error parsing Excel file: $e');
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  static bool validateScores(List<SubjectScore> scores) {
    for (var score in scores) {
      // Check if registration number is empty
      if (score.regNo.isEmpty) {
        debugPrint('Invalid registration number found');
        return false;
      }

      // Validate score ranges
      if ((score.ca1 != null && (score.ca1! < 0 || score.ca1! > 20)) ||
          (score.ca2 != null && (score.ca2! < 0 || score.ca2! > 20)) ||
          (score.exam != null && (score.exam! < 0 || score.exam! > 60))) {
        debugPrint(
            'Invalid score range found for registration number: ${score.regNo}');
        return false;
      }
    }
    return true;
  }

  // Helper method to parse and validate scores
  static int? _parseScore(dynamic value, int maxScore) {
    if (value == null) return null;
    final score = int.tryParse(value.toString()) ?? 0;
    return (score >= 0 && score <= maxScore) ? score : null;
  }
}

class TraitsTemplate {
  static Future<String> generateTraitsTemplate() async {
    try {
      // Create a new Excel Document
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      // Set headers
      sheet.getRangeByIndex(1, 1).setText('Registration Number');
      sheet.getRangeByIndex(1, 2).setText('Creativity (5)');
      sheet.getRangeByIndex(1, 3).setText('Sports (5)');
      sheet.getRangeByIndex(1, 4).setText('Attentivenes (5)');
      sheet.getRangeByIndex(1, 5).setText('Obedience (5)');
      sheet.getRangeByIndex(1, 6).setText('Cleanines (5)');
      sheet.getRangeByIndex(1, 7).setText('Politeness (5)');
      sheet.getRangeByIndex(1, 8).setText('Honesty (5)');
      sheet.getRangeByIndex(1, 9).setText('Punctuality (5)');
      sheet.getRangeByIndex(1, 10).setText('Music (5)');

      // Add sample data
      final sampleData = [
        ['STD001', '4', '3', '4', '4', '3', '4', '5', '4', '3'],
        ['STD002', '5', '4', '5', '4', '5', '4', '5', '5', '4'],
        ['STD003', '3', '2', '3', '3', '2', '3', '4', '3', '2'],
      ];

      // Insert sample data
      for (var i = 0; i < sampleData.length; i++) {
        for (var j = 0; j < sampleData[i].length; j++) {
          sheet.getRangeByIndex(i + 2, j + 1).setText(sampleData[i][j]);
        }
      }

      // Auto-fit columns
      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);
      sheet.autoFitColumn(5);
      sheet.autoFitColumn(6);
      sheet.autoFitColumn(7);
      sheet.autoFitColumn(8);
      sheet.autoFitColumn(9);
      sheet.autoFitColumn(10);

      // Save the document
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      if (kIsWeb) {
        // Download for web platform
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'trait_and_skills_template.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        return anchor.toString();
      } else {
        // Save file for other platforms
        final String? path = await FilePicker.platform.getDirectoryPath();
        if (path != null) {
          final File file = File('$path/trait_and_skills_template.xlsx');
          await file.writeAsBytes(bytes);
          debugPrint('Template saved at: ${file.path}');
        }
        return path ?? '';
      }
    } catch (e) {
      debugPrint('Error generating template: $e');
      throw Exception('Failed to generate template: $e');
    }
  }

  static Future<List<TraitsAndSkills>> uploadTraits() async {
    try {
      // Pick file with validation
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Ensure we get the file data for web
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      // Get file bytes
      final bytes = kIsWeb
          ? result.files.first.bytes!
          : await File(result.files.single.path!).readAsBytes();

      final excel = Excel.decodeBytes(bytes);
      var traits = <TraitsAndSkills>[];

      // Validate if Excel file has any sheets
      if (excel.tables.isEmpty) {
        throw Exception('Excel file has no sheets');
      }

      final sheet = excel.tables[excel.tables.keys.first]!;

      // Process rows with validation
      for (var row = 1; row < sheet.maxRows; row++) {
        var rowData = sheet.row(row);

        // Skip empty or invalid rows
        if (rowData.isEmpty || rowData[0]?.value == null) continue;

        try {
          // Validate and parse scores
          final regNo = rowData[0]?.value.toString().trim() ?? '';
          final creativity = _parseScore(rowData[1]?.value, 5);
          final sports = _parseScore(rowData[2]?.value, 5);
          final attentiveness = _parseScore(rowData[3]?.value, 5);
          final obedience = _parseScore(rowData[4]?.value, 5);
          final cleanliness = _parseScore(rowData[5]?.value, 5);
          final politeness = _parseScore(rowData[6]?.value, 5);
          final honesty = _parseScore(rowData[7]?.value, 5);
          final punctuality = _parseScore(rowData[8]?.value, 5);
          final music = _parseScore(rowData[9]?.value, 5);

          if (regNo.isNotEmpty) {
            traits.add(TraitsAndSkills(
              regNo: regNo,
              creativity: creativity,
              sports: sports,
              attentiveness: attentiveness,
              obedience: obedience,
              cleanliness: cleanliness,
              politeness: politeness,
              honesty: honesty,
              punctuality: punctuality,
              music: music,
            ));
          }
        } catch (e) {
          debugPrint('Warning: Error parsing row $row: $e');
        }
      }

      if (traits.isEmpty) {
        throw Exception('No valid scores found in the file');
      }

      debugPrint('Successfully parsed ${traits.length} scores from Excel');
      return traits;
    } catch (e) {
      debugPrint('Error parsing Excel file: $e');
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  static bool validateScores(List<TraitsAndSkills> traits) {
    for (var trait in traits) {
      // Check if registration number is empty
      if (trait.regNo.isEmpty) {
        debugPrint('Invalid registration number found');
        return false;
      }

      // Validate score ranges
      if ((trait.creativity != null &&
              (trait.creativity! < 0 || trait.creativity! > 5)) ||
          (trait.sports != null && (trait.sports! < 0 || trait.sports! > 5)) ||
          (trait.attentiveness != null &&
              (trait.attentiveness! < 0 || trait.attentiveness! > 5)) ||
          (trait.obedience != null &&
              (trait.obedience! < 0 || trait.obedience! > 5)) ||
          (trait.cleanliness != null &&
              (trait.cleanliness! < 0 || trait.cleanliness! > 5)) ||
          (trait.politeness != null &&
              (trait.politeness! < 0 || trait.politeness! > 5)) ||
          (trait.honesty != null &&
              (trait.honesty! < 0 || trait.honesty! > 5)) ||
          (trait.punctuality != null &&
              (trait.punctuality! < 0 || trait.punctuality! > 5)) ||
          (trait.music != null && (trait.music! < 0 || trait.music! > 5))) {
        debugPrint(
            'Invalid score range found for registration number: ${trait.regNo}');
        return false;
      }
    }
    return true;
  }

  // Helper method to parse and validate scores
  static int? _parseScore(dynamic value, int maxScore) {
    if (value == null) return null;
    final score = int.tryParse(value.toString()) ?? 0;
    return (score >= 0 && score <= maxScore) ? score : null;
  }
}
