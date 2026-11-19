import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/branch.dart';
import '../models/member.dart';
import '../widgets/member_id_card.dart';
import 'id_card_pdf_widgets.dart';

/// পরিচয়পত্রের PDF বানানো — সামনে আর পেছনে, CR80 মাপে।
class IdCardService {
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

  Future<pw.MemoryImage?> _logoImage() async {
    try {
      final data = await rootBundle.load('assets/images/agragami_logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  /// সদস্যের ছবি (F25) — Cloudinary URL থেকে নিয়ে PDF-এ
  /// বসানো হয়। ছবি না থাকলে, আনা না গেলে বা ফাইলটা আসল
  /// ছবি না হলে null ফেরে — তখন নামের প্রথম অক্ষর দেখানো
  /// হয় (আগের মতো)। ছবি যাচাই করে নেওয়া হয়, যাতে নষ্ট
  /// ছবিতে পুরো PDF বানানো ভেঙে না যায়।
  Future<pw.MemoryImage?> _memberPhoto(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      final bytes = response.bodyBytes;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      return pw.MemoryImage(bytes);
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

  /// সদস্য আর সমিতির তথ্য দিয়ে দুই পাতার PDF বানায়।
  Future<Uint8List> buildPdf(Member member, Branch? branch) async {
    final font = await _bengaliFont();
    final bold = await _bengaliFontBold();
    final logo = await _logoImage();
    final photo = await _memberPhoto(member.photoUrl);
    const cardSize =
        PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm);
    final initials =
        member.name.isNotEmpty ? member.name.substring(0, 1) : '?';

    final doc = pw.Document();

    // ১. সামনের পাতা
    doc.addPage(
      pw.Page(
        pageFormat: cardSize,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              color: IdCardPdfWidgets.green,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              child: pw.Row(
                children: [
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
                      color: IdCardPdfWidgets.gold,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      'সদস্য',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 8,
                        color: IdCardPdfWidgets.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(height: 2, color: IdCardPdfWidgets.gold),
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
                        border: pw.Border.all(color: IdCardPdfWidgets.line),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      // F25: ছবি থাকলে ছবি, না থাকলে নামের
                      // প্রথম অক্ষর (আগের মতো)।
                      child: photo != null
                          ? pw.ClipRRect(
                              horizontalRadius: 6,
                              verticalRadius: 6,
                              child: pw.Image(photo, fit: pw.BoxFit.cover),
                            )
                          : pw.Text(
                              initials,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 22,
                                color: IdCardPdfWidgets.green,
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
                              color: IdCardPdfWidgets.ink,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          IdCardPdfWidgets.field(
                              font, bold, 'সদস্য নম্বর', member.displayNumber),
                          IdCardPdfWidgets.field(
                              font, bold, 'সমিতি', branch?.name ?? '—'),
                          IdCardPdfWidgets.field(
                            font,
                            bold,
                            'ভর্তির তারিখ',
                            idCardDateText(member.joinDate),
                          ),
                          IdCardPdfWidgets.field(
                              font, bold, 'ফোন', member.phone),
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

    // ২. পেছনের পাতা
    doc.addPage(
      pw.Page(
        pageFormat: cardSize,
        margin: pw.EdgeInsets.zero,
        build: (_) => IdCardPdfWidgets.buildBackPage(
          member: member,
          font: font,
          bold: bold,
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
