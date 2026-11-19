import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/bn_digits.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../passbook_screen.dart';

/// জমা বদলানো (M9) — টাকা, মাস/বছর, TrxID, পাঠানোর নম্বর।
/// অবস্থা (status) এখান থেকে বদলানো যায় না — অনুমোদন বা
/// বাতিল অনুমোদন কেন্দ্র থেকেই হয়। শুধু অ্যাডমিন ব্যবহার করে।
class EditPaymentDialog extends ConsumerStatefulWidget {
  final Payment payment;

  const EditPaymentDialog({super.key, required this.payment});

  @override
  ConsumerState<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends ConsumerState<EditPaymentDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _trxId;
  late final TextEditingController _senderMobile;
  late int _month;
  late int _year;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.payment;
    _amount = TextEditingController(text: '${p.amount}');
    _trxId = TextEditingController(text: p.trxId ?? '');
    _senderMobile = TextEditingController(text: p.senderMobile ?? '');
    _month = p.forMonth.clamp(1, 12);
    _year = p.forYear;
  }

  @override
  void dispose() {
    _amount.dispose();
    _trxId.dispose();
    _senderMobile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'টাকার সঠিক পরিমাণ লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = widget.payment;
      final updated = Payment(
        id: p.id,
        memberId: p.memberId,
        branchId: p.branchId,
        type: p.type,
        amount: amount,
        method: p.method,
        trxId: _trxId.text.trim().isEmpty ? null : _trxId.text.trim(),
        paymentMethodId: p.paymentMethodId,
        paymentMethodName: p.paymentMethodName,
        paymentAccountNumber: p.paymentAccountNumber,
        senderMobile: _senderMobile.text.trim().isEmpty
            ? null
            : toAsciiDigits(_senderMobile.text.trim()),
        forMonth: _month,
        forYear: _year,
        date: p.date,
        recordedBy: p.recordedBy,
        status: p.status,
        receiptNumber: p.receiptNumber,
        rejectReason: p.rejectReason,
      );
      await ref.read(firestoreServiceProvider).updatePayment(
            updated,
            by: AuthService().uidOrEmpty,
          );
      if (!mounted) return;
      invalidateTotals(ref);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('জমা বদলানো হয়েছে')),
      );
    } catch (e) {
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'জমা বদলানো যায়নি — আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    // পুরোনো জমার বছর তালিকার বাইরে থাকতে পারে (যেমন ১৯৭০-এর
    // সেন্টিনেল) — initialValue তালিকায় না থাকলে ড্রপডাউন ভাঙে।
    final years = [
      for (var y = currentYear - 5; y <= currentYear; y++) y,
    ];
    if (!years.contains(_year)) years.insert(0, _year);
    return AlertDialog(
      title: const Text('জমা বদলান'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: const [BnDigitsOnlyFormatter()],
              decoration: const InputDecoration(
                labelText: 'টাকার পরিমাণ',
                prefixText: '৳ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
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
                        DropdownMenuItem(
                          value: m,
                          child: Text(bengaliMonths[m - 1]),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _month = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'বছর'),
                    items: [
                      for (final y in years)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _year = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trxId,
              decoration: const InputDecoration(
                labelText: 'লেনদেন নম্বর (TrxID)',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderMobile,
              keyboardType: TextInputType.phone,
              inputFormatters: const [BnDigitsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'যে নম্বর থেকে পাঠিয়েছে',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        PrimaryButton(
          label: _busy ? AppStrings.loading : AppStrings.save,
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}
