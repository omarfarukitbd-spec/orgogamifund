import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/expense.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    final membershipsAsync = ref.watch(myMembershipsProvider);
    if (membershipsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final memberships = membershipsAsync.valueOrNull ?? const <Membership>[];
    final allowedIds = isAdmin ? null : approvedBranchIds(memberships);
    if (!isAdmin && (allowedIds == null || allowedIds.isEmpty)) {
      return const NotMemberGate();
    }
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final allBranches = branchesAsync.valueOrNull ?? const <Branch>[];
    final branches = allowedIds == null
        ? allBranches
        : allBranches.where((b) => allowedIds.contains(b.id)).toList();
    // সদস্যের ক্ষেত্রে সমিতি ঠিক করা না থাকলে নিজের প্রথম
    // সমিতিটাই দেখানো হয় — "সব সমিতি" এখানে নেই, কারণ
    // অন্য সমিতির খরচের প্রশ্ন পাঠানোই যাবে না।
    final effectiveBranchId = isAdmin
        ? _branchId
        : (_branchId != null && branches.any((b) => b.id == _branchId)
            ? _branchId
            : (branches.isEmpty ? null : branches.first.id));
    final expensesAsync = ref.watch(
      StreamProvider<List<Expense>>(
        (ref) => FirestoreService().watchExpenses(branchId: effectiveBranchId),
      ),
    );
    final expenses = expensesAsync.valueOrNull ?? const <Expense>[];
    final total = expenses.fold(0, (sum, e) => sum + e.amount);
    final branchName = (id) {
      final found = allBranches.where((b) => b.id == id).toList();
      return found.isEmpty ? '—' : found.first.name;
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: effectiveBranchId,
            decoration: const InputDecoration(
              labelText: 'কোন সমিতি',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            items: [
              if (isAdmin)
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
            value: expensesAsync.isLoading ? '—' : formatTaka(total),
            note: '${expenses.length}টি খরচ',
          ),
          const SizedBox(height: 12),
          if (isAdmin)
            ElevatedButton.icon(
              onPressed: () => context.go('/expenses/add'),
              icon: const Icon(Icons.add_outlined),
              label: const Text(AppStrings.addExpense),
            ),
          const SizedBox(height: 16),
          if (expensesAsync.isLoading)
            const SkeletonCardList()
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
                  child: Row(
                    children: [
                      const ListIcon(icon: Icons.shopping_bag_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.description.isEmpty ? e.category : e.description,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e.category} • ${branchName(e.branchId)} • '
                              '${e.date.day}/${e.date.month}/${e.date.year}',
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
                ),
              ),
            ),
        ],
      ),
    );
  }
}
