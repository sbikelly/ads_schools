import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'firebase_service.dart';

class DataUploadService {
  Future<void> uploadReportCardData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null) return;
    try {
      final bytes = kIsWeb
          ? result.files.first.bytes!
          : File(result.files.single.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      // Process each sheet
      for (var sheet in excel.tables.keys) {
        switch (sheet) {
          case 'Student Info':
            await _processStudentInfo(excel.tables[sheet]!);
            break;
          case 'Academic Records':
            await _processAcademicRecords(excel.tables[sheet]!);
            break;
          case 'Skills & Traits':
            await _processAssessments(excel.tables[sheet]!);
            break;
        }
      }
    } catch (e) {
      debugPrint('Error uploading report card data: $e');
      rethrow;
    }
  }

  String _calculateRemark(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B2':
        return 'Very Good';
      case 'B3':
        return 'Good';
      case 'C4':
        return 'Upper Credit';
      case 'C5':
        return 'Credit';
      case 'C6':
        return 'Lower Credit';
      case 'D7':
        return 'Pass';
      case 'D8':
        return 'Weak Pass';
      case 'F9':
        return 'Fail';
      default:
        return '';
    }
  }

  String _getCellValue(Sheet sheet, int row, int col) {
    return sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value
            ?.toString() ??
        '';
  }

  Future<void> _processAcademicRecords(Sheet sheet) async {
    try {
      // Skip header row
      for (var row = 2; row < sheet.maxRows; row++) {
        final record = AcademicRecord(
          subjectName: _getCellValue(sheet, row, 1),
          ca1: int.parse(_getCellValue(sheet, row, 2)),
          ca2: int.parse(_getCellValue(sheet, row, 3)),
          exam: int.parse(_getCellValue(sheet, row, 4)),
          total: int.parse(_getCellValue(sheet, row, 5)),
          grade: _getCellValue(sheet, row, 6),
          position: int.parse(_getCellValue(sheet, row, 7)),
          classCount: int.parse(_getCellValue(sheet, row, 8)),
          classAverage: double.parse(_getCellValue(sheet, row, 9)),
          remark: _calculateRemark(_getCellValue(sheet, row, 6)),
        );

        final regNo = _getCellValue(sheet, row, 0);

        await FirebaseService.updateOrAddDocument(
          collection: 'scores',
          document: record,
          queryFields: {
            'regNo': regNo,
            'subjectName': record.subjectName,
          },
          toJsonOrMap: (r) => r.toMap(),
        );
      }
    } catch (e) {
      debugPrint('Error processing academic records: $e');
      rethrow;
    }
  }

  Future<void> _processAssessments(Sheet sheet) async {
    try {
      // Skip header row
      for (var row = 2; row < sheet.maxRows; row++) {
        final assessment = Assessment(
          type: _getCellValue(sheet, row, 1),
          name: _getCellValue(sheet, row, 2),
          rating: _getCellValue(sheet, row, 3),
        );

        final regNo = _getCellValue(sheet, row, 0);

        await FirebaseService.updateOrAddDocument(
          collection: 'assessments',
          document: assessment,
          queryFields: {
            'regNo': regNo,
            'type': assessment.type,
            'name': assessment.name,
          },
          toJsonOrMap: (a) => a.toMap(),
        );
      }
    } catch (e) {
      debugPrint('Error processing assessments: $e');
      rethrow;
    }
  }

  Future<void> _processStudentInfo(Sheet sheet) async {
    try {
      // Skip header row
      for (var row = 2; row < sheet.maxRows; row++) {
        final student = Student(
          regNo: _getCellValue(sheet, row, 0),
          name: _getCellValue(sheet, row, 1),
          currentClass: _getCellValue(sheet, row, 2),
          personalInfo: {
            'term': _getCellValue(sheet, row, 3),
            'session': _getCellValue(sheet, row, 4),
          },
        );

        await FirebaseService.updateOrAddDocument(
          collection: 'students',
          document: student,
          queryFields: {'regNo': student.regNo},
          toJsonOrMap: (s) => s.toMap(),
        );
      }
    } catch (e) {
      debugPrint('Error processing student info: $e');
      rethrow;
    }
  }
}
