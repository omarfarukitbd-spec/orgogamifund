import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_parser.dart';

/// কর্জে হাসানা — সুদমুক্ত ঋণ।
/// Firestore কালেকশন: loans
/// এখানে সুদের কোনো ফিল্ড নেই — সুদ, ফাইন বা লভ্যাংশের
/// হিসাব এই অ্যাপে রাখা হয় না।
enum LoanStatus { active, repaid, overdue }

class LoanRepayment {
  final int amount;
  final DateTime date;
  /// মাধ্যমের ধরন — mobileBanking / bank / cash।
  /// পুরোনো কিস্তিতে bkash/nagad নামে লেখা থাকতে পারে।
  final String method;
  /// জমার সময় মাধ্যমের নাম-নম্বরের ছাপ — মাধ্যম পরে
  /// বদলালে বা বন্ধ হলেও আগের কিস্তির হিসাব ঠিক থাকে।
  final String? paymentMethodId;
  final String? paymentMethodName;
  final String? paymentAccountNumber;
  final String? trxId;
  final String? senderMobile;

  const LoanRepayment({
    required this.amount,
    required this.date,
    required this.method,
    this.paymentMethodId,
    this.paymentMethodName,
    this.paymentAccountNumber,
    this.trxId,
    this.senderMobile,
  });

  /// দেখানোর মতো মাধ্যমের নাম — ছাপ থাকলে সেটাই,
  /// না থাকলে (পুরোনো কিস্তি) ধরনের নাম।
  String get methodLabel {
    if (paymentMethodName != null && paymentMethodName!.isNotEmpty) {
      return paymentMethodName!;
    }
    return switch (method) {
      'mobileBanking' || 'bkash' || 'nagad' => 'মোবাইল ব্যাংকিং',
      'bank' => 'ব্যাংক',
      _ => 'নগদ টাকা',
    };
  }

  factory LoanRepayment.fromMap(Map<String, dynamic> data) {
    return LoanRepayment(
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      date: parseFirestoreDate(data['date']),
      method: (data['method'] as String?) ?? '',
      paymentMethodId: data['paymentMethodId'] as String?,
      paymentMethodName: data['paymentMethodName'] as String?,
      paymentAccountNumber: data['paymentAccountNumber'] as String?,
      trxId: (data['trxId'] ?? data['transactionId']) as String?,
      senderMobile: data['senderMobile'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'method': method,
        'paymentMethodId': paymentMethodId,
        'paymentMethodName': paymentMethodName,
        'paymentAccountNumber': paymentAccountNumber,
        'trxId': trxId,
        'senderMobile': senderMobile,
      };
}

class Loan {
  final String id;
  final String memberId;
  final String branchId;
  final int amount;
  final DateTime dateIssued;
  final String reason;
  final LoanStatus status;
  final List<LoanRepayment> repayments;
  /// মাসে কত করে ফেরত দেওয়ার কথা — শুধু পরিকল্পনা,
  /// এতে সুদ বা বাড়তি কিছু যোগ হয় না।
  final int? monthlyInstallment;
  final int? installmentMonths;

  const Loan({
    required this.id,
    required this.memberId,
    required this.branchId,
    required this.amount,
    required this.dateIssued,
    required this.reason,
    required this.status,
    this.repayments = const [],
    this.monthlyInstallment,
    this.installmentMonths,
  });

  int get repaidTotal => repayments.fold(0, (sum, r) => sum + r.amount);
  int get outstanding => amount - repaidTotal;

  /// ফেরত দেওয়ার শেষ তারিখ — ঋণ নেওয়ার তারিখ + কিস্তির
  /// মাস। কিস্তির মেয়াদ না থাকলে শেষ তারিখ নেই।
  DateTime? get dueDate {
    final months = installmentMonths;
    if (months == null || months <= 0) return null;
    return DateTime(dateIssued.year, dateIssued.month + months,
        dateIssued.day);
  }

  /// মেয়াদ পেরিয়েছে কি না — পড়ার সময় হিসাব হয় (F31)।
  /// Firestore-এ 'overdue' অবস্থা কখনো লেখা হয় না (কোনো
  /// কোড সেটা লেখে না), তাই সংরক্ষিত অবস্থার ওপর ভরসা না
  /// করে শেষ তারিখ দিয়ে হিসাব করা হয়; পুরোনো ডকুমেন্টে
  /// 'overdue' লেখা থাকলে সেটাও ধরা হয়। ফেরত দেওয়া ঋণ
  /// কখনো মেয়াদ-পেরোনো নয়।
  bool get isOverdue {
    if (status == LoanStatus.repaid) return false;
    if (status == LoanStatus.overdue) return true;
    final due = dueDate;
    if (due == null) return false;
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day)
        .isAfter(DateTime(due.year, due.month, due.day));
  }

  factory Loan.fromMap(String id, Map<String, dynamic> data) {
    final list = (data['repayments'] as List?) ?? [];
    final rawStatus = (data['status'] as String?)?.toLowerCase();
    final status = switch (rawStatus) {
      'repaid' || 'paid_off' || 'paidoff' => LoanStatus.repaid,
      'overdue' || 'defaulted' => LoanStatus.overdue,
      _ => LoanStatus.active,
    };

    return Loan(
      id: id,
      memberId: (data['memberId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      dateIssued: parseFirestoreDate(data['dateIssued']),
      reason: (data['reason'] as String?) ?? '',
      status: status,
      // নষ্ট কিস্তি থাকলে সেটা বাদ যায় — একটা ভুল এন্ট্রিতে
      // পুরো ঋণের ডকুমেন্ট পড়া ভাঙে না।
      repayments: list
          .map((e) => e is Map
              ? LoanRepayment.fromMap(Map<String, dynamic>.from(e))
              : null)
          .whereType<LoanRepayment>()
          .toList(),
      monthlyInstallment: (data['monthlyInstallment'] as num?)?.toInt(),
      installmentMonths: (data['installmentMonths'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'branchId': branchId,
      'amount': amount,
      'dateIssued': Timestamp.fromDate(dateIssued),
      'reason': reason,
      'status': status.name,
      'repayments': repayments.map((r) => r.toMap()).toList(),
      'monthlyInstallment': monthlyInstallment,
      'installmentMonths': installmentMonths,
    };
  }
}
