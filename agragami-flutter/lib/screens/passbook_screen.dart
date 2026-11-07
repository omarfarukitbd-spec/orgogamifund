import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/branch.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/dues.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';

/// টাকা লেখার রূপ — ৳১২,৫০০ এর বদলে ৳12,500, যাতে সব
/// ডিভাইসে একইভাবে দেখায়।
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
final _loansProvider = StreamProvider.family<List<Loan>, String>(
  (ref, id) => FirestoreService().watchMemberLoans(id),
);
final _branchesProvider = StreamProvider<List<Branch>>(
  (ref) => FirestoreService().watchBranches(),
);

/// সদস্যের পাসবই — নিজের হিসাব এক জায়গায়।
/// উপরে পরিচয়, তারপর মোট জমা, বকেয়া, ঋণ আর বাকি জমা,
/// ১২ মাসের জমার ছক, আর নিচে লেনদেনের খাতা।
/// আসল ডেটা না থাকলে '—' আর খালি অবস্থা দেখায় — কোনো
/// টাকার সংখ্যা বানানো হয় না।
/// একাধিক সমিতির সদস্য হলে উপরে সমিতি বেছে নেওয়া যায়;
/// কোনো সমিতির সদস্য না হলে আবেদনের পথ দেখানো হয়।
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
              return _PassbookBody(memberId: active.first.id);
            }
            final chosenId = _memberId ?? active.first.id;
            final chosen = active
                .where((m) => m.id == chosenId)
                .toList(growable: false);
            final member =
                chosen.isEmpty ? active.first : chosen.first;
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
                Expanded(child: _PassbookBody(memberId: member.id)),
              ],
            );
          },
        );
      },
    );
  }
}

/// একাধিক সমিতির সদস্য হলে কোন সমিতির পাসবই দেখবে — সেটা।
class _MemberPicker extends ConsumerWidget {
  final List<Member> members;
  final String selectedId;
  final void Function(String) onChanged;

  const _MemberPicker({
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
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

class _PassbookBody extends ConsumerWidget {
  final String memberId;

  const _PassbookBody({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(_memberProvider(memberId));
    final paymentsAsync = ref.watch(_paymentsProvider(memberId));
    final loansAsync = ref.watch(_loansProvider(memberId));
    final branchesAsync = ref.watch(_branchesProvider);

    if (memberAsync.isLoading ||
        paymentsAsync.isLoading ||
        loansAsync.isLoading ||
        branchesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      );
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
    final loans = loansAsync.valueOrNull ?? const <Loan>[];
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final branch = branches
        .where((b) => b.id == member.branchId)
        .toList(growable: false);
    final branchOrNull = branch.isEmpty ? null : branch.first;

    final approved =
        payments.where((p) => p.status == PaymentStatus.approved).toList();
    final pending =
        payments.where((p) => p.status == PaymentStatus.pending).toList();
    final totalDeposit = approved.fold(0, (sum, p) => sum + p.amount);
    final pendingTotal = pending.fold(0, (sum, p) => sum + p.amount);
    final activeLoan = loans
        .where((l) => l.status == LoanStatus.active)
        .fold(0, (sum, l) => sum + l.outstanding);

    int? dues;
    if (branchOrNull != null) {
      // বকেয়া গোনা শুরু হয় সদস্যের যোগদান আর সমিতির শুরুর
      // তারিখের মধ্যে যেটা পরে, সেখান থেকে — সমিতি শুরু
      // হওয়ার আগের মাসগুলো আর গোনা হয় না।
      dues = memberDues(
        joinDate: member.joinDate,
        branchStart: branchOrNull.startDate,
        monthlyDonation: branchOrNull.monthlyDonation,
        approvedTotal: totalDeposit,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(member: member, branchName: branchOrNull?.name),
          const SizedBox(height: 12),
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
                  label: 'বকেয়া',
                  value: dues == null ? '—' : formatTaka(dues),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.handshake_outlined,
                  label: 'চলতি কর্জে হাসানা',
                  value: formatTaka(activeLoan),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.hourglass_top_outlined,
                  label: 'যাচাইাধীন জমা',
                  value: formatTaka(pendingTotal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${DateTime.now().year} সালের জমা',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _MonthGrid(payments: payments),
          const SizedBox(height: 20),
          Text(
            'লেনদেনের খাতা',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _Ledger(payments: payments),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Member member;
  final String? branchName;

  const _ProfileHeader({required this.member, this.branchName});

  @override
  Widget build(BuildContext context) {
    final url = member.photoUrl;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage:
                url != null && url.isNotEmpty ? NetworkImage(url) : null,
            child: url == null || url.isEmpty
                ? const Icon(Icons.person_outlined, size: 36)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text('সমিতি: ${branchName ?? '—'}'),
                Text('সদস্য নম্বর: ${member.id}'),
                Text('ফোন: ${member.phone}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final List<Payment> payments;

  const _MonthGrid({required this.payments});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AppCard(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
        ),
        itemCount: 12,
        itemBuilder: (context, i) {
          final month = i + 1;
          final isFuture = month > now.month;
          final approved = payments.any(
            (p) =>
                p.forMonth == month &&
                p.forYear == now.year &&
                p.status == PaymentStatus.approved,
          );
          final pending = payments.any(
            (p) =>
                p.forMonth == month &&
                p.forYear == now.year &&
                p.status == PaymentStatus.pending,
          );
          final Color color;
          final String state;
          if (isFuture) {
            color = Colors.grey;
            state = '—';
          } else if (approved) {
            color = Colors.green;
            state = 'জমা হয়েছে';
          } else if (pending) {
            color = Colors.amber.shade800;
            state = 'যাচাইাধীন';
          } else {
            color = Colors.grey;
            state = 'বাকি';
          }
          return Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bengaliMonths[i],
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
                Text(state, style: TextStyle(fontSize: 11, color: color)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Ledger extends StatefulWidget {
  final List<Payment> payments;

  const _Ledger({required this.payments});

  @override
  State<_Ledger> createState() => _LedgerState();
}

class _LedgerState extends State<_Ledger> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final shown = widget.payments.where((p) {
      if (_filter == 'approved') return p.status == PaymentStatus.approved;
      if (_filter == 'pending') return p.status == PaymentStatus.pending;
      return true;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _chip('সকল', 'all'),
            _chip('অনুমোদিত', 'approved'),
            _chip('যাচাইাধীন', 'pending'),
          ],
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'এই তালিকায় কিছু নেই',
            message: 'জমা দিলে এখানে দেখা যাবে।',
          )
        else
          ...shown.map((p) => _LedgerRow(payment: p)),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final Payment payment;

  const _LedgerRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final statusText = switch (payment.status) {
      PaymentStatus.approved => 'অনুমোদিত',
      PaymentStatus.pending => 'যাচাইাধীন',
      PaymentStatus.rejected => 'বাতিল',
    };
    final methodText = payment.methodLabel;
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.receipt_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bengaliMonths[payment.forMonth - 1]} ${payment.forYear} — $methodText',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${payment.date.day}/${payment.date.month}/${payment.date.year}'
                  ' • TrxID: ${payment.trxId ?? '—'}'
                  ' • $statusText',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (payment.receiptNumber != null)
                  Text(
                    'রসিদ: ${payment.receiptNumber}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Text(
            formatTaka(payment.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
