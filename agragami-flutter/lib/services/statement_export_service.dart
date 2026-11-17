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
  /// মাসিক পূর্ণাঙ্গ আর্থিক বিবরণী CSV তৈরি
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

    // ১. জমা তালিকা
    sb.writeln(isBn ? '[জমা ও কিস্তির বিবরণ]' : '[Deposits Ledger]');
    sb.writeln(
        '${isBn ? "তারিখ" : "Date"},${isBn ? "সদস্য আইডি" : "Member ID"},${isBn ? "রসিদ নম্বর" : "Receipt No"},${isBn ? "পদ্ধতি" : "Method"},${isBn ? "TrxID" : "TrxID"},${isBn ? "পরিমাণ (টাকা)" : "Amount (BDT)"}');

    int totalDeposit = 0;
    for (final p in payments) {
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

    // ৩. সারসংক্ষেপ
    final netBalance = totalDeposit - totalExpense;
    sb.writeln(isBn ? '[সারসংক্ষেপ]' : '[Summary]');
    sb.writeln(
        '${isBn ? "মোট প্রাপ্তি" : "Total Inflow"},$totalDeposit ${isBn ? "টাকা" : "BDT"}');
    sb.writeln(
        '${isBn ? "মোট ব্যয়" : "Total Outflow"},$totalExpense ${isBn ? "টাকা" : "BDT"}');
    sb.writeln(
        '${isBn ? "নীট স্থিতি" : "Net Balance"},$netBalance ${isBn ? "টাকা" : "BDT"}');

    return sb.toString();
  }

  /// পাসবই লেনদেন ইতিহাস CSV তৈরি
  String generateMemberPassbookCsv({
    required String memberName,
    required String memberId,
    required String branchName,
    required List<Payment> payments,
  }) {
    final isBn = AppStrings.isBangla;
    final sb = StringBuffer();
    sb.write('\uFEFF');

    sb.writeln(
        '${isBn ? "সদস্য পাসবই বিবরণী" : "Member Passbook Statement"},$memberName ($memberId)');
    sb.writeln('${isBn ? "সমিতি" : "Somithi"},$branchName');
    sb.writeln('');

    sb.writeln(
        '${isBn ? "তারিখ" : "Date"},${isBn ? "মাস ও বছর" : "Month/Year"},${isBn ? "রসিদ নম্বর" : "Receipt No"},${isBn ? "পদ্ধতি" : "Method"},${isBn ? "পরিমাণ (টাকা)" : "Amount (BDT)"},${isBn ? "অবস্থা" : "Status"}');

    int totalApproved = 0;
    for (final p in payments) {
      if (p.status == PaymentStatus.approved) totalApproved += p.amount;
      final dateStr =
          '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}';
      sb.writeln(
          '$dateStr,"${p.forMonth}/${p.forYear}","${p.receiptNumber ?? ''}","${p.methodLabel}",${p.amount},"${p.status.name}"');
    }
    sb.writeln(
        '${isBn ? "মোট অনুমোদিত জমা" : "Total Approved Deposit"},,,,$totalApproved,');

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
