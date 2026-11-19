import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/expense.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_parser.dart';
import '../utils/firebase_errors.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
import 'expenses/edit_expense_dialog.dart';
import 'passbook_screen.dart';

/// খরচের তালিকা — সমিতি বেছে নিলে শুধু ওই সমিতিরটা।
/// উপরে ওই তালিকার মোট খরচ। অ্যাডমিন বা ব্রাঞ্চ অ্যাডমিন
/// ছাড়া কেউ নতুন খরচ লিখতে পারে না।
/// সদস্য শুধু নিজের সমিতির খরচ দেখে — অন্য সমিতির খরচের
/// জন্য প্রশ্নই পাঠানো হয় না। সদস্য নয় এমন কেউ এখানে
/// আবেদনের পথ দেখে, খরচ দেখে না।
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String? _branchId;

  Future<void> _deleteExpense(Expense e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('খরচ মুছবেন?'),
        content: Text(
          '${formatTaka(e.amount)}-এর এই খরচটি মুছে যাবে। এই কাজ ফিরিয়ে নেওয়া যাবে না।',
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
      await ref.read(firestoreServiceProvider).deleteExpense(
            e.id,
            by: AuthService().uidOrEmpty,
          );
      if (!mounted) return;
      invalidateTotals(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('খরচ মুছা হয়েছে')),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(err, fallback: 'খরচ মুছা যায়নি — আবার চেষ্টা করুন'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    // Phase 5 (F5): শাখা অ্যাডমিন শুধু নিজের সমিতি দেখে —
    // "সব সমিতি" তার জন্য নেই, ফিল্টার ছাড়া পড়লে নিয়মে
    // (rules) বাধা পায়।
    final isBranchAdmin = isAdmin && !isSuperAdmin;
    if (isBranchAdmin &&
        (user!.branchId == null || user.branchId!.isEmpty)) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'আপনার সমিতি ঠিক করা নেই',
        message: 'সুপার অ্যাডমিনের সাথে যোগাযোগ করুন।',
      );
    }
    final membershipsAsync = ref.watch(myMembershipsProvider);
    if (membershipsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (membershipsAsync.hasError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'তথ্য আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
        actionLabel: AppStrings.tryAgain,
        onAction: () => ref.invalidate(myMembershipsProvider),
      );
    }
    final memberships = membershipsAsync.valueOrNull ?? const <Membership>[];
    final allowedIds = isSuperAdmin
        ? null
        : isBranchAdmin
            ? <String>[user!.branchId!]
            : approvedBranchIds(memberships);
    if (!isAdmin && (allowedIds == null || allowedIds.isEmpty)) {
      return const NotMemberGate();
    }
    final branchesAsync = ref.watch(branchesStreamProvider);
    final allBranches = branchesAsync.valueOrNull ?? const <Branch>[];
    final branches = allowedIds == null
        ? allBranches
        : allBranches.where((b) => allowedIds.contains(b.id)).toList();
    // সদস্যের ক্ষেত্রে সমিতি ঠিক করা না থাকলে নিজের প্রথম
    // সমিতিটাই দেখানো হয় — "সব সমিতি" এখানে নেই, কারণ
    // অন্য সমিতির খরচের প্রশ্ন পাঠানোই যাবে না।
    final effectiveBranchId = isSuperAdmin
        ? _branchId
        : isBranchAdmin
            ? user!.branchId
            : (_branchId != null && branches.any((b) => b.id == _branchId)
                ? _branchId
                : (branches.isEmpty ? null : branches.first.id));
    // Phase 5 (F11): সমিতির অ্যাডমিন খরচের তালিকা সদস্যদের
    // জন্য বন্ধ রাখতে পারে — তখন সদস্য তালিকা দেখে না।
    final selectedBranch =
        branches.where((b) => b.id == effectiveBranchId).toList();
    final expensesHiddenFromMembers = !isAdmin &&
        selectedBranch.isNotEmpty &&
        !selectedBranch.first.canMembersViewExpenses;
    final expensesAsync =
        ref.watch(expensesByBranchProvider(effectiveBranchId ?? ''));
    final expenses = expensesAsync.valueOrNull ?? const <Expense>[];
    final total = expenses.fold(0, (sum, e) => sum + e.amount);
    String branchName(String id) {
      final found = allBranches.where((b) => b.id == id).toList();
      return found.isEmpty ? '—' : found.first.name;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBranchAdmin)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'সমিতি: ${branchName(effectiveBranchId ?? '')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: effectiveBranchId,
              decoration: const InputDecoration(
                labelText: 'কোন সমিতি',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              items: [
                if (isSuperAdmin)
                  const DropdownMenuItem(value: null, child: Text('সব সমিতি')),
                ...branches.map(
                  (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                ),
              ],
              onChanged: (v) => setState(() => _branchId = v),
            ),
          const SizedBox(height: 12),
          StatCard(
            icon: Icons.receipt_long_outlined,
            label: 'মোট খরচ',
            value: expensesAsync.isLoading || expensesAsync.hasError
                ? '—'
                : formatTaka(total),
            note: expensesAsync.hasError
                ? 'তথ্য আনা যায়নি'
                : '${expenses.length}টি খরচ',
          ),
          const SizedBox(height: 12),
          if (isAdmin)
            ElevatedButton.icon(
              onPressed: () => context.goNamed('addExpense'),
              icon: const Icon(Icons.add_outlined),
              label: Text(AppStrings.addExpense),
            ),
          const SizedBox(height: 16),
          if (expensesHiddenFromMembers)
            const EmptyState(
              icon: Icons.visibility_off_outlined,
              title: 'খরচের তালিকা সদস্যদের জন্য বন্ধ আছে',
              message: 'এই সমিতির অ্যাডমিন খরচ দেখা বন্ধ রেখেছেন।',
            )
          else if (expensesAsync.isLoading)
            const SkeletonCardList()
          else if (expensesAsync.hasError)
            EmptyState(
              icon: Icons.error_outline,
              title: 'তথ্য আনা যায়নি',
              message: 'নেট দেখে আবার চেষ্টা করুন।',
              actionLabel: AppStrings.tryAgain,
              onAction: () => ref.invalidate(
                expensesByBranchProvider(effectiveBranchId ?? ''),
              ),
            )
          else if (expenses.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'এখনো কোনো খরচ লেখা হয়নি',
              message: 'খরচ লিখলে এখানে দেখা যাবে।',
            )
          else
            ...expenses.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const ListIcon(icon: Icons.shopping_bag_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.description.isEmpty
                                      ? e.category
                                      : e.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${e.category} • ${branchName(e.branchId)} • '
                                  '${isMissingDate(e.date) ? "তারিখ নেই" : "${e.date.day}/${e.date.month}/${e.date.year}"}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatTaka(e.amount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (isAdmin)
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => EditExpenseDialog(expense: e),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('বদলান'),
                            ),
                            const Spacer(),
                            // F6: "মুছুন" শুধু সুপার অ্যাডমিন দেখে।
                            if (isSuperAdmin)
                              TextButton.icon(
                                onPressed: () => _deleteExpense(e),
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
                ),
              ),
            ),
        ],
      ),
    );
  }
}
