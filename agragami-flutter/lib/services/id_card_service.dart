import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/branch.dart';
import '../models/member.dart';
import '../widgets/member_id_card.dart';

/// পরিচয়পত্রের PDF বানানো — সামনে আর পেছনে, CR80 মাপে।
/// বাংলা লেখা PDF-এ ঠিকভাবে আসতে কালপুরুষ ফন্টের TTF ফাইল
/// assets/fonts/ ফোল্ডারে রাখতে হয়। ফাইল না থাকলে ইংরেজি
/// অক্ষরে (Helvetica) লেখা হবে — অ্যাপের ভেতরে PNG নিলে
/// বাংলা ঠিকই আসে, কারণ সেখানে Flutter-এর ফন্ট ব্যবহার হয়।
class IdCardService {
  static const PdfColor _green = PdfColor.fromInt(0xFF0B6B3A);
  static const PdfColor _greenDark = PdfColor.fromInt(0xFF084E2B);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC9A227);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1F1C);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5F6B64);
  static const PdfColor _line = PdfColor.fromInt(0xFFE3E8E5);

  Future<pw.Font> _bengaliFont() async {
    try {
      final data = await rootBundle.load(
        'assets/fonts/Kalpurush-Regular.ttf',
      );
      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  /// অ্যাপের লোগো — না পাওয়া গেলে null, তখন লোগো ছাড়াই
  /// কার্ড বানানো হয়, ভাঙে না।
  Future<pw.MemoryImage?> _logoImage() async {
    try {
      final data = await rootBundle.load('assets/images/agragami_logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<pw.Font> _bengaliFontBold() async {
    try {
      final data = await rootBundle.load(
        'assets/fonts/Kalpurush-Bold.ttf',
      );
      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helveticaBold();
    }
  }

  pw.Widget _field(pw.Font font, pw.Font bold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 72,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 9, color: _muted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: bold, fontSize: 10, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _qrGrid(String seed) {
    final grid = qrPatternGrid(seed);
    return pw.Column(
      children: [
        for (var r = 0; r < grid.length; r++)
          pw.Row(
            children: [
              for (var c = 0; c < grid.length; c++)
                pw.Container(
                  width: 2.4,
                  height: 2.4,
                  color: grid[r][c] ? _ink : PdfColors.white,
                ),
            ],
          ),
      ],
    );
  }

  /// সদস্য আর সমিতির তথ্য দিয়ে দুই পাতার PDF বানায়।
  Future<Uint8List> buildPdf(Member member, Branch? branch) async {
    final font = await _bengaliFont();
    final bold = await _bengaliFontBold();
    final logo = await _logoImage();
    const cardSize = PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm);
    final initials = member.name.isNotEmpty ? member.name.substring(0, 1) : '?';

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: cardSize,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              color: _green,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              child: pw.Row(
                children: [
                  // স্ক্রিনের কার্ডের মতো — সাদা গোল কোণার
                  // ঘরে লোগো, সবুজ হেডারের ওপরে।
                  if (logo != null) ...[
                    pw.Container(
                      width: 22,
                      height: 22,
                      padding: const pw.EdgeInsets.all(1.5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Image(logo, fit: pw.BoxFit.cover),
                    ),
                    pw.SizedBox(width: 7),
                  ],
                  pw.Expanded(
                    child: pw.Text(
                      'অগ্রগামী ফান্ড',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 13,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _gold,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      'সদস্য',
                      style: pw.TextStyle(font: bold, fontSize: 8, color: _ink),
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(height: 2, color: _gold),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 52,
                      height: 64,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFE6F2EB),
                        border: pw.Border.all(color: _line),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        initials,
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 22,
                          color: _green,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            member.name,
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 13,
                              color: _ink,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          _field(font, bold, 'সদস্য নম্বর', member.id),
                          _field(font, bold, 'সমিতি', branch?.name ?? '—'),
                          _field(
                            font,
                            bold,
                            'ভর্তির তারিখ',
                            idCardDateText(member.joinDate),
                          ),
                          _field(font, bold, 'ফোন', member.phone),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    doc.addPage(
      pw.Page(
        pageFormat: cardSize,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(
          color: _greenDark,
          padding: const pw.EdgeInsets.all(10),
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
                        fontSize: 11,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'জরুরি যোগাযোগ: ${member.emergencyContactName} — ${member.emergencyContactPhone}',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'সদস্য নম্বর: ${member.id}',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'এই কার্ড হারালে অফিসে জানান। কার্ডটি শুধু সদস্যের পরিচয়ের জন্য।',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Container(
                                height: 1,
                                color: PdfColors.white,
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'সভাপতি',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 8,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Container(
                                height: 1,
                                color: PdfColors.white,
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'সম্পাদক',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 8,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: _qrGrid(member.id),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    member.id,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 7,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  /// PDF দেখানো বা ডাউনলোডের জন্য সিস্টেমের প্রিন্ট/শেয়ার খোলে।
  Future<void> sharePdf(Member member, Branch? branch) async {
    final bytes = await buildPdf(member, branch);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'id-card-${member.id}.pdf',
    );
  }
}
