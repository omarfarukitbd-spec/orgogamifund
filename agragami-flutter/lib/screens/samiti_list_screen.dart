import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/admin_branch_scope.dart';
import '../utils/samiti_apply.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'samiti/create_samiti_dialog.dart';

final branchesProvider = branchesStreamProvider;

/// সমিতির তালিকা — এইচটিএমএল প্রিভিউয়ের মতো কার্ড, ব্যানার আইকন,
/// মাসিক জমা ও সদস্য সংখ্যা এবং স্ট্যাটাস চিপ।
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
    // F6: সমিতি বানানো শুধু সুপার অ্যাডমিনের কাজ (rules:
    // branches create শুধু সুপার অ্যাডমিন)।
    final isSuperAdmin = userAsync.valueOrNull?.isSuperAdmin ?? false;
    // Phase 9 (G6): "আপনি অ্যাডমিন" ট্যাগ শাখা-ভিত্তিক —
    // কার্ডকে রোল আর বাঁধা সমিতি জানানো হয়।
    final isBranchAdmin =
        userAsync.valueOrNull?.isBranchAdmin ?? false;
    final adminBranchId = userAsync.valueOrNull?.branchId;

    return Scaffold(
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => _openCreateSamiti(context),
              icon: const Icon(Icons.add),
              label: Text(AppStrings.createSamiti),
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
              actionLabel: isSuperAdmin ? AppStrings.createSamiti : null,
              onAction: isSuperAdmin ? () => _openCreateSamiti(context) : null,
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
                'ঢোকার পর সবাই সমিতির নাম, উদ্দেশ্য, মাসিক জমা আর সদস্য সংখ্যা দেখতে পারে — ভেতরের হিসাব শুধু ওই সমিতির সদস্যরাই দেখতে পারে।',
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
                  isSuperAdmin: isSuperAdmin,
                  isBranchAdmin: isBranchAdmin,
                  adminBranchId: adminBranchId,
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
  final bool isSuperAdmin;
  final bool isBranchAdmin;
  final String? adminBranchId;

  const _SamitiCardItem({
    required this.branch,
    required this.membership,
    required this.isSuperAdmin,
    required this.isBranchAdmin,
    required this.adminBranchId,
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
    final showApply = shouldShowApplyButton(
      isApprovedMember: isApproved,
      isPendingApplication: isPending,
    );
    // Phase 9 (G6): "আপনি অ্যাডমিন" ট্যাগ শুধু এই সমিতির
    // অ্যাডমিন হলে — শাখা অ্যাডমিন অন্য সমিতির কার্ডে আর
    // ট্যাগ দেখে না। সুপার অ্যাডমিন সব সমিতির অ্যাডমিন।
    final isAdminOfBranch = isAdminForBranch(
      isSuperAdmin: isSuperAdmin,
      isBranchAdmin: isBranchAdmin,
      adminBranchId: adminBranchId,
      branchId: branch.id,
    );
    final iconData = _iconForPurpose(branch.purpose);

    return AppCard(
      onTap: () => context.goNamed(
        'samitiDetail',
        pathParameters: {'id': branch.id},
      ),
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
                'মাসিক জমা: ৳${branch.monthlyDepositAmount}',
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
          // Phase 7: অ্যাডমিনও এই সমিতির সদস্য হতে পারে — তাই
          // অ্যাডমিন ট্যাগ আর সদস্যপদের অবস্থা আলাদা আলাদা
          // দেখানো হয়। আগে অ্যাডমিন হলে শুধু ট্যাগ দেখা যেত,
          // আবেদনের বোতাম কখনো আসত না।
          // Phase 9 (G6): ট্যাগ শুধু এই সমিতির অ্যাডমিনের।
          if (isAdminOfBranch) ...[
            const PillTag(
              text: 'আপনি অ্যাডমিন',
              backgroundColor: AppColors.goldSoft,
              textColor: AppColors.goldDark,
            ),
            const SizedBox(height: 8),
          ],
          if (isApproved)
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
            ),
          if (showApply)
            PrimaryButton(
              label: 'সদস্য হতে আবেদন করুন',
              onPressed: () => context.goNamed(
                'apply',
                queryParameters: {'branchId': branch.id},
              ),
              icon: Icons.person_add_outlined,
            ),
        ],
      ),
    );
  }
}
