import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../models/payment_method.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/bn_digits.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';

/// মাধ্যম যোগ/বদলানোর ফরম — ডায়ালগে খোলে।
class MethodFormDialog extends ConsumerStatefulWidget {
  final List<Branch> branches;
  final PaymentMethodConfig? existing;

  const MethodFormDialog({super.key, required this.branches, this.existing});

  @override
  ConsumerState<MethodFormDialog> createState() => _MethodFormDialogState();
}

class _MethodFormDialogState extends ConsumerState<MethodFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _accountNumber;
  late final TextEditingController _holderName;
  late final TextEditingController _instructions;
  late final TextEditingController _sortOrder;
  PaymentMethodType _type = PaymentMethodType.mobileBanking;
  String? _branchId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _accountNumber = TextEditingController(text: e?.accountNumber ?? '');
    _holderName = TextEditingController(text: e?.accountHolderName ?? '');
    _instructions = TextEditingController(text: e?.instructions ?? '');
    _sortOrder =
        TextEditingController(text: e == null ? '0' : '${e.sortOrder}');
    _type = e?.type ?? PaymentMethodType.mobileBanking;
    _branchId = e?.branchId;
  }

  @override
  void dispose() {
    _name.dispose();
    _accountNumber.dispose();
    _holderName.dispose();
    _instructions.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'মাধ্যমের নাম লিখুন (যেমন: বিকাশ)');
      return;
    }
    // M15: নগদ টাকার কোনো অ্যাকাউন্ট নম্বর বা অ্যাকাউন্টের
    // নাম থাকে না — এই দুই ঘর শুধু অন্য ধরনের জন্য।
    final isCash = _type == PaymentMethodType.cash;
    if (!isCash && _accountNumber.text.trim().isEmpty) {
      setState(() => _error = 'অ্যাকাউন্ট নম্বর লিখুন');
      return;
    }
    if (!isCash && _holderName.text.trim().isEmpty) {
      setState(() => _error = 'অ্যাকাউন্টের নাম লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = ref.read(firestoreServiceProvider);
      final by = AuthService().uidOrEmpty;
      final existing = widget.existing;
      // M3: অ্যাকাউন্ট নম্বর ASCII-তে স্বাভাবিক করে রাখা হয়।
      final accountNumber =
          isCash ? '' : toAsciiDigits(_accountNumber.text.trim());
      final holderName = isCash ? '' : _holderName.text.trim();
      final sortOrder = parseAmount(_sortOrder.text) ?? 0;
      if (existing == null) {
        final method = PaymentMethodConfig(
          id: '',
          name: _name.text.trim(),
          type: _type,
          accountNumber: accountNumber,
          accountHolderName: holderName,
          branchId: _branchId,
          isActive: true,
          sortOrder: sortOrder,
          instructions: _instructions.text.trim().isEmpty
              ? null
              : _instructions.text.trim(),
          createdBy: by,
          createdAt: DateTime.now(),
        );
        await store.addPaymentMethod(method, createdBy: by);
      } else {
        final updated = PaymentMethodConfig(
          id: existing.id,
          name: _name.text.trim(),
          type: _type,
          accountNumber: accountNumber,
          accountHolderName: holderName,
          branchId: _branchId,
          isActive: existing.isActive,
          sortOrder: sortOrder,
          instructions: _instructions.text.trim().isEmpty
              ? null
              : _instructions.text.trim(),
          createdBy: existing.createdBy,
          createdAt: existing.createdAt,
        );
        await store.updatePaymentMethod(updated, updatedBy: by);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'পেমেন্ট মাধ্যম যোগ করা হয়েছে'
                : 'পেমেন্ট মাধ্যম বদলানো হয়েছে',
          ),
        ),
      );
    } catch (e) {
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'সংরক্ষণ করা যায়নি — আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'নতুন পেমেন্ট মাধ্যম' : 'মাধ্যম বদলান',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'নাম (যেমন: বিকাশ, নগদ, রকেট)',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethodType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'ধরন'),
              items: PaymentMethodType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        switch (t) {
                          PaymentMethodType.mobileBanking => 'মোবাইল ব্যাংকিং',
                          PaymentMethodType.bank => 'ব্যাংক',
                          PaymentMethodType.cash => 'নগদ টাকা',
                        },
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            // M15: নগদ টাকার ক্ষেত্রে অ্যাকাউন্টের ঘর দেখানো হয় না।
            if (_type != PaymentMethodType.cash) ...[
              TextField(
                controller: _accountNumber,
                keyboardType: TextInputType.text,
                inputFormatters: const [BnDigitsInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'অ্যাকাউন্ট নম্বর',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _holderName,
                decoration: const InputDecoration(
                  labelText: 'অ্যাকাউন্টের নাম',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String?>(
              initialValue: _branchId,
              decoration: const InputDecoration(
                labelText: 'কোন সমিতির জন্য',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('সব সমিতি'),
                ),
                for (final b in widget.branches)
                  DropdownMenuItem<String?>(
                    value: b.id,
                    child: Text(b.name),
                  ),
              ],
              onChanged: (v) => setState(() => _branchId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructions,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'নির্দেশনা (ঐচ্ছিক)',
                hintText: 'যেমন: সেন্ড মানি করুন, রেফারেন্সে নাম লিখুন',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortOrder,
              keyboardType: TextInputType.number,
              inputFormatters: const [BnDigitsOnlyFormatter()],
              decoration: const InputDecoration(
                labelText: 'দেখানোর ক্রম (ছোট সংখ্যা আগে দেখাবে)',
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
