import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branch.dart';
import '../models/committee_member.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../models/member_application.dart';
import '../models/membership.dart';
import '../models/notice.dart';
import '../models/payment.dart';
import '../models/payment_method.dart';
import '../repositories/audit_repository.dart';
import '../repositories/branch_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/governance_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/member_repository.dart';
import '../repositories/payment_repository.dart';
import 'firebase_service.dart';
import 'firestore_providers.dart';

export 'firestore_providers.dart';

/// FirestoreService ফেসাড প্রোভাইডার
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(
    auditRepo: ref.watch(auditRepositoryProvider),
    branchRepo: ref.watch(branchRepositoryProvider),
    memberRepo: ref.watch(memberRepositoryProvider),
    paymentRepo: ref.watch(paymentRepositoryProvider),
    expenseRepo: ref.watch(expenseRepositoryProvider),
    loanRepo: ref.watch(loanRepositoryProvider),
    governanceRepo: ref.watch(governanceRepositoryProvider),
  );
});

/// ডোমেন রিপোজিটরিগুলোর সমন্বয়ে গঠিত একক ফেসাড সার্ভিস
class FirestoreService {
  final FirebaseFirestore _db;
  final AuditRepository audit;
  final BranchRepository branch;
  final MemberRepository member;
  final PaymentRepository payment;
  final ExpenseRepository expense;
  final LoanRepository loan;
  final GovernanceRepository governance;

  FirestoreService({
    FirebaseFirestore? db,
    AuditRepository? auditRepo,
    BranchRepository? branchRepo,
    MemberRepository? memberRepo,
    PaymentRepository? paymentRepo,
    ExpenseRepository? expenseRepo,
    LoanRepository? loanRepo,
    GovernanceRepository? governanceRepo,
  })  : _db = db ?? FirebaseService.instance.db,
        audit = auditRepo ?? AuditRepository(db: db),
        branch = branchRepo ?? BranchRepository(db: db),
        member = memberRepo ?? MemberRepository(db: db),
        payment = paymentRepo ?? PaymentRepository(db: db),
        expense = expenseRepo ?? ExpenseRepository(db: db),
        loan = loanRepo ?? LoanRepository(db: db),
        governance = governanceRepo ?? GovernanceRepository(db: db);

  // ইউজার ও অ্যাডমিন মেথড
  Future<void> createUserDoc({required String uid, required String email}) =>
      member.createUserDoc(uid: uid, email: email);
  Future<bool?> hasAnyUser() => member.hasAnyUser();
  Future<void> createFirstAdminDoc({
    required String uid,
    required String name,
    required String email,
  }) =>
      member.createFirstAdminDoc(uid: uid, name: name, email: email);

  // সমিতি মেথড
  Stream<List<Branch>> watchBranches() => branch.watchBranches();
  Stream<Branch?> watchBranch(String branchId) => branch.watchBranch(branchId);
  Future<void> createBranch({
    required String name,
    required String description,
    required SamitiPurpose purpose,
    required int monthlyDonation,
    required String by,
  }) =>
      branch.createBranch(
        name: name,
        description: description,
        purpose: purpose,
        monthlyDonation: monthlyDonation,
        by: by,
      );
  Future<void> updateBranch({
    required String branchId,
    required String name,
    required String description,
    required SamitiPurpose purpose,
    required int monthlyDonation,
    required String by,
  }) =>
      branch.updateBranch(
        branchId: branchId,
        name: name,
        description: description,
        purpose: purpose,
        monthlyDonation: monthlyDonation,
        by: by,
      );
  Future<void> recountMemberCount(String branchId) =>
      branch.recountMemberCount(branchId);

  // সদস্যপদ ও সদস্য মেথড
  Stream<List<Membership>> watchMyMemberships(String userId) =>
      member.watchMyMemberships(userId);
  Stream<Membership?> watchMembership(String userId, String branchId) =>
      member.watchMembership(userId, branchId);
  Future<Membership?> getMembership(String userId, String branchId) =>
      member.getMembership(userId, branchId);
  Future<bool> isMemberOf(String userId, String branchId) =>
      member.isMemberOf(userId, branchId);
  Future<List<String>> myApprovedBranchIds(String userId) =>
      member.myApprovedBranchIds(userId);
  Stream<List<Member>> watchMembersForUser(String userId) =>
      member.watchMembersForUser(userId);
  Stream<List<Member>> watchMembers({String? branchId}) =>
      member.watchMembers(branchId: branchId);
  Stream<Member?> watchMember(String memberId) => member.watchMember(memberId);

