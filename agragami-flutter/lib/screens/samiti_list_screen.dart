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
import 'samiti/create_samiti_dialog.dart';

final branchesProvider = StreamProvider<List<Branch>>(
  (ref) => FirestoreService().watchBranches(),
);

/// সমিতির তালিকা — এইচটিএমএল প্রিভিউয়ের মতো কার্ড, ব্যানার আইকন,
/// মাসিক দান ও সদস্য সংখ্যা এবং স্ট্যাটাস চিপ।
class SamitiListScreen extends ConsumerWidget {
  const SamitiListScreen({super.key});

  void _openCreateSamiti(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const CreateSamitiDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => _openCreateSamiti(context),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.createSamiti),
            )
          : null,
      body: branchesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonCardList(),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'তালিকা আনা যায়নি',
          message: 'ইন্টারনেট দেখে আবার চেষ্টা করুন।',
          actionLabel: AppStrings.tryAgain,
          onAction: () => ref.invalidate(branchesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: AppStrings.samitiEmptyTitle,
              message: isAdmin
                  ? AppStrings.samitiEmptyAdminBody
                  : AppStrings.samitiEmptyBody,
              actionLabel: isAdmin ? AppStrings.createSamiti : null,
              onAction: isAdmin ? () => _openCreateSamiti(context) : null,
            );
          }
          final memberships =
              membershipsAsync.valueOrNull ?? const <Membership>[];
          Membership? membershipFor(String branchId) {
            final found =
                memberships.where((m) => m.branchId == branchId).toList();
            return found.isEmpty ? null : found.first;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Text(
                'ঢোকার পর সবাই সমিতির নাম, উদ্দেশ্য, মাসিক দান আর সদস্য সংখ্যা দেখতে পারে — ভেতরের হিসাব শুধু ওই সমিতির সদস্যরাই দেখতে পারে।',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              for (final b in list) ...[
                _SamitiCardItem(
                  branch: b,
                  membership: membershipFor(b.id),
                  isAdmin: isAdmin,
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SamitiCardItem extends StatelessWidget {
  final Branch branch;
  final Membership? membership;
  final bool isAdmin;

  const _SamitiCardItem({
    required this.branch,
    required this.membership,
    required this.isAdmin,
  });

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isApproved = membership?.isApproved ?? false;
    final isPending = membership?.isPending ?? false;
    final iconData = _iconForPurpose(branch.purpose);

    return AppCard(
      onTap: () => context.go('/samiti/${branch.id}'),
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
                child: Icon(iconData, color: AppColors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16.5,
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
            const SizedBox(height: 6),
            Text(
              branch.description,
              style: TextStyle(
                fontSize: 13.5,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: AppColors.line.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'মাসিক দান: ৳${branch.monthlyDonation}',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
              const Spacer(),
              Text(
                'সদস্য: ${branch.memberCount} জন',
                style: TextStyle(
                  fontSize: 13.5,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isAdmin)
            const PillTag(
              text: 'আপনি অ্যাডমিন',
              backgroundColor: AppColors.goldSoft,
              textColor: AppColors.goldDark,
            )
          else if (isApproved)
            const PillTag(
              text: 'আপনি এই সমিতির সদস্য',
              backgroundColor: AppColors.greenSoft,
              textColor: AppColors.green,
            )
          else if (isPending)
            const PillTag(
              text: 'আবেদন প্রক্রিয়াধীন',
              backgroundColor: AppColors.goldSoft,
              textColor: AppColors.goldDark,
            )
          else
            PrimaryButton(
              label: 'সদস্য হতে আবেদন করুন',
              onPressed: () => context.go('/apply?branchId=${branch.id}'),
              icon: Icons.person_add_outlined,
            ),
        ],
      ),
    );
  }
}
