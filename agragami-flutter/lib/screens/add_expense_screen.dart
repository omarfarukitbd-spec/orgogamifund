import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/branch.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';

/// খরচ লেখা — শুধু অ্যাডমিন আর ব্রাঞ্চ অ্যাডমিন।
/// ধরন, টাকা, তারিখ, কীসের খরচ, আর রসিদের ছবি (যদি থাকে)।
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  static const int _maxBytes = 5 * 1024 * 1024;

  final _amount = TextEditingController();
  final _description = TextEditingController();
  String _category = expenseCategories.first;
  String? _branchId;
  DateTime _date = DateTime.now();
  Uint8List? _receiptBytes;
  bool _busy = false;
  String? _error;

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
    } catch (_) {
      setState(() => _error = 'ছবি নেওয়া যায়নি — আবার চেষ্টা করুন');
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

  Future<void> _submit() async {
    final amount = int.tryParse(_amount.text.trim());
    if (_branchId == null) {
      setState(() => _error = 'কোন সমিতির খরচ, বেছে নিন');
      return;
    }
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
      final expense = Expense(
        id: '',
        branchId: _branchId!,
        category: _category,
        amount: amount,
        date: _date,
        description: _description.text.trim(),
        recordedBy: AuthService().uidOrEmpty,
      );
      await FirestoreService().submitExpense(
        expense: expense,
        receiptBytes: _receiptBytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('খরচ লেখা হয়েছে')),
      );
      context.go('/expenses');
    } catch (_) {
      setState(() => _error = 'খরচ লেখা যায়নি — নেট দেখে আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _branchId,
            decoration: const InputDecoration(
              labelText: 'কোন সমিতি',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            items: branches
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: (v) => setState(() => _branchId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'কী ধরনের খরচ',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: expenseCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'টাকার পরিমাণ',
              prefixText: '৳ ',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(
              'তারিখ: ${_date.day}/${_date.month}/${_date.year}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _pickDate,
          ),
          TextField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'কীসের খরচ',
              hintText: 'যেমন: মাদ্রাসার ছাদের কাজের মালামাল',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickReceipt,
            icon: const Icon(Icons.photo_outlined),
            label: Text(
              _receiptBytes == null ? 'রসিদের ছবি যোগ করুন' : 'রসিদের ছবি বদলান',
            ),
          ),
          if (_receiptBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_receiptBytes!, height: 180, fit: BoxFit.cover),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _busy ? 'আসছে…' : 'খরচ লিখুন',
            onPressed: _busy ? null : _submit,
            icon: Icons.check_outlined,
          ),
        ],
      ),
    );
  }
}
