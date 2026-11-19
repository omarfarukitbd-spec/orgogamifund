import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/voucher_share_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_parser.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../passbook_screen.dart';
import '../payments/edit_payment_dialog.dart';

/// লেনদেনের খাতা — ফিল্টার, লেজার রো এবং এক-ক্লিকে রসিদ ভাউচার শেয়ার
class PassbookLedger extends ConsumerStatefulWidget {
  final List<Payment> payments;
  final String memberName;
  final String branchName;

  /// মানুষের পড়ার মতো সদস্য নম্বর (F15) — ভাউচারে দেখানো হয়।
  final String? memberNumber;
  final bool isAdmin;

  /// সুপার অ্যাডমিন কি না — "মুছুন" শুধু সুপার অ্যাডমিন
  /// দেখে (F6); "বদলান" সব অ্যাডমিন দেখে।
  final bool isSuperAdmin;

  const PassbookLedger({
    super.key,
    required this.payments,
    required this.memberName,
    required this.branchName,
    this.memberNumber,
    this.isAdmin = false,
    this.isSuperAdmin = false,
  });

  @override
  ConsumerState<PassbookLedger> createState() => _PassbookLedgerState();
}

class _PassbookLedgerState extends ConsumerState<PassbookLedger> {
  String _filter = 'all';

  Future<void> _deletePayment(Payment p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('জমা মুছবেন?'),
        content: Text(
          '${formatTaka(p.amount)}-এর এই জমাটি মুছে যাবে। এই কাজ ফিরিয়ে নেওয়া যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(firestoreServiceProvider).deletePayment(
            p.id,
            by: AuthService().uidOrEmpty,
          );
      if (!mounted) return;
      invalidateTotals(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('জমা মুছা হয়েছে')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(e, fallback: 'জমা মুছা যায়নি — আবার চেষ্টা করুন'),
          ),
        ),
      );
    }
  }

  void _showVoucherDialog(BuildContext context, Payment p) {
    final isBn = AppStrings.isBangla;
    final voucherService = VoucherShareService();
    final voucherText = voucherService.formatPaymentVoucherText(
      payment: p,
      memberName: widget.memberName,
      branchName: widget.branchName,
      memberNumber: widget.memberNumber,
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
            // M9: অ্যাডমিন ভাউচার থেকেই জমা বদলাতে/মুছতে পারে।
            // F6: "মুছুন" শুধু সুপার অ্যাডমিন দেখে।
            if (widget.isAdmin) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => EditPaymentDialog(payment: p),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('বদলান'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  if (widget.isSuperAdmin) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deletePayment(p);
                        },
                        icon: const Icon(
                          Icons.delete_outlined,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        label: const Text(
                          'মুছুন',
                          style: TextStyle(color: AppColors.danger),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: AppColors.danger),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
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
