import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings.dart';
import '../../models/expense.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/bn_digits.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// খরচ বদলানো (M9) — ধরন, টাকা, তারিখ, বিবরণ, রসিদের ছবি।
/// নতুন ছবি না দিলে আগের ছবিই থাকে। শুধু অ্যাডমিন ব্যবহার করে।
class EditExpenseDialog extends ConsumerStatefulWidget {
  final Expense expense;

  const EditExpenseDialog({super.key, required this.expense});

  @override
  ConsumerState<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends ConsumerState<EditExpenseDialog> {
  static const int _maxBytes = 5 * 1024 * 1024;

  late final TextEditingController _amount;
  late final TextEditingController _description;
  late String _category;
  late DateTime _date;
  Uint8List? _receiptBytes;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amount = TextEditingController(text: '${e.amount}');
    _description = TextEditingController(text: e.description);
    _category =
        expenseCategories.contains(e.category) ? e.category : expenseCategories.first;
    _date = e.date.year < 2000 ? DateTime.now() : e.date;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxBytes) {
        setState(() => _error = 'ছবিটি ৫ MB-এর বেশি — ছোট ছবি বেছে নিন');
        return;
      }
      setState(() {
        _receiptBytes = bytes;
        _error = null;
      });
    } catch (e) {
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'ছবি নেওয়া যায়নি — আবার চেষ্টা করুন',
        ),
      );
    }
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
    if (amount == null || amount <= 0) {
      setState(() => _error = 'টাকার সঠিক পরিমাণ লিখুন');
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'কীসের খরচ, এক লাইনে লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final e = widget.expense;
      final updated = Expense(
        id: e.id,
        branchId: e.branchId,
        category: _category,
        amount: amount,
        date: _date,
        description: _description.text.trim(),
        attachmentUrl: e.attachmentUrl,
        recordedBy: e.recordedBy,
      );
      await ref.read(firestoreServiceProvider).updateExpense(
            expense: updated,
            receiptBytes: _receiptBytes,
            by: AuthService().uidOrEmpty,
          );
      if (!mounted) return;
      invalidateTotals(ref);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('খরচ বদলানো হয়েছে')),
      );
    } catch (e) {
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'খরচ বদলানো যায়নি — আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('খরচ বদলান'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'কী ধরনের খরচ'),
              items: expenseCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
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
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'কীসের খরচ'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickReceipt,
              icon: const Icon(Icons.photo_outlined),
              label: Text(
                _receiptBytes == null
                    ? (widget.expense.attachmentUrl == null
                        ? 'রসিদের ছবি যোগ করুন'
                        : 'রসিদের ছবি বদলান')
                    : 'রসিদের ছবি বদলান',
              ),
            ),
            if (_receiptBytes != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    Image.memory(_receiptBytes!, height: 180, fit: BoxFit.cover),
              ),
            ],
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
