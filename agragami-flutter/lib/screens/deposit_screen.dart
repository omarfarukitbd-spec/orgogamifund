import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/payment_method_card.dart';
import 'passbook_screen.dart';

/// জমা দেওয়ার ফরম — সমিতি, মাস, টাকা আর TrxID।
/// পেমেন্ট মাধ্যম কোডে লেখা থাকে না — অ্যাডমিন যেগুলো
/// চালু রেখেছেন, শুধু সেগুলোই দেখায়। কোনো নম্বর এখানে
/// বানানো হয় না; মাধ্যম যোগ করা না থাকলে পরিষ্কার
/// করে জানিয়ে দেওয়া হয়।
/// জমা হলে অবস্থা pending — অ্যাডমিন যাচাই করে অনুমোদন দেবেন,
/// তবেই পাসবইয়ে জমা হিসেবে উঠবে।
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

  /// জমা দেওয়া — শুধু নিজের সমিতিতে। সমিতি আর ওই সমিতির
  /// সদস্যের রেকর্ড — দুটোই আগে থেকে ঠিক করা থাকে।
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
            'এই TrxID দিয়ে এই মাধ্যমেই আগেই একটি জমা দেওয়া হয়েছে। '
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.depositSent)),
      );
      setState(() {
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
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final uid = user?.id ?? AuthService().uidOrEmpty;
    final membershipsAsync = ref.watch(myMembershipsProvider);
    // সদস্যপদ না জানা পর্যন্ত জমার ফরম দেখানো হয় না —
    // নইলে সদস্য নয় এমন ব্যবহারকারীকে ভুল করে আটকে দেওয়া হতো।
    if (membershipsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final memberships = membershipsAsync.valueOrNull ?? const <Membership>[];
    final allowedIds =
        isAdmin ? null : approvedBranchIds(memberships);
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
    // আগে বাছা সমিতি এখন আর অনুমোদিত তালিকায় না থাকলে বাদ যায়।
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
      final found =
          myMembers.where((m) => m.branchId == branchId).toList();
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
    final chosen =
        methods.where((m) => m.id == _methodId).firstOrNull;
    final loadingMethods =
        effectiveBranchId != null && methodsAsync is AsyncLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'প্রথমে সমিতি বেছে নিন, তারপর নিচের মাধ্যমগুলো থেকে '
            'একটায় টাকা পাঠিয়ে ঘরগুলো পূরণ করুন।',
            style: TextStyle(fontSize: 14.5, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: effectiveBranchId,
            decoration: const InputDecoration(
              labelText: 'কোন সমিতি',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            items: branches
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _branchId = v;
              _methodId = null;
            }),
          ),
          const SizedBox(height: 12),
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
                    for (var y = DateTime.now().year - 1;
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
          if (effectiveBranchId == null)
            const Text(
              'সমিতি বাছলে এখানে টাকা পাঠানোর মাধ্যমগুলো দেখাবে।',
              style: TextStyle(fontSize: 14.5, color: Colors.grey),
            )
          else if (loadingMethods)
            const Center(child: CircularProgressIndicator())
          else if (methods.isEmpty)
            const EmptyState(
              icon: Icons.account_balance_outlined,
              title: 'এই সমিতির জন্য এখনো কোনো পেমেন্ট মাধ্যম যোগ করা হয়নি',
            )
          else
            ...methods.map(
              (m) => PaymentMethodCard(
                method: m,
                selected: _methodId == m.id,
                onTap: () => setState(() => _methodId = m.id),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: AppStrings.depositAmount,
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
                labelText: 'যে নম্বর থেকে পাঠিয়েছেন',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
          if (chosen != null && chosen.type != PaymentMethodType.cash) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _trxId,
              decoration: const InputDecoration(
                labelText: AppStrings.trxId,
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _busy ? AppStrings.loading : AppStrings.depositSubmit,
            onPressed: _busy || effectiveBranchId == null
                ? null
                : () => _submit(
                      methods,
                      effectiveBranchId,
                      memberIdFor(effectiveBranchId),
                    ),
            icon: Icons.send_outlined,
          ),
        ],
      ),
    );
  }
}
