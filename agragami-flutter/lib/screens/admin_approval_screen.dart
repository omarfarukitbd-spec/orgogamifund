import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'passbook_screen.dart';

/// অনুমোদন কেন্দ্র — অ্যাডমিনের সব বাকি কাজ এক জায়গায়।
/// নতুন সদস্যের আবেদন আর যাচাই বাকি জমা — দুটো তালিকাই এখানে।
/// অনুমোদন দিলে আবেদনকারী ওই সমিতির সদস্য হয়, জমার রসিদ নম্বর বসে।
/// বাতিল করলে কারণ লিখতে হয়।
/// এই পাতা শুধু অ্যাডমিন দেখতে পারেন — সদস্য বা সদস্য নয়
/// এমন কেউ এলে কিছু দেখা যায় না।
/// আবেদন সমিতি ধরে ছাঁকা যায়, যাতে এক সমিতির আবেদন
/// আরেক সমিতির সাথে না মেশে।
class AdminApprovalScreen extends ConsumerStatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  ConsumerState<AdminApprovalScreen> createState() =>
      _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends ConsumerState<AdminApprovalScreen> {
  String? _branchFilter;

  Future<String?> _askReason(BuildContext context, String title) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'কারণ লিখুন',
            hintText: 'যেমন: TrxID মেলেনি',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('বাতিল করুন'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() work,
    String doneMessage,
  ) async {
    try {
      await work();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(doneMessage)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কাজটি হয়নি — আবার চেষ্টা করুন')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(firestoreServiceProvider);
    final reviewer = AuthService().uidOrEmpty;
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;
    if (!isAdmin) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outlined,
          title: AppStrings.adminOnlyPage,
          message: 'অনুমোদনের কাজ শুধু অ্যাডমিন করতে পারেন।',
        ),
      );
    }
    final applications = ref.watch(
      StreamProvider(
        (ref) => store.watchPendingApplications(branchId: _branchFilter),
      ),
    );
    final payments = ref.watch(
      StreamProvider((ref) => store.watchPendingPayments()),
    );
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => store.watchBranches()),
    );
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    String branchName(String id) {
      final found = branches.where((b) => b.id == id).toList();
      return found.isEmpty ? '—' : found.first.name;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(AppStrings.navApproval),
          actions: [
            IconButton(
              tooltip: AppStrings.navPaymentMethods,
              onPressed: () => context.go('/payment-methods'),
              icon: const Icon(Icons.account_balance_outlined),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'নতুন সদস্য'),
              Tab(text: 'জমা যাচাই'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: DropdownButtonFormField<String>(
                    initialValue: _branchFilter,
                    decoration: const InputDecoration(
                      labelText: 'কোন সমিতির আবেদন',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('সব সমিতি'),
                      ),
                      ...branches.map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _branchFilter = v),
                  ),
                ),
                Expanded(
                  child: applications.when(
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
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final a = list[i];
                          return AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('সমিতি: ${branchName(a.branchId)}'),
                                Text('ফোন: ${a.phone}'),
                                Text('এনআইডি: ${a.nidNumber}'),
                                Text(
                                  'আবেদন: ${a.requestedAt.day}/${a.requestedAt.month}/${a.requestedAt.year}',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _run(
                                          context,
                                          () => store.approveApplication(
                                            a,
                                            reviewedBy: reviewer,
                                          ),
                                          'সদস্য অনুমোদন হয়েছে',
                                        ),
                                        child: const Text(AppStrings.approve),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final reason = await _askReason(
                                            context,
                                            'আবেদন কেন বাতিল করছেন?',
                                          );
                                          if (reason == null ||
                                              reason.isEmpty) {
                                            return;
                                          }
                                          if (!context.mounted) return;
                                          await _run(
                                            context,
                                            () => store.rejectApplication(
                                              a.id,
                                              reason: reason,
                                              reviewedBy: reviewer,
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
            ),
            payments.when(
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
                    icon: Icons.payments_outlined,
                    title: 'যাচাই বাকি কোনো জমা নেই',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = list[i];
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatTaka(p.amount)} — ${p.methodLabel}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          if (p.paymentAccountNumber != null &&
                              p.paymentAccountNumber!.isNotEmpty)
                            Text('মাধ্যমের নম্বর: ${p.paymentAccountNumber}'),
                          Text(
                            '${bengaliMonths[p.forMonth - 1]} ${p.forYear}'
                            ' • TrxID: ${p.trxId ?? '—'}',
                          ),
                          if (p.senderMobile != null &&
                              p.senderMobile!.isNotEmpty)
                            Text('পাঠিয়েছেন: ${p.senderMobile}'),
                          const Text('অবস্থা: ${AppStrings.depositPending}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _run(
                                    context,
                                    () => store.approvePayment(
                                      p,
                                      reviewedBy: reviewer,
                                    ),
                                    'জমা অনুমোদন হয়েছে, রসিদ নম্বর বসেছে',
                                  ),
                                  child: const Text(AppStrings.approve),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final reason = await _askReason(
                                      context,
                                      'জমা কেন বাতিল করছেন?',
                                    );
                                    if (reason == null || reason.isEmpty) {
                                      return;
                                    }
                                    if (!context.mounted) return;
                                    await _run(
                                      context,
                                      () => store.rejectPayment(
                                        p.id,
                                        reason: reason,
                                        reviewedBy: reviewer,
                                      ),
                                      'জমা বাতিল হয়েছে',
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
          ],
        ),
      ),
    );
  }
}
