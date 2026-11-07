import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/branch.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';

/// কর্জে হাসানা ঋণ দেওয়া — শুধু অ্যাডমিন আর ব্রাঞ্চ অ্যাডমিন।
/// টাকা, কারণ, তারিখ, আর মাসে কত করে কত মাসে ফেরত দেবে —
/// এই পরিকল্পনাটা লেখা হয়। সুদের কোনো ঘর নেই।
class IssueLoanScreen extends ConsumerStatefulWidget {
  const IssueLoanScreen({super.key});

  @override
  ConsumerState<IssueLoanScreen> createState() => _IssueLoanScreenState();
}

class _IssueLoanScreenState extends ConsumerState<IssueLoanScreen> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  final _installment = TextEditingController();
  final _months = TextEditingController();
  String? _branchId;
  String? _memberId;
  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _error;

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

  Future<void> _submit() async {
    final amount = int.tryParse(_amount.text.trim());
    final installment = int.tryParse(_installment.text.trim());
    final months = int.tryParse(_months.text.trim());
    if (_branchId == null) {
      setState(() => _error = 'কোন সমিতি থেকে ঋণ দিচ্ছেন, বেছে নিন');
      return;
    }
    if (_memberId == null) {
      setState(() => _error = 'কাকে ঋণ দিচ্ছেন, বেছে নিন');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'টাকার সঠিক পরিমাণ লিখুন');
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'কেন ঋণ দিচ্ছেন, লিখুন');
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
      final loan = Loan(
        id: '',
        memberId: _memberId!,
        branchId: _branchId!,
        amount: amount,
        dateIssued: _date,
        reason: _reason.text.trim(),
        status: LoanStatus.active,
        monthlyInstallment: installment,
        installmentMonths: months,
      );
      await FirestoreService().issueLoan(loan);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ঋণ দেওয়া হয়েছে')),
      );
      context.go('/loans');
    } catch (_) {
      setState(() => _error = 'ঋণ দেওয়া যায়নি — নেট দেখে আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final membersAsync = ref.watch(
      StreamProvider<List<Member>>(
        (ref) => FirestoreService().watchMembers(branchId: _branchId),
      ),
    );
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final members = membersAsync.valueOrNull ?? const <Member>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('কর্জে হাসানা — সুদমুক্ত ঋণ। ফেরতের পরিকল্পনাটা নিচে লিখুন।'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _branchId,
            decoration: const InputDecoration(
              labelText: 'কোন সমিতি',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            items: branches
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _branchId = v;
              _memberId = null;
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _memberId,
            decoration: const InputDecoration(
              labelText: 'কাকে ঋণ দিচ্ছেন',
              prefixIcon: Icon(Icons.person_outlined),
            ),
            items: members
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _memberId = v),
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
          TextField(
            controller: _reason,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'কেন ঋণ দিচ্ছেন',
              prefixIcon: Icon(Icons.notes_outlined),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _installment,
                  keyboardType: TextInputType.number,
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
          const SizedBox(height: 24),
          PrimaryButton(
            label: _busy ? 'আসছে…' : 'ঋণ দিন',
            onPressed: _busy ? null : _submit,
            icon: Icons.handshake_outlined,
          ),
        ],
      ),
    );
  }
}
