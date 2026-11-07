import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/branch.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/report_pdf_service.dart';
import '../utils/dues.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
import 'passbook_screen.dart';

/// মাসিক রিপোর্ট — এক মাসের আয়, ব্যয়, ঋণ আর নিট হিসাব।
/// নিচে একই পাতায় বকেয়া সদস্যদের তালিকা — ফোন আর
/// হোয়াটসঅ্যাপে মনে করিয়ে দেওয়ার বোতামসহ।
/// সদস্য শুধু নিজের সমিতির রিপোর্ট দেখে — অন্য সমিতির
/// হিসাব বা বকেয়া তালিকার জন্য প্রশ্নই পাঠানো হয় না।
/// অ্যাডমিন সব সমিতি দেখতে পারে।
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? _branchId;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  String _tab = 'report';
  bool _busy = false;
  String? _error;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _waNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) return '880${digits.substring(1)}';
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(firestoreServiceProvider);
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
      StreamProvider<List<Branch>>((ref) => store.watchBranches()),
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
    final branchName = () {
      final found =
          allBranches.where((b) => b.id == effectiveBranchId).toList();
      return found.isEmpty ? 'সব সমিতি' : found.first.name;
    }();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _month,
                  decoration: const InputDecoration(labelText: 'মাস'),
                  items: [
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(value: m, child: Text(bengaliMonths[m - 1])),
                  ],
                  onChanged: (v) => setState(() => _month = v ?? _month),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(labelText: 'বছর'),
                  items: [
                    for (var y = DateTime.now().year - 2;
                        y <= DateTime.now().year;
                        y++)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setState(() => _year = v ?? _year),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('মাসের হিসাব'),
                selected: _tab == 'report',
                onSelected: (_) => setState(() => _tab = 'report'),
              ),
              ChoiceChip(
                label: const Text('বকেয়া সদস্য'),
                selected: _tab == 'defaulters',
                onSelected: (_) => setState(() => _tab = 'defaulters'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tab == 'report')
            _MonthlyReport(
              store: store,
              branchId: effectiveBranchId,
              branchName: branchName,
              month: _month,
              year: _year,
              busy: _busy,
              onPdf: () async {
                setState(() {
                  _busy = true;
                  _error = null;
                });
                try {
                  final data = await _loadMonth(store, effectiveBranchId);
                  if (!mounted) return;
                  await ReportPdfService().shareMonthlyReport(
                    branchName: branchName,
                    year: _year,
                    month: _month,
                    income: data['income']!,
                    expenses: data['expenses']!,
                    loansGiven: data['loansGiven']!,
                    repayments: data['repayments']!,
                  );
                } catch (_) {
                  setState(() => _error = 'PDF বানানো যায়নি — আবার চেষ্টা করুন');
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            )
          else
            _DefaulterList(
              branchId: effectiveBranchId,
              onCall: (phone) => _launch('tel:$phone'),
              onWhatsApp: (phone) => _launch(
                'https://wa.me/${_waNumber(phone)}?text=${Uri.encodeComponent('আসসালামু আলাইকুম, এই মাসের জমাটা এখনো বাকি আছে। অনুগ্রহ করে জমা দিয়ে দেবেন। — অগ্রগামী ফান্ড')}',
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }

  Future<Map<String, int>> _loadMonth(
    FirestoreService store,
    String? branchId,
  ) async {
    final payments = await store.fetchPaymentsForMonth(
      year: _year,
      month: _month,
      branchId: branchId,
    );
    final expenses = await store.fetchExpensesForMonth(
      year: _year,
      month: _month,
      branchId: branchId,
    );
    final loans = await store.fetchLoans(branchId: branchId);
    final income = payments
        .where((p) => p.status == PaymentStatus.approved)
        .fold(0, (sum, p) => sum + p.amount);
    final expenseTotal = expenses.fold(0, (sum, e) => sum + e.amount);
    final loansGiven = loans
        .where((l) =>
            l.dateIssued.year == _year && l.dateIssued.month == _month)
        .fold(0, (sum, l) => sum + l.amount);
    final repayments = loans.fold(0, (sum, l) {
      return sum +
          l.repayments
              .where((r) => r.date.year == _year && r.date.month == _month)
              .fold(0, (s, r) => s + r.amount);
    });
    return {
      'income': income,
      'expenses': expenseTotal,
      'loansGiven': loansGiven,
      'repayments': repayments,
    };
  }
}

class _MonthlyReport extends StatelessWidget {
  final FirestoreService store;
  final String? branchId;
  final String branchName;
  final int month;
  final int year;
  final bool busy;
  final Future<void> Function() onPdf;

  const _MonthlyReport({
    required this.store,
    required this.branchId,
    required this.branchName,
    required this.month,
    required this.year,
    required this.busy,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SkeletonCardList();
        }
        if (snap.hasError || !snap.hasData) {
          return const EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'হিসাব আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
          );
        }
        final data = snap.data!;
        final income = data['income']!;
        final expenses = data['expenses']!;
        final loansGiven = data['loansGiven']!;
        final repayments = data['repayments']!;
        final net = income - expenses - loansGiven + repayments;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.arrow_downward_outlined,
                    label: 'জমা (আয়)',
                    value: formatTaka(income),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.arrow_upward_outlined,
                    label: 'খরচ',
                    value: formatTaka(expenses),
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
                    label: 'ঋণ দেওয়া হয়েছে',
                    value: formatTaka(loansGiven),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.replay_outlined,
                    label: 'কিস্তি ফেরত এসেছে',
                    value: formatTaka(repayments),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'মাসের নিট — $branchName',
              value: formatTaka(net),
              note: 'আয় − খরচ − ঋণ দেওয়া + কিস্তি ফেরত',
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: busy ? 'আসছে…' : 'PDF হিসেবে নিন',
              onPressed: busy ? null : onPdf,
              icon: Icons.picture_as_pdf_outlined,
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _load() async {
    final payments = await store.fetchPaymentsForMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    final expenses = await store.fetchExpensesForMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    final loans = await store.fetchLoans(branchId: branchId);
    final income = payments
        .where((p) => p.status == PaymentStatus.approved)
        .fold(0, (sum, p) => sum + p.amount);
    final expenseTotal = expenses.fold(0, (sum, e) => sum + e.amount);
    final loansGiven = loans
        .where((l) => l.dateIssued.year == year && l.dateIssued.month == month)
        .fold(0, (sum, l) => sum + l.amount);
    final repayments = loans.fold(0, (sum, l) {
      return sum +
          l.repayments
              .where((r) => r.date.year == year && r.date.month == month)
              .fold(0, (s, r) => s + r.amount);
    });
    return {
      'income': income,
      'expenses': expenseTotal,
      'loansGiven': loansGiven,
      'repayments': repayments,
    };
  }
}

class _DefaulterList extends ConsumerWidget {
  final String? branchId;
  final void Function(String phone) onCall;
  final void Function(String phone) onWhatsApp;

  const _DefaulterList({
    required this.branchId,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(firestoreServiceProvider);
    final membersAsync = ref.watch(
      StreamProvider<List<Member>>(
        (ref) => store.watchMembers(branchId: branchId),
      ),
    );
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => store.watchBranches()),
    );
    if (membersAsync.isLoading || branchesAsync.isLoading) {
      return const SkeletonCardList();
    }
    if (membersAsync.hasError || branchesAsync.hasError) {
      return const EmptyState(
        icon: Icons.error_outline,
        title: 'তথ্য আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
      );
    }
    final members = (membersAsync.valueOrNull ?? const <Member>[])
        .where((m) => m.active)
        .toList();
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    return FutureBuilder<List<Payment>>(
      future: store.fetchApprovedPayments(branchId: branchId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SkeletonCardList();
        }
        if (snap.hasError || !snap.hasData) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'তথ্য আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
          );
        }
        final approved = snap.data!;
        final now = DateTime.now();
        final defaulters =
            <({Member member, Branch branch, int dueMonths, int dueAmount})>[];
        for (final member in members) {
          final found =
              branches.where((b) => b.id == member.branchId).toList();
          if (found.isEmpty) continue;
          final branch = found.first;
          if (branch.monthlyDonation <= 0) continue;
          // যোগদানের পর থেকে এখন পর্যন্ত যত মাস পার হয়েছে,
          // সমিতির শুরুর তারিখের আগের মাসগুলো বাদ দিয়ে।
          final start = effectiveStart(member.joinDate, branch.startDate);
          final expected = monthsBetweenInclusive(start, now);
          // এই সদস্যের অনুমোদিত মাসিক জমা কত মাসের — এক মাসে
          // দুইবার জমা দিলেও মাস একবারই গোনা হয়।
          final paidMonths = approved
              .where(
                (p) =>
                    p.memberId == member.id && p.type == PaymentType.monthly,
              )
              .map((p) => '${p.forYear}-${p.forMonth}')
              .toSet()
              .length;
          final dueMonths = expected - paidMonths;
          if (dueMonths > 0) {
            defaulters.add(
              (
                member: member,
                branch: branch,
                dueMonths: dueMonths,
                dueAmount: dueMonths * branch.monthlyDonation,
              ),
            );
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'এই মাস পর্যন্ত যাদের জমা বাকি আছে — ফোন বা হোয়াটসঅ্যাপে মনে করিয়ে দিন।',
            ),
            const SizedBox(height: 12),
            if (defaulters.isEmpty)
              const EmptyState(
                icon: Icons.check_circle_outlined,
                title: 'এই মাসে কেউ বকেয়া নেই',
                message: 'সবার জমা সময়মতো এসেছে।',
              )
            else
              ...defaulters.map(
                (d) => AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${d.branch.name} • ${d.dueMonths} মাস বাকি • '
                              'বকেয়া ${formatTaka(d.dueAmount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call_outlined),
                        tooltip: 'ফোন করুন',
                        onPressed: () => onCall(d.member.phone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_outlined),
                        tooltip: 'হোয়াটসঅ্যাপ',
                        onPressed: () => onWhatsApp(d.member.phone),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
