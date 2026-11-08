import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/not_member_gate.dart';
import 'deposit/deposit_components.dart';
import 'deposit/deposit_form_fields.dart';

/// জমা দেওয়ার স্ক্রিন — ৩ ধাপের নির্দেশক, পেমেন্ট মাধ্যম ও নিশ্চিতকরণ।
class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amount = TextEditingController();
  final _trxId = TextEditingController();
  final _senderMobile = TextEditingController();
  String? _branchId;
  String? _methodId;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _busy = false;
  bool _submittedSuccess = false;
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
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('তবুও পাঠান'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _submit(
    List<PaymentMethodConfig> methods,
    String branchId,
    String memberId,
  ) async {
    final chosen = methods.where((m) => m.id == _methodId).firstOrNull;
    final amount = int.tryParse(_amount.text.trim());
    if (chosen == null) {
      setState(() => _error = 'কীভাবে টাকা পাঠিয়েছেন, বেছে নিন');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'টাকার সঠিক পরিমাণ লিখুন');
      return;
    }
    final trxId = _trxId.text.trim();
    if (chosen.type != PaymentMethodType.cash && trxId.isEmpty) {
      setState(() => _error = 'লেনদেন নম্বর (TrxID) লিখুন');
      return;
    }
    if (chosen.type == PaymentMethodType.mobileBanking &&
        _senderMobile.text.trim().isEmpty) {
      setState(() => _error = 'যে নম্বর থেকে টাকা পাঠিয়েছেন, সেটা লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = FirestoreService();
      if (trxId.isNotEmpty) {
        final used = await store.trxIdAlreadyUsed(
          paymentMethodId: chosen.id,
          trxId: trxId,
          branchId: branchId,
        );
        if (used && mounted) {
          final proceed = await _askConfirm(
            'এই TrxID দিয়ে আগেই একটি জমা দেওয়া হয়েছে। '
            'ভুলে দুইবার জমা দিচ্ছেন কি না দেখে নিন। তবুও পাঠাবেন?',
          );
          if (!proceed) {
            setState(() => _busy = false);
            return;
          }
        }
      }
      final payment = Payment(
        id: '',
        memberId: memberId,
        branchId: branchId,
        type: PaymentType.monthly,
        amount: amount,
        method: switch (chosen.type) {
          PaymentMethodType.mobileBanking => PaymentMethodKind.mobileBanking,
          PaymentMethodType.bank => PaymentMethodKind.bank,
          PaymentMethodType.cash => PaymentMethodKind.cash,
        },
        trxId: trxId.isEmpty ? null : trxId,
        paymentMethodId: chosen.id,
        paymentMethodName: chosen.name,
        paymentAccountNumber: chosen.accountNumber,
        senderMobile: _senderMobile.text.trim().isEmpty
            ? null
            : _senderMobile.text.trim(),
        forMonth: _month,
        forYear: _year,
        date: DateTime.now(),
        recordedBy: AuthService().uidOrEmpty,
        status: PaymentStatus.pending,
      );
      await store.submitPayment(payment);
      if (!mounted) return;
      setState(() {
        _submittedSuccess = true;
        _amount.clear();
        _trxId.clear();
        _senderMobile.clear();
        _methodId = null;
      });
    } catch (_) {
      setState(() => _error = 'জমা পাঠানো যায়নি — নেট দেখে আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedSuccess) {
      return DepositSuccessView(
        onViewPassbook: () => context.go('/passbook'),
        onDepositAgain: () => setState(() => _submittedSuccess = false),
      );
    }

    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final uid = user?.id ?? AuthService().uidOrEmpty;
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
      StreamProvider<List<Branch>>(
        (ref) => FirestoreService().watchBranches(),
      ),
    );
    final allBranches = branchesAsync.valueOrNull ?? const <Branch>[];
    final branches = allowedIds == null
        ? allBranches
        : allBranches.where((b) => allowedIds.contains(b.id)).toList();
    final effectiveBranchId =
        _branchId != null && branches.any((b) => b.id == _branchId)
            ? _branchId
            : null;

    final myMembersAsync = ref.watch(
      StreamProvider<List<Member>>(
        (ref) => FirestoreService().watchMembersForUser(uid),
      ),
    );
    final myMembers = myMembersAsync.valueOrNull ?? const <Member>[];
    String memberIdFor(String branchId) {
      final found = myMembers.where((m) => m.branchId == branchId).toList();
      if (found.isNotEmpty) return found.first.id;
      return user?.linkedMemberId ?? uid;
    }

    final methodsAsync = effectiveBranchId == null
        ? const AsyncValue<List<PaymentMethodConfig>>.data([])
        : ref.watch(
            StreamProvider<List<PaymentMethodConfig>>(
              (ref) => FirestoreService().watchActivePaymentMethods(
                branchId: effectiveBranchId,
              ),
            ),
          );
    final methods = methodsAsync.valueOrNull ?? const <PaymentMethodConfig>[];
    final loadingMethods =
        effectiveBranchId != null && methodsAsync is AsyncLoading;

    int currentStep = 1;
    if (effectiveBranchId != null && _methodId != null) {
      currentStep = 3;
    } else if (effectiveBranchId != null) {
      currentStep = 2;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DepositStepsBar(currentStep: currentStep),
          const SizedBox(height: 14),
          DepositFormFields(
            branches: branches,
            effectiveBranchId: effectiveBranchId,
            onBranchChanged: (v) => setState(() {
              _branchId = v;
              _methodId = null;
            }),
            methods: methods,
            loadingMethods: loadingMethods,
            methodId: _methodId,
            onMethodSelected: (id) => setState(() => _methodId = id),
            month: _month,
            onMonthChanged: (m) => setState(() => _month = m),
            year: _year,
            onYearChanged: (y) => setState(() => _year = y),
            amountController: _amount,
            senderMobileController: _senderMobile,
            trxIdController: _trxId,
            error: _error,
            busy: _busy,
            onSubmit: () {
              if (effectiveBranchId != null) {
                _submit(
                  methods,
                  effectiveBranchId,
                  memberIdFor(effectiveBranchId),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
