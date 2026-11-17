import 'package:flutter/material.dart';
import '../../models/loan.dart';
import '../../models/payment_method.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/payment_method_card.dart';

/// কিস্তি পরিশোধের ফরম
class LoanRepaymentForm extends StatefulWidget {
  final Loan loan;
  final List<PaymentMethodConfig> methods;
  final bool loadingMethods;

  const LoanRepaymentForm({
    super.key,
    required this.loan,
    required this.methods,
    required this.loadingMethods,
  });

  @override
  State<LoanRepaymentForm> createState() => _LoanRepaymentFormState();
}

class _LoanRepaymentFormState extends State<LoanRepaymentForm> {
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

  Future<void> _recordRepayment() async {
    final chosen =
        widget.methods.where((m) => m.id == _methodId).firstOrNull;
    if (chosen == null) {
      setState(() => _error = 'কীভাবে টাকা দিল, বেছে নিন');
      return;
    }
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'টাকার সঠিক পরিমাণ লিখুন');
      return;
    }
    if (amount > widget.loan.outstanding) {
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
        final usedInLoan = widget.loan.repayments.any(
          (r) => r.trxId == trxId && r.paymentMethodId == chosen.id,
        );
        final usedInPayments = await store.trxIdAlreadyUsed(
          paymentMethodId: chosen.id,
          trxId: trxId,
          branchId: widget.loan.branchId,
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
        widget.loan.id,
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
    if (widget.loadingMethods) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.methods.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance_outlined,
        title: 'এই সমিতির জন্য এখনো কোনো পেমেন্ট মাধ্যম যোগ করা হয়নি',
        message: 'অ্যাডমিন মাধ্যম যোগ করলে এখানে দেখা যাবে।',
      );
    }

    final chosen =
        widget.methods.where((m) => m.id == _methodId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.methods.map(
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
        if (chosen != null && chosen.type != PaymentMethodType.cash) ...[
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
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 12),
        PrimaryButton(
          label: _busy ? 'আসছে…' : 'কিস্তি জমা নিন',
          onPressed: _busy || widget.methods.isEmpty ? null : _recordRepayment,
          icon: Icons.check_outlined,
        ),
      ],
    );
  }
}
