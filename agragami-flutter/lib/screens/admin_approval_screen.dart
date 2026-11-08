import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/empty_state.dart';
import 'approval/pending_applications_tab.dart';
import 'approval/pending_payments_tab.dart';

/// অনুমোদন কেন্দ্র — নতুন সদস্য ও জমা যাচাইয়ের দুটি ট্যাব।
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
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'নতুন সদস্য'),
              Tab(text: 'জমা যাচাই'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PendingApplicationsTab(
              applicationsAsync: applications,
              branches: branches,
              branchFilter: _branchFilter,
              onFilterChanged: (v) => setState(() => _branchFilter = v),
              reviewer: reviewer,
              store: store,
              onRun: _run,
              onAskReason: _askReason,
            ),
            PendingPaymentsTab(
              paymentsAsync: payments,
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
