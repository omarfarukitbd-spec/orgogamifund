import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branch.dart';
import '../services/firebase_service.dart';
import 'audit_repository.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final auditRepo = ref.watch(auditRepositoryProvider);
  return BranchRepository(auditRepository: auditRepo);
});

/// সমিতি সংক্রান্ত যাবতীয় ডেটাবেজ কার্যক্রমের রিপোজিটরি
class BranchRepository {
  final FirebaseFirestore _db;
  final AuditRepository _audit;

  BranchRepository({
    FirebaseFirestore? db,
    AuditRepository? auditRepository,
  })  : _db = db ?? FirebaseService.instance.db,
        _audit = auditRepository ?? AuditRepository(db: db);

  /// সমস্ত সমিতির লাইভ স্ট্রিম — নামের ক্রমে সাজানো।
  Stream<List<Branch>> watchBranches() {
    return _db
        .collection(Collections.branches)
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Branch.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// নির্দিষ্ট একটি সমিতির লাইভ স্ট্রিম
  Stream<Branch?> watchBranch(String branchId) {
    if (branchId.isEmpty) return Stream.value(null);
    return _db.collection(Collections.branches).doc(branchId).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Branch.fromMap(doc.id, doc.data()!)
              : null,
        );
  }

  /// নতুন সমিতি তৈরি করা — Branch.toMap() লাইভ স্কিমা
  /// অনুযায়ী লেখে, তাই নতুন সমিতিতেও পুরোনো সমিতির
  /// মতো একই ক্ষেত্র থাকে (B8: আর্থিক নিয়মগুলোও এখন
  /// খোলার সময়ই বসানো যায়)।
  Future<String> createBranch({
    required String name,
    required String description,
    required SamitiPurpose purpose,
    required int monthlyDepositAmount,
    int admissionFee = 0,
    int monthlyDueDay = 10,
    int lateFineAmount = 0,
    int minOptionalDeposit = 0,
    bool optionalDepositEnabled = false,
    BankDetails? bankDetails,
    List<String> termsAndConditions = const [],
    required String by,
  }) async {
    final branch = Branch(
      id: '',
      name: name,
      description: description,
      purpose: purpose,
      monthlyDepositAmount: monthlyDepositAmount,
      admissionFee: admissionFee,
      monthlyDueDay: monthlyDueDay,
      lateFineAmount: lateFineAmount,
      minOptionalDeposit: minOptionalDeposit,
      optionalDepositEnabled: optionalDepositEnabled,
      bankDetails: bankDetails,
      termsAndConditions: termsAndConditions,
      startDate: DateTime.now(),
    );
    final data = branch.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _db.collection(Collections.branches).add(data);
    await _audit.logAudit(
      action: 'create_branch',
      by: by,
      detail: 'সমিতি: $name (${ref.id})',
    );
    return ref.id;
  }

  /// সমিতির তথ্য আপডেট বা সম্পাদন করা (B8) — লাইভ স্কিমার
  /// সব আর্থিক ক্ষেত্র: মাসিক জমা, ভর্তি ফি, জমার শেষ দিন,
  /// বিলম্ব জরিমানা, ঐচ্ছিক জমা, কোষাধ্যক্ষ, ব্যাংক তথ্য,
  /// শর্তাবলি। পুরোনো `monthlyDonation` ক্ষেত্র মুছে দেওয়া
  /// হয় — লাইভ ডকুমেন্ট `monthlyDepositAmount` ব্যবহার করে।
  /// memberCount/balance এখান থেকে ছোঁয়া হয় না। Phase 5
  /// (F11): সদস্যদের দেখার অনুমতিগুলো (মোট তহবিল, খরচ,
  /// সদস্য তালিকা) এখন এখান থেকেই বদলানো যায় — আগে
  /// এগুলো শুধু Firebase Console থেকে বদলাতে হতো, আর
  /// অ্যাপে কোথাও ব্যবহারই হতো না।
  Future<void> updateBranch({
    required String branchId,
    required String name,
    required String description,
    required SamitiPurpose purpose,
    required int monthlyDepositAmount,
    required int admissionFee,
    required int monthlyDueDay,
    required int lateFineAmount,
    required int minOptionalDeposit,
    required bool optionalDepositEnabled,
    String? treasurerUserId,
    BankDetails? bankDetails,
    required List<String> termsAndConditions,
    required String by,
    bool? canMembersViewTotalFund,
    bool? canMembersViewExpenses,
    bool? canMembersViewMemberList,
  }) async {
    if (branchId.isEmpty) return;
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'purpose': purpose.name,
      'monthlyDepositAmount': monthlyDepositAmount,
      'monthlyDonation': FieldValue.delete(),
      'admissionFee': admissionFee,
      'monthlyDueDay': monthlyDueDay.clamp(1, 31),
      'lateFineAmount': lateFineAmount,
      'minOptionalDeposit': minOptionalDeposit,
      'optionalDepositEnabled': optionalDepositEnabled,
      'treasurerUserId': treasurerUserId,
      'termsAndConditions': termsAndConditions,
      'updatedAt': FieldValue.serverTimestamp(),
      // F11: অনুমতিগুলো permissions ম্যাপের ভেতরে ডট-পথে
      // লেখা হয় — বাকি permissions ছোঁয়া হয় না।
      if (canMembersViewTotalFund != null)
        'permissions.canMembersViewTotalFund': canMembersViewTotalFund,
      if (canMembersViewExpenses != null)
        'permissions.canMembersViewExpenses': canMembersViewExpenses,
      if (canMembersViewMemberList != null)
        'permissions.canMembersViewMemberList': canMembersViewMemberList,
    };
    if (bankDetails == null || bankDetails.isEmpty) {
      data['bankDetails'] = FieldValue.delete();
    } else {
      data['bankDetails'] = bankDetails.toMap();
    }
    await _db.collection(Collections.branches).doc(branchId).update(data);
    await _audit.logAudit(
      action: 'update_branch',
      by: by,
      detail: 'সমিতি আপডেট: $name ($branchId)',
    );
  }

  /// সমিতির সদস্য সংখ্যা রি-কাউন্ট করে আপডেট করা
  Future<void> recountMemberCount(String branchId) async {
    if (branchId.isEmpty) return;
    final snap = await _db
        .collection(Collections.members)
        .where('branchId', isEqualTo: branchId)
        .where('status', isEqualTo: 'active')
        .get();
    await _db.collection(Collections.branches).doc(branchId).update({
      'memberCount': snap.docs.length,
    });
  }
}
