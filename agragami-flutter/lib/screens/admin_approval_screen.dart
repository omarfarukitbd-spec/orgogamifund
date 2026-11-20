import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/firebase_errors.dart';
import '../widgets/empty_state.dart';
import 'approval/pending_applications_tab.dart';
import 'approval/pending_edit_requests_tab.dart';
import 'approval/pending_payments_tab.dart';

/// অনুমোদন কেন্দ্র — নতুন সদস্য, জমা আর তথ্য সংশোধন
/// যাচাইয়ের তিনটি ট্যাব।
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
            child: Text(AppStrings.cancel),
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
      // M12: অনুমোদন/বাতিলের পর মোট হিসাব তাজা হয় — নইলে
      // হোম/সমিতির কার্ডে পুরোনো অঙ্ক দেখাত।
      invalidateTotals(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(doneMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firebaseErrorMessage(e, fallback: 'কাজটি হয়নি — আবার চেষ্টা করুন'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(firestoreServiceProvider);
    final reviewer = ref.read(authServiceProvider).uidOrEmpty;
    // m8: লোড হওয়ার সময় অ্যাডমিনকেও "শুধু অ্যাডমিন" বার্তা
    // দেখানো হয় না — আগে স্পিনার, তারপর সিদ্ধান্ত।
    final userAsync = ref.watch(currentUserProvider);
    if (userAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // m9: ব্যবহারকারীর তথ্য আনতে ভুল হলে "শুধু অ্যাডমিন" বলে
    // আটকে দেওয়া হয় না — ভুল দেখিয়ে আবার চেষ্টার সুযোগ।
    if (userAsync.hasError) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'তথ্য আনা যায়নি',
          message: 'নেট দেখে আবার চেষ্টা করুন।',
          actionLabel: AppStrings.tryAgain,
          onAction: () => ref.invalidate(currentUserProvider),
        ),
      );
    }
    final user = userAsync.valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    if (!isAdmin) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.lock_outlined,
          title: AppStrings.adminOnlyPage,
          message: 'অনুমোদনের কাজ শুধু অ্যাডমিন করতে পারেন।',
        ),
      );
    }
    // Phase 5 (F5): শাখা অ্যাডমিন শুধু নিজের সমিতির
    // অপেক্ষমাণ কাজ দেখে — ফিল্টার ছাড়া পড়লে নিয়মে
    // (rules) বাধা পায়। সুপার অ্যাডমিন "সব সমিতি" দেখতে পারে।
    final isBranchAdmin = isAdmin && !(user?.isSuperAdmin ?? false);
    // Phase 9 (G13): সমিতি বাঁধা না থাকা শাখা অ্যাডমিনের
    // গার্ড — branchId null হলে ফিল্টার null হয়ে সব
    // সমিতির আবেদন দেখাত (খরচ/ঋণ/রিপোর্টের মতোই বার্তা)।
    if (isBranchAdmin &&
        (user?.branchId == null || user!.branchId!.isEmpty)) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.groups_outlined,
          title: 'আপনার সমিতি ঠিক করা নেই',
          message: 'সুপার অ্যাডমিনের সাথে যোগাযোগ করুন।',
        ),
      );
    }
    final effectiveFilter = isBranchAdmin ? user!.branchId : _branchFilter;
    // M4: টপ-লেভেল family প্রোভাইডার — build()-এর ভেতরে নতুন
    // প্রোভাইডার বানানো হয় না, rebuild-এ স্ট্রিম বাঁচে।
    final applications =
        ref.watch(pendingApplicationsProvider(effectiveFilter));
    final payments = ref.watch(pendingPaymentsProvider(effectiveFilter));
    // Phase 9 (G12): তথ্য সংশোধনের আবেদন — একই
    // শাখা-ফিল্টার চলে।
    final editRequests =
        ref.watch(pendingEditRequestsProvider(effectiveFilter));
    final branchesAsync = ref.watch(branchesStreamProvider);
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppStrings.navApproval),
          actions: [
            IconButton(
              tooltip: AppStrings.navPaymentMethods,
              onPressed: () => context.goNamed('paymentMethods'),
              icon: const Icon(Icons.account_balance_outlined),
            ),
          ],
          bottom: const TabBar(
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'নতুন সদস্য'),
              Tab(text: 'জমা যাচাই'),
              Tab(text: 'তথ্য সংশোধন'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PendingApplicationsTab(
              applicationsAsync: applications,
              branches: branches,
              branchFilter: effectiveFilter,
              isBranchAdmin: isBranchAdmin,
              onFilterChanged: (v) => setState(() => _branchFilter = v),
              onRetry: () =>
                  ref.invalidate(pendingApplicationsProvider(effectiveFilter)),
              reviewer: reviewer,
              store: store,
              onRun: _run,
              onAskReason: _askReason,
            ),
            PendingPaymentsTab(
              paymentsAsync: payments,
              branches: branches,
              branchFilter: effectiveFilter,
              isBranchAdmin: isBranchAdmin,
              isSuperAdmin: user?.isSuperAdmin ?? false,
              onFilterChanged: (v) => setState(() => _branchFilter = v),
              onRetry: () =>
                  ref.invalidate(pendingPaymentsProvider(effectiveFilter)),
              reviewer: reviewer,
              store: store,
              onRun: _run,
              onAskReason: _askReason,
            ),
            PendingEditRequestsTab(
              requestsAsync: editRequests,
              branches: branches,
              branchFilter: effectiveFilter,
              isBranchAdmin: isBranchAdmin,
              onFilterChanged: (v) => setState(() => _branchFilter = v),
              onRetry: () =>
                  ref.invalidate(pendingEditRequestsProvider(effectiveFilter)),
              reviewer: reviewer,
              store: store,
              onRun: _run,
              onAskReason: _askReason,
            ),
          ],
        ),
      ),
    );
  }
}
