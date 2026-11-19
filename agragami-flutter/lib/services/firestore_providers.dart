import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
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
import 'firebase_service.dart';
import 'firestore_service.dart';

/// এখন ঢুকে থাকা ব্যবহারকারীর সব সমিতির সদস্যপদ —
/// অনুমোদিত, বাকি, বাতিল — সবই আসে।
/// ব্যক্তিগত তথ্য দেখানোর আগে স্ক্রিনগুলো এখান থেকে
/// দেখে নেয় ব্যবহারকারী ওই সমিতির সদস্য কি না।
/// m25: আগে not_member_gate.dart-এ ছিল, প্রোভাইডারদের
/// সাথে এখানে আনা হয়েছে। currentUserProvider-এর বদলে
/// authStateChanges শোনা হয় — নইলে auth_service-এর সাথে
/// চক্রাকার import হয়ে যেত।
final myMembershipsProvider =
    StreamProvider.autoDispose<List<Membership>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return FirebaseService.instance.auth.authStateChanges().asyncExpand(
    (user) {
      if (user == null) return const Stream<List<Membership>>.empty();
      return service.watchMyMemberships(user.uid);
    },
  );
});

/// সদস্যপদের তালিকা থেকে অনুমোদিত সমিতিগুলোর id —
/// শুধু সেগুলোরই ব্যক্তিগত তথ্য দেখানো যাবে।
List<String> approvedBranchIds(List<Membership> memberships) {
  return memberships.where((m) => m.isApproved).map((m) => m.branchId).toList();
}

/// সমস্ত সক্রিয় সমিতির শেয়ার্ড লাইভ স্ট্রিম
final branchesStreamProvider = StreamProvider.autoDispose<List<Branch>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchBranches();
});

/// একটি সমিতির লাইভ স্ট্রিম — সমিতির বিস্তারিত স্ক্রিনের জন্য।
/// টপ-লেভেল family প্রোভাইডার, যাতে build()-এর ভেতরে নতুন
/// প্রোভাইডার বানিয়ে প্রতিবার rebuild-এ Firestore আবার না পড়ে।
final branchStreamProvider =
    StreamProvider.autoDispose.family<Branch?, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchBranch(branchId);
});

/// সমিতি অনুযায়ী সদস্যদের শেয়ার্ড লাইভ স্ট্রিম
final membersByBranchProvider =
    StreamProvider.autoDispose.family<List<Member>, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchMembers(branchId: branchId.isEmpty ? null : branchId);
});

/// সমিতি অনুযায়ী সক্রিয় সদস্যদের শেয়ার্ড লাইভ স্ট্রিম
/// (F3) — সদস্য-মুখী তালিকায় (সদস্য তালিকা, বকেয়া, ঋণ)
/// এই প্রোভাইডার ব্যবহার করা হয়, কারণ rules সদস্যদের
/// শুধু status == 'active' ডকুমেন্ট পড়তে দেয়।
final activeMembersByBranchProvider =
    StreamProvider.autoDispose.family<List<Member>, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchActiveMembers(branchId: branchId.isEmpty ? null : branchId);
});

/// একজন সদস্যের রেকর্ডের লাইভ স্ট্রিম — পাসবইয়ের জন্য।
final memberStreamProvider =
    StreamProvider.autoDispose.family<Member?, String>((ref, memberId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchMember(memberId);
});

/// একজন ব্যবহারকারীর প্রোফাইলের লাইভ স্ট্রিম (Phase 6) —
/// সদস্যের পরিচয় পাতায় তার বর্তমান রোল দেখানোর জন্য।
/// rules: users ডকুমেন্ট নিজে বা সুপার অ্যাডমিন পড়তে পারে।
final userDocProvider =
    StreamProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchUserDoc(uid);
});

/// একজন ব্যবহারকারীর সাথে যুক্ত সদস্য প্রোফাইলগুলো —
/// পাসবই, পরিচয়পত্র আর জমার স্ক্রিনের জন্য।
final membersForUserProvider =
    StreamProvider.autoDispose.family<List<Member>, String>((ref, uid) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchMembersForUser(uid);
});

/// কয়েকজন সদস্যের রেকর্ড — কমিটি স্ক্রিনে নাম-ফোন
/// দেখানোর জন্য। আর্গুমেন্ট: সদস্য id কমা দিয়ে জোড়া।
/// ফিল্টার ছাড়া পুরো members পড়া হয় না — সদস্যদের
/// জন্য নিয়মে (rules) সেটা বাধা পায়।
final membersByIdsProvider = FutureProvider.autoDispose
    .family<Map<String, Member>, String>((ref, joinedIds) {
  final service = ref.watch(firestoreServiceProvider);
  final ids = joinedIds.isEmpty ? const <String>[] : joinedIds.split(',');
  return service.fetchMembersByIds(ids);
});

