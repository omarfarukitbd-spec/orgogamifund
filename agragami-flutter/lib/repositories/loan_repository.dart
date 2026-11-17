import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/loan.dart';
import '../services/firebase_service.dart';
import 'audit_repository.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  final auditRepo = ref.watch(auditRepositoryProvider);
  return LoanRepository(auditRepository: auditRepo);
});

/// করযে হাসানা (সুদমুক্ত ঋণ) সংক্রান্ত ডেটাবেজ কার্যক্রমের রিপোজিটরি
class LoanRepository {
  final FirebaseFirestore _db;
  final AuditRepository _audit;

  LoanRepository({
    FirebaseFirestore? db,
    AuditRepository? auditRepository,
  })  : _db = db ?? FirebaseService.instance.db,
        _audit = auditRepository ?? AuditRepository(db: db);

  /// সমস্ত ঋণের লাইভ স্ট্রিম
  Stream<List<Loan>> watchLoans({String? branchId}) {
    var query = _db
        .collection(Collections.loans)
        .orderBy('dateIssued', descending: true);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => Loan.fromMap(d.id, d.data())).toList(),
        );
  }

  /// একক ঋণের বিস্তারিত পর্যবেক্ষণ
  Stream<Loan?> watchLoan(String loanId) {
    if (loanId.isEmpty) return Stream.value(null);
    return _db.collection(Collections.loans).doc(loanId).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Loan.fromMap(doc.id, doc.data()!)
              : null,
        );
  }

  /// নির্দিষ্ট সদস্যের সমস্ত ঋণ পর্যবেক্ষণ
  Stream<List<Loan>> watchMemberLoans(String memberId) {
    if (memberId.isEmpty) return const Stream.empty();
    return _db
        .collection(Collections.loans)
        .where('memberId', isEqualTo: memberId)
        .orderBy('dateIssued', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Loan.fromMap(d.id, d.data())).toList(),
        );
  }

  /// নতুন করযে হাসানা ঋণ প্রদান করা
  Future<String> issueLoan(Loan loan) async {
    final doc = _db.collection(Collections.loans).doc();
    await doc.set(loan.toMap());
    return doc.id;
  }

  /// ঋণের কিস্তি পরিশোধ সংরক্ষণ করা (ট্রানজ্যাকশন ব্যবহার করে)
  Future<void> recordRepayment(
    String loanId,
    LoanRepayment repayment, {
    String recordedBy = '',
  }) async {
    final ref = _db.collection(Collections.loans).doc(loanId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return;
      final loan = Loan.fromMap(snap.id, snap.data()!);
      final updated = [...loan.repayments, repayment];
      final repaid = updated.fold(0, (total, r) => total + r.amount);
      tx.update(ref, {
        'repayments': updated.map((r) => r.toMap()).toList(),
        'status': repaid >= loan.amount
            ? LoanStatus.repaid.name
            : LoanStatus.active.name,
      });
    });
    await _audit.logAudit(
      action: 'loan_repayment_recorded',
      by: recordedBy,
      detail:
          'ঋণের কিস্তি ${repayment.amount} টাকা (${repayment.methodLabel}) জমা নেওয়া হয়েছে',
    );
  }

  /// ঋণের তালিকা একবারে ফেচ করা (রিপোর্টের জন্য)
  Future<List<Loan>> fetchLoans({String? branchId}) async {
    var query = _db
        .collection(Collections.loans)
        .orderBy('dateIssued', descending: true);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Loan.fromMap(d.id, d.data())).toList();
  }
}
