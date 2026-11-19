import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/branch.dart';
import '../../models/member.dart';
import '../../models/payment.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/dues.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../passbook_screen.dart';

/// বকেয়া সদস্যের তালিকা — ফোন ও হোয়াটসঅ্যাপ বাটনসহ
class DefaultersListView extends ConsumerWidget {
  final String? branchId;
  final void Function(String phone) onCall;
  final void Function(String phone) onWhatsApp;

  const DefaultersListView({
    super.key,
    required this.branchId,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersByBranchProvider(branchId ?? ''));
    final branchesAsync = ref.watch(branchesStreamProvider);
    final paymentsAsync = ref.watch(approvedPaymentsProvider(branchId ?? ''));
    if (membersAsync.isLoading ||
        branchesAsync.isLoading ||
        paymentsAsync.isLoading) {
      return const SkeletonCardList();
    }
    if (membersAsync.hasError ||
        branchesAsync.hasError ||
        paymentsAsync.hasError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'তথ্য আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
        actionLabel: 'আবার চেষ্টা করুন',
        onAction: () {
          ref.invalidate(membersByBranchProvider(branchId ?? ''));
          ref.invalidate(branchesStreamProvider);
          ref.invalidate(approvedPaymentsProvider(branchId ?? ''));
        },
      );
    }
    final members = (membersAsync.valueOrNull ?? const <Member>[])
        .where((m) => m.active)
        .toList();
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final approved = paymentsAsync.valueOrNull ?? const <Payment>[];
    final defaulters =
        <({Member member, Branch branch, int dueMonths, int dueAmount})>[];

    for (final member in members) {
      final found = branches.where((b) => b.id == member.branchId).toList();
      if (found.isEmpty) continue;
      final branch = found.first;
      if (branch.monthlyDepositAmount <= 0) continue;
      // পাসবইয়ের সাথে একই মাসভিত্তিক হিসাব — আংশিক জমা
      // পুরো মাস ধরা হয় না।
      final dues = memberDuesPerMonth(
        joinDate: member.joinDate,
        branchStart: branch.startDate,
        monthlyAmount: branch.monthlyDepositAmount,
        payments: approved.where((p) => p.memberId == member.id).toList(),
        dueDay: branch.monthlyDueDay,
        lateFineAmount: branch.lateFineAmount,
      );
      if (dues == null || dues.dueMonths <= 0) continue;
      defaulters.add(
        (
          member: member,
          branch: branch,
          dueMonths: dues.dueMonths,
          dueAmount: dues.totalDue,
        ),
      );
    }

    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'এই মাস পর্যন্ত যাদের জমা বাকি আছে — কল বা হোয়াটসঅ্যাপে মনে করিয়ে দিন।',
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            if (defaulters.isEmpty)
              const EmptyState(
                icon: Icons.check_circle_outlined,
                title: 'এই মাসে কেউ বকেয়া নেই',
                message: 'সবার জমা সময়মতো এসেছে।',
              )
            else
              ...defaulters.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              d.member.name,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            PillTag(
                              text: '${d.dueMonths} মাস বাকি',
                              backgroundColor: const Color(0xFFFDF1F0),
                              textColor: AppColors.danger,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.branch.name} • বকেয়া: ${formatTaka(d.dueAmount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => onCall(d.member.phone),
                                icon: const Icon(Icons.call_outlined, size: 18),
                                label: const Text('কল করুন'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.green,
                                  side: const BorderSide(color: AppColors.green),
                                ),
                                onPressed: () => onWhatsApp(d.member.phone),
                                icon: const Icon(Icons.chat_outlined, size: 18),
                                label: const Text('হোয়াটসঅ্যাপ'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
  }
}
