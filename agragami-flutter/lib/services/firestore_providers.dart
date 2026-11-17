import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branch.dart';
import '../models/committee_member.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../models/member_application.dart';
import '../models/notice.dart';
import '../models/payment.dart';
import '../models/payment_method.dart';
import 'firestore_service.dart';

/// সমস্ত সক্রিয় সমিতির শেয়ার্ড লাইভ স্ট্রিম
final branchesStreamProvider = StreamProvider<List<Branch>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchBranches();
});

/// সমস্ত সদস্যের শেয়ার্ড লাইভ স্ট্রিম
final membersStreamProvider = StreamProvider<List<Member>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchMembers();
});

/// সমিতি অনুযায়ী সদস্যদের শেয়ার্ড লাইভ স্ট্রিম
final membersByBranchProvider =
    StreamProvider.family<List<Member>, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchMembers(branchId: branchId.isEmpty ? null : branchId);
});

/// অপেক্ষমাণ সদস্য আবেদনের শেয়ার্ড লাইভ স্ট্রিম
final pendingApplicationsProvider =
    StreamProvider<List<MemberApplication>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchPendingApplications();
});

/// অপেক্ষমাণ জমার শেয়ার্ড লাইভ স্ট্রিম
final pendingPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchPendingPayments();
});

/// পেমেন্ট মেথড কনফিগের শেয়ার্ড লাইভ স্ট্রিম
final paymentMethodsProvider =
    StreamProvider<List<PaymentMethodConfig>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchAllPaymentMethods();
});

/// নোটিশ বোর্ডের শেয়ার্ড লাইভ স্ট্রিম
final noticesStreamProvider = StreamProvider<List<Notice>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchNotices();
});

/// পরিচালনা কমিটির শেয়ার্ড লাইভ স্ট্রিম
final committeeStreamProvider =
    StreamProvider<List<CommitteeMember>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchCommittee();
});

/// করযে হাসানা (ঋণ) তালিকার শেয়ার্ড লাইভ স্ট্রিম
final loansStreamProvider = StreamProvider<List<Loan>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchLoans();
});

/// খরচ রেজিস্টারের শেয়ার্ড লাইভ স্ট্রিম
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchExpenses();
});

/// হোম পেইজের সামগ্রিক হিসাব
final homeTotalsFutureProvider =
    FutureProvider.autoDispose<HomeTotals>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.fetchHomeTotals();
});

/// সমিতি অনুযায়ী হিসাব
final homeTotalsByBranchProvider =
    FutureProvider.autoDispose.family<HomeTotals, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.fetchHomeTotals(branchId: branchId.isEmpty ? null : branchId);
});

/// হোমের মোট হিসাব মডেল
class HomeTotals {
  final int? approvedTotal;
  final int? expenseTotal;
  final int? activeMembers;

  const HomeTotals({this.approvedTotal, this.expenseTotal, this.activeMembers});
}
