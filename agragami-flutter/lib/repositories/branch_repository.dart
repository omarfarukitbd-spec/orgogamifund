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

  /// সমস্ত সমিতির লাইভ স্ট্রিম
  Stream<List<Branch>> watchBranches() {
    return _db.collection(Collections.branches).snapshots().map(
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

  /// নতুন সমিতি তৈরি করা
  Future<String> createBranch({
    required String name,
    required String description,
    required SamitiPurpose purpose,
    required int monthlyDonation,
    required String by,
  }) async {
    final branch = Branch(
      id: '',
      name: name,
      description: description,
      purpose: purpose,
      monthlyDonation: monthlyDonation,
      startDate: DateTime.now(),
    );
    final data = branch.toMap()
      ..['createdAt'] = DateTime.now().toIso8601String();
    final ref = await _db.collection(Collections.branches).add(data);
    await _audit.logAudit(
      action: 'create_branch',
      by: by,
      detail: 'সমিতি: $name (${ref.id})',
    );
    return ref.id;
  }

  /// সমিতির তথ্য আপডেট বা সম্পাদন করা
  Future<void> updateBranch({
    required String branchId,
    required String name,
    required String description,
    required SamitiPurpose purpose,
    required int monthlyDonation,
    required String by,
  }) async {
    if (branchId.isEmpty) return;
    await _db.collection(Collections.branches).doc(branchId).update({
      'name': name,
      'description': description,
      'purpose': purpose.name,
      'monthlyDonation': monthlyDonation,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
