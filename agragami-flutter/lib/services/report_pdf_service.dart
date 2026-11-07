import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// মাসিক রিপোর্টের PDF — আয়, ব্যয়, ঋণ আর নিট হিসাব।
/// বাংলা লেখা PDF-এ ঠিকভাবে আসতে কালপুরুষ ফন্টের TTF
/// ফাইল assets/fonts/ ফোল্ডারে রাখতে হয় — না থাকলে
/// ইংরেজি অক্ষরে লেখা হবে।
class ReportPdfService {
  static const PdfColor _green = PdfColor.fromInt(0xFF0B6B3A);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC9A227);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1F1C);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5F6B64);
  static const PdfColor _line = PdfColor.fromInt(0xFFE3E8E5);

  Future<pw.Font> _font() async {
    try {
      final data = await rootBundle.load(
        'assets/fonts/Kalpurush-Regular.ttf',
      );
      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  Future<pw.Font> _fontBold() async {
    try {
      final data = await rootBundle.load(
        'assets/fonts/Kalpurush-Bold.ttf',
      );
      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helveticaBold();
    }
  }

  String _taka(int amount) => '৳$amount';

  pw.Widget _row(pw.Font font, pw.Font bold, String label, int amount,
      {bool total = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: const pw.Border(bottom: pw.BorderSide(color: _line)),
        color: total ? const PdfColor.fromInt(0xFFE6F2EB) : PdfColors.white,
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: total ? bold : font,
                fontSize: 11,
                color: _ink,
              ),
            ),
          ),
          pw.Text(
            _taka(amount),
            style: pw.TextStyle(
              font: total ? bold : font,
              fontSize: 11,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> buildMonthlyReport({
    required String branchName,
    required int year,
    required int month,
    required int income,
    required int expenses,
    required int loansGiven,
    required int repayments,
  }) async {
    final font = await _font();
    final bold = await _fontBold();
    final net = income - expenses - loansGiven + repayments;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              color: _green,
              padding: const pw.EdgeInsets.all(14),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'অগ্রগামী ফান্ড',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 18,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'মাসিক হিসাব — $branchName',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 11,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(
                    '$month/$year',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(height: 3, color: _gold),
            pw.SizedBox(height: 20),
            _row(font, bold, 'জমা (আয়)', income),
            _row(font, bold, 'খরচ', -expenses),
            _row(font, bold, 'কর্জে হাসানা ঋণ দেওয়া হয়েছে', -loansGiven),
            _row(font, bold, 'কিস্তি ফেরত এসেছে', repayments),
            _row(font, bold, 'মাসের নিট', net, total: true),
            pw.SizedBox(height: 16),
            pw.Text(
              'এই হিসাবে সুদ, জরিমানা বা লভ্যাংশের কোনো টাকা নেই —'
              ' ঋণ শুধু কর্জে হাসানা, সুদমুক্ত।',
              style: pw.TextStyle(font: font, fontSize: 10, color: _muted),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<void> shareMonthlyReport({
    required String branchName,
    required int year,
    required int month,
    required int income,
    required int expenses,
    required int loansGiven,
    required int repayments,
  }) async {
    final bytes = await buildMonthlyReport(
      branchName: branchName,
      year: year,
      month: month,
      income: income,
      expenses: expenses,
      loansGiven: loansGiven,
      repayments: repayments,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'report-$year-$month.pdf',
    );
  }
}
