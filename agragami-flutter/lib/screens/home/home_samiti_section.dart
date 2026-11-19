import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../services/firestore_service.dart';
import '../../utils/admin_branch_scope.dart';
import '../../widgets/app_card.dart';
import '../passbook_screen.dart';

/// সদস্যের নিজের সমিতিগুলোর হিসাব কার্ড
class MySamitiTotalsSection extends ConsumerWidget {
  final List<String> branchIds;

  /// সুপার অ্যাডমিন কি না, শাখা অ্যাডমিন কি না, আর তার
  /// নিজের সমিতি — প্রতিটি কার্ডে শাখা-ভিত্তিক পরীক্ষা হয়
  /// (Phase 8, G3): মোট হিসাব সবসময় দেখে শুধু ওই সমিতির
  /// অ্যাডমিন, canMembersViewTotalFund শুধু সদস্যদের জন্য (F11)।
  final bool isSuperAdmin;
  final bool isBranchAdmin;
  final String? adminBranchId;

  const MySamitiTotalsSection({
    super.key,
    required this.branchIds,
    this.isSuperAdmin = false,
    this.isBranchAdmin = false,
    this.adminBranchId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesStreamProvider);
    // ভুল হলে সেকশনটা চুপচাপ উধাও হয় না — ভুল দেখানো হয়।
    if (branchesAsync.hasError) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'সমিতির তালিকা আনা যায়নি — নেট দেখে আবার চেষ্টা করুন।',
                style: TextStyle(fontSize: 14.5),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(branchesStreamProvider),
              child: Text(AppStrings.tryAgain),
            ),
          ],
        ),
      );
    }
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final mine = branches.where((b) => branchIds.contains(b.id)).toList();
    if (mine.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in mine) ...[
          _OneSamitiCard(
            branch: b,
            // Phase 8 (G3): কার্ড-প্রতি শাখা-ভিত্তিক
            // অ্যাডমিন-পরীক্ষা — অন্য সমিতির শাখা অ্যাডমিন
            // এখানে সদস্যের মতোই দেখে।
            isAdmin: isAdminForBranch(
              isSuperAdmin: isSuperAdmin,
              isBranchAdmin: isBranchAdmin,
              adminBranchId: adminBranchId,
              branchId: b.id,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OneSamitiCard extends ConsumerWidget {
  final Branch branch;
  final bool isAdmin;

  const _OneSamitiCard({required this.branch, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // F11: সমিতির অ্যাডমিন মোট হিসাব সদস্যদের জন্য বন্ধ
    // রাখতে পারে — তখন কার্ডে শুধু নাম দেখা যায়।
    final totalsHidden = !isAdmin && !branch.canMembersViewTotalFund;
    final totalsAsync = totalsHidden
        ? const AsyncValue<HomeTotals>.data(HomeTotals())
        : ref.watch(homeTotalsByBranchProvider(branch.id));
    final totals = totalsAsync.valueOrNull;

    String value(int? amount, {bool money = true}) {
      if (amount == null) return '—';
      return money ? formatTaka(amount) : '$amount';
    }

    // তহবিল = জমা − খরচ − বকেয়া ঋণ (রিপোর্টের সাথে মিলিয়ে)।
    final totalBalance =
        totals == null ? '—' : formatTaka(totals.fund);

    return AppCard(
      onTap: () => context.goNamed(
        'samitiDetail',
        pathParameters: {'id': branch.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branch.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (totalsHidden) ...[
            const Text(
              'এই সমিতির মোট হিসাব সদস্যদের জন্য বন্ধ আছে।',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ] else if (totalsAsync.hasError) ...[
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'হিসাব আনা যায়নি — নেট দেখে আবার চেষ্টা করুন।',
                    style: TextStyle(fontSize: 14.5),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(
                    homeTotalsByBranchProvider(branch.id),
                  ),
                  child: Text(AppStrings.tryAgain),
                ),
              ],
            ),
          ] else ...[
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
    final branchesAsync = ref.watch(branchesStreamProvider);
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    if (branches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in branches)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => context.goNamed(
                'samitiDetail',
                pathParameters: {'id': b.id},
              ),
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
          onTap: () => context.goNamed('samiti'),
        ),
        const SizedBox(height: 8),
        if (isAdmin || isMember) ...[
          RowLinkButton(
            icon: Icons.receipt_long_outlined,
            title: 'খরচের হিসাব',
            onTap: () => context.goNamed('expenses'),
          ),
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.handshake_outlined,
            title: 'কর্জে হাসানা ঋণ',
            onTap: () => context.goNamed('loans'),
          ),
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.bar_chart_outlined,
            title: 'মাসিক রিপোর্ট ও বকেয়া সদস্য',
            onTap: () => context.goNamed('reports'),
          ),
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.book_outlined,
            title: 'আমার পাসবই',
            onTap: () => context.goNamed('passbook'),
          ),
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.badge_outlined,
            title: 'আমার আইডি কার্ড',
            onTap: () => context.goNamed('idCard'),
          ),
          const SizedBox(height: 8),
        ],
        RowLinkButton(
          icon: Icons.campaign_outlined,
          title: 'নোটিশ বোর্ড',
          onTap: () => context.goNamed('notices'),
        ),
        const SizedBox(height: 8),
        RowLinkButton(
          icon: Icons.groups_outlined,
          title: 'কমিটি',
          onTap: () => context.goNamed('committee'),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 8),
          RowLinkButton(
            icon: Icons.account_balance_outlined,
            title: 'পেমেন্ট মাধ্যম — নম্বর যোগ করুন',
            onTap: () => context.goNamed('paymentMethods'),
          ),
        ],
      ],
    );
  }
}
