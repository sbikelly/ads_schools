import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GenerateQRScreen extends StatelessWidget {
  final Student student;

  const GenerateQRScreen({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(isLoading: false),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _generateAndPrintPDF(context),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Generate ID Card PDF"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget infoRow({required String title, required String? info}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        children: [
          pw.Text(
            "$title: ",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            info ?? 'Not Available',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _buildPDF() async {
    final pdf = pw.Document();

    // Load images
    final appLogo = pw.MemoryImage(
      (await rootBundle.load('assets/app-logo.png')).buffer.asUint8List(),
    );
    final passport = pw.MemoryImage(
      (await rootBundle.load(student.photo ?? 'assets/profile-placeholder.jpg'))
          .buffer
          .asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (context) {
          return pw.Container(
            width: PdfPageFormat.a6.width,
            child:
                // Front Page
                pw.Container(
              width: PdfPageFormat.a6.width,
              padding: const pw.EdgeInsets.all(8.0),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  _buildHeader(appLogo),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Student ID Card",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Container(
                      height: 100,
                      width: 100,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(passport, fit: pw.BoxFit.cover),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10.0),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        infoRow(title: "Name", info: student.name),
                        infoRow(title: "Reg No", info: student.regNo),
                        infoRow(title: "Class", info: student.currentClass),
                        infoRow(
                          title: "D.O.B",
                          info: student.dob != null
                              ? '${student.dob!.day}/${student.dob!.month}/${student.dob!.year}'
                              : null,
                        ),
                        infoRow(title: "Gender", info: student.gender),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (context) {
          return pw.Container(
            width: PdfPageFormat.a6.width,
            child:
                // Back Page
                pw.Container(
              width: PdfPageFormat.a6.width,
              padding: const pw.EdgeInsets.all(8.0),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Container(
                      width: 100,
                      height: 100,
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data:
                            '${student.name} | ${student.regNo} | ${student.currentClass}',
                        drawText: false,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _generateAndPrintPDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = await _buildPDF();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } finally {
      Navigator.of(context).pop(); // Close the progress dialog
    }
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'For inquiries, contact: info@adokwebsolutions.com.ng',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.Text(
            'This ID card is non-transferable and must be presented on request.',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'Adokweb Solutions Academy',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              ),
              pw.Text('E-Mail: info@adokwebsolutions.com.ng',
                  style: pw.TextStyle(fontSize: 10)),
              pw.Text('Website: https://adokwebsolutions.com.ng',
                  style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
