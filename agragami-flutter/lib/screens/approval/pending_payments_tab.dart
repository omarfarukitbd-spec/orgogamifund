import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../passbook_screen.dart';
import '../payments/edit_payment_dialog.dart';

/// জমা যাচাই ও অনুমোদন ট্যাব
class PendingPaymentsTab extends StatefulWidget {
  final AsyncValue<List<Payment>> paymentsAsync;
  final List<Branch> branches;
  final String? branchFilter;

  /// শাখা অ্যাডমিন হলে true — তখন সমিতি বাছার ড্রপডাউন
  /// দেখানো হয় না (নিজের সমিতিই ফিল্টার)।
  final bool isBranchAdmin;

  /// সুপার অ্যাডমিন না হলে "মুছুন" বোতাম লুকানো হয় (F6) —
  /// জমা মুছতে শুধু সুপার অ্যাডমিন পারে (rules)।
  final bool isSuperAdmin;
  final ValueChanged<String?> onFilterChanged;

  /// তালিকা আনতে ভুল হলে আবার চেষ্টার বোতাম (F5)।
  final VoidCallback onRetry;
  final String reviewer;
  final FirestoreService store;
  final Future<void> Function(BuildContext, Future<void> Function(), String)
      onRun;
  final Future<String?> Function(BuildContext, String) onAskReason;

  const PendingPaymentsTab({
    super.key,
    required this.paymentsAsync,
    required this.branches,
    required this.branchFilter,
    required this.isBranchAdmin,
    required this.isSuperAdmin,
    required this.onFilterChanged,
    required this.onRetry,
    required this.reviewer,
    required this.store,
    required this.onRun,
    required this.onAskReason,
  });

  @override
  State<PendingPaymentsTab> createState() => _PendingPaymentsTabState();
}

class _PendingPaymentsTabState extends State<PendingPaymentsTab> {
  // m5: যে জমার যাচাই চলছে, তার বোতাম বন্ধ থাকে —
  // ডাবল-ট্যাপে অনুমোদন-তারপর-বাতিল হতে পারে না।
  final _busyIds = <String>{};

  Future<void> _runFor(String id, Future<void> Function() work) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await work();
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _deletePayment(Payment p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('জমা মুছবেন?'),
        content: Text(
          '${formatTaka(p.amount)}-এর এই জমাটি মুছে যাবে। এই কাজ ফিরিয়ে নেওয়া যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.store.deletePayment(
        p.id,
        by: AuthService().uidOrEmpty,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('জমা মুছা হয়েছে')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(e, fallback: 'জমা মুছা যায়নি — আবার চেষ্টা করুন'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // F5: জমা যাচাইতেও সমিতির ফিল্টার — আবেদন ট্যাবের
        // মতো। শাখা অ্যাডমিনের ড্রপডাউন নেই, নিজের সমিতির
        // নামটুকু দেখানো হয়।
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
                labelText: 'কোন সমিতির জমা',
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
          child: widget.paymentsAsync.when(
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
                  icon: Icons.payments_outlined,
                  title: 'যাচাই বাকি কোনো জমা নেই',
                  message: 'সদস্যরা জমা পাঠালে এখানে দেখা যাবে।',
                );
              }
              return _PaymentsList(
                list: list,
                busyIds: _busyIds,
                isSuperAdmin: widget.isSuperAdmin,
                onRunFor: _runFor,
                onRun: widget.onRun,
                onAskReason: widget.onAskReason,
                onDelete: _deletePayment,
                reviewer: widget.reviewer,
                store: widget.store,
              );
            },
          ),
        ),
      ],
    );
  }

  String _branchName(String id) {
    final found = widget.branches.where((b) => b.id == id).toList();
    return found.isEmpty ? '—' : found.first.name;
  }
}
/// অপেক্ষমাণ জমার তালিকা — ফিল্টার আর ত্রুটি-অবস্থা থেকে
/// আলাদা উইজেট, যাতে build() ছোট থাকে।
class _PaymentsList extends StatelessWidget {
  final List<Payment> list;
  final Set<String> busyIds;
  final bool isSuperAdmin;
  final Future<void> Function(String, Future<void> Function()) onRunFor;
  final Future<void> Function(BuildContext, Future<void> Function(), String)
      onRun;
  final Future<String?> Function(BuildContext, String) onAskReason;
  final Future<void> Function(Payment) onDelete;
  final String reviewer;
  final FirestoreService store;

  const _PaymentsList({
    required this.list,
    required this.busyIds,
    required this.isSuperAdmin,
    required this.onRunFor,
    required this.onRun,
    required this.onAskReason,
    required this.onDelete,
    required this.reviewer,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = list[i];
        final busy = busyIds.contains(p.id);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${formatTaka(p.amount)} — ${p.methodLabel}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const PillTag(
                    text: 'যাচাইাধীন',
                    backgroundColor: AppColors.goldSoft,
                    textColor: AppColors.goldDark,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (p.paymentAccountNumber != null &&
                  p.paymentAccountNumber!.isNotEmpty)
                Text(
                  'মাধ্যমের নম্বর: ${p.paymentAccountNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
              Text(
                '${bengaliMonths[p.forMonth - 1]} ${p.forYear}'
                ' • TrxID: ${p.trxId ?? "—"}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
              if (p.senderMobile != null && p.senderMobile!.isNotEmpty)
                Text(
                  'পাঠিয়েছেন: ${p.senderMobile}',
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
                      label: busy ? AppStrings.loading : AppStrings.approve,
                      onPressed: busy
                          ? null
                          : () => onRunFor(
                                p.id,
                                () => onRun(
                                  context,
                                  () => store.approvePayment(
                                    p,
                                    reviewedBy: reviewer,
                                  ),
                                  'জমা অনুমোদন হয়েছে, রসিদ নম্বর বসেছে',
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      onPressed: busy
                          ? null
                          : () async {
                              final reason = await onAskReason(
                                context,
                                'জমা কেন বাতিল করছেন?',
                              );
                              if (reason == null || reason.isEmpty) return;
                              if (!context.mounted) return;
                              await onRunFor(
                                p.id,
                                () => onRun(
                                  context,
                                  () => store.rejectPayment(
                                    p.id,
                                    reason: reason,
                                    reviewedBy: reviewer,
                                  ),
                                  'জমা বাতিল হয়েছে',
                                ),
                              );
                            },
                      child: Text(AppStrings.reject),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: busy
                        ? null
                        : () => showDialog(
                              context: context,
                              builder: (_) => EditPaymentDialog(payment: p),
                            ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('বদলান'),
                  ),
                  const Spacer(),
                  // F6: "মুছুন" শুধু সুপার অ্যাডমিন দেখে।
                  if (isSuperAdmin)
                    TextButton.icon(
                      onPressed: busy ? null : () => onDelete(p),
                      icon: const Icon(
                        Icons.delete_outlined,
                        size: 16,
                        color: AppColors.danger,
                      ),
                      label: const Text(
                        'মুছুন',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