  // জমা ও পেমেন্ট মেথড
  Stream<List<Payment>> watchPendingPayments({String? branchId}) =>
      payment.watchPendingPayments(branchId: branchId);
  Stream<List<Payment>> watchMemberPayments(String memberId) =>
      payment.watchMemberPayments(memberId);
  Future<String> submitPayment(Payment p) => payment.submitPayment(p);
  Future<void> approvePayment(Payment p, {required String reviewedBy}) =>
      payment.approvePayment(p, reviewedBy: reviewedBy);
  Future<void> rejectPayment(
    String paymentId, {
    required String reason,
    required String reviewedBy,
  }) =>
      payment.rejectPayment(paymentId, reason: reason, reviewedBy: reviewedBy);
  Stream<List<PaymentMethodConfig>> watchActivePaymentMethods({
    String? branchId,
  }) =>
      payment.watchActivePaymentMethods(branchId: branchId);
  Stream<List<PaymentMethodConfig>> watchAllPaymentMethods() =>
      payment.watchAllPaymentMethods();
  Future<String> addPaymentMethod(
    PaymentMethodConfig method, {
    required String createdBy,
  }) =>
      payment.addPaymentMethod(method, createdBy: createdBy);
  Future<void> updatePaymentMethod(
    PaymentMethodConfig method, {
    required String updatedBy,
  }) =>
      payment.updatePaymentMethod(method, updatedBy: updatedBy);
  Future<void> setPaymentMethodActive(
    String methodId, {
    required bool active,
    required String by,
    required String methodName,
  }) =>
      payment.setPaymentMethodActive(
        methodId,
        active: active,
        by: by,
        methodName: methodName,
      );
  Future<bool> trxIdAlreadyUsed({
    required String paymentMethodId,
    required String trxId,
    required String branchId,
  }) =>
      payment.trxIdAlreadyUsed(
        paymentMethodId: paymentMethodId,
        trxId: trxId,
        branchId: branchId,
      );
  Future<List<Payment>> fetchApprovedPayments({String? branchId}) =>
      payment.fetchApprovedPayments(branchId: branchId);
  Future<List<Payment>> fetchPaymentsForMonth({
    required int year,
    required int month,
    String? branchId,
  }) =>
      payment.fetchPaymentsForMonth(year: year, month: month, branchId: branchId);

  // ব্যয় মেথড
  Stream<List<Expense>> watchExpenses({String? branchId}) =>
      expense.watchExpenses(branchId: branchId);
  Future<String> submitExpense({
    required Expense expense,
    Uint8List? receiptBytes,
  }) =>
      this.expense.submitExpense(expense: expense, receiptBytes: receiptBytes);
  Future<List<Expense>> fetchExpensesForMonth({
    required int year,
    required int month,
    String? branchId,
  }) =>
      expense.fetchExpensesForMonth(year: year, month: month, branchId: branchId);

  // ঋণ মেথড
  Stream<List<Loan>> watchLoans({String? branchId}) =>
      loan.watchLoans(branchId: branchId);
  Stream<Loan?> watchLoan(String loanId) => loan.watchLoan(loanId);
  Stream<List<Loan>> watchMemberLoans(String memberId) =>
      loan.watchMemberLoans(memberId);
  Future<String> issueLoan(Loan l) => loan.issueLoan(l);
  Future<void> recordRepayment(
    String loanId,
    LoanRepayment repayment, {
    String recordedBy = '',
  }) =>
      loan.recordRepayment(loanId, repayment, recordedBy: recordedBy);
  Future<List<Loan>> fetchLoans({String? branchId}) =>
      loan.fetchLoans(branchId: branchId);

  // নোটিশ, কমিটি ও আবেদন মেথড
  Stream<List<MemberApplication>> watchPendingApplications({String? branchId}) =>
      governance.watchPendingApplications(branchId: branchId);
  Future<String> submitMemberApplication({
    required MemberApplication application,
    Uint8List? photoBytes,
    Uint8List? nidFrontBytes,
    Uint8List? nidBackBytes,
  }) =>
      governance.submitMemberApplication(
        application: application,
        photoBytes: photoBytes,
        nidFrontBytes: nidFrontBytes,
        nidBackBytes: nidBackBytes,
      );
  Future<void> approveApplication(
    MemberApplication application, {
    required String reviewedBy,
  }) =>
      governance.approveApplication(application, reviewedBy: reviewedBy);
  Future<void> rejectApplication(
    String applicationId, {
    required String reason,
    required String reviewedBy,
  }) =>
      governance.rejectApplication(applicationId, reason: reason, reviewedBy: reviewedBy);
  Stream<List<Notice>> watchNotices({String? branchId}) =>
      governance.watchNotices(branchId: branchId);
  Future<String> submitNotice({
    required Notice notice,
    Uint8List? attachmentBytes,
  }) =>
      governance.submitNotice(notice: notice, attachmentBytes: attachmentBytes);
  Stream<List<CommitteeMember>> watchCommittee({String? branchId}) =>
      governance.watchCommittee(branchId: branchId);

  // সামগ্রিক হিসাব মেথড
  Future<HomeTotals> fetchHomeTotals({String? branchId}) async {
    try {
      var pQ = _db.collection(Collections.payments).where('branchId', isEqualTo: branchId);
      var eQ = _db.collection(Collections.expenses).where('branchId', isEqualTo: branchId);
      var mQ = _db.collection(Collections.members).where('branchId', isEqualTo: branchId);
      final r = await Future.wait([
        (branchId != null ? pQ : _db.collection(Collections.payments)).get(),
        (branchId != null ? eQ : _db.collection(Collections.expenses)).get(),
        (branchId != null ? mQ : _db.collection(Collections.members)).get(),
      ]);
      final approvedTotal = r[0].docs.fold<int>(0, (sum, d) {
        final s = (d.data()['status'] as String?)?.toLowerCase();
        return s == 'approved' ? sum + ((d.data()['amount'] as num?)?.toInt() ?? 0) : sum;
      });
      final expenseTotal = r[1].docs.fold<int>(
        0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toInt() ?? 0),
      );
      final activeCount = r[2].docs.where((d) {
        final s = (d.data()['status'] as String?)?.toLowerCase();
        return s == null || (s != 'left' && s != 'inactive');
      }).length;
      return HomeTotals(
        approvedTotal: approvedTotal,
        expenseTotal: expenseTotal,
        activeMembers: activeCount,
      );
    } catch (_) {
      return const HomeTotals();
    }
  }
}
