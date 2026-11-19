import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_parser.dart';

/// একটি সমিতি / ব্রাঞ্চ।
/// Firestore কালেকশন: branches
/// উদ্দেশ্য আলাদা করে রাখা হয়েছে — মাদ্রাসা সহায়তা, মসজিদ ও
/// এতিমখানা দান, বা পরে যোগ হওয়া অন্য কোনো কাজ।
/// লাইভ ডকুমেন্টের সব ক্ষেত্র পড়া হয়: কোড, ভর্তি ফি,
/// মাসিক জমার পরিমাণ, দানের শেষ দিন, বিলম্ব জরিমানা,
/// ঐচ্ছিক জমার নিয়ম, ব্যাংক তথ্য আর শর্তাবলি।
enum SamitiPurpose { madrasa, mosqueOrphanage, other }

/// সমিতির উদ্দেশ্যের বাংলা নাম — তালিকায় সবাই দেখতে পায়।
String samitiPurposeText(SamitiPurpose purpose) {
  switch (purpose) {
    case SamitiPurpose.madrasa:
      return 'মাদ্রাসা সহায়তা';
    case SamitiPurpose.mosqueOrphanage:
      return 'মসজিদ ও এতিমখানা দান';
    case SamitiPurpose.other:
      return 'অন্যান্য';
  }
}

/// সমিতির ব্যাংক তথ্য — লাইভ ডকুমেন্টের `bankDetails` ম্যাপ।
/// চাবির নাম পুরোনো আর নতুন লেখায় আলাদা হতে পারে, তাই
/// কয়েকটা সম্ভাব্য চাবি দেখে পড়া হয়।
class BankDetails {
  final String? bankName;
  final String? branchName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? routingNumber;
  final String? bkashNumber;
  final String? nagadNumber;

  const BankDetails({
    this.bankName,
    this.branchName,
    this.accountNumber,
    this.accountHolderName,
    this.routingNumber,
    this.bkashNumber,
    this.nagadNumber,
  });

  bool get isEmpty => [
        bankName,
        branchName,
        accountNumber,
        accountHolderName,
        routingNumber,
        bkashNumber,
        nagadNumber,
      ].every((v) => v == null || v.isEmpty);

  factory BankDetails.fromMap(Map<String, dynamic> data) {
    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
        if (value is num) return value.toString();
      }
      return null;
    }

    return BankDetails(
      bankName: pick(['bankName', 'bank']),
      branchName: pick(['branchName', 'branch']),
      accountNumber: pick(['accountNumber', 'accountNo', 'account']),
      accountHolderName: pick(['accountHolderName', 'accountHolder']),
      routingNumber: pick(['routingNumber']),
      bkashNumber: pick(['bkashNumber', 'bKash', 'bkash']),
      nagadNumber: pick(['nagadNumber', 'Nagad', 'nagad']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (bankName != null) 'bankName': bankName,
      if (branchName != null) 'branchName': branchName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (accountHolderName != null) 'accountHolderName': accountHolderName,
      if (routingNumber != null) 'routingNumber': routingNumber,
      if (bkashNumber != null) 'bkashNumber': bkashNumber,
      if (nagadNumber != null) 'nagadNumber': nagadNumber,
    };
  }
}

class Branch {
  final String id;
  final String name;
  final String description;
  final SamitiPurpose purpose;

  /// সমিতির কোড — যেমন AGF-2015।
  final String? code;

  /// মাসে জমা দিতে হয় কত টাকা। লাইভে নতুন লেখায়
  /// `monthlyDepositAmount`, পুরোনো লেখায় `monthlyDonation` —
  /// দুটোই পড়া হয়, নতুনটাই অগ্রাধিকার পায়।
  final int monthlyDepositAmount;

  /// এককালীন ভর্তি ফি।
  final int admissionFee;

  /// মাসের কত তারিখের মধ্যে জমা দিতে হয় (ডিফল্ট ১০)।
  /// এই তারিখ পেরিয়ে গেলেই ওই মাস বকেয়া ধরা হয়।
  final int monthlyDueDay;

  /// বকেয়া মাসপ্রতি বিলম্ব জরিমানা।
  final int lateFineAmount;

  /// ঐচ্ছিক জমার ন্যূনতম পরিমাণ।
  final int minOptionalDeposit;

  /// ঐচ্ছিক জমা চালু কি না।
  final bool optionalDepositEnabled;

  /// ব্যাংক অ্যাকাউন্টের তথ্য (থাকলে)।
  final BankDetails? bankDetails;

  /// সমিতির শর্তাবলি।
  final List<String> termsAndConditions;

  final String? treasurerUserId;
  final DateTime? startDate;
  final bool canMembersViewTotalFund;
  final bool canMembersViewExpenses;
  final bool canMembersViewMemberList;

  /// অনুমোদিত সদস্যের সংখ্যা — সমিতির ডকুমেন্টেই রাখা হয়,
  /// যাতে সদস্য নয় এমন লগইন করা ব্যবহারকারীও সংখ্যাটা
  /// দেখতে পায়, সদস্যদের নাম না দেখে। অনুমোদনের সময় বাড়ে।
  final int memberCount;

