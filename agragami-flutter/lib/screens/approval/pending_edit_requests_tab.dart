import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../models/edit_request.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';

/// সদস্যের তথ্য সংশোধনের আবেদন যাচাই ট্যাব (Phase 9, G12)।
/// অনুমোদন হলে সদস্যের রেকর্ডে বদলানো তথ্য বসে।
class PendingEditRequestsTab extends StatefulWidget {
  final AsyncValue<List<EditRequest>> requestsAsync;
  final List<Branch> branches;
  final String? branchFilter;

  /// শাখা অ্যাডমিন হলে true — তখন সমিতি বাছার ড্রপডাউন
  /// দেখানো হয় না (নিজের সমিতিই ফিল্টার)।
  final bool isBranchAdmin;
  final ValueChanged<String?> onFilterChanged;

  /// তালিকা আনতে ভুল হলে আবার চেষ্টার বোতাম (F5)।
  final VoidCallback onRetry;
  final String reviewer;
  final FirestoreService store;
  final Future<void> Function(BuildContext, Future<void> Function(), String)
      onRun;
  final Future<String?> Function(BuildContext, String) onAskReason;

  const PendingEditRequestsTab({
    super.key,
    required this.requestsAsync,
    required this.branches,
    required this.branchFilter,
    required this.isBranchAdmin,
    required this.onFilterChanged,
    required this.onRetry,
    required this.reviewer,
    required this.store,
    required this.onRun,
    required this.onAskReason,
  });

  @override
  State<PendingEditRequestsTab> createState() => _PendingEditRequestsTabState();
}

class _PendingEditRequestsTabState extends State<PendingEditRequestsTab> {
  // B5: যে আবেদনের যাচাই চলছে, তার বোতাম বন্ধ থাকে —
  // ডাবল-ট্যাপে দুইবার অনুমোদন হয় না।
  final _busyIds = <String>{};

  String _branchName(String id) {
    final found = widget.branches.where((b) => b.id == id).toList();
    return found.isEmpty ? '—' : found.first.name;
  }

  Future<void> _runFor(String id, Future<void> Function() work) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await work();
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // F5: শাখা অ্যাডমিনের ড্রপডাউন নেই — নিজের সমিতির
        // নামটুকু দেখানো হয়, যাতে বোঝা যায় কোন সমিতির
        // আবেদন দেখছে।
        if (widget.isBranchAdmin)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.groups_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'সমিতি: ${_branchName(widget.branchFilter ?? '')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else
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
          child: widget.requestsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonCardList(),
            ),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'তালিকা আনা যায়নি',
              actionLabel: AppStrings.tryAgain,
              onAction: widget.onRetry,
            ),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.edit_note_outlined,
                  title: 'অনুমোদনের অপেক্ষায় কোনো আবেদন নেই',
                  message: 'সদস্য তথ্য সংশোধনের আবেদন করলে এখানে দেখা যাবে।',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final r = list[i];
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.memberName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'সমিতি: ${_branchName(r.branchId)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          'আবেদন: ${r.requestedAt.day}/${r.requestedAt.month}/${r.requestedAt.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // বদলাতে চাওয়া ক্ষেত্র — পুরোনো → নতুন।
                        for (final entry in r.changes.entries) ...[
                          Text(
                            '${editRequestFieldLabel(entry.key)}: '
                            '${r.previous[entry.key] ?? '—'} → ${entry.value}',
                            style: const TextStyle(fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: _busyIds.contains(r.id)
                                    ? AppStrings.loading
                                    : AppStrings.approve,
                                onPressed: _busyIds.contains(r.id)
                                    ? null
                                    : () => _runFor(
                                          r.id,
                                          () => widget.onRun(
                                            context,
                                            () => widget.store
                                                .approveEditRequest(
                                              r,
                                              reviewedBy: widget.reviewer,
                                            ),
                                            'তথ্য সংশোধনের আবেদন অনুমোদন হয়েছে',
                                          ),
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
                                onPressed: _busyIds.contains(r.id)
                                    ? null
                                    : () async {
                                        final reason =
                                            await widget.onAskReason(
                                          context,
                                          'আবেদন কেন বাতিল করছেন?',
                                        );
                                        if (reason == null || reason.isEmpty) {
                                          return;
                                        }
                                        if (!context.mounted) return;
                                        await _runFor(
                                          r.id,
                                          () => widget.onRun(
                                            context,
                                            () => widget.store
                                                .rejectEditRequest(
                                              r.id,
                                              reason: reason,
                                              reviewedBy: widget.reviewer,
                                            ),
                                            'আবেদন বাতিল হয়েছে',
                                          ),
                                        );
                                      },
                                child: Text(AppStrings.reject),
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
