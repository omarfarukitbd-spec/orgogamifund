import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../models/member_application.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';

/// নতুন সদস্য পদের আবেদন যাচাই ও অনুমোদন ট্যাব
class PendingApplicationsTab extends StatefulWidget {
  final AsyncValue<List<MemberApplication>> applicationsAsync;
  final List<Branch> branches;
  final String? branchFilter;
  final ValueChanged<String?> onFilterChanged;
  final String reviewer;
  final FirestoreService store;
  final Future<void> Function(BuildContext, Future<void> Function(), String)
      onRun;
  final Future<String?> Function(BuildContext, String) onAskReason;

  const PendingApplicationsTab({
    super.key,
    required this.applicationsAsync,
    required this.branches,
    required this.branchFilter,
    required this.onFilterChanged,
    required this.reviewer,
    required this.store,
    required this.onRun,
    required this.onAskReason,
  });

  @override
  State<PendingApplicationsTab> createState() => _PendingApplicationsTabState();
}

class _PendingApplicationsTabState extends State<PendingApplicationsTab> {
  String _branchName(String id) {
    final found = widget.branches.where((b) => b.id == id).toList();
    return found.isEmpty ? '—' : found.first.name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: DropdownButtonFormField<String>(
            initialValue: widget.branchFilter,
            decoration: const InputDecoration(
              labelText: 'কোন সমিতির আবেদন',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('সব সমিতি')),
              ...widget.branches.map(
                (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
              ),
            ],
            onChanged: widget.onFilterChanged,
          ),
        ),
        Expanded(
          child: widget.applicationsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonCardList(),
            ),
            error: (e, _) => const EmptyState(
              icon: Icons.error_outline,
              title: 'তালিকা আনা যায়নি',
            ),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_add_outlined,
                  title: 'অনুমোদনের অপেক্ষায় কেউ নেই',
                  message: 'নতুন কোনো আবেদন এলে এখানে দেখা যাবে।',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final a = list[i];
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'সমিতি: ${_branchName(a.branchId)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          'ফোন: ${a.phone}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          'এনআইডি: ${a.nidNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          'আবেদন: ${a.requestedAt.day}/${a.requestedAt.month}/${a.requestedAt.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: AppStrings.approve,
                                onPressed: () => widget.onRun(
                                  context,
                                  () => widget.store.approveApplication(
                                    a,
                                    reviewedBy: widget.reviewer,
                                  ),
                                  'সদস্য অনুমোদন হয়েছে',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                    color: AppColors.danger,
                                  ),
                                ),
                                onPressed: () async {
                                  final reason = await widget.onAskReason(
                                    context,
                                    'আবেদন কেন বাতিল করছেন?',
                                  );
                                  if (reason == null || reason.isEmpty) return;
                                  if (!context.mounted) return;
                                  await widget.onRun(
                                    context,
                                    () => widget.store.rejectApplication(
                                      a.id,
                                      reason: reason,
                                      reviewedBy: widget.reviewer,
                                    ),
                                    'আবেদন বাতিল হয়েছে',
                                  );
                                },
                                child: const Text(AppStrings.reject),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
