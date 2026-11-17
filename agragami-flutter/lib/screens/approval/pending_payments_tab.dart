import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/payment.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../passbook_screen.dart';

/// জমা যাচাই ও অনুমোদন ট্যাব
class PendingPaymentsTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return paymentsAsync.when(
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
                          label: AppStrings.approve,
                          onPressed: () => onRun(
                            context,
                            () => store.approvePayment(
                              p,
                              reviewedBy: reviewer,
                            ),
                            'জমা অনুমোদন হয়েছে, রসিদ নম্বর বসেছে',
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
                          onPressed: () async {
                            final reason = await onAskReason(
                              context,
                              'জমা কেন বাতিল করছেন?',
                            );
                            if (reason == null || reason.isEmpty) return;
                            if (!context.mounted) return;
                            await onRun(
                              context,
                              () => store.rejectPayment(
                                p.id,
                                reason: reason,
                                reviewedBy: reviewer,
                              ),
                              'জমা বাতিল হয়েছে',
                            );
                          },
                          child: const Text(AppStrings.reject),
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
