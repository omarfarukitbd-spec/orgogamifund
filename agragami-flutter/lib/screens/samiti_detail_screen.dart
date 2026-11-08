import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
import 'passbook_screen.dart';

/// একটি সমিতির বিস্তারিত পাতা।
/// সদস্য নয় এমন লগইন করা ব্যবহারকারী এখানে শুধু খোলা তথ্য
/// দেখে — নাম, উদ্দেশ্য, মাসিক দান, সদস্য সংখ্যা — আর
/// আবেদনের বোতাম। সদস্যের নাম, টাকার হিসাব, জমার খাতা,
/// বকেয়া — এগুলো দেখা যায় শুধু ওই সমিতির সদস্য বা
/// অ্যাডমিন হলে, আর সেগুলোর জন্য প্রশ্নও তখনই পাঠানো হয়।
class SamitiDetailScreen extends ConsumerWidget {
  final String branchId;

  const SamitiDetailScreen({super.key, required this.branchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchAsync = ref.watch(
      StreamProvider<Branch?>(
        (ref) => FirestoreService().watchBranch(branchId),
      ),
    );
    final userAsync = ref.watch(currentUserProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);

    return branchAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) => const EmptyState(
        icon: Icons.error_outline,
        title: 'তথ্য আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
      ),
      data: (branch) {
        if (branch == null) {
          return const EmptyState(
            icon: Icons.groups_outlined,
            title: 'সমিতিটি পাওয়া যায়নি',
            message: 'তালিকা থেকে আবার খুলে দেখুন।',
          );
        }
        final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
        final memberships =
            membershipsAsync.valueOrNull ?? const <Membership>[];
        final found =
            memberships.where((m) => m.branchId == branch.id).toList();
        final membership = found.isEmpty ? null : found.first;
        final canSee = isAdmin || (membership?.isApproved ?? false);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      samitiPurposeText(branch.purpose),
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Colors.grey,
                      ),
                    ),
                    if (branch.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        branch.description,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${AppStrings.monthlyDonation}: ৳${branch.monthlyDonation}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${AppStrings.memberCountLabel}: '
                          '${branch.memberCount} জন',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!canSee) ...[
                if (membership?.isPending ?? false)
                  const AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.applicationPending,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'অনুমোদন হলে এই সমিতির ভেতরের হিসাব দেখা যাবে।',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (membership?.isRejected ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        AppStrings.applicationRejected,
                        style: TextStyle(fontSize: 14.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: AppStrings.joinSamiti,
                        onPressed: () =>
                            context.go('/apply?branchId=${branch.id}'),
                        icon: Icons.person_add_outlined,
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        AppStrings.membersOnlyNote,
                        style: TextStyle(fontSize: 14.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: AppStrings.joinSamiti,
                        onPressed: () =>
                            context.go('/apply?branchId=${branch.id}'),
                        icon: Icons.person_add_outlined,
                      ),
                    ],
                  ),
              ] else
                _MemberDetail(branch: branch, isAdmin: isAdmin),
            ],
          ),
        );
      },
    );
  }
}

/// সদস্য বা অ্যাডমিনের জন্য ভেতরের হিসাব — সদস্য তালিকা,
/// মোট জমা, মোট খরচ, তহবিলের টাকা। এই অংশটা শুধু
/// সদস্য হলেই বানানো হয়, তাই প্রশ্নও তখনই যায়।
class _MemberDetail extends ConsumerWidget {
  final Branch branch;
  final bool isAdmin;

  const _MemberDetail({required this.branch, required this.isAdmin});

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
                      radius: 23,
                      backgroundImage:
                          m.photoUrl != null && m.photoUrl!.isNotEmpty
                              ? NetworkImage(m.photoUrl!)
                              : null,
                      child: m.photoUrl == null || m.photoUrl!.isEmpty
                          ? const Icon(Icons.person_outlined, size: 26)
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
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey,
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
          const SizedBox(height: 16),
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
