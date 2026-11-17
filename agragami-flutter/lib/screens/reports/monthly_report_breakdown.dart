import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../passbook_screen.dart';

/// মাসিক রিপোর্ট ব্রেকডাউন — আয়, ব্যয়, ঋণ ও নিট অবস্থা
class MonthlyReportBreakdown extends StatelessWidget {
  final FirestoreService store;
  final String? branchId;
  final String branchName;
  final int month;
  final int year;
  final bool busy;
  final Future<void> Function() onPdf;

  const MonthlyReportBreakdown({
    super.key,
    required this.store,
    required this.branchId,
    required this.branchName,
    required this.month,
    required this.year,
    required this.busy,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SkeletonCardList();
        }
        if (snap.hasError || !snap.hasData) {
          return const EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'হিসাব আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
          );
        }
        final data = snap.data!;
        final income = data['income']!;
        final expenses = data['expenses']!;
        final loansGiven = data['loansGiven']!;
        final repayments = data['repayments']!;
        final net = income - expenses - loansGiven + repayments;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.arrow_downward_outlined,
                    label: 'জমা (আয়)',
                    value: formatTaka(income),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.arrow_upward_outlined,
                    label: 'মোট খরচ',
                    value: formatTaka(expenses),
                    isGold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.handshake_outlined,
                    label: 'ঋণ দেওয়া হয়েছে',
                    value: formatTaka(loansGiven),
                    isGold: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.replay_outlined,
                    label: 'কিস্তি ফেরত এসেছে',
                    value: formatTaka(repayments),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'মাসের নিট অবস্থা — $branchName',
              value: formatTaka(net),
              note: 'আয় − খরচ − ঋণ দেওয়া + কিস্তি ফেরত',
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: busy ? 'আসছে…' : 'PDF হিসেবে ডাউনলোড করুন',
              onPressed: busy ? null : onPdf,
              icon: Icons.picture_as_pdf_outlined,
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _load() async {
    final payments = await store.fetchPaymentsForMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    final expenses = await store.fetchExpensesForMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    final loans = await store.fetchLoans(branchId: branchId);
    final income = payments
        .where((p) => p.status == PaymentStatus.approved)
        .fold(0, (sum, p) => sum + p.amount);
    final expenseTotal = expenses.fold(0, (sum, e) => sum + e.amount);
    final loansGiven = loans
        .where((l) => l.dateIssued.year == year && l.dateIssued.month == month)
        .fold(0, (sum, l) => sum + l.amount);
    final repayments = loans.fold(0, (sum, l) {
      return sum +
          l.repayments
              .where((r) => r.date.year == year && r.date.month == month)
              .fold(0, (s, r) => s + r.amount);
    });
    return {
      'income': income,
      'expenses': expenseTotal,
      'loansGiven': loansGiven,
      'repayments': repayments,
    };
  }
}
