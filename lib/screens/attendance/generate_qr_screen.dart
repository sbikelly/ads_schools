import 'package:ads_schools/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentIdCardGenerator {
  static const mainPDFColor = PdfColor.fromInt(0xFF134F47);
  static const secondaryPDFColor = PdfColor.fromInt(0xFF996A2D);

  final Student student;
  BuildContext context;

  StudentIdCardGenerator({required this.student, required this.context});

  Future<void> generateAndPrint() async {
    final pdf = await _buildPDF();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildBackPage(pw.ImageProvider hologramPattern, headerFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: mainPDFColor, width: 3),
        borderRadius: pw.BorderRadius.circular(15),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Opacity(
              opacity: 0.3,
              child: pw.Image(hologramPattern, fit: pw.BoxFit.cover),
            ),
          ),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Opacity(
              opacity: 0.1,
              child: pw.Text(
                'VALID 2023-2024',
                style: pw.TextStyle(
                  fontSize: 40,
                  color: mainPDFColor,
                ),
              ),
            ),
          ),
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 10),
              pw.Text('SCAN TO MARK ATTENDANCE/VERIFY',
                  style: pw.TextStyle(
                      font: headerFont[0], // Use Oswald Regular
                      fontSize: 12,
                      color: mainPDFColor,
                      fontWeight: pw.FontWeight.bold)),
              pw.Container(
                width: 150,
                height: 130,
                margin: const pw.EdgeInsets.all(5),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(
                    errorCorrectLevel: pw.BarcodeQRCorrectionLevel.high,
                  ),
                  data:
                      'https://adokwebsolutions.com.ng/verify?reg=${student.studentId}',
                  drawText: false,
                ),
              ),
              _buildFooter(),
              _buildEmergencyContact(),
              _buildBarcode(),
              _buildSignatureSection(holder: false),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBarcode() {
    return pw.Container(
      width: 200,
      height: 20,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.BarcodeWidget(
        barcode: pw.Barcode.code128(),
        data: student.studentId!,
        textStyle: const pw.TextStyle(fontSize: 6),
      ),
    );
  }

  pw.Widget _buildDOBBGRow(String label, String value, headerFont,
      {bool underline = false}) {
    return pw.Row(
      children: [
        pw.Container(
            decoration: underline
                ? pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey500, width: 0.5)))
                : null,
            child: pw.Text(label,
                style: pw.TextStyle(font: headerFont[1], color: mainPDFColor))),
        pw.SizedBox(width: 5),
        pw.Container(
          decoration: underline
              ? pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey500, width: 0.5)))
              : null,
          child: pw.Text(value,
              style:
                  pw.TextStyle(font: headerFont[0], color: PdfColors.grey800)),
        ),
      ],
    );
  }

  pw.Widget _buildEmergencyContact() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 8,
      ),
      margin: const pw.EdgeInsets.only(bottom: 5), // Added margin
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.red800),
      ),
      child: pw.Column(
        children: [
          pw.Text('IN CASE OF EMERGENCY',
              style: pw.TextStyle(
                  font: pw.Font.helveticaBold(), // Use built-in as fallback
                  fontSize: 8,
                  color: PdfColors.red800)),
          pw.SizedBox(height: 3),
          pw.Text(student.parentName ?? 'Parent/Guardian',
              style: pw.TextStyle(
                font: pw.Font.helvetica(), // Use built-in as fallback
                fontSize: 8,
              )),
          pw.Text(student.parentPhone ?? 'Contact Number',
              style: pw.TextStyle(
                font: pw.Font.helvetica(), // Use built-in as fallback
                fontSize: 8,
              )),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(
        8,
      ),
      //margin: const pw.EdgeInsets.only(top: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('For verification: https://adokwebsolutions.com.ng/verify',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: mainPDFColor)),
          pw.SizedBox(height: 5),
          pw.Text(
              'This ID Card is a property of Adokweb Solutions. It identifies the bearer whose photograph and other relevant information appear in reverse. it must be in the possession of the bearer at all times and must be shown on demand. Transfer of this card to another person is prohibited and may lead to disciplinary action. If found, please call the emmergency number below or report to the nearest police station.',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 6, color: mainPDFColor)),
        ],
      ),
    );
  }

  pw.Widget _buildFrontPage(
      pw.ImageProvider logo, pw.ImageProvider passport, headerFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: mainPDFColor, width: 3),
        borderRadius: pw.BorderRadius.circular(15),
        gradient: pw.LinearGradient(
          colors: [PdfColors.white, PdfColors.blue50],
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
        ),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min, // Added to prevent overflow
        children: [
          _buildHeader(logo, headerFont),
          pw.Divider(color: mainPDFColor, thickness: 1),
          pw.Container(
            height: 18,
            child: pw.Text('STUDENT ID CARD',
                style: pw.TextStyle(
                    font: headerFont[1],
                    fontWeight: pw.FontWeight.bold,
                    color: mainPDFColor)),
          ),
          pw.Stack(
            alignment: pw.Alignment.topCenter,
            children: [
              pw.Container(
                height: 100, // Reduced height
                decoration: pw.BoxDecoration(
                  color: mainPDFColor,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                margin: const pw.EdgeInsets.only(bottom: 10),
              ),
              pw.Positioned(
                top: 10,
                child: pw.Container(
                  width: 80, // Reduced size
                  height: 80,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.white, width: 5),
                  ),
                  child: pw.ClipOval(
                    child: pw.Image(passport, fit: pw.BoxFit.cover),
                  ),
                ),
              ),
            ],
          ),
          _buildStudentInfoSection(headerFont),
          pw.SizedBox(height: 10), // Space before signature
          _buildSignatureSection(holder: true),
          pw.SizedBox(height: 5),
          _buildBarcode(),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(pw.ImageProvider logo, headerFont) {
    return pw.Row(
      children: [
        pw.Image(logo, width: 30, height: 40),
        pw.SizedBox(width: 5),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Federal College Of Education,',
                style: pw.TextStyle(
                    font: headerFont[1], // Use Oswald Bold
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: mainPDFColor)),
            pw.Text('P.M.B 1027, Pankshin, Plateau State,',
                style: pw.TextStyle(
                    //font: headerFont[0], // Use Oswald Regular
                    fontSize: 10,
                    color: PdfColors.grey600)),
            pw.Text('Tel: 07020094201',
                style: pw.TextStyle(
                    //font: headerFont[0],
                    fontSize: 8,
                    color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  Future<pw.Document> _buildPDF() async {
    final pdf = pw.Document();
    final http.Client client = http.Client();

    try {
      final oswaldRegular = pw.Font.ttf(
        await rootBundle.load('fonts/Oswald/static/Oswald-Regular.ttf'),
      );
      final oswaldBold = pw.Font.ttf(
        await rootBundle.load('fonts/Oswald/static/Oswald-Bold.ttf'),
      );
      // Load Google Font
      final robotoRegular = pw.Font.ttf(
        await rootBundle.load('fonts/Roboto/static/Roboto-Regular.ttf'),
      );
      final robotoBold = pw.Font.ttf(
        await rootBundle.load('fonts/Roboto/static/Roboto-Bold.ttf'),
      );
      // Load images
      final appLogo = pw.MemoryImage(
        (await rootBundle.load('fce_badge.png')).buffer.asUint8List(),
      );
      final hologramPattern = pw.MemoryImage(
        (await rootBundle.load('fce_badge.png')).buffer.asUint8List(),
      );

      // Load student photo with error handling
      Uint8List passportBytes;
      try {
        if (student.photo != null && student.photo!.isNotEmpty) {
          final response = await client.get(Uri.parse(student.photo!));
          passportBytes = response.statusCode == 200
              ? response.bodyBytes
              : (await rootBundle.load('profile.jpg')).buffer.asUint8List();
        } else {
          throw Exception('No photo available');
        }
      } catch (e) {
        passportBytes =
            (await rootBundle.load('profile.jpg')).buffer.asUint8List();
      }
      final passport = pw.MemoryImage(passportBytes);
      final headerFont = [oswaldRegular, oswaldBold, robotoRegular, robotoBold];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          build: (context) => _buildFrontPage(appLogo, passport, headerFont),
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          build: (context) => _buildBackPage(hologramPattern, headerFont),
        ),
      );

      return pdf;
    } finally {
      client.close();
    }
  }

  pw.Widget _buildSignatureSection({required bool holder}) {
    return pw.Container(
      alignment: holder ? pw.Alignment.centerRight : pw.Alignment.center,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment:
            holder ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 150,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: mainPDFColor)),
            ),
            child: holder
                ? pw.Text("Signature",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey500))
                : pw.Text("Signature",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey800)),
          ),
          pw.Text(holder ? "Holder's Signature" : "Registrar",
              textAlign: holder ? pw.TextAlign.right : pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: mainPDFColor)),
        ],
      ),
    );
  }

  pw.Widget _buildStudentInfoSection(headerFont) {
    return pw.Container(
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(1.5),
          1: pw.FlexColumnWidth(5),
        },
        children: [
          _buildTableRow('Name:', student.name.toUpperCase(), headerFont,
              underline: true),
          _buildTableRow('Mat No.:', student.regNo, headerFont,
              underline: true),
          _buildTableRow('Dept.:', student.currentClass, headerFont,
              underline: true),
          _buildTableRow('Gender:', student.gender ?? 'N/A', headerFont,
              underline: true),
          // Combined D.O.B and B.G row
          pw.TableRow(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey500, width: 0.5))),
                child: pw.Row(
                  children: [
                    pw.Text('B.G:',
                        style: pw.TextStyle(
                            font: headerFont[1], color: mainPDFColor)),
                    pw.SizedBox(width: 4),
                    pw.Text(student.bloodGroup ?? 'N/A',
                        style: pw.TextStyle(
                            font: headerFont[0], color: PdfColors.grey800)),
                  ],
                ),
              ),
              pw.Container(
                margin: pw.EdgeInsets.only(left: 15),
                decoration: pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey500, width: 0.5))),
                child: pw.Row(
                  children: [
                    pw.Text('D.O.B:',
                        style: pw.TextStyle(
                            font: headerFont[1], color: mainPDFColor)),
                    pw.SizedBox(width: 2),
                    pw.Text(_formatDate(student.dob),
                        style: pw.TextStyle(
                            font: headerFont[0], color: PdfColors.grey800)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildTableRow(String label, String value, headerFont,
      {bool underline = false}) {
    return pw.TableRow(
      children: [
        pw.Container(
            decoration: underline
                ? pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(
                            color: PdfColors.grey500, width: 0.5)))
                : null,
            child: pw.Text(label,
                style: pw.TextStyle(font: headerFont[1], color: mainPDFColor))),
        pw.Container(
          decoration: underline
              ? pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey500, width: 0.5)))
              : null,
          child: pw.Text(value,
              style:
                  pw.TextStyle(font: headerFont[0], color: PdfColors.grey800)),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    return date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : 'N/A';
  }
}
