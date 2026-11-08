import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_icon.dart';
import '../widgets/not_member_gate.dart';
import 'passbook_screen.dart';

/// হোম — লগইন করা সবাই খুলতে পারে, কিন্তু টাকার সংখ্যা
/// শুধু তারাই দেখে যারা কোনো সমিতির সদস্য বা অ্যাডমিন।
/// সদস্য নয় এমন ব্যবহারকারী এখানে শুধু সমিতির তালিকা
/// (নাম, উদ্দেশ্য, সদস্য সংখ্যা) আর আবেদনের পথ দেখে —
/// কোনো সমিতির টাকা, সদস্যের নাম বা বকেয়া দেখে না।
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final memberships = membershipsAsync.valueOrNull ?? const <Membership>[];
    final myBranchIds = approvedBranchIds(memberships);
    final isAdmin = user?.isAdmin ?? false;
    final isMember = myBranchIds.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const AgragamiLogo(size: 56, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.appTagline,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isAdmin) ...[
            _GlobalTotals(),
            const SizedBox(height: 12),
            AppCard(
              onTap: () => context.go('/approval'),
              child: const Row(
                children: [
                  ListIcon(icon: Icons.fact_check_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'অনুমোদন কেন্দ্র — বাকি কাজগুলো এক জায়গায় দেখুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_outlined, color: Colors.grey),
                ],
              ),
            ),
          ] else if (!isMember) ...[
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.notMemberAnyTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppStrings.notMemberAnyBody,
                    style: TextStyle(fontSize: 14.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: AppStrings.viewSamitis,
              onPressed: () => context.go('/samiti'),
              icon: Icons.groups_outlined,
            ),
            const SizedBox(height: 16),
            _PublicSamitiList(),
          ] else
            _MySamitiTotals(branchIds: myBranchIds),
          const SizedBox(height: 16),
          Text(
            'দরকারি পাতা',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          const _Link(
            icon: Icons.groups_outlined,
            label: 'সমিতিগুলো দেখুন',
            path: '/samiti',
          ),
          if (isAdmin || isMember) ...[
            const _Link(
              icon: Icons.receipt_long_outlined,
              label: 'খরচের হিসাব',
              path: '/expenses',
            ),
            const _Link(
              icon: Icons.handshake_outlined,
              label: 'কর্জে হাসানা ঋণ',
              path: '/loans',
            ),
            const _Link(
              icon: Icons.bar_chart_outlined,
              label: 'মাসিক রিপোর্ট আর বকেয়া সদস্য',
              path: '/reports',
            ),
            const _Link(
              icon: Icons.book_outlined,
              label: 'আমার পাসবই',
              path: '/passbook',
            ),
            const _Link(
              icon: Icons.badge_outlined,
              label: 'আমার আইডি কার্ড',
              path: '/id-card',
            ),
          ],
          const _Link(
            icon: Icons.campaign_outlined,
            label: 'নোটিশ বোর্ড',
            path: '/notices',
          ),
          const _Link(
            icon: Icons.groups_outlined,
            label: 'কমিটি',
            path: '/committee',
          ),
          if (isAdmin) ...[
            const _Link(
              icon: Icons.account_balance_outlined,
              label: 'পেমেন্ট মাধ্যম — নম্বর যোগ করুন',
              path: '/payment-methods',
            ),
            const SizedBox(height: 8),
            const Text(
              'আপনি অ্যাডমিন — খরচ লেখা, ঋণ দেওয়া আর নোটিশ দেওয়া ওই পাতাগুলো থেকেই করা যাবে।',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

/// অ্যাডমিনের জন্য সব সমিতির মোট হিসাব — আগের মতোই।
class _GlobalTotals extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(
      FutureProvider<HomeTotals>(
        (ref) => FirestoreService().fetchHomeTotals(),
      ),
    );
    final totals = totalsAsync.valueOrNull;

    String value(int? amount, {bool money = true}) {
      if (amount == null) return '—';
      return money ? formatTaka(amount) : '$amount';
    }

    return Column(
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'এখন তহবিলে আছে',
                value: totals == null ||
                        totals.approvedTotal == null ||
                        totals.expenseTotal == null
                    ? '—'
                    : formatTaka(
                        totals.approvedTotal! - totals.expenseTotal!,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// সদস্যের নিজের সমিতিগুলোর হিসাব — এক সমিতির হিসাব
/// আরেক সমিতির সদস্য এখানে দেখে না।
class _MySamitiTotals extends ConsumerWidget {
  final List<String> branchIds;

  const _MySamitiTotals({required this.branchIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final mine =
        branches.where((b) => branchIds.contains(b.id)).toList();
    if (mine.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in mine) ...[
          _OneSamitiTotals(branch: b),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OneSamitiTotals extends ConsumerWidget {
  final Branch branch;

  const _OneSamitiTotals({required this.branch});

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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'তহবিলে আছে',
                  value: totals == null ||
                          totals.approvedTotal == null ||
                          totals.expenseTotal == null
                      ? '—'
                      : formatTaka(
                          totals.approvedTotal! - totals.expenseTotal!,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// সদস্য নয় এমন ব্যবহারকারীর জন্য সমিতির খোলা তালিকা —
/// নাম, উদ্দেশ্য আর সদস্য সংখ্যা শুধু।
class _PublicSamitiList extends ConsumerWidget {
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
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_outlined, color: Colors.grey),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;

  const _Link({required this.icon, required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => context.go(path),
        child: Row(
          children: [
            ListIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
