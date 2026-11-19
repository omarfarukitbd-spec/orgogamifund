import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_parser.dart';

/// একটি জমা।
/// Firestore কালেকশন: payments
/// সদস্য নিজে অ্যাডমিনের দেওয়া মাধ্যম (মোবাইল ব্যাংকিং/ব্যাংক)
/// দিয়ে টাকা পাঠিয়ে TrxID দিয়ে জমা দেয়,
/// অ্যাডমিন যাচাই করে অনুমোদন দেন। জরিমানা বলে কিছু নেই।
/// জমার সাথে মাধ্যমের নাম-নম্বরের ছাপ লেখা থাকে —
/// মাধ্যম পরে বদলালে বা বন্ধ হলেও আগের জমার হিসাব ঠিক থাকে।
/// পুরোনো জমায় মাধ্যম বিকাশ/নগদ নামে লেখা ছিল — সেগুলো
/// মোবাইল ব্যাংকিং হিসেবে ধরা হয়।
enum PaymentMethodKind { mobileBanking, bank, cash }
enum PaymentType { monthly, yearly, special }
enum PaymentStatus { pending, approved, rejected }

class Payment {
  final String id;
  final String memberId;
  final String branchId;
  final PaymentType type;
  final int amount;
  final PaymentMethodKind method;
  final String? trxId;
  final String? paymentMethodId;
  final String? paymentMethodName;
  final String? paymentAccountNumber;
  final String? senderMobile;
  final int forMonth;
  final int forYear;
  final DateTime date;
  final String recordedBy;
  final PaymentStatus status;
  final String? receiptNumber;
  final String? rejectReason;

  const Payment({
    required this.id,
    required this.memberId,
    required this.branchId,
    required this.type,
    required this.amount,
    required this.method,
    this.trxId,
    this.paymentMethodId,
    this.paymentMethodName,
    this.paymentAccountNumber,
    this.senderMobile,
    required this.forMonth,
    required this.forYear,
    required this.date,
    required this.recordedBy,
    required this.status,
    this.receiptNumber,
    this.rejectReason,
  });

  /// অবস্থার বাংলা নাম — UI-তে ইংরেজি enum নাম দেখানো হয় না।
  String get statusLabel {
    return switch (status) {
      PaymentStatus.approved => 'অনুমোদিত',
      PaymentStatus.pending => 'যাচাইাধীন',
      PaymentStatus.rejected => 'বাতিল',
    };
  }

  /// দেখানোর মতো মাধ্যমের নাম — ছাপ থাকলে সেটাই,
  /// না থাকলে (পুরোনো জমা) ধরনের নাম।
  String get methodLabel {
    if (paymentMethodName != null && paymentMethodName!.isNotEmpty) {
      return paymentMethodName!;
    }
    return switch (method) {
      PaymentMethodKind.mobileBanking => 'মোবাইল ব্যাংকিং',
      PaymentMethodKind.bank => 'ব্যাংক',
      PaymentMethodKind.cash => 'নগদ টাকা',
    };
  }

  static PaymentMethodKind _kindFrom(String? raw) {
    return switch (raw) {
      'mobileBanking' || 'bkash' || 'nagad' => PaymentMethodKind.mobileBanking,
      'bank' => PaymentMethodKind.bank,
      _ => PaymentMethodKind.cash,
    };
  }

  factory Payment.fromMap(String id, Map<String, dynamic> data) {
    final rawStatus = ((data['status'] ?? data['approvalStatus']) as String?)?.toLowerCase();
    final status = switch (rawStatus) {
      'approved' => PaymentStatus.approved,
      'rejected' => PaymentStatus.rejected,
      _ => PaymentStatus.pending,
    };

    final date = parseFirestoreDate(data['date']);
    // কোন মাসের জমা: লেখা থাকলে সেটাই। না থাকলে বা ভুল
    // থাকলে (মাস ১–১২-এর বাইরে) জমার তারিখ থেকে নেওয়া হয়।
    // তারিখও না থাকলে ১৯৭০-০১ — ফলে জমাটা হিসাবের বাইরে
    // থাকে, জানুয়ারিতে ভুলভাবে জমা হয় না।
    var forMonth = (data['forMonth'] as num?)?.toInt();
    if (forMonth == null || forMonth < 1 || forMonth > 12) {
      forMonth = isMissingDate(date) ? 1 : date.month;
    }
    var forYear = (data['forYear'] as num?)?.toInt();
    if (forYear == null || forYear < 2000 || forYear > 2100) {
      forYear = isMissingDate(date) ? 1970 : date.year;
    }

    return Payment(
      id: id,
      memberId: (data['memberId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      type: PaymentType.values.firstWhere(
        (t) => t.name.toLowerCase() == (data['type'] as String?)?.toLowerCase(),
        orElse: () => PaymentType.monthly,
      ),
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      method: _kindFrom(data['method'] as String?),
      trxId: ((data['trxId'] ?? data['transactionId']) as String?),
      paymentMethodId: data['paymentMethodId'] as String?,
      paymentMethodName: data['paymentMethodName'] as String?,
      paymentAccountNumber: data['paymentAccountNumber'] as String?,
      senderMobile: data['senderMobile'] as String?,
      forMonth: forMonth,
      forYear: forYear,
      date: date,
      recordedBy: (data['recordedBy'] as String?) ?? '',
      status: status,
      receiptNumber: data['receiptNumber'] as String?,
      rejectReason: data['rejectReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'branchId': branchId,
      'type': type.name,
      'amount': amount,
      'method': method.name,
      'trxId': trxId,
      'transactionId': trxId,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'paymentAccountNumber': paymentAccountNumber,
      'senderMobile': senderMobile,
      'forMonth': forMonth,
      'forYear': forYear,
      'date': Timestamp.fromDate(date),
      'recordedBy': recordedBy,
      'status': status.name,
      'approvalStatus': status.name.toUpperCase(),
      'receiptNumber': receiptNumber,
      'rejectReason': rejectReason,
    };
  }
}
