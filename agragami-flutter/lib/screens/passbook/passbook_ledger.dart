import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/payment.dart';
import '../../services/voucher_share_service.dart';
import '../../utils/date_parser.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../passbook_screen.dart';

/// লেনদেনের খাতা — ফিল্টার, লেজার রো এবং এক-ক্লিকে রসিদ ভাউচার শেয়ার
class PassbookLedger extends StatefulWidget {
  final List<Payment> payments;
  final String memberName;
  final String branchName;

  const PassbookLedger({
    super.key,
    required this.payments,
    required this.memberName,
    required this.branchName,
  });

  @override
  State<PassbookLedger> createState() => _PassbookLedgerState();
}

class _PassbookLedgerState extends State<PassbookLedger> {
  String _filter = 'all';

  void _showVoucherDialog(BuildContext context, Payment p) {
    final isBn = AppStrings.isBangla;
    final voucherService = VoucherShareService();
    final voucherText = voucherService.formatPaymentVoucherText(
      payment: p,
      memberName: widget.memberName,
      branchName: widget.branchName,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_outlined, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBn ? 'জমার ভাউচার ও রসিদ' : 'Deposit Voucher & Receipt',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '${isBn ? "পরিমাণ" : "Amount"}: ${formatTaka(p.amount)} (${p.statusLabel})',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'TrxID: ${p.trxId} • ${isBn ? "রসিদ" : "Receipt"}: ${p.receiptNumber ?? "—"}',
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                voucherService.shareToWhatsApp(text: voucherText);
              },
              icon: const Icon(Icons.chat_outlined),
              label: Text(isBn
                  ? 'হোয়াটসঅ্যাপে ভাউচার পাঠান'
                  : 'Share to WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                voucherService.shareGeneral(text: voucherText);
              },
              icon: const Icon(Icons.share_outlined),
              label: Text(isBn
                  ? 'অন্যান্য মাধ্যমে শেয়ার করুন'
                  : 'Share via Other Apps'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

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
            _filterChip(AppStrings.filterAll, 'all'),
            _filterChip(AppStrings.filterApproved, 'approved'),
            _filterChip(AppStrings.filterPending, 'pending'),
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
                        '${bengaliMonths[(shown[i].forMonth - 1).clamp(0, 11)]} মাসের জমা',
                    subtitle:
                        '${shown[i].methodLabel} • ${isMissingDate(shown[i].date) ? "তারিখ নেই" : "${shown[i].date.day}/${shown[i].date.month}/${shown[i].date.year}"} • TrxID: ${shown[i].trxId ?? "—"}${shown[i].receiptNumber != null ? " • রসিদ: ${shown[i].receiptNumber}" : ""}',
                    amount: formatTaka(shown[i].amount),
                    isIncome: true,
                    showDivider: i < shown.length - 1,
                    onTap: () => _showVoucherDialog(context, shown[i]),
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
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
      selected: selected,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : AppColors.line,
      ),
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