/// অপেক্ষমাণ সদস্য আবেদনের শেয়ার্ড লাইভ স্ট্রিম (M4)।
/// সমিতি অনুযায়ী ফিল্টার করা যায় — branchId null মানে সব সমিতি।
/// টপ-লেভেল family প্রোভাইডার, যাতে build()-এর ভেতরে নতুন
/// প্রোভাইডার বানিয়ে প্রতিবার rebuild-এ Firestore আবার না পড়ে।
final pendingApplicationsProvider = StreamProvider.autoDispose
    .family<List<MemberApplication>, String?>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchPendingApplications(branchId: branchId);
});

/// অপেক্ষমাণ জমার শেয়ার্ড লাইভ স্ট্রিম (F5)।
/// সমিতি অনুযায়ী ফিল্টার করা যায় — branchId null মানে সব
/// সমিতি (শুধু সুপার অ্যাডমিন)। শাখা অ্যাডমিন সবসময়
/// নিজের সমিতির id পাঠায় — ফিল্টার ছাড়া পড়লে নিয়মে
/// (rules) বাধা পায়।
final pendingPaymentsProvider = StreamProvider.autoDispose
    .family<List<Payment>, String?>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchPendingPayments(branchId: branchId);
});

/// একজন সদস্যের সমস্ত জমার লাইভ স্ট্রিম — পাসবইয়ের জন্য।
final memberPaymentsProvider =
    StreamProvider.autoDispose.family<List<Payment>, String>((ref, memberId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchMemberPayments(memberId);
});

/// পেমেন্ট মেথড কনফিগের শেয়ার্ড লাইভ স্ট্রিম
final paymentMethodsProvider =
    StreamProvider.autoDispose<List<PaymentMethodConfig>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchAllPaymentMethods();
});

/// একটি সমিতির সক্রিয় পেমেন্ট মেথড — জমা আর কিস্তির জন্য।
/// খালি স্ট্রিং মানে সব সমিতি।
final activePaymentMethodsProvider = StreamProvider.autoDispose
    .family<List<PaymentMethodConfig>, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchActivePaymentMethods(
    branchId: branchId.isEmpty ? null : branchId,
  );
});

/// নোটিশ বোর্ডের শেয়ার্ড লাইভ স্ট্রিম
final noticesStreamProvider = StreamProvider.autoDispose<List<Notice>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchNotices();
});

/// সমিতি অনুযায়ী নোটিশ — নোটিশ বোর্ডের জন্য।
/// খালি স্ট্রিং মানে সব নোটিশ।
final noticesForBranchProvider =
    StreamProvider.autoDispose.family<List<Notice>, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchNotices(branchId: branchId.isEmpty ? null : branchId);
});

/// পরিচালনা কমিটির শেয়ার্ড লাইভ স্ট্রিম
final committeeStreamProvider =
    StreamProvider.autoDispose<List<CommitteeMember>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchCommittee();
});

/// সমিতি অনুযায়ী ঋণের লাইভ স্ট্রিম — ঋণের তালিকার জন্য।
/// খালি স্ট্রিং মানে সব সমিতি (অ্যাডমিন)।
final loansByBranchProvider =
    StreamProvider.autoDispose.family<List<Loan>, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchLoans(branchId: branchId.isEmpty ? null : branchId);
});

/// একটি ঋণের লাইভ স্ট্রিম — ঋণের বিস্তারিত স্ক্রিনের জন্য।
final loanStreamProvider =
    StreamProvider.autoDispose.family<Loan?, String>((ref, loanId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchLoan(loanId);
});

/// সমিতি অনুযায়ী খরচের লাইভ স্ট্রিম — খরচের তালিকার জন্য।
/// খালি স্ট্রিং মানে সব সমিতি (অ্যাডমিন)।
final expensesByBranchProvider =
    StreamProvider.autoDispose.family<List<Expense>, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.watchExpenses(branchId: branchId.isEmpty ? null : branchId);
});

/// হোমের মোট হিসাব — সমিতির তালিকা দিয়ে।
/// আর্গুমেন্ট: সমিতি id '|' দিয়ে জোড়া; খালি স্ট্রিং মানে
/// সব সমিতি (অ্যাডমিন)। সদস্যের জন্য শুধু তার অনুমোদিত
/// সমিতিগুলো পাঠাতে হয় — ফিল্টার ছাড়া পড়লে নিয়মে বাধা পায়।
final homeTotalsForBranchesProvider =
    FutureProvider.autoDispose.family<HomeTotals, String>((ref, joinedIds) {
  final service = ref.watch(firestoreServiceProvider);
  if (joinedIds.isEmpty) return service.fetchHomeTotals();
  return service.fetchHomeTotalsForBranches(joinedIds.split('|'));
});

