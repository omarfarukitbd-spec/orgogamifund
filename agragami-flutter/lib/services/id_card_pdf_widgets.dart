import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';

import '../models/member.dart';
import '../utils/member_qr.dart';

/// আইডি কার্ডের PDF তৈরির সাধারণ উইজেট ও বিল্ডার
class IdCardPdfWidgets {
  static const PdfColor green = PdfColor.fromInt(0xFF0B6B3A);
  static const PdfColor greenDark = PdfColor.fromInt(0xFF084E2B);
  static const PdfColor gold = PdfColor.fromInt(0xFFC9A227);
  static const PdfColor ink = PdfColor.fromInt(0xFF1A1F1C);
  static const PdfColor muted = PdfColor.fromInt(0xFF5F6B64);
  static const PdfColor line = PdfColor.fromInt(0xFFE3E8E5);

  static pw.Widget field(
    pw.Font font,
    pw.Font bold,
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 72,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 9, color: muted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: bold, fontSize: 10, color: ink),
            ),
          ),
        ],
      ),
    );
  }

  /// M7: আসল QR কোডের মডিউল — কার্ডের স্ক্রিনের QR-এর
  /// সাথে একই তথ্য (MemberQr)। মডিউল সংখ্যা তথ্যের
  /// দৈর্ঘ্য অনুযায়ী বদলায়, তাই সেলের মাপ হিসাব করে
  /// পুরো কোড ~50pt চওড়া রাখা হয়।
  static pw.Widget qrGrid(String memberId) {
    final qrCode = QrCode.fromData(
      data: MemberQr.dataFor(memberId),
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final count = qrImage.moduleCount;
    final cell = 50 / count;
    return pw.Column(
      children: [
        for (var r = 0; r < count; r++)
          pw.Row(
            children: [
              for (var c = 0; c < count; c++)
                pw.Container(
                  width: cell,
                  height: cell,
                  color: qrImage.isDark(r, c) ? ink : PdfColors.white,
                ),
            ],
          ),
      ],
    );
  }

  /// পেছনের পাতা বিল্ড করা
  static pw.Widget buildBackPage({
    required Member member,
    required pw.Font font,
    required pw.Font bold,
  }) {
    return pw.Container(
      color: greenDark,
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
                  style: pw.TextStyle(
                      font: font, fontSize: 9, color: PdfColors.white),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'সদস্য নম্বর: ${member.displayNumber}',
                  style: pw.TextStyle(
                      font: font, fontSize: 9, color: PdfColors.white),
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
                          pw.Container(height: 1, color: PdfColors.white),
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
                          pw.Container(height: 1, color: PdfColors.white),
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
                child: qrGrid(member.id),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                // F15: QR-এর নিচে দেখানোর নম্বর (QR নিজে
                // ডকুমেন্ট id দিয়ে বানানো থাকে)।
                member.displayNumber,
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
    );
  }
}
