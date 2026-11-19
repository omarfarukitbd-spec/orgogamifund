import 'package:flutter/material.dart';
import '../../models/loan.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../passbook_screen.dart';

/// ঋণের কিস্তির খাতা
class LoanRepaymentsLedger extends StatelessWidget {
  final List<LoanRepayment> repayments;

  const LoanRepaymentsLedger({super.key, required this.repayments});

  @override
  Widget build(BuildContext context) {
    if (repayments.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'এখনো কোনো কিস্তি জমা হয়নি',
        message: 'কিস্তি জমা নিলে এখানে দেখা যাবে।',
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < repayments.length; i++) ...[
            LedgerRowItem(
              icon: Icons.payments_outlined,
              // F22: কিস্তির নম্বর সময়ের ক্রমে — recordRepayment
              // শেষে যোগ করে, তাই repayments[0]-ই প্রথম কিস্তি।
              // আগের `length - i` উল্টো নম্বর দিত।
              title:
                  'কিস্তি ${i + 1} — পরিশোধ (${repayments[i].methodLabel})',
              subtitle:
                  '${repayments[i].date.day}/${repayments[i].date.month}/${repayments[i].date.year}${repayments[i].trxId != null ? " • TrxID: ${repayments[i].trxId}" : ""}',
              amount: formatTaka(repayments[i].amount),
              isIncome: true,
              showDivider: i < repayments.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}
