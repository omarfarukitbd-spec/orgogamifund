import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/membership.dart';
import '../models/payment.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import 'home/home_samiti_section.dart';
import 'passbook_screen.dart';

/// হোম স্ক্রিন — এইচটিএমএল প্রিভিউয়ের নিখুঁত রূপ।
/// আসসালামু আলাইকুম গ্রিটিং, দুটি স্ট্যাট কার্ড, দুটি কুইক অ্যাকশন কার্ড,
/// অনুমোদন ও নোটিশ লিংক, সাম্প্রতিক লেনদেন এবং প্রয়োজনীয় পৃষ্ঠাসমূহ।
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final memberships = membershipsAsync.valueOrNull ?? const <Membership>[];
    final myBranchIds = approvedBranchIds(memberships);
    final isAdmin = user?.isAdmin ?? false;
    final isMember = myBranchIds.isNotEmpty;

    // মোট হিসাব: অ্যাডমিন সব সমিতি দেখে, সদস্য শুধু তার
    // অনুমোদিত সমিতিগুলো — ফিল্টার ছাড়া পড়লে নিয়মে বাধা পায়।
    // অতিথির (কোনো সমিতির সদস্য নয়) জন্য হিসাব পড়া হয় না।
    final totalsKey = isAdmin
        ? ''
        : myBranchIds.isEmpty
            ? null
            : (myBranchIds.toList()..sort()).join('|');
    final totalsAsync = totalsKey == null
        ? const AsyncValue<HomeTotals>.data(HomeTotals())
        : ref.watch(homeTotalsForBranchesProvider(totalsKey));
    final totals = totalsAsync.valueOrNull;
    final totalsFailed = totalsKey != null && totalsAsync.hasError;

    final fundTotal = totals == null || totalsKey == null
        ? '৳ —'
        : formatTaka(totals.fund);
    final memberCountStr =
        totals == null || totalsKey == null ? '—' : '${totals.activeMembers} জন';

    final displayName = (user?.email.isNotEmpty == true)
        ? user!.email.split('@').first
        : (isAdmin ? 'অ্যাডমিন' : 'সদস্য');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // আসসালামু আলাইকুম এবং ট্যাগ রো
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'আসসালামু আলাইকুম, ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15.5,
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              PillTag(
                text: isAdmin ? 'অ্যাডমিন' : (isMember ? 'সদস্য' : 'অতিথি'),
                backgroundColor:
                    isAdmin ? AppColors.goldSoft : AppColors.greenSoft,
                textColor: isAdmin ? AppColors.goldDark : AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ২টি প্রধান স্ট্যাট কার্ড (মোট তহবিল ও মোট সদস্য)
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'মোট তহবিল',
                  value: fundTotal,
                  note: totalsFailed
                      ? 'তথ্য আনা যায়নি'
                      : 'তহবিলের বর্তমান স্থিতি',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.groups_outlined,
                  label: 'মোট সদস্য',
                  value: memberCountStr,
                  note: 'সক্রিয় নিবন্ধিত সদস্য',
                  isGold: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ২টি কুইক অ্যাকশন কার্ড (আমার পাসবই ও আইডি কার্ড)
          Row(
            children: [
              Expanded(
                child: QuickActionCard(
                  icon: Icons.book_outlined,
                  title: 'আমার পাসবই',
                  subtitle: '১২ মাসের ছক ও লেনদেন',
                  onTap: () => context.go('/passbook'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.badge_outlined,
                  title: 'আইডি কার্ড',
                  subtitle: 'PNG ডাউনলোড করা যাবে',
                  isGold: true,
                  onTap: () => context.go('/id-card'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // অনুমোদন কেন্দ্র (অ্যাডমিনদের জন্য) ও নোটিশ লিংক
          if (isAdmin) ...[
            RowLinkButton(
              icon: Icons.fact_check_outlined,
              iconColor: AppColors.green,
              title: 'অনুমোদন কেন্দ্র — বাকি কাজগুলো এক জায়গায় দেখুন',
              onTap: () => context.go('/approval'),
            ),
            const SizedBox(height: 10),
          ],
          RowLinkButton(
            icon: Icons.campaign_outlined,
            iconColor: AppColors.goldDark,
            title: 'নোটিশ বোর্ড — সর্বশেষ ঘোষণা দেখুন',
            onTap: () => context.go('/notices'),
          ),

          // সাম্প্রতিক লেনদেন সেকশন
          const SectionTitle('সাম্প্রতিক লেনদেন'),
          _RecentTransactionsCard(
            myBranchIds: myBranchIds,
            isAdmin: isAdmin,
          ),

          // সদস্য না হলে আবেদনের ব্যানার
          if (!isAdmin && !isMember) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.notMemberAnyTitle,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.notMemberAnyBody,
                    style: const TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: AppStrings.viewSamitis,
              onPressed: () => context.go('/samiti'),
              icon: Icons.groups_outlined,
            ),
            const SizedBox(height: 16),
            const PublicSamitiListSection(),
          ] else if (isMember) ...[
            const SizedBox(height: 16),
            MySamitiTotalsSection(branchIds: myBranchIds),
          ],

          // দরকারি পাতা সেকশন
          const SizedBox(height: 8),
          UsefulPagesSection(isAdmin: isAdmin, isMember: isMember),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// সাম্প্রতিক লেনদেন কার্ড — সাম্প্রতিক ২টি জমা আর ২টি খরচ।
/// টপ-লেভেল প্রোভাইডার থেকে আসে; অ্যাডমিন সব সমিতি দেখে,
/// সদস্য শুধু তার অনুমোদিত সমিতিগুলো।
class _RecentTransactionsCard extends ConsumerWidget {
  final List<String> myBranchIds;
  final bool isAdmin;

  const _RecentTransactionsCard({
    required this.myBranchIds,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = isAdmin
        ? ''
        : (myBranchIds.toList()..sort()).join('|');
    final txnsAsync = (!isAdmin && myBranchIds.isEmpty)
        ? const AsyncValue<RecentTransactions>.data(
            RecentTransactions(payments: [], expenses: []),
          )
        : ref.watch(recentTransactionsProvider(key));

    if (txnsAsync.hasError) {
      return const AppCard(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: LedgerRowItem(
          icon: Icons.error_outline,
          title: 'তথ্য আনা যায়নি',
          subtitle: 'নেট দেখে আবার চেষ্টা করুন',
          amount: '৳ —',
          isIncome: true,
          showDivider: false,
        ),
      );
    }

    final txns = txnsAsync.valueOrNull;
    final payments = txns?.payments ?? const <Payment>[];
    final expenses = txns?.expenses ?? const <Expense>[];

    final hasPayments = payments.isNotEmpty;
    final hasExpenses = expenses.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          if (hasPayments) ...[
            for (int i = 0;
                i < (payments.length > 2 ? 2 : payments.length);
                i++)
              LedgerRowItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'মাসিক জমা — ${payments[i].senderMobile ?? "সদস্য"}',
                subtitle:
                    '${payments[i].forYear}/${payments[i].forMonth} • ${payments[i].methodLabel}',
                amount: formatTaka(payments[i].amount),
                isIncome: true,
                showDivider: hasExpenses || i < payments.length - 1,
              ),
          ] else ...[
            const LedgerRowItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'মাসিক জমা — কোনো নতুন তথ্য নেই',
              subtitle: 'অনুমোদিত জমা এখানে দেখাবে',
              amount: '৳ —',
              isIncome: true,
              showDivider: true,
            ),
          ],
          if (hasExpenses) ...[
            for (int i = 0;
                i < (expenses.length > 2 ? 2 : expenses.length);
                i++)
              LedgerRowItem(
                icon: Icons.receipt_long_outlined,
                title:
                    'খরচ — ${expenses[i].description.isNotEmpty ? expenses[i].description : expenses[i].category}',
                subtitle: expenses[i].category,
                amount: formatTaka(expenses[i].amount),
                isIncome: false,
                isGold: true,
                showDivider:
                    i < (expenses.length > 2 ? 2 : expenses.length) - 1,
              ),
          ] else ...[
            const LedgerRowItem(
              icon: Icons.receipt_long_outlined,
              title: 'খরচ — কোনো নতুন রেকর্ড নেই',
              subtitle: 'সমিতির অনুমোদিত খরচ এখানে দেখাবে',
              amount: '৳ —',
              isIncome: false,
              isGold: true,
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }
}
