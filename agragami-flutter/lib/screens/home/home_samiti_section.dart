import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_card.dart';
import '../passbook_screen.dart';

/// সদস্যের নিজের সমিতিগুলোর হিসাব কার্ড
class MySamitiTotalsSection extends ConsumerWidget {
  final List<String> branchIds;

  const MySamitiTotalsSection({super.key, required this.branchIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final mine = branches.where((b) => branchIds.contains(b.id)).toList();
    if (mine.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in mine) ...[
          _OneSamitiCard(branch: b),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OneSamitiCard extends ConsumerWidget {
  final Branch branch;

  const _OneSamitiCard({required this.branch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(
      FutureProvider<HomeTotals>(
        (ref) => FirestoreService().fetchHomeTotals(branchId: branch.id),
      ),
    );
    final totals = totalsAsync.valueOrNull;

    String value(int? amount, {bool money = true}) {
      if (amount == null) return '—';
      return money ? formatTaka(amount) : '$amount';
    }

    final totalBalance = totals == null ||
            totals.approvedTotal == null ||
            totals.expenseTotal == null
        ? '—'
        : formatTaka(totals.approvedTotal! - totals.expenseTotal!);

    return AppCard(
      onTap: () => context.go('/samiti/${branch.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branch.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'মোট জমা',
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
          const SizedBox(height: 8),
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
                  label: 'তহবিলে আছে',
                  value: totalBalance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// সদস্য নয় এমন ব্যবহারকারীর জন্য সমিতির তালিকা
class PublicSamitiListSection extends ConsumerWidget {
  const PublicSamitiListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    if (branches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in branches)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => context.go('/samiti/${b.id}'),
              child: Row(
                children: [
                  const ListIcon(icon: Icons.groups_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${samitiPurposeText(b.purpose)}'
                          ' • ${AppStrings.memberCountLabel}: ${b.memberCount} জন',
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
                  Icon(
                    Icons.chevron_right_outlined,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// অ্যাপের দরকারি পাতাগুলোর নেভিগেশন তালিকা
class UsefulPagesSection extends StatelessWidget {
  final bool isAdmin;
  final bool isMember;

  const UsefulPagesSection({
    super.key,
    required this.isAdmin,
    required this.isMember,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('দরকারি পাতা'),
        const SizedBox(height: 4),
        RowLinkButton(
          icon: Icons.groups_outlined,
          title: 'সমিতিগুলো দেখুন',
          onTap: () => context.go('/samiti'),
        ),
        const SizedBox(height: 8),
        if (isAdmin || isMember) ...[
          RowLinkButton(
            icon: Icons.receipt_long_outlined,
            title: 'খরচের হিসাব',
            onTap: () => context.go('/expenses'),
          ),
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.handshake_outlined,
            title: 'কর্জে হাসানা ঋণ',
            onTap: () => context.go('/loans'),
          ),
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.bar_chart_outlined,
            title: 'মাসিক রিপোর্ট ও বকেয়া সদস্য',
            onTap: () => context.go('/reports'),
          ),
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.book_outlined,
            title: 'আমার পাসবই',
            onTap: () => context.go('/passbook'),
          ),
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.badge_outlined,
            title: 'আমার আইডি কার্ড',
            onTap: () => context.go('/id-card'),
          ),
          const SizedBox(height: 8),
        ],
        RowLinkButton(
          icon: Icons.campaign_outlined,
          title: 'নোটিশ বোর্ড',
          onTap: () => context.go('/notices'),
        ),
        const SizedBox(height: 8),
        RowLinkButton(
          icon: Icons.groups_outlined,
          title: 'কমিটি',
          onTap: () => context.go('/committee'),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.account_balance_outlined,
            title: 'পেমেন্ট মাধ্যম — নম্বর যোগ করুন',
            onTap: () => context.go('/payment-methods'),
          ),
        ],
      ],
    );
  }
}
