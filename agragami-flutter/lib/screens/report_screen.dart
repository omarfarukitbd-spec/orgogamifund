import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/branch.dart';
import '../models/membership.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/report_pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/not_member_gate.dart';
import 'passbook_screen.dart';
import 'reports/defaulters_list_view.dart';
import 'reports/monthly_report_breakdown.dart';

/// মাসিক রিপোর্ট স্ক্রিন — এইচটিএমএল প্রিভিউয়ের মতো রিপোর্ট ও বকেয়া তালিকা।
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
        .where(
          (l) => l.dateIssued.year == _year && l.dateIssued.month == _month,
        )
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      DropdownMenuItem(
                        value: m,
                        child: Text(bengaliMonths[m - 1]),
                      ),
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
          Row(
            children: [
              Expanded(
                child: _tabButton('মাসের হিসাব', 'report'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tabButton('বকেয়া সদস্য', 'defaulters'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tab == 'report')
            MonthlyReportBreakdown(
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
                  setState(
                    () => _error = 'PDF তৈরি করা যায়নি — আবার চেষ্টা করুন',
                  );
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            )
          else
            DefaultersListView(
              branchId: effectiveBranchId,
              onCall: (phone) => _launch('tel:$phone'),
              onWhatsApp: (phone) => _launch(
                'https://wa.me/${_waNumber(phone)}?text=${Uri.encodeComponent('আসসালামু আলাইকুম, এই মাসের জমাটা এখনো বাকি আছে। অনুগ্রহ করে জমা দিয়ে দেবেন। — অগ্রগামী ফান্ড')}',
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabButton(String label, String tabKey) {
    final active = _tab == tabKey;
    return InkWell(
      onTap: () => setState(() => _tab = tabKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.green : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.green : AppColors.line,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
