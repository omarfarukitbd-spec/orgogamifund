import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/branch.dart';
import '../models/member.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/dues.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
import 'passbook/passbook_ledger.dart';
import 'passbook/passbook_month_grid.dart';

String formatTaka(int amount) {
  return '৳${NumberFormat('#,##0', 'en_US').format(amount)}';
}

const List<String> bengaliMonths = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

final _memberProvider = StreamProvider.family<Member?, String>(
  (ref, id) => FirestoreService().watchMember(id),
);
final _paymentsProvider = StreamProvider.family<List<Payment>, String>(
  (ref, id) => FirestoreService().watchMemberPayments(id),
);
final _branchesProvider = StreamProvider<List<Branch>>(
  (ref) => FirestoreService().watchBranches(),
);

/// সদস্যের পাসবই — ১২ মাসের ছক, মোট জমা ও বকেয়া, লেনদেনের খাতা।
class PassbookScreen extends ConsumerStatefulWidget {
  const PassbookScreen({super.key});

  @override
  ConsumerState<PassbookScreen> createState() => _PassbookScreenState();
}

class _PassbookScreenState extends ConsumerState<PassbookScreen> {
  String? _memberId;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) => const EmptyState(
        icon: Icons.error_outline,
        title: 'তথ্য আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
      ),
      data: (user) {
        final uid = user?.id ?? '';
        if (uid.isEmpty) {
          return const EmptyState(
            icon: Icons.book_outlined,
            title: 'তথ্য আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
          );
        }
        final membersAsync = ref.watch(
          StreamProvider<List<Member>>(
            (ref) => FirestoreService().watchMembersForUser(uid),
          ),
        );
        return membersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonCardList(),
          ),
          error: (e, _) => const EmptyState(
            icon: Icons.error_outline,
            title: 'তথ্য আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
          ),
          data: (members) {
            final active = members.where((m) => m.active).toList();
            if (active.isEmpty) {
              return const NotMemberGate();
            }
            if (active.length == 1) {
              return _PassbookContent(memberId: active.first.id);
            }
            final chosenId = _memberId ?? active.first.id;
            final chosen = active
                .where((m) => m.id == chosenId)
                .toList(growable: false);
            final member = chosen.isEmpty ? active.first : chosen.first;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _MemberPicker(
                    members: active,
                    selectedId: member.id,
                    onChanged: (id) => setState(() => _memberId = id),
                  ),
                ),
                Expanded(child: _PassbookContent(memberId: member.id)),
              ],
            );
          },
        );
      },
    );
  }
}

class _MemberPicker extends ConsumerWidget {
  final List<Member> members;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _MemberPicker({
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(_branchesProvider);
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    String branchName(String id) {
      final found = branches.where((b) => b.id == id).toList();
      return found.isEmpty ? 'সমিতি' : found.first.name;
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: 'কোন সমিতির পাসবই',
        prefixIcon: Icon(Icons.groups_outlined),
      ),
      items: members
          .map(
            (m) => DropdownMenuItem(
              value: m.id,
              child: Text(branchName(m.branchId)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _PassbookContent extends ConsumerWidget {
  final String memberId;

  const _PassbookContent({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(_memberProvider(memberId));
    final paymentsAsync = ref.watch(_paymentsProvider(memberId));
    final branchesAsync = ref.watch(_branchesProvider);

    if (memberAsync.isLoading || paymentsAsync.isLoading || branchesAsync.isLoading) {
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonCardList());
    }
    final member = memberAsync.valueOrNull;
    if (member == null) {
      return const EmptyState(
        icon: Icons.book_outlined,
        title: 'সদস্যের তথ্য পাওয়া যায়নি',
        message: 'অ্যাডমিনের সাথে যোগাযোগ করুন।',
      );
    }
    final payments = paymentsAsync.valueOrNull ?? const <Payment>[];
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final branch = branches
        .where((b) => b.id == member.branchId)
        .toList(growable: false);
    final branchOrNull = branch.isEmpty ? null : branch.first;

    final approved =
        payments.where((p) => p.status == PaymentStatus.approved).toList();
    final totalDeposit = approved.fold(0, (sum, p) => sum + p.amount);

    int? dues;
    if (branchOrNull != null) {
      dues = memberDues(
        joinDate: member.joinDate,
        branchStart: branchOrNull.startDate,
        monthlyDonation: branchOrNull.monthlyDonation,
        approvedTotal: totalDeposit,
      );
    }

    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // হেডার: নাম, সমিতি এবং পিল ট্যাগ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${branchOrNull?.name ?? "সমিতি"} · সদস্য নং: ${member.id}',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const PillTag(text: 'পাসবই'),
            ],
          ),
          const SizedBox(height: 14),

          // ২টি স্ট্যাট কার্ড (মোট জমা ও মোট বকেয়া)
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.savings_outlined,
                  label: 'মোট জমা',
                  value: formatTaka(totalDeposit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.pending_actions_outlined,
                  label: 'মোট বকেয়া',
                  value: dues == null ? '—' : formatTaka(dues),
                  isGold: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'বকেয়া গোনা হয় সদস্যের যোগ দেওয়ার তারিখ আর সমিতি শুরুর তারিখের মধ্যে যেটা পরে, সেখান থেকে।',
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),

          // ১২ মাসের ছক
          SectionTitle('${now.year} সালের ছক'),
          PassbookMonthGrid(payments: payments, year: now.year),

          // লেনদেনের খাতা
          const SectionTitle('লেনদেনের খাতা'),
          PassbookLedger(payments: payments),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