  const Branch({
    required this.id,
    required this.name,
    required this.description,
    required this.purpose,
    this.code,
    required this.monthlyDepositAmount,
    this.admissionFee = 0,
    this.monthlyDueDay = 10,
    this.lateFineAmount = 0,
    this.minOptionalDeposit = 0,
    this.optionalDepositEnabled = false,
    this.bankDetails,
    this.termsAndConditions = const [],
    this.treasurerUserId,
    this.startDate,
    this.canMembersViewTotalFund = true,
    this.canMembersViewExpenses = true,
    this.canMembersViewMemberList = true,
    this.memberCount = 0,
  });

  factory Branch.fromMap(String id, Map<String, dynamic> data) {
    final permissionsMap = data['permissions'] as Map?;
    // অনুমতির মান bool না হলে (ভুল ডেটা) ডিফল্ট true ধরা হয় —
    // `as bool?` কাস্টে পুরো স্ট্রিম ভাঙত।
    bool flag(dynamic value) => value is bool ? value : true;
    final canViewTotalFund = flag(data['canMembersViewTotalFund'] ??
        permissionsMap?['canMembersViewTotalFund']);
    final canViewExpenses = flag(data['canMembersViewExpenses'] ??
        permissionsMap?['canMembersViewExpenses']);
    final canViewMemberList = flag(data['canMembersViewMemberList'] ??
        permissionsMap?['canMembersViewMemberList']);

    DateTime? startDate;
    if (data['startDate'] != null) {
      final parsed = parseFirestoreDate(data['startDate']);
      if (!isMissingDate(parsed)) startDate = parsed;
    }
    if (startDate == null && data['establishedYear'] != null) {
      final yearStr = data['establishedYear'].toString();
      final yearNum = int.tryParse(yearStr);
      if (yearNum != null) {
        startDate = DateTime(yearNum, 1, 1);
      }
    }

    // মাসিক জমা: নতুন চাবি আগে, পুরোনো চাবি পরে।
    final monthlyAmount =
        ((data['monthlyDepositAmount'] ?? data['monthlyDonation']) as num?)
                ?.toInt() ??
            0;
    final dueDay = (data['monthlyDueDay'] as num?)?.toInt() ?? 10;
    final terms = (data['termsAndConditions'] as List?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    final bankMap = data['bankDetails'];
    final bankDetails = bankMap is Map<String, dynamic>
        ? BankDetails.fromMap(bankMap)
        : bankMap is Map
            ? BankDetails.fromMap(Map<String, dynamic>.from(bankMap))
            : null;

    return Branch(
      id: id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      purpose: switch (((data['purpose'] as String?) ?? '').toLowerCase().replaceAll('_', '')) {
        'madrasa' => SamitiPurpose.madrasa,
        'mosqueorphanage' => SamitiPurpose.mosqueOrphanage,
        _ => SamitiPurpose.other,
      },
      code: (data['code'] as String?)?.trim().isEmpty == true
          ? null
          : (data['code'] as String?)?.trim(),
      monthlyDepositAmount: monthlyAmount,
      admissionFee: (data['admissionFee'] as num?)?.toInt() ?? 0,
      monthlyDueDay: dueDay.clamp(1, 31),
      lateFineAmount: (data['lateFineAmount'] as num?)?.toInt() ?? 0,
      minOptionalDeposit:
          (data['minOptionalDeposit'] as num?)?.toInt() ?? 0,
      optionalDepositEnabled:
          data['optionalDepositEnabled'] is bool
              ? data['optionalDepositEnabled'] as bool
              : false,
      bankDetails:
          bankDetails == null || bankDetails.isEmpty ? null : bankDetails,
      termsAndConditions: terms,
      treasurerUserId: data['treasurerUserId'] as String?,
      startDate: startDate,
      canMembersViewTotalFund: canViewTotalFund,
      canMembersViewExpenses: canViewExpenses,
      canMembersViewMemberList: canViewMemberList,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// লাইভ স্কিমা অনুযায়ী লেখা হয় — নতুন সমিতিতেও
  /// পুরোনো সমিতির মতো একই ক্ষেত্র থাকে।
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'purpose': purpose.name,
      if (code != null) 'code': code,
      'monthlyDepositAmount': monthlyDepositAmount,
      'admissionFee': admissionFee,
      'monthlyDueDay': monthlyDueDay,
      'lateFineAmount': lateFineAmount,
      'minOptionalDeposit': minOptionalDeposit,
      'optionalDepositEnabled': optionalDepositEnabled,
      if (bankDetails != null) 'bankDetails': bankDetails!.toMap(),
      'termsAndConditions': termsAndConditions,
      'treasurerUserId': treasurerUserId,
      'startDate':
          startDate == null ? null : Timestamp.fromDate(startDate!),
      'permissions': {
        'canMembersViewTotalFund': canMembersViewTotalFund,
        'canMembersViewExpenses': canMembersViewExpenses,
        'canMembersViewMemberList': canMembersViewMemberList,
      },
      'memberCount': memberCount,
    };
  }
}
