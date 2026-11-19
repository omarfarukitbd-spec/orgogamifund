import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../passbook_screen.dart';

/// মাসিক রিপোর্ট ব্রেকডাউন — আয়, ব্যয়, ঋণ ও নিট অবস্থা
class MonthlyReportBreakdown extends ConsumerWidget {
  final String? branchId;
  final String branchName;
  final int month;
  final int year;
  final bool busy;
  final Future<void> Function() onPdf;
  final Future<void> Function()? onCsv;

  const MonthlyReportBreakdown({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.month,
    required this.year,
    required this.busy,
    required this.onPdf,
    this.onCsv,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // মাসের হিসাব টপ-লেভেল প্রোভাইডার থেকে আসে — আগে
    // FutureBuilder-এ build()-এর ভেতরে _load() ডাকা হতো,
    // প্রতিটি rebuild-এ ৩টা কোয়েরি আবার চলত।
    final totalsAsync = ref.watch(
      monthReportProvider((year: year, month: month, branchId: branchId)),
    );
    return totalsAsync.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'হিসাব আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
        actionLabel: 'আবার চেষ্টা করুন',
        onAction: () => ref.invalidate(
          monthReportProvider(
            (year: year, month: month, branchId: branchId),
          ),
        ),
      ),
      data: (totals) {
        final income = totals.income;
        final expenses = totals.expenses;
        final loansGiven = totals.loansGiven;
        final repayments = totals.repayments;
        final net = totals.net;

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
            if (onCsv != null) ...[
              const SizedBox(height: 10),
              SecondaryButton(
                label: busy ? 'আসছে…' : 'CSV / Excel বিবরণী এক্সপোর্ট',
                onPressed: busy ? null : onCsv,
                icon: Icons.table_chart_outlined,
              ),
            ],
          ],
        );
      },
    );
  }
}
