/// বকেয়া হিসাবের ছোট হিসাবগুলো এক জায়গায়,
/// যাতে পাসবই আর রিপোর্টে একই নিয়মে হিসাব হয়।
library;

import '../models/payment.dart';
import 'date_parser.dart';

/// মাসভিত্তিক বকেয়া হিসাবের ফলাফল।
/// পাসবই আর বকেয়া তালিকা দুই জায়গাতেই এই একটাই
/// ফলাফল ব্যবহার হয় — দুই স্ক্রিনে দুই রকম অঙ্ক আর নয়।
class DuesResult {
  /// মাসিক বকেয়া টাকা (জরিমানা ছাড়া)।
  final int totalDue;

  /// বিলম্ব জরিমানা — বকেয়া থাকা প্রতিটি মাসের জন্য
  /// শাখার নির্ধারিত জরিমানা। শাখায় জরিমানা ০ হলে ০।
  final int lateFine;

  /// পুরো পরিমাণ পরিশোধিত মাসের সংখ্যা।
  final int paidMonths;

  /// বকেয়া আছে এমন মাসের সংখ্যা।
  final int dueMonths;

  /// হিসাবের আওতায় মোট মাস (যোগদান থেকে হিসাবের শেষ মাস)।
  final int expectedMonths;

  const DuesResult({
    required this.totalDue,
    required this.lateFine,
    required this.paidMonths,
    required this.dueMonths,
    required this.expectedMonths,
  });

  /// জরিমানাসহ সর্বমোট বকেয়া।
  int get totalWithFine => totalDue + lateFine;
}

/// কোনো সদস্যের মাসভিত্তিক বকেয়া হিসাব।
///
/// নিয়ম:
/// - প্রতি মাসে আলাদাভাবে হিসাব হয়: ওই মাসের অনুমোদিত
///   জমা মাসিক পরিমাণের চেয়ে কম হলে বাকিটা বকেয়া।
///   আংশিক জমা (যেমন ২০০-র মধ্যে ১০০) ওই মাসকে পুরো
///   পরিশোধিত ধরে না — বাকি ১০০ বকেয়া থাকে।
/// - বকেয়া গোনা শুরু হয় সদস্যের যোগদানের তারিখ আর
///   সমিতির শুরুর তারিখের মধ্যে যেটা পরে, সেখান থেকে।
///   যোগদানের আগের মাস কখনো বকেয়া ধরা হয় না।
/// - চলতি মাস ধরা হয় শুধু [dueDay] পেরিয়ে গেলে
///   (শাখার নিয়ম — যেমন মাসের ১০ তারিখ)।
/// - জমার মাস ধরা হয় তার forMonth/forYear দিয়ে,
///   লেনদেনের তারিখ দিয়ে নয়।
/// - যোগদানের তারিখ আর সমিতির শুরুর তারিখ দুটোই
///   জানা না থাকলে null ফেরে — আন্দাজে হিসাব হয় না।
DuesResult? memberDuesPerMonth({
  required DateTime? joinDate,
  required DateTime? branchStart,
  required int monthlyAmount,
  required List<Payment> payments,
  int dueDay = 10,
  int lateFineAmount = 0,
  DateTime? asOf,
}) {
  final now = asOf ?? DateTime.now();

  // শুরুর তারিখ: যোগদান আর সমিতি শুরুর মধ্যে যেটা পরে।
  // "তারিখ নেই" চিহ্ন থাকলে সেটা না-জানা ধরা হয়।
  DateTime? start;
  if (joinDate != null && !isMissingDate(joinDate)) start = joinDate;
  if (branchStart != null && !isMissingDate(branchStart)) {
    if (start == null || branchStart.isAfter(start)) start = branchStart;
  }
  if (start == null) return null;

  // হিসাবের শেষ মাস: চলতি মাস dueDay পেরিয়ে গেলেই ধরা হয়।
  final day = dueDay.clamp(1, 31);
  var endYear = now.year;
  var endMonth = now.month;
  if (now.day < day) {
    endMonth -= 1;
    if (endMonth == 0) {
      endMonth = 12;
      endYear -= 1;
    }
  }
  final end = DateTime(endYear, endMonth, 1);
  var cursor = DateTime(start.year, start.month, 1);
  if (cursor.isAfter(end)) {
    // এখনো প্রথম মাসের dueDay আসেনি — কোনো বকেয়া নেই।
    return const DuesResult(
      totalDue: 0,
      lateFine: 0,
      paidMonths: 0,
      dueMonths: 0,
      expectedMonths: 0,
    );
  }

  // মাসভিত্তিক অনুমোদিত জমা: "বছর-মাস" → টাকা।
  final paidByMonth = <String, int>{};
  for (final p in payments) {
    if (p.status != PaymentStatus.approved) continue;
    final key = '${p.forYear}-${p.forMonth}';
    paidByMonth[key] = (paidByMonth[key] ?? 0) + p.amount;
  }

  var totalDue = 0;
  var lateFine = 0;
  var paidMonths = 0;
  var dueMonths = 0;
  var expectedMonths = 0;
  while (!cursor.isAfter(end)) {
    expectedMonths += 1;
    final paid = paidByMonth['${cursor.year}-${cursor.month}'] ?? 0;
    final due = monthlyAmount - paid;
    if (due <= 0) {
      paidMonths += 1;
    } else {
      totalDue += due;
      dueMonths += 1;
      // বকেয়া থাকা প্রতিটি মাসের জন্য শাখার জরিমানা।
      lateFine += lateFineAmount;
    }
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }
  return DuesResult(
    totalDue: totalDue,
    lateFine: lateFine,
    paidMonths: paidMonths,
    dueMonths: dueMonths,
    expectedMonths: expectedMonths,
  );
}

/// কোনো বছরের প্রতি মাসে অনুমোদিত জমা কত — মাস → টাকা।
/// পাসবইয়ের মাস-গ্রিড এই হিসাব দিয়ে প্রতি মাসের অবস্থা দেখায়।
Map<int, int> paidAmountByMonth({
  required List<Payment> payments,
  required int year,
}) {
  final byMonth = <int, int>{};
  for (final p in payments) {
    if (p.status != PaymentStatus.approved) continue;
    if (p.forYear != year) continue;
    byMonth[p.forMonth] = (byMonth[p.forMonth] ?? 0) + p.amount;
  }
  return byMonth;
}
