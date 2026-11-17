import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
import 'samiti/samiti_member_detail.dart';

/// একটি সমিতির বিস্তারিত পাতা — এইচটিএমএল প্রিভিউয়ের মতো হেডার কার্ড,
/// সদস্য হলে ৪টি স্ট্যাট কার্ড ও সদস্য তালিকা; সদস্য না হলে লক কার্ড ও আবেদন বাটন।
class SamitiDetailScreen extends ConsumerWidget {
  final String branchId;

  const SamitiDetailScreen({super.key, required this.branchId});

  IconData _iconForPurpose(SamitiPurpose purpose) {
    switch (purpose) {
      case SamitiPurpose.madrasa:
        return Icons.menu_book_outlined;
      case SamitiPurpose.mosqueOrphanage:
        return Icons.account_balance_outlined;
      case SamitiPurpose.other:
        return Icons.groups_outlined;
    }
  }

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
        final theme = Theme.of(context);
        final iconData = _iconForPurpose(branch.purpose);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // সমিতির হেডার কার্ড
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.greenSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Icon(iconData, color: AppColors.green, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                samitiPurposeText(branch.purpose),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (branch.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        branch.description,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: AppColors.line.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${AppStrings.monthlyDonation}: ৳${branch.monthlyDonation}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${AppStrings.memberCountLabel}: ${branch.memberCount} জন',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // যদি সদস্য না হয় — লক বক্স ও আবেদন বাটন
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
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.greenSoft.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              color: AppColors.green,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'সদস্য হলে ভেতরের হিসাব — সদস্য তালিকা, মোট টাকা, জমার খাতা, বকেয়া — দেখা যাবে।',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
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
                SamitiMemberDetail(branch: branch, isAdmin: isAdmin),
            ],
          ),
        );
      },
    );
  }
}
