import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/loan.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/bn_digits.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../passbook_screen.dart';

/// ঋণ বদলানো (M9) — টাকা, কারণ, তারিখ, কিস্তির পরিকল্পনা।
/// টাকা ফেরত দেওয়া অঙ্কের নিচে নামানো যায় না। কিস্তির
/// খাতা এখান থেকে বদলানো যায় না — সেটা আলাদা হিসাব।
/// শুধু অ্যাডমিন ব্যবহার করে।
class EditLoanDialog extends ConsumerStatefulWidget {
  final Loan loan;

  const EditLoanDialog({super.key, required this.loan});

  @override
  ConsumerState<EditLoanDialog> createState() => _EditLoanDialogState();
}

class _EditLoanDialogState extends ConsumerState<EditLoanDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _reason;
  late final TextEditingController _installment;
  late final TextEditingController _months;
  late DateTime _date;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    _amount = TextEditingController(text: '${l.amount}');
    _reason = TextEditingController(text: l.reason);
    _installment = TextEditingController(
      text: l.monthlyInstallment == null ? '' : '${l.monthlyInstallment}',
    );
    _months = TextEditingController(
      text: l.installmentMonths == null ? '' : '${l.installmentMonths}',
    );
    _date = l.dateIssued.year < 2000 ? DateTime.now() : l.dateIssued;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    _installment.dispose();
    _months.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    final installment = _installment.text.trim().isEmpty
        ? null
        : parseAmount(_installment.text);
    final months =
        _months.text.trim().isEmpty ? null : parseAmount(_months.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'টাকার সঠিক পরিমাণ লিখুন');
      return;
    }
    if (amount < widget.loan.repaidTotal) {
      setState(
        () => _error =
            'ফেরত দেওয়া ${formatTaka(widget.loan.repaidTotal)}-এর চেয়ে কম লেখা যাবে না',
      );
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'কেন ঋণ দেওয়া হয়েছিল, লিখুন');
      return;
    }
    if (installment != null && months != null) {
      if (installment * months < amount) {
        setState(
          () => _error = 'কিস্তি আর মাস মিলিয়ে মোট টাকা আসে না — আবার দেখুন',
        );
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final l = widget.loan;
      final updated = Loan(
        id: l.id,
        memberId: l.memberId,
        branchId: l.branchId,
        amount: amount,
        dateIssued: _date,
        reason: _reason.text.trim(),
        status: l.status,
        repayments: l.repayments,
        monthlyInstallment: installment,
        installmentMonths: months,
      );
      await ref.read(firestoreServiceProvider).updateLoan(
            updated,
            by: AuthService().uidOrEmpty,
          );
      if (!mounted) return;
      invalidateTotals(ref);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ঋণ বদলানো হয়েছে')),
      );
    } catch (e) {
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'ঋণ বদলানো যায়নি — আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ঋণ বদলান'),
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
            if (widget.loan.repaidTotal > 0) ...[
              const SizedBox(height: 6),
              Text(
                'এর মধ্যে ${formatTaka(widget.loan.repaidTotal)} ফেরত দেওয়া হয়েছে',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'কেন ঋণ দেওয়া হয়েছিল',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const ListIcon(icon: Icons.calendar_today_outlined),
                title: Text(
                  'তারিখ: ${_date.day}/${_date.month}/${_date.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.edit_outlined, color: Colors.grey),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _installment,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [BnDigitsOnlyFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'মাসে কত করে',
                      prefixText: '৳ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _months,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [BnDigitsOnlyFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'কত মাসে',
                      suffixText: 'মাস',
                    ),
                  ),
                ),
              ],
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
