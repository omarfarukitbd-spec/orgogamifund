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
    required int monthlyDepositAmount,
    int admissionFee = 0,
    int monthlyDueDay = 10,
    int lateFineAmount = 0,
    int minOptionalDeposit = 0,
    bool optionalDepositEnabled = false,
    BankDetails? bankDetails,
    List<String> termsAndConditions = const [],
    required String by,
  }) =>
      branch.createBranch(
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
        by: by,
      );
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
  }) =>
      branch.updateBranch(
        branchId: branchId,
        name: name,
        description: description,
        purpose: purpose,
        monthlyDepositAmount: monthlyDepositAmount,
        admissionFee: admissionFee,
        monthlyDueDay: monthlyDueDay,
        lateFineAmount: lateFineAmount,
        minOptionalDeposit: minOptionalDeposit,
        optionalDepositEnabled: optionalDepositEnabled,
        treasurerUserId: treasurerUserId,
        bankDetails: bankDetails,
        termsAndConditions: termsAndConditions,
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
  Future<Map<String, Member>> fetchMembersByIds(List<String> ids) =>
      member.fetchMembersByIds(ids);
  Future<void> updateMember({
    required String memberId,
    required Map<String, dynamic> data,
    Uint8List? photoBytes,
    String by = '',
  }) =>
      member.updateMember(
        memberId: memberId,
        data: data,
        photoBytes: photoBytes,
        by: by,
      );
  Future<void> updateProfileName({
    required String uid,
    required String name,
  }) =>
      member.updateProfileName(uid: uid, name: name);

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
  Future<void> updatePayment(Payment p, {required String by}) =>
      payment.updatePayment(p, by: by);
  Future<void> deletePayment(String paymentId, {required String by}) =>
      payment.deletePayment(paymentId, by: by);
  Future<bool> hasPaymentForMonth({
    required String memberId,
    required int forYear,
    required int forMonth,
  }) =>
      payment.hasPaymentForMonth(
        memberId: memberId,
        forYear: forYear,
        forMonth: forMonth,
      );
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
  Future<void> deletePaymentMethod(
    String methodId, {
    required String by,
    required String methodName,
  }) =>
      payment.deletePaymentMethod(methodId, by: by, methodName: methodName);
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
  Future<List<Payment>> fetchRecentApprovedPayments({
    String? branchId,
    int limit = 2,
  }) =>
      payment.fetchRecentApprovedPayments(branchId: branchId, limit: limit);
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
  Future<void> updateExpense({
    required Expense expense,
    Uint8List? receiptBytes,
    String by = '',
  }) =>
      this.expense.updateExpense(
            expense: expense,
            receiptBytes: receiptBytes,
            by: by,
          );
  Future<void> deleteExpense(String expenseId, {required String by}) =>
      expense.deleteExpense(expenseId, by: by);
  Future<List<Expense>> fetchExpensesForMonth({
    required int year,
    required int month,
    String? branchId,
  }) =>
      expense.fetchExpensesForMonth(year: year, month: month, branchId: branchId);
  Future<List<Expense>> fetchRecentExpenses({
    String? branchId,
    int limit = 2,
  }) =>
      expense.fetchRecentExpenses(branchId: branchId, limit: limit);

  // ঋণ মেথড
  Stream<List<Loan>> watchLoans({String? branchId}) =>
      loan.watchLoans(branchId: branchId);
  Stream<Loan?> watchLoan(String loanId) => loan.watchLoan(loanId);
  Stream<List<Loan>> watchMemberLoans(String memberId) =>
      loan.watchMemberLoans(memberId);
  Future<String> issueLoan(Loan l) => loan.issueLoan(l);
  Future<void> updateLoan(Loan l, {required String by}) =>
      loan.updateLoan(l, by: by);
  Future<void> deleteLoan(String loanId, {required String by}) =>
      loan.deleteLoan(loanId, by: by);
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
  Future<String> addCommitteeMember(
    CommitteeMember member, {
    required String by,
  }) =>
      governance.addCommitteeMember(member, by: by);
  Future<void> updateCommitteeMember(
    CommitteeMember member, {
    required String by,
  }) =>
      governance.updateCommitteeMember(member, by: by);
  Future<void> removeCommitteeMember(
    String committeeMemberId, {
    required String by,
    String designation = '',
  }) =>
      governance.removeCommitteeMember(
        committeeMemberId,
        by: by,
        designation: designation,
      );

  // সামগ্রিক হিসাব মেথড
  /// হোমের মোট হিসাব — অনুমোদিত জমা, মোট খরচ, সক্রিয়
  /// সদস্য আর বকেয়া ঋণ। ভুল হলে ব্যতিক্রম ছোড়া হয় —
  /// আগের মতো নিঃশব্দে শূন্য হিসাব ফেরত দেওয়া হয় না,
  /// যাতে UI "তথ্য আনা যায়নি" দেখাতে পারে।
  Future<HomeTotals> fetchHomeTotals({String? branchId}) async {
    Query<Map<String, dynamic>> paymentsQuery =
        _db.collection(Collections.payments);
    Query<Map<String, dynamic>> expensesQuery =
        _db.collection(Collections.expenses);
    Query<Map<String, dynamic>> membersQuery =
        _db.collection(Collections.members);
    Query<Map<String, dynamic>> loansQuery =
        _db.collection(Collections.loans);
    if (branchId != null) {
      paymentsQuery = paymentsQuery.where('branchId', isEqualTo: branchId);
      expensesQuery = expensesQuery.where('branchId', isEqualTo: branchId);
      membersQuery = membersQuery.where('branchId', isEqualTo: branchId);
      loansQuery = loansQuery.where('branchId', isEqualTo: branchId);
    }
    final r = await Future.wait([
      paymentsQuery.get(),
      expensesQuery.get(),
      membersQuery.get(),
      loansQuery.get(),
    ]);
    final approvedTotal = r[0].docs.fold<int>(0, (total, d) {
      // পুরোনো ডকুমেন্টে শুধু approvalStatus থাকতে পারে।
      final data = d.data();
      final s = ((data['status'] ?? data['approvalStatus']) as String?)
          ?.toLowerCase();
      return s == 'approved'
          ? total + ((data['amount'] as num?)?.toInt() ?? 0)
          : total;
    });
    final expenseTotal = r[1].docs.fold<int>(
      0,
      (total, d) => total + ((d.data()['amount'] as num?)?.toInt() ?? 0),
    );
    final activeCount = r[2].docs.where((d) {
      final s = (d.data()['status'] as String?)?.toLowerCase();
      return s == null || (s != 'left' && s != 'inactive');
    }).length;
    final loansOutstanding = r[3].docs.fold<int>(0, (total, d) {
      final outstanding = Loan.fromMap(d.id, d.data()).outstanding;
      return total + (outstanding > 0 ? outstanding : 0);
    });
    return HomeTotals(
      approvedTotal: approvedTotal,
      expenseTotal: expenseTotal,
      activeMembers: activeCount,
      loansOutstanding: loansOutstanding,
    );
  }

  /// কয়েকটি সমিতির হিসাব একসাথে — সদস্যের হোমের জন্য।
  /// ফিল্টার ছাড়া পড়লে নিয়মে (rules) বাধা পায়, তাই
  /// প্রতিটি অনুমোদিত সমিতি আলাদা করে পড়ে যোগ করা হয়।
  Future<HomeTotals> fetchHomeTotalsForBranches(
    List<String> branchIds,
  ) async {
    var approved = 0;
    var expenses = 0;
    var members = 0;
    var loans = 0;
    for (final id in branchIds) {
      final t = await fetchHomeTotals(branchId: id);
      approved += t.approvedTotal;
      expenses += t.expenseTotal;
      members += t.activeMembers;
      loans += t.loansOutstanding;
    }
    return HomeTotals(
      approvedTotal: approved,
      expenseTotal: expenses,
      activeMembers: members,
      loansOutstanding: loans,
    );
  }

  /// হোমের "সাম্প্রতিক লেনদেন" — সাম্প্রতিক জমা আর খরচ।
  /// branchIds null মানে সব সমিতি (অ্যাডমিন); সদস্যের জন্য
  /// শুধু তার অনুমোদিত সমিতিগুলো — ফিল্টার ছাড়া পড়লে
  /// নিয়মে (rules) বাধা পায়।
  Future<RecentTransactions> fetchRecentTransactions({
    List<String>? branchIds,
    int limit = 2,
  }) async {
    final payments = <Payment>[];
    final expenses = <Expense>[];
    final ids = branchIds ?? <String?>[null];
    for (final id in ids) {
      payments.addAll(
        await payment.fetchRecentApprovedPayments(
          branchId: id,
          limit: limit,
        ),
      );
      expenses.addAll(
        await expense.fetchRecentExpenses(branchId: id, limit: limit),
      );
    }
    payments.sort((a, b) => b.date.compareTo(a.date));
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return RecentTransactions(
      payments: payments.take(limit).toList(),
      expenses: expenses.take(limit).toList(),
    );
  }

  /// এক মাসের হিসাব — রিপোর্ট স্ক্রিন, PDF আর CSV একই
  /// ফাংশন থেকে নেয়, যাতে তিন জায়গায় তিন রকম হিসাব না হয়।
  /// আয় = ওই মাসের অনুমোদিত জমা (forMonth/forYear দিয়ে),
  /// খরচ = ওই মাসের খরচ, ঋণ = ওই মাসে দেওয়া ঋণ,
  /// কিস্তি = ওই মাসে ফেরত আসা কিস্তি।
  Future<MonthTotals> loadMonthTotals({
    required int year,
    required int month,
    String? branchId,
  }) async {
    final paymentsFuture = payment.fetchPaymentsForMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    final expensesFuture = expense.fetchExpensesForMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    final loansFuture = loan.fetchLoans(branchId: branchId);
    final payments = await paymentsFuture;
    final expenses = await expensesFuture;
    final loans = await loansFuture;
    final income = payments
        .where((p) => p.status == PaymentStatus.approved)
        .fold(0, (total, p) => total + p.amount);
    final expenseTotal = expenses.fold(0, (total, e) => total + e.amount);
    final loansGiven = loans
        .where((l) => l.dateIssued.year == year && l.dateIssued.month == month)
        .fold(0, (total, l) => total + l.amount);
    final repayments = loans.fold(0, (total, l) {
      return total +
          l.repayments
              .where((r) => r.date.year == year && r.date.month == month)
              .fold(0, (s, r) => s + r.amount);
    });
    return MonthTotals(
      income: income,
      expenses: expenseTotal,
      loansGiven: loansGiven,
      repayments: repayments,
    );
  }
}
