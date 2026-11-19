import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/cloudinary_config.dart';
import '../models/branch.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/bn_digits.dart';
import '../utils/firebase_errors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

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
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
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

  Future<void> _submitExpense(Expense expense, Uint8List? receiptBytes) {
    return ref.read(firestoreServiceProvider).submitExpense(
      expense: expense,
      receiptBytes: receiptBytes,
    );
  }

  void _onExpenseSaved() {
    // রসিদ দিয়েও Cloudinary সেট করা না থাকলে ছবি জমা হয়নি —
    // ব্যবহারকারীকে জানিয়ে দিই, খরচ তবুও লেখা হয়েছে।
    final receiptSkipped =
        _receiptBytes != null && !CloudinaryConfig.isConfigured;
    // M12: খরচ লেখার পর মোট হিসাব তাজা হয়।
    invalidateTotals(ref);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receiptSkipped
              ? 'খরচ লেখা হয়েছে — তবে রসিদের ছবি আপলোড হয়নি, কারণ ছবি আপলোড এখনো সেট করা হয়নি'
              : 'খরচ লেখা হয়েছে',
        ),
      ),
    );
    context.goNamed('expenses');
  }

  /// F16: কার্যকর সমিতি — শাখা অ্যাডমিনের ক্ষেত্রে নিজের
  /// সমিতি, অন্যদের ক্ষেত্রে ড্রপডাউনে বাছা সমিতি।
  String? _effectiveBranchId() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null && user.isBranchAdmin) return user.branchId;
    return _branchId;
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amount.text);
    final branchId = _effectiveBranchId();
    if (branchId == null) {
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
    final expense = Expense(
      id: '',
      branchId: branchId,
      category: _category,
      amount: amount,
      date: _date,
      description: _description.text.trim(),
      recordedBy: AuthService().uidOrEmpty,
    );
    try {
      await _submitExpense(expense, _receiptBytes);
      if (!mounted) return;
      _onExpenseSaved();
    } on UploadFailedException catch (_) {
      // রসিদের ছবি আপলোড হয়নি — নিঃশব্দে ছবি ছাড়া লেখা হয় না।
      // ব্যবহারকারী চাইলে ছবি ছাড়াই লিখতে পারে।
      if (!mounted) return;
      final saveWithout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ছবি আপলোড হয়নি'),
          content: const Text(
            'রসিদের ছবিটা আপলোড করা যায়নি। ছবি ছাড়াই খরচ লিখবেন?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ছবি ছাড়াই লিখুন'),
            ),
          ],
        ),
      );
      if (saveWithout != true) {
        // F14: ডায়ালগের পর setState-এর আগে mounted দেখা হয়।
        if (!mounted) return;
        setState(() => _error = 'ছবি আপলোড হয়নি — আবার চেষ্টা করুন');
        return;
      }
      try {
        await _submitExpense(expense, null);
        if (!mounted) return;
        _onExpenseSaved();
      } catch (e) {
        // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
        if (!mounted) return;
        setState(
          () => _error = firebaseErrorMessage(
            e,
            fallback: 'খরচ লেখা যায়নি — নেট দেখে আবার চেষ্টা করুন',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'খরচ লেখা যায়নি — নেট দেখে আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesStreamProvider);
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final user = ref.watch(currentUserProvider).valueOrNull;
    // F16: শাখা অ্যাডমিন শুধু নিজের সমিতি দেখে — অন্য
    // সমিতির ড্রপডাউন আইটেম দেখানো হয় না।
    final isBranchAdmin = user != null && user.isBranchAdmin;
    final effectiveBranchId = isBranchAdmin ? user.branchId : _branchId;
    final visibleBranches = isBranchAdmin
        ? branches.where((b) => b.id == user.branchId).toList()
        : branches;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBranchAdmin && user.branchId == null)
            const Text(
              'আপনার কোনো সমিতি বাঁধা নেই — সুপার অ্যাডমিনকে জানান',
              style: TextStyle(fontSize: 14, color: Colors.red),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: effectiveBranchId,
              decoration: const InputDecoration(
                labelText: 'কোন সমিতি',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              items: visibleBranches
                  .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
              onChanged:
                  isBranchAdmin ? null : (v) => setState(() => _branchId = v),
            ),
          const SizedBox(height: 12),
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
            decoration: const InputDecoration(
              labelText: 'কীসের খরচ',
              hintText: 'যেমন: মাদ্রাসার ছাদের কাজের মালামাল',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 12),
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
