import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../models/member.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../passbook_screen.dart';

/// সদস্য বা অ্যাডমিনের জন্য ভেতরের হিসাব — সদস্য তালিকা,
/// মোট জমা, মোট খরচ, তহবিলের টাকা ও লেনদেন।
class SamitiMemberDetail extends ConsumerWidget {
  final Branch branch;
  final bool isAdmin;

  const SamitiMemberDetail({
    super.key,
    required this.branch,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(firestoreServiceProvider);
    final totalsAsync = ref.watch(
      FutureProvider<HomeTotals>(
        (ref) => store.fetchHomeTotals(branchId: branch.id),
      ),
    );
    final membersAsync = ref.watch(
      StreamProvider<List<Member>>(
        (ref) => store.watchMembers(branchId: branch.id),
      ),
    );
    final totals = totalsAsync.valueOrNull;
    final members = membersAsync.valueOrNull ?? const <Member>[];

    String value(int? amount, {bool money = true}) {
      if (amount == null) return '—';
      return money ? formatTaka(amount) : '$amount';
    }

    final fund = totals == null ||
            totals.approvedTotal == null ||
            totals.expenseTotal == null
        ? null
        : totals.approvedTotal! - totals.expenseTotal!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'মোট জমা হয়েছে',
                value: value(totals?.approvedTotal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.receipt_long_outlined,
                label: 'মোট খরচ',
                value: value(totals?.expenseTotal),
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
                icon: Icons.groups_outlined,
                label: 'সক্রিয় সদস্য',
                value: value(totals?.activeMembers, money: false),
                isGold: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'এখন তহবিলে আছে',
                value: fund == null ? '—' : formatTaka(fund),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'জমা দিন',
                onPressed: () => context.go('/deposit'),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecondaryButton(
                label: 'পাসবই',
                onPressed: () => context.go('/passbook'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'সদস্যরা (${members.length} জন)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (membersAsync.isLoading)
          const SkeletonCardList()
        else if (members.isEmpty)
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'এখনো কোনো সদস্য নেই',
          )
        else
          ...members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.greenSoft,
                      backgroundImage:
                          m.photoUrl != null && m.photoUrl!.isNotEmpty
                              ? NetworkImage(m.photoUrl!)
                              : null,
                      child: m.photoUrl == null || m.photoUrl!.isEmpty
                          ? const Icon(
                              Icons.person_outline,
                              color: AppColors.green,
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ফোন: ${m.phone}',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await store.recountMemberCount(branch.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.recountDone)),
                );
              }
            },
            child: const Text(AppStrings.recountMembers),
          ),
        ],
      ],
    );
  }
}
