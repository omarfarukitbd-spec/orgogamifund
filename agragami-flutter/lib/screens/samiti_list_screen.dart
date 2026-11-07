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
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';

/// সমিতির তালিকা — লগইন করা যে কেউ দেখতে পায়।
/// এখানে শুধু সবার জন্য খোলা তথ্য থাকে: নাম, উদ্দেশ্য,
/// মাসিক দান আর অনুমোদিত সদস্যের সংখ্যা।
/// সদস্য কে কে, সমিতিতে কত টাকা আছে, কে জমা দিলো —
/// এগুলো এখানে আসে না; ওগুলো শুধু ওই সমিতির সদস্যরাই
/// বিস্তারিত পাতায় দেখতে পায়।
class SamitiListScreen extends ConsumerWidget {
  const SamitiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final userAsync = ref.watch(currentUserProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);

    return Scaffold(
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
          onAction: () {},
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'এখনো কোনো সমিতি নেই',
              message: 'অ্যাডমিন নতুন সমিতি খুললে এখানে দেখা যাবে।',
            );
          }
          final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
          final memberships =
              membershipsAsync.valueOrNull ?? const <Membership>[];
          Membership? membershipFor(String branchId) {
            final found =
                memberships.where((m) => m.branchId == branchId).toList();
            return found.isEmpty ? null : found.first;
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = list[i];
              final m = membershipFor(b.id);
              return AppCard(
                onTap: () => context.go('/samiti/${b.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.chevron_right_outlined),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(samitiPurposeText(b.purpose)),
                    if (b.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(b.description),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.monthlyDonation}: ৳${b.monthlyDonation}'
                      '  •  ${AppStrings.memberCountLabel}: ${b.memberCount} জন',
                    ),
                    const SizedBox(height: 12),
                    if (isAdmin)
                      const _StateChip(
                        label: 'অ্যাডমিন',
                        color: Colors.green,
                      )
                    else if (m?.isApproved ?? false)
                      const _StateChip(
                        label: AppStrings.alreadyMember,
                        color: Colors.green,
                      )
                    else if (m?.isPending ?? false)
                      const _StateChip(
                        label: AppStrings.applicationPending,
                        color: Colors.amber,
                      )
                    else if (m?.isRejected ?? false)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(AppStrings.applicationRejected),
                          const SizedBox(height: 8),
                          SecondaryButton(
                            label: AppStrings.joinSamiti,
                            onPressed: () =>
                                context.go('/apply?branchId=${b.id}'),
                          ),
                        ],
                      )
                    else
                      SecondaryButton(
                        label: AppStrings.joinSamiti,
                        onPressed: () =>
                            context.go('/apply?branchId=${b.id}'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StateChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
