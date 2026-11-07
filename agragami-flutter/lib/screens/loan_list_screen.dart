import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/branch.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
import 'passbook_screen.dart';

/// কর্জে হাসানা ঋণের তালিকা — কে কত নিয়েছে, কত ফেরত
/// দিয়েছে, কত বাকি। সুদের কোনো কথা এখানে নেই।
/// সদস্য শুধু নিজের সমিতির ঋণ দেখে — অন্য সমিতির ঋণের
/// জন্য প্রশ্নই পাঠানো হয় না।
class LoanListScreen extends ConsumerStatefulWidget {
  const LoanListScreen({super.key});

  @override
  ConsumerState<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends ConsumerState<LoanListScreen> {
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
    final effectiveBranchId = isAdmin
        ? _branchId
        : (_branchId != null && branches.any((b) => b.id == _branchId)
            ? _branchId
            : (branches.isEmpty ? null : branches.first.id));
    final loansAsync = ref.watch(
      StreamProvider<List<Loan>>(
        (ref) => FirestoreService().watchLoans(branchId: effectiveBranchId),
      ),
    );
    // সদস্যের নাম শুধু ওই সমিতির সদস্যদের মধ্যেই খোঁজা হয়।
    final membersAsync = ref.watch(
      StreamProvider<List<Member>>(
        (ref) => FirestoreService().watchMembers(branchId: effectiveBranchId),
      ),
    );
    final loans = loansAsync.valueOrNull ?? const <Loan>[];
    final members = membersAsync.valueOrNull ?? const <Member>[];
    final active = loans.where((l) => l.status == LoanStatus.active).toList();
    final outstandingTotal =
        active.fold(0, (sum, l) => sum + l.outstanding);

    String memberName(String id) {
      final found = members.where((m) => m.id == id).toList();
      return found.isEmpty ? '—' : found.first.name;
    }

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
            icon: Icons.handshake_outlined,
            label: 'মোট বাকি ঋণ',
            value: loansAsync.isLoading ? '—' : formatTaka(outstandingTotal),
            note: '${active.length}টি চলতি ঋণ',
          ),
          const SizedBox(height: 12),
          if (isAdmin)
            ElevatedButton.icon(
              onPressed: () => context.go('/loans/add'),
              icon: const Icon(Icons.add_outlined),
              label: const Text('ঋণ দিন'),
            ),
          const SizedBox(height: 16),
          if (loansAsync.isLoading)
            const SkeletonCardList()
          else if (loans.isEmpty)
            const EmptyState(
              icon: Icons.handshake_outlined,
              title: 'এখনো কোনো ঋণ দেওয়া হয়নি',
              message: 'ঋণ দিলে এখানে দেখা যাবে।',
            )
          else
            ...loans.map(
              (loan) => AppCard(
                onTap: () => context.go('/loans/${loan.id}'),
                child: Row(
                  children: [
                    const Icon(Icons.handshake_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName(loan.memberId),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${loan.reason} • ${loan.dateIssued.day}/${loan.dateIssued.month}/${loan.dateIssued.year}'
                            ' • ${loan.status == LoanStatus.repaid ? 'ফেরত দেওয়া হয়েছে' : 'চলছে'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatTaka(loan.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'বাকি ${formatTaka(loan.outstanding)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
