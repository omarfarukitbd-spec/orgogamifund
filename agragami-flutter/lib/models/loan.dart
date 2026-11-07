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
      date: DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime.now(),
      method: (data['method'] as String?) ?? '',
      paymentMethodId: data['paymentMethodId'] as String?,
      paymentMethodName: data['paymentMethodName'] as String?,
      paymentAccountNumber: data['paymentAccountNumber'] as String?,
      trxId: data['trxId'] as String?,
      senderMobile: data['senderMobile'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'date': date.toIso8601String(),
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

  factory Loan.fromMap(String id, Map<String, dynamic> data) {
    final list = (data['repayments'] as List?) ?? [];
    return Loan(
      id: id,
      memberId: (data['memberId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      dateIssued:
          DateTime.tryParse((data['dateIssued'] as String?) ?? '') ?? DateTime.now(),
      reason: (data['reason'] as String?) ?? '',
      status: LoanStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => LoanStatus.active,
      ),
      repayments: list
          .map((e) => LoanRepayment.fromMap(e as Map<String, dynamic>))
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
      'dateIssued': dateIssued.toIso8601String(),
      'reason': reason,
      'status': status.name,
      'repayments': repayments.map((r) => r.toMap()).toList(),
      'monthlyInstallment': monthlyInstallment,
      'installmentMonths': installmentMonths,
    };
  }
}
