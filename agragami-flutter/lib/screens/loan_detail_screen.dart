import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/skeleton_loader.dart';
import 'passbook_screen.dart';

/// একটি ঋণের বিস্তারিত — কত নিয়েছে, কত ফেরত দিয়েছে,
/// কত বাকি, আর কিস্তির খাতা। এখান থেকেই কিস্তি জমা নেওয়া যায়।
/// কিস্তির মাধ্যম কোডে লেখা থাকে না — অ্যাডমিন যে মাধ্যমগুলো
/// চালু রেখেছেন, শুধু সেগুলোই দেখায়; জমার মতো এখানেও
/// মাধ্যমের নাম-নম্বরের ছাপ কিস্তির সাথে লেখা থাকে।
/// ঋণটি যে সমিতির, সেই সমিতির সদস্য বা অ্যাডমিন না হলে
/// কিছু দেখা যায় না — সদস্যের নামও না।
class LoanDetailScreen extends ConsumerStatefulWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  final _amount = TextEditingController();
  final _trxId = TextEditingController();
  final _senderMobile = TextEditingController();
  String? _methodId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _trxId.dispose();
    _senderMobile.dispose();
    super.dispose();
  }

  Future<bool> _askConfirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নিশ্চিত করুন'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('তবুও জমা নিন'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _recordRepayment(
    Loan loan,
    List<PaymentMethodConfig> methods,
  ) async {
    final chosen = methods.where((m) => m.id == _methodId).firstOrNull;
    if (chosen == null) {
      setState(() => _error = 'কীভাবে টাকা দিল, বেছে নিন');
      return;
    }
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'টাকার সঠিক পরিমাণ লিখুন');
      return;
    }
    if (amount > loan.outstanding) {
      setState(() => _error = 'বাকির চেয়ে বেশি লেখা হয়েছে — আবার দেখুন');
      return;
    }
    final trxId = _trxId.text.trim();
    if (chosen.type != PaymentMethodType.cash && trxId.isEmpty) {
      setState(() => _error = 'লেনদেন নম্বর (TrxID) লিখুন');
      return;
    }
    if (chosen.type == PaymentMethodType.mobileBanking &&
        _senderMobile.text.trim().isEmpty) {
      setState(() => _error = 'যে নম্বর থেকে টাকা পাঠিয়েছে, সেটা লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = FirestoreService();
      if (trxId.isNotEmpty) {
        // একই TrxID এই ঋণে বা এই সমিতির অন্য জমায় আগেই
        // ব্যবহার হয়েছে কি না — থাকলে ভুলে দুইবার লেখা
        // হচ্ছে কি না জিজ্ঞেস করা হয়।
        final usedInLoan = loan.repayments.any(
          (r) => r.trxId == trxId && r.paymentMethodId == chosen.id,
        );
        final usedInPayments = await store.trxIdAlreadyUsed(
          paymentMethodId: chosen.id,
          trxId: trxId,
          branchId: loan.branchId,
        );
        if ((usedInLoan || usedInPayments) && mounted) {
          final proceed = await _askConfirm(
            'এই TrxID দিয়ে এই মাধ্যমেই আগেই একটি জমা দেওয়া হয়েছে। '
            'ভুলে দুইবার জমা নিচ্ছেন কি না দেখে নিন। তবুও জমা নেবেন?',
          );
          if (!proceed) {
            setState(() => _busy = false);
            return;
          }
        }
      }
      await store.recordRepayment(
        loan.id,
        LoanRepayment(
          amount: amount,
          date: DateTime.now(),
          method: chosen.type.name,
          paymentMethodId: chosen.id,
          paymentMethodName: chosen.name,
          paymentAccountNumber: chosen.accountNumber,
          trxId: trxId.isEmpty ? null : trxId,
          senderMobile: _senderMobile.text.trim().isEmpty
              ? null
              : _senderMobile.text.trim(),
        ),
        recordedBy: AuthService().uidOrEmpty,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কিস্তি জমা নেওয়া হয়েছে')),
      );
      setState(() {
        _amount.clear();
        _trxId.clear();
        _senderMobile.clear();
        _methodId = null;
      });
    } catch (_) {
      setState(() => _error = 'জমা নেওয়া যায়নি — নেট দেখে আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanAsync = ref.watch(
      StreamProvider<Loan?>(
        (ref) => FirestoreService().watchLoan(widget.loanId),
      ),
    );
    final userAsync = ref.watch(currentUserProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    final myBranchIds = approvedBranchIds(
      membershipsAsync.valueOrNull ?? const <Membership>[],
    );
    return loanAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) {
        // নিয়মে আটকে গেলে (permission-denied) মানে ওই সমিতির
        // সদস্য নয় — তখন আবেদনের পথ দেখানো হয়।
        if (e is FirebaseException && e.code == 'permission-denied') {
          return const NotMemberGate();
        }
        return const EmptyState(
          icon: Icons.error_outline,
          title: 'তথ্য আনা যায়নি',
          message: 'নেট দেখে আবার চেষ্টা করুন।',
        );
      },
      data: (loan) {
        if (loan == null) {
          return const EmptyState(
            icon: Icons.handshake_outlined,
            title: 'ঋণটি পাওয়া যায়নি',
            message: 'তালিকা থেকে আবার খুলে দেখুন।',
          );
        }
        // নিয়ম এখনো না বসানো থাকলেও স্ক্রিন নিজে আটকায় —
        // সদস্য নয় এমন কেউ ঋণের তথ্য দেখতে পায় না।
        if (!isAdmin && !myBranchIds.contains(loan.branchId)) {
          return NotMemberGate(branchId: loan.branchId);
        }
        final membersAsync = ref.watch(
          StreamProvider<List<Member>>(
            (ref) => FirestoreService().watchMembers(
              branchId: loan.branchId,
            ),
          ),
        );
        final members = membersAsync.valueOrNull ?? const <Member>[];
        final found = members.where((m) => m.id == loan.memberId).toList();
        final name = found.isEmpty ? '—' : found.first.name;
        final isRepaid = loan.status == LoanStatus.repaid;
        // এই সমিতির জন্য চালু মাধ্যমগুলো — বন্ধ মাধ্যম এখানে আসে না।
        final methodsAsync = ref.watch(
          StreamProvider<List<PaymentMethodConfig>>(
            (ref) => FirestoreService().watchActivePaymentMethods(
              branchId: loan.branchId,
            ),
          ),
        );
        final methods =
            methodsAsync.valueOrNull ?? const <PaymentMethodConfig>[];
        final chosen =
            methods.where((m) => m.id == _methodId).firstOrNull;
        final loadingMethods = methodsAsync is AsyncLoading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'কারণ: ${loan.reason}',
                      style: const TextStyle(fontSize: 14.5, color: Colors.grey),
                    ),
                    Text(
                      'তারিখ: ${loan.dateIssued.day}/${loan.dateIssued.month}/${loan.dateIssued.year}',
                      style: const TextStyle(fontSize: 14.5, color: Colors.grey),
                    ),
                    if (loan.monthlyInstallment != null &&
                        loan.installmentMonths != null)
                      Text(
                        'পরিকল্পনা: মাসে ${formatTaka(loan.monthlyInstallment!)} '
                        'করে ${loan.installmentMonths} মাসে',
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Colors.grey,
                        ),
                      ),
                    Text(
                      loan.status == LoanStatus.repaid
                          ? 'ফেরত দেওয়া হয়েছে'
                          : 'চলছে',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.payments_outlined,
                      label: 'মোট ঋণ',
                      value: formatTaka(loan.amount),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.handshake_outlined,
                      label: 'বাকি',
                      value: formatTaka(loan.outstanding),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'কিস্তি জমা নিন',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (isRepaid)
                const EmptyState(
                  icon: Icons.check_circle_outlined,
                  title: 'এই ঋণ পুরো ফেরত দেওয়া হয়েছে',
                  message: 'আর কিস্তি নেওয়ার কিছু নেই।',
                )
              else ...[
                if (loadingMethods)
                  const Center(child: CircularProgressIndicator())
                else if (methods.isEmpty)
                  const EmptyState(
                    icon: Icons.account_balance_outlined,
                    title: 'এই সমিতির জন্য এখনো কোনো পেমেন্ট মাধ্যম যোগ করা হয়নি',
                    message: 'অ্যাডমিন মাধ্যম যোগ করলে এখানে দেখা যাবে।',
                  )
                else
                  ...methods.map(
                    (m) => PaymentMethodCard(
                      method: m,
                      selected: _methodId == m.id,
                      onTap: () => setState(() => _methodId = m.id),
                    ),
                  ),
                const SizedBox(height: 4),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'কত টাকা জমা দিল',
                    prefixText: '৳ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                if (chosen != null &&
                    chosen.type == PaymentMethodType.mobileBanking) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _senderMobile,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'যে নম্বর থেকে পাঠিয়েছে',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
                if (chosen != null &&
                    chosen.type != PaymentMethodType.cash) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _trxId,
                    decoration: const InputDecoration(
                      labelText: 'লেনদেন নম্বর (TrxID)',
                      prefixIcon: Icon(Icons.receipt_outlined),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),
                PrimaryButton(
                  label: _busy ? 'আসছে…' : 'কিস্তি জমা নিন',
                  onPressed: _busy || methods.isEmpty
                      ? null
                      : () => _recordRepayment(loan, methods),
                  icon: Icons.check_outlined,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'কিস্তির খাতা',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (loan.repayments.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'এখনো কোনো কিস্তি জমা হয়নি',
                  message: 'কিস্তি জমা নিলে এখানে দেখা যাবে।',
                )
              else
                ...loan.repayments.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Row(
                        children: [
                          const ListIcon(
                            icon: Icons.receipt_outlined,
                            size: 36,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.date.day}/${r.date.month}/${r.date.year}'
                                  ' • ${r.methodLabel}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (r.trxId != null && r.trxId!.isNotEmpty)
                                  Text(
                                    'TrxID: ${r.trxId}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            formatTaka(r.amount),
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
      },
    );
  }
}
