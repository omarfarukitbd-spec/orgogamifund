import '../utils/date_parser.dart';

/// একটি সমিতি / ব্রাঞ্চ।
/// Firestore কালেকশন: branches
/// উদ্দেশ্য আলাদা করে রাখা হয়েছে — মাদ্রাসা সহায়তা, মসজিদ ও
/// এতিমখানা দান, বা পরে যোগ হওয়া অন্য কোনো কাজ।
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

class Branch {
  final String id;
  final String name;
  final String description;
  final SamitiPurpose purpose;
  final int monthlyDonation;
  final String? treasurerUserId;
  final int balance;
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
    required this.monthlyDonation,
    this.treasurerUserId,
    this.balance = 0,
    this.startDate,
    this.canMembersViewTotalFund = true,
    this.canMembersViewExpenses = true,
    this.canMembersViewMemberList = true,
    this.memberCount = 0,
  });

  factory Branch.fromMap(String id, Map<String, dynamic> data) {
    final permissionsMap = data['permissions'] as Map?;
    final canViewTotalFund = (data['canMembersViewTotalFund'] ??
            permissionsMap?['canMembersViewTotalFund']) as bool? ??
        true;
    final canViewExpenses = (data['canMembersViewExpenses'] ??
            permissionsMap?['canMembersViewExpenses']) as bool? ??
        true;
    final canViewMemberList = (data['canMembersViewMemberList'] ??
            permissionsMap?['canMembersViewMemberList']) as bool? ??
        true;

    DateTime? startDate;
    if (data['startDate'] != null) {
      startDate = parseFirestoreDate(data['startDate']);
    } else if (data['establishedYear'] != null) {
      final yearStr = data['establishedYear'].toString();
      final yearNum = int.tryParse(yearStr);
      if (yearNum != null) {
        startDate = DateTime(yearNum, 1, 1);
      }
    }

    return Branch(
      id: id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      purpose: SamitiPurpose.values.firstWhere(
        (p) => p.name == data['purpose'],
        orElse: () => SamitiPurpose.other,
      ),
      monthlyDonation: ((data['monthlyDonation'] ?? data['monthlyDepositAmount']) as num?)?.toInt() ?? 0,
      treasurerUserId: data['treasurerUserId'] as String?,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      startDate: startDate,
      canMembersViewTotalFund: canViewTotalFund,
      canMembersViewExpenses: canViewExpenses,
      canMembersViewMemberList: canViewMemberList,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'purpose': purpose.name,
      'monthlyDonation': monthlyDonation,
      'treasurerUserId': treasurerUserId,
      'balance': balance,
      'startDate': startDate?.toIso8601String(),
      'canMembersViewTotalFund': canMembersViewTotalFund,
      'canMembersViewExpenses': canMembersViewExpenses,
      'canMembersViewMemberList': canMembersViewMemberList,
      'memberCount': memberCount,
    };
  }
}
