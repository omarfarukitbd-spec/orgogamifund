import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../utils/admin_branch_scope.dart';
import '../utils/bn_digits.dart';
import '../utils/firebase_errors.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import 'deposit/deposit_components.dart';
import 'deposit/deposit_form_fields.dart';
import 'passbook_screen.dart';

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
  // অ্যাডমিন অন্য সদস্যের হয়ে জমা দিলে সেই সদস্য (M2)।
  String? _adminMemberId;
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
            child: Text(AppStrings.cancel),
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
    String? memberId,
    bool isAdmin,
  ) async {
    void showError(String msg) {
      setState(() => _error = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }

    // M2: সদস্য রেকর্ড না পেলে আন্দাজে UID বা অন্য সমিতির
    // সদস্য লেখা হয় না — জমা আটকে স্পষ্ট বার্তা দেওয়া হয়।
    if (memberId == null) {
      showError(
        isAdmin
            ? 'কোন সদস্যের হয়ে জমা দিচ্ছেন, বেছে নিন'
            : 'এই সমিতিতে আপনার সদস্য রেকর্ড পাওয়া যায়নি — অ্যাডমিনের সাথে যোগাযোগ করুন',
      );
      return;
    }
    final chosen = methods.where((m) => m.id == _methodId).firstOrNull;
    final amount = parseAmount(_amount.text);
    if (chosen == null) {
      showError('কীভাবে টাকা পাঠিয়েছেন, বেছে নিন');
      return;
    }
    if (amount == null || amount <= 0) {
      showError('টাকার সঠিক পরিমাণ লিখুন');
      return;
    }
    final trxId = _trxId.text.trim();
    if (chosen.type != PaymentMethodType.cash && trxId.isEmpty) {
      showError('লেনদেন নম্বর (TrxID) লিখুন');
      return;
    }
    if (chosen.type == PaymentMethodType.mobileBanking &&
        _senderMobile.text.trim().isEmpty) {
      showError('যে নম্বর থেকে টাকা পাঠিয়েছেন, সেটা লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = ref.read(firestoreServiceProvider);
      if (trxId.isNotEmpty) {
        // F7: F2-এর নতুন rules-এ নিজের সমিতির জমা সব সদস্য
        // পড়তে পারে, তাই এই যাচাই আর permission-denied খায়
        // না। তবুও সুরক্ষা হিসেবে: যাচাই করা না গেলে জমা
        // আটকে রাখা হয় না — নিশ্চিত করে এগোনো যায়।
        bool used;
        try {
          used = await store.trxIdAlreadyUsed(
            paymentMethodId: chosen.id,
            trxId: trxId,
            branchId: branchId,
          );
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
          if (!mounted) return;
          final proceedAnyway = await _askConfirm(
            'TrxID যাচাই করা যায়নি — অনুমতির সমস্যা। তবুও পাঠাবেন?',
          );
          if (!proceedAnyway) {
            setState(() => _busy = false);
            return;
          }
          used = false;
        }
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
      // m7: একই মাসের জমা আগেই থাকলে নিশ্চিত করা হয় —
      // ভুলে দুইবার মাসিক জমা দেওয়া আটকায়।
      final duplicateMonth = await store.hasPaymentForMonth(
        memberId: memberId,
        forYear: _year,
        forMonth: _month,
      );
      if (duplicateMonth && mounted) {
        final proceed = await _askConfirm(
          'এই সদস্যের ${bengaliMonths[_month - 1]} $_year মাসের জমা আগেই আছে। তবুও পাঠাবেন?',
        );
        if (!proceed) {
          setState(() => _busy = false);
          return;
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
            : toAsciiDigits(_senderMobile.text.trim()),
        forMonth: _month,
        forYear: _year,
        date: DateTime.now(),
        recordedBy: AuthService().uidOrEmpty,
        status: PaymentStatus.pending,
      );
      await store.submitPayment(payment);
      if (!mounted) return;
      // M12: জমা পাঠানোর পর মোট হিসাব তাজা হয়।
      invalidateTotals(ref);
      setState(() {
        _submittedSuccess = true;
        _amount.clear();
        _trxId.clear();
        _senderMobile.clear();
        _methodId = null;
      });
    } catch (e) {
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'জমা পাঠানো যায়নি — নেট দেখে আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedSuccess) {
      return DepositSuccessView(
        onViewPassbook: () => context.goNamed('passbook'),
        onDepositAgain: () => setState(() => _submittedSuccess = false),
      );
    }

    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final isBranchAdmin = isAdmin && !isSuperAdmin;
    final uid = user?.id ?? AuthService().uidOrEmpty;
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
    // Phase 8 (G4): শাখা অ্যাডমিনের ড্রপডাউন F5 প্যাটার্নে —
    // নিজের সমিতি + অনুমোদিত সদস্যপদ (G3-এর নিয়ম)। আগে
    // শাখা অ্যাডমিনও সুপার অ্যাডমিনের মতো সব সমিতি দেখত।
    final allowedIds = scopedBranchIds(
      isSuperAdmin: isSuperAdmin,
      isBranchAdmin: isBranchAdmin,
      adminBranchId: user?.branchId,
      approvedIds: approvedBranchIds(memberships),
    );
    if (!isAdmin && (allowedIds == null || allowedIds.isEmpty)) {
      return const NotMemberGate();
    }
    if (isBranchAdmin && (allowedIds == null || allowedIds.isEmpty)) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'আপনার সমিতি ঠিক করা নেই',
        message: 'সুপার অ্যাডমিনের সাথে যোগাযোগ করুন।',
      );
    }
    final branchesAsync = ref.watch(branchesStreamProvider);
    final allBranches = branchesAsync.valueOrNull ?? const <Branch>[];
    final branches = allowedIds == null
        ? allBranches
        : allBranches.where((b) => allowedIds.contains(b.id)).toList();
    final effectiveBranchId =
        _branchId != null && branches.any((b) => b.id == _branchId)
            ? _branchId
            : null;

    final myMembersAsync = ref.watch(membersForUserProvider(uid));
    final myMembers = myMembersAsync.valueOrNull ?? const <Member>[];
    // M2: এই সমিতিতে নিজের সদস্য রেকর্ড — না থাকলে null,
    // আন্দাজে UID বা অন্য সমিতির সদস্য নয়।
    String? memberIdFor(String branchId) {
      if (isAdmin && _adminMemberId != null) return _adminMemberId;
      final found = myMembers.where((m) => m.branchId == branchId).toList();
      if (found.isNotEmpty) return found.first.id;
      return null;
    }

    final branchMembersAsync = effectiveBranchId == null || !isAdmin
        ? const AsyncValue<List<Member>>.data([])
        : ref.watch(activeMembersByBranchProvider(effectiveBranchId));
    final branchMembers =
        branchMembersAsync.valueOrNull ?? const <Member>[];
    final effectiveAdminMemberId =
        _adminMemberId != null &&
                branchMembers.any((m) => m.id == _adminMemberId)
            ? _adminMemberId
            : null;

    final methodsAsync = effectiveBranchId == null
        ? const AsyncValue<List<PaymentMethodConfig>>.data([])
        : ref.watch(activePaymentMethodsProvider(effectiveBranchId));
    final effectiveBranch = effectiveBranchId == null
        ? null
        : branches
            .where((b) => b.id == effectiveBranchId)
            .firstOrNull;
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
          // অ্যাডমিন অন্য সদস্যের হয়ে জমা দিতে পারে (M2)।
          if (isAdmin && effectiveBranchId != null) ...[
            DropdownButtonFormField<String>(
              initialValue: effectiveAdminMemberId,
              decoration: const InputDecoration(
                labelText: 'কোন সদস্যের হয়ে জমা দিচ্ছেন',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              items: branchMembers
                  .map(
                    (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _adminMemberId = v),
            ),
            // Phase 8 (G4): সদস্যের প্রশ্ন ভাঙলে (অনুমতি নেই
            // বা নেট সমস্যা) "কোনো সদস্য নেই" ভুল বার্তা না
            // দেখিয়ে ভুলই দেখানো হয় — সাথে আবার চেষ্টা।
            if (branchMembersAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'সদস্যের তালিকা আনা যায়নি — নেট দেখে আবার চেষ্টা করুন',
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        activeMembersByBranchProvider(effectiveBranchId),
                      ),
                      child: Text(AppStrings.tryAgain),
                    ),
                  ],
                ),
              )
            else if (!branchMembersAsync.isLoading &&
                branchMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'এই সমিতিতে এখনো কোনো সদস্য নেই — আগে সদস্য অনুমোদন করুন',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 12),
          ],
          DepositFormFields(
            branches: branches,
            effectiveBranchId: effectiveBranchId,
            onBranchChanged: (v) => setState(() {
              _branchId = v;
              _methodId = null;
              _adminMemberId = null;
            }),
            bankDetails: effectiveBranch?.bankDetails,
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
                  isAdmin,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
