import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/payment.dart';

final voucherShareServiceProvider =
    Provider<VoucherShareService>((ref) => VoucherShareService());

/// জমা রসিদ ও ভাউচার হোয়াটসঅ্যাপ এবং এসএমএসে শেয়ার করার সার্ভিস
class VoucherShareService {
  /// জমার আনুষ্ঠানিক ভাউচার টেক্সট তৈরি।
  /// [memberNumber] — মানুষের পড়ার মতো সদস্য নম্বর (F15);
  /// না দিলে সদস্য id-এর সংক্ষিপ্ত রূপ দেখানো হয়, কখনো
  /// পুরো ২০-অক্ষরের id নয়।
  String formatPaymentVoucherText({
    required Payment payment,
    required String memberName,
    required String branchName,
    String? memberNumber,
  }) {
    final isBn = AppStrings.isBangla;
    final sb = StringBuffer();
    final displayNo = memberNumber ??
        (payment.memberId.length > 6
            ? payment.memberId.substring(0, 6)
            : payment.memberId);

    sb.writeln(isBn
        ? 'অগ্রগামী ফান্ড সমিতি — জমা নিশ্চিতকরণ রসিদ'
        : 'Ogrogami Fund Somithi - Deposit Receipt');
    sb.writeln('----------------------------------------');
    sb.writeln('${isBn ? "সমিতি" : "Somithi"}: $branchName');
    sb.writeln('${isBn ? "সদস্যের নাম" : "Member Name"}: $memberName');
    sb.writeln('${isBn ? "সদস্য নম্বর" : "Member ID"}: $displayNo');
    if (payment.receiptNumber != null && payment.receiptNumber!.isNotEmpty) {
      sb.writeln(
          '${isBn ? "রসিদ নম্বর" : "Receipt No"}: ${payment.receiptNumber}');
    }
    sb.writeln(
        '${isBn ? "জমার মাস" : "Month"}: ${payment.forMonth}/${payment.forYear}');
    sb.writeln('${isBn ? "জমার পরিমাণ" : "Amount"}: ${payment.amount} ${isBn ? "টাকা" : "BDT"}');
    sb.writeln('${isBn ? "পেমেন্ট মাধ্যম" : "Payment Method"}: ${payment.methodLabel}');
    sb.writeln('${isBn ? "লেনদেন আইডি (TrxID)" : "TrxID"}: ${payment.trxId}');
    sb.writeln('${isBn ? "অবস্থা" : "Status"}: ${payment.status.name.toUpperCase()}');
    final dateStr =
        '${payment.date.year}-${payment.date.month.toString().padLeft(2, '0')}-${payment.date.day.toString().padLeft(2, '0')}';
    sb.writeln('${isBn ? "তারিখ" : "Date"}: $dateStr');
    sb.writeln('----------------------------------------');
    sb.writeln(isBn
        ? 'অগ্রগামী ফান্ড — সম্পূর্ণ হালাল ও সুদমুক্ত সমিতি'
        : 'Ogrogami Fund - 100% Halal & Interest-Free');

    return sb.toString();
  }

  /// সরাসরি হোয়াটসঅ্যাপে ভাউচার মেসেজ পাঠানো
  Future<bool> shareToWhatsApp({
    required String text,
    String? phoneNumber,
  }) async {
    final cleanPhone = phoneNumber?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    final encodedText = Uri.encodeComponent(text);

    Uri uri;
    if (cleanPhone.isNotEmpty) {
      uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');
    } else {
      uri = Uri.parse('whatsapp://send?text=$encodedText');
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // হোয়াটসঅ্যাপ অ্যাপ না থাকলে ওয়েব লিংক
        final webUri =
            Uri.parse('https://api.whatsapp.com/send?text=$encodedText');
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // ব্যর্থ হলে সিস্টেম শেয়ার ডায়ালগ প্রদর্শন
      await Share.share(text);
      return true;
    }
  }

  /// জেনেরিক শেয়ার শিট চালু করা
  Future<void> shareGeneral({required String text}) async {
    await Share.share(text);
  }
}
