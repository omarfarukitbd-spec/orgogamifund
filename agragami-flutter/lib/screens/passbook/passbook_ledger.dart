import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../passbook_screen.dart';

/// লেনদেনের খাতা — ফিল্টার এবং লেজার রো
class PassbookLedger extends StatefulWidget {
  final List<Payment> payments;

  const PassbookLedger({super.key, required this.payments});

  @override
  State<PassbookLedger> createState() => _PassbookLedgerState();
}

class _PassbookLedgerState extends State<PassbookLedger> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final shown = widget.payments.where((p) {
      if (_filter == 'approved') return p.status == PaymentStatus.approved;
      if (_filter == 'pending') return p.status == PaymentStatus.pending;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _filterChip('সকল', 'all'),
            _filterChip('অনুমোদিত', 'approved'),
            _filterChip('যাচাইাধীন', 'pending'),
          ],
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'এই তালিকায় কোনো লেনদেন নেই',
            message: 'জমা দিলে এখানে দেখা যাবে।',
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (int i = 0; i < shown.length; i++) ...[
                  LedgerRowItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title:
                        '${bengaliMonths[shown[i].forMonth - 1]} মাসের জমা',
                    subtitle:
                        '${shown[i].methodLabel} • TrxID: ${shown[i].trxId ?? "—"}${shown[i].receiptNumber != null ? " • রসিদ: ${shown[i].receiptNumber}" : ""}',
                    amount: formatTaka(shown[i].amount),
                    isIncome: true,
                    showDivider: i < shown.length - 1,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.ink,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.green,
      backgroundColor: AppColors.card,
      side: BorderSide(
        color: selected ? AppColors.green : AppColors.line,
      ),
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
