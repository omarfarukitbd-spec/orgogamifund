import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import '../models/payment.dart';

final statementExportServiceProvider =
    Provider<StatementExportService>((ref) => StatementExportService());

/// সমিতির আর্থিক ও সদস্য লেনদেনের বিবরণী (CSV / Excel) এক্সপোর্ট সার্ভিস
class StatementExportService {
  /// মাসিক পূর্ণাঙ্গ আর্থিক বিবরণী CSV তৈরি।
  /// Phase 5 (F23): শুধু অনুমোদিত জমা গোনা হয় (যাচাইাধীন
  /// জমা আয় নয়), আর ঋণের প্রবাহও যোগ হয় — এই মাসে দেওয়া
  /// ঋণ আর এই মাসে ফেরত আসা কিস্তি, loadMonthTotals-এর
  /// একই মাস-ছাঁকা দিয়ে। নীট স্থিতি PDF-এর সাথে মেলে:
  /// জমা − খরচ − দেওয়া ঋণ + ফেরত কিস্তি।
  String generateMonthlyStatementCsv({
    required int year,
    required int month,
    required String branchName,
    required List<Payment> payments,
    required List<Expense> expenses,
    required List<Loan> loans,
  }) {
    final isBn = AppStrings.isBangla;
    final sb = StringBuffer();

    // UTF-8 BOM যাতে মাইক্রোসফট এক্সেল বাংলা অক্ষর ঠিকমতো দেখায়
    sb.write('\uFEFF');

    sb.writeln(
        '${isBn ? "অগ্রগামী ফান্ড সমিতি আর্থিক বিবরণী" : "Ogrogami Fund Somithi Financial Statement"},$branchName');
    sb.writeln(
        '${isBn ? "মাস ও বছর" : "Month & Year"},${isBn ? "$month/$year" : "$month/$year"}');
    sb.writeln('');

    // ১. জমা তালিকা — শুধু অনুমোদিত জমা (F23)।
    sb.writeln(isBn ? '[জমা ও কিস্তির বিবরণ]' : '[Deposits Ledger]');
    sb.writeln(
        '${isBn ? "তারিখ" : "Date"},${isBn ? "সদস্য আইডি" : "Member ID"},${isBn ? "রসিদ নম্বর" : "Receipt No"},${isBn ? "পদ্ধতি" : "Method"},${isBn ? "TrxID" : "TrxID"},${isBn ? "পরিমাণ (টাকা)" : "Amount (BDT)"}');

    int totalDeposit = 0;
    for (final p in payments) {
      if (p.status != PaymentStatus.approved) continue;
      totalDeposit += p.amount;
      final dateStr =
          '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}';
      sb.writeln(
          '$dateStr,"${p.memberId}","${p.receiptNumber ?? ''}","${p.methodLabel}","${p.trxId}",${p.amount}');
    }
    sb.writeln('${isBn ? "মোট জমা" : "Total Deposits"},,,,,$totalDeposit');
    sb.writeln('');

    // ২. খরচ তালিকা
    sb.writeln(isBn ? '[ব্যয়ের বিবরণ]' : '[Expense Ledger]');
    sb.writeln(
        '${isBn ? "তারিখ" : "Date"},${isBn ? "খাত / উদ্দেশ্য" : "Category / Purpose"},${isBn ? "ভাউচার / বিবরণ" : "Description"},${isBn ? "পরিমাণ (টাকা)" : "Amount (BDT)"}');

    int totalExpense = 0;
    for (final e in expenses) {
      totalExpense += e.amount;
      final dateStr =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      sb.writeln(
          '$dateStr,"${e.category}","${e.description.replaceAll('"', '""')}",${e.amount}');
    }
    sb.writeln('${isBn ? "মোট খরচ" : "Total Expenses"},,,$totalExpense');
    sb.writeln('');

    // ৩. ঋণের প্রবাহ (F23) — loadMonthTotals-এর একই
    // মাস-ছাঁকা: এই মাসে দেওয়া ঋণ (dateIssued দিয়ে) আর
    // এই মাসে ফেরত আসা কিস্তি (কিস্তির তারিখ দিয়ে)।
    sb.writeln(isBn ? '[ঋণ ও কিস্তির বিবরণ]' : '[Loans & Repayments]');
    sb.writeln(
        '${isBn ? "তারিখ" : "Date"},${isBn ? "ধরন" : "Type"},${isBn ? "সদস্য আইডি" : "Member ID"},${isBn ? "পরিমাণ (টাকা)" : "Amount (BDT)"}');

    int loansGiven = 0;
    int repayments = 0;
    for (final l in loans) {
      if (l.dateIssued.year == year && l.dateIssued.month == month) {
        loansGiven += l.amount;
        final dateStr =
            '${l.dateIssued.year}-${l.dateIssued.month.toString().padLeft(2, '0')}-${l.dateIssued.day.toString().padLeft(2, '0')}';
        sb.writeln(
            '$dateStr,${isBn ? "ঋণ দেওয়া হয়েছে" : "Loan Given"},"${l.memberId}",${l.amount}');
      }
      for (final r in l.repayments) {
        if (r.date.year == year && r.date.month == month) {
          repayments += r.amount;
          final dateStr =
              '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
          sb.writeln(
              '$dateStr,${isBn ? "কিস্তি ফেরত" : "Repayment"},"${l.memberId}",${r.amount}');
        }
      }
    }
    sb.writeln(
        '${isBn ? "মোট ঋণ দেওয়া হয়েছে" : "Total Loans Given"},,,$loansGiven');
    sb.writeln(
        '${isBn ? "মোট কিস্তি ফেরত" : "Total Repayments"},,,$repayments');
    sb.writeln('');

    // ৪. সারসংক্ষেপ — PDF-এর সাথে একই সূত্র।
    final totalInflow = totalDeposit + repayments;
    final totalOutflow = totalExpense + loansGiven;
    final netBalance = totalInflow - totalOutflow;
    sb.writeln(isBn ? '[সারসংক্ষেপ]' : '[Summary]');
    sb.writeln(
        '${isBn ? "মোট প্রাপ্তি" : "Total Inflow"},$totalInflow ${isBn ? "টাকা" : "BDT"}');
    sb.writeln(
        '${isBn ? "মোট ব্যয়" : "Total Outflow"},$totalOutflow ${isBn ? "টাকা" : "BDT"}');
    sb.writeln(
        '${isBn ? "নীট স্থিতি" : "Net Balance"},$netBalance ${isBn ? "টাকা" : "BDT"}');

    return sb.toString();
  }

  /// স্টেটমেন্ট শেয়ার বা ডাউনলোড করা
  Future<void> exportAndShareCsv({
    required String csvContent,
    required String filename,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(csvContent));
    try {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'text/csv', name: filename)],
        subject: filename,
      );
    } catch (_) {
      // শেয়ার ব্যর্থ হলে বিকল্প হিসেবে প্রিন্টিং এক্সপোর্টে প্রদান
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  }
}
