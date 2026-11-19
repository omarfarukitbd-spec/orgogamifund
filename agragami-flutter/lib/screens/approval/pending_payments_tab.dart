import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../passbook_screen.dart';
import '../payments/edit_payment_dialog.dart';

/// জমা যাচাই ও অনুমোদন ট্যাব
class PendingPaymentsTab extends StatefulWidget {
  final AsyncValue<List<Payment>> paymentsAsync;
  final String reviewer;
  final FirestoreService store;
  final Future<void> Function(BuildContext, Future<void> Function(), String)
      onRun;
  final Future<String?> Function(BuildContext, String) onAskReason;

  const PendingPaymentsTab({
    super.key,
    required this.paymentsAsync,
    required this.reviewer,
    required this.store,
    required this.onRun,
    required this.onAskReason,
  });

  @override
  State<PendingPaymentsTab> createState() => _PendingPaymentsTabState();
}

class _PendingPaymentsTabState extends State<PendingPaymentsTab> {
  // m5: যে জমার যাচাই চলছে, তার বোতাম বন্ধ থাকে —
  // ডাবল-ট্যাপে অনুমোদন-তারপর-বাতিল হতে পারে না।
  final _busyIds = <String>{};

  Future<void> _runFor(String id, Future<void> Function() work) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await work();
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

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
      await widget.store.deletePayment(
        p.id,
        by: AuthService().uidOrEmpty,
      );
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return widget.paymentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) => const EmptyState(
        icon: Icons.error_outline,
        title: 'তালিকা আনা যায়নি',
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.payments_outlined,
            title: 'যাচাই বাকি কোনো জমা নেই',
            message: 'সদস্যরা জমা পাঠালে এখানে দেখা যাবে।',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = list[i];
            final busy = _busyIds.contains(p.id);
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formatTaka(p.amount)} — ${p.methodLabel}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const PillTag(
                        text: 'যাচাইাধীন',
                        backgroundColor: AppColors.goldSoft,
                        textColor: AppColors.goldDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (p.paymentAccountNumber != null &&
                      p.paymentAccountNumber!.isNotEmpty)
                    Text(
                      'মাধ্যমের নম্বর: ${p.paymentAccountNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  Text(
                    '${bengaliMonths[p.forMonth - 1]} ${p.forYear}'
                    ' • TrxID: ${p.trxId ?? "—"}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  if (p.senderMobile != null && p.senderMobile!.isNotEmpty)
                    Text(
                      'পাঠিয়েছেন: ${p.senderMobile}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: busy ? AppStrings.loading : AppStrings.approve,
                          onPressed: busy
                              ? null
                              : () => _runFor(
                                    p.id,
                                    () => widget.onRun(
                                      context,
                                      () => widget.store.approvePayment(
                                        p,
                                        reviewedBy: widget.reviewer,
                                      ),
                                      'জমা অনুমোদন হয়েছে, রসিদ নম্বর বসেছে',
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                          onPressed: busy
                              ? null
                              : () async {
                                  final reason = await widget.onAskReason(
                                    context,
                                    'জমা কেন বাতিল করছেন?',
                                  );
                                  if (reason == null || reason.isEmpty) return;
                                  if (!context.mounted) return;
                                  await _runFor(
                                    p.id,
                                    () => widget.onRun(
                                      context,
                                      () => widget.store.rejectPayment(
                                        p.id,
                                        reason: reason,
                                        reviewedBy: widget.reviewer,
                                      ),
                                      'জমা বাতিল হয়েছে',
                                    ),
                                  );
                                },
                          child: Text(AppStrings.reject),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: busy
                            ? null
                            : () => showDialog(
                                  context: context,
                                  builder: (_) =>
                                      EditPaymentDialog(payment: p),
                                ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('বদলান'),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed:
                            busy ? null : () => _deletePayment(p),
                        icon: const Icon(
                          Icons.delete_outlined,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        label: const Text(
                          'মুছুন',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