/// হোমের "সাম্প্রতিক লেনদেন" — সাম্প্রতিক জমা আর খরচ।
/// আর্গুমেন্ট: সমিতি id '|' দিয়ে জোড়া; খালি স্ট্রিং মানে
/// সব সমিতি (অ্যাডমিন)।
final recentTransactionsProvider = FutureProvider.autoDispose
    .family<RecentTransactions, String>((ref, joinedIds) {
  final service = ref.watch(firestoreServiceProvider);
  if (joinedIds.isEmpty) return service.fetchRecentTransactions();
  return service.fetchRecentTransactions(
    branchIds: joinedIds.split('|'),
  );
});

/// সমিতি অনুযায়ী হিসাব
final homeTotalsByBranchProvider =
    FutureProvider.autoDispose.family<HomeTotals, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.fetchHomeTotals(branchId: branchId.isEmpty ? null : branchId);
});

/// এক মাসের হিসাব — রিপোর্ট স্ক্রিনের জন্য।
/// FutureBuilder-এ build()-এর ভেতরে _load() ডাকার বদলে
/// এই প্রোভাইডার ব্যবহার হয়, যাতে rebuild-এ আবার না পড়ে।
final monthReportProvider = FutureProvider.autoDispose
    .family<MonthTotals, ({int year, int month, String? branchId})>((ref, arg) {
  final service = ref.watch(firestoreServiceProvider);
  return service.loadMonthTotals(
    year: arg.year,
    month: arg.month,
    branchId: arg.branchId,
  );
});

/// সমিতির অনুমোদিত জমা — বকেয়া তালিকার জন্য।
/// খালি স্ট্রিং মানে সব সমিতি (অ্যাডমিন)।
final approvedPaymentsProvider =
    FutureProvider.autoDispose.family<List<Payment>, String>((ref, branchId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.fetchApprovedPayments(
    branchId: branchId.isEmpty ? null : branchId,
  );
});

/// লেখার পর মোট হিসাবগুলো তাজা করা (M12)।
/// হোম/সমিতির মোট, সাম্প্রতিক লেনদেন, মাসের রিপোর্ট আর
/// অনুমোদিত জমা — সবই একবারের FutureProvider; লেখার পর
/// invalidate না করলে অনুমোদন/খরচ/কিস্তির পরেও পুরোনো
/// অঙ্ক দেখাত। family-কে invalidate করলে তার সব instance
/// তাজা হয় (riverpod-এ family invalidate সব member-এ চলে)।
void invalidateTotals(WidgetRef ref) {
  ref.invalidate(homeTotalsForBranchesProvider);
  ref.invalidate(homeTotalsByBranchProvider);
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(monthReportProvider);
  ref.invalidate(approvedPaymentsProvider);
}

/// হোমের মোট হিসাব মডেল।
/// তহবিল = অনুমোদিত জমা − খরচ − বকেয়া ঋণ — রিপোর্টের
/// নিট হিসাবের সাথে মিলিয়ে, ঋণ বাদ না দিলে দুই জায়গায়
/// দুই রকম অঙ্ক দেখাত।
class HomeTotals {
  final int approvedTotal;
  final int expenseTotal;
  final int activeMembers;
  final int loansOutstanding;

  /// যে সমিতিগুলোর হিসাব আনা যায়নি (অনুমতি নেই বা নেটওয়ার্ক
  /// সমস্যা) — Phase 5 (02-M2): একটা সমিতি ব্যর্থ হলে বাকিগুলোর
  /// হিসাবও হারিয়ে যেত; এখন আংশিক হিসাব দেখানো হয় আর এই
  /// তালিকা দিয়ে UI-তে "কিছু সমিতির হিসাব দেখা যায়নি" লেখা হয়।
  final List<String> failedBranchIds;

  const HomeTotals({
    this.approvedTotal = 0,
    this.expenseTotal = 0,
    this.activeMembers = 0,
    this.loansOutstanding = 0,
    this.failedBranchIds = const [],
  });

  /// তহবিলে আছে — অনুমোদিত জমা থেকে খরচ আর বকেয়া ঋণ বাদে।
  int get fund => approvedTotal - expenseTotal - loansOutstanding;

  /// সব সমিতির হিসাব এসেছে কি না।
  bool get isComplete => failedBranchIds.isEmpty;
}

/// এক মাসের হিসাব — রিপোর্ট, PDF আর CSV একই ফাংশন থেকে নেয়।
class MonthTotals {
  final int income;
  final int expenses;
  final int loansGiven;
  final int repayments;

  const MonthTotals({
    required this.income,
    required this.expenses,
    required this.loansGiven,
    required this.repayments,
  });

  /// মাসের নিট অবস্থা — আয় − খরচ − ঋণ দেওয়া + কিস্তি ফেরত।
  int get net => income - expenses - loansGiven + repayments;
}

/// হোমের "সাম্প্রতিক লেনদেন" — সাম্প্রতিক জমা আর খরচ।
class RecentTransactions {
  final List<Payment> payments;
  final List<Expense> expenses;

  const RecentTransactions({
    required this.payments,
    required this.expenses,
  });
}
