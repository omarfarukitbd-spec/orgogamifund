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

  /// সমস্ত ঋণের লাইভ স্ট্রিম (সর্বোচ্চ ২০০টি — সংখ্যা
  /// বাড়লে পেজিনেশন লাগবে)।
  Stream<List<Loan>> watchLoans({String? branchId}) {
    var query = _db
        .collection(Collections.loans)
        .orderBy('dateIssued', descending: true)
        .limit(200);
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
      // M7: ঋণ না থাকলে নিঃশব্দে সফল নয় — ভুল ছোড়া হয়,
      // যাতে UI "জমা নেওয়া হয়েছে" মিথ্যা না বলে।
      if (!snap.exists || snap.data() == null) {
        throw StateError('loan-not-found');
      }
      final loan = Loan.fromMap(snap.id, snap.data()!);
      final updated = [...loan.repayments, repayment];
      final repaid = updated.fold(0, (total, r) => total + r.amount);
      // m6: বেশি জমার সীমা ট্রানজ্যাকশনের ভেতরে — একই
      // সময়ে দুই কিস্তি এলে বাসি তথ্যে সীমা পেরিয়ে যেত।
      if (repaid > loan.amount) throw StateError('overpayment');
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

  /// ঋণ বদলানো (M9) — টাকা, কারণ, তারিখ, কিস্তির পরিকল্পনা।
  /// টাকা ফেরত দেওয়া অঙ্কের নিচে নামানো যায় না।
  Future<void> updateLoan(
    Loan loan, {
    required String by,
  }) async {
    if (loan.id.isEmpty) return;
    if (loan.amount < loan.repaidTotal) {
      throw StateError('amount-below-repaid');
    }
    await _db.collection(Collections.loans).doc(loan.id).update({
      'amount': loan.amount,
      'reason': loan.reason,
      'dateIssued': Timestamp.fromDate(loan.dateIssued),
      'monthlyInstallment': loan.monthlyInstallment,
      'installmentMonths': loan.installmentMonths,
      'status': loan.repaidTotal >= loan.amount
          ? LoanStatus.repaid.name
          : LoanStatus.active.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _audit.logAudit(
      action: 'loan_updated',
      by: by,
      detail: 'ঋণ বদলানো হয়েছে: ${loan.amount} টাকা (${loan.id})',
    );
  }

  /// ঋণ মুছা (M9) — শুধু কিস্তি জমা হয়নি এমন ঋণ।
  /// কিস্তি থাকলে মুছলে কিস্তির হিসাব হারিয়ে যেত।
  /// শুধু সুপার অ্যাডমিন মুছতে পারে (rules)।
  Future<void> deleteLoan(
    String loanId, {
    required String by,
  }) async {
    if (loanId.isEmpty) return;
    final snap = await _db.collection(Collections.loans).doc(loanId).get();
    if (snap.exists && snap.data() != null) {
      final loan = Loan.fromMap(snap.id, snap.data()!);
      if (loan.repayments.isNotEmpty) {
        throw StateError('loan-has-repayments');
      }
    }
    await _db.collection(Collections.loans).doc(loanId).delete();
    await _audit.logAudit(
      action: 'loan_deleted',
      by: by,
      detail: 'ঋণ মুছা হয়েছে ($loanId)',
    );
  }

  /// ঋণের তালিকা একবারে ফেচ করা (রিপোর্টের জন্য)
  Future<List<Loan>> fetchLoans({String? branchId}) async {
    var query = _db
        .collection(Collections.loans)
        .orderBy('dateIssued', descending: true)
        .limit(200);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Loan.fromMap(d.id, d.data())).toList();
  }
}
