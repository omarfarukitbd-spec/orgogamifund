import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/branch.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/bn_digits.dart';
import '../utils/firebase_errors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

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

  /// F16: কার্যকর সমিতি — শাখা অ্যাডমিনের ক্ষেত্রে নিজের
  /// সমিতি, অন্যদের ক্ষেত্রে ড্রপডাউনে বাছা সমিতি।
  String? _effectiveBranchId() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null && user.isBranchAdmin) return user.branchId;
    return _branchId;
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amount.text);
    final installment = _installment.text.trim().isEmpty
        ? null
        : parseAmount(_installment.text);
    final months =
        _months.text.trim().isEmpty ? null : parseAmount(_months.text);
    final branchId = _effectiveBranchId();
    if (branchId == null) {
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
        branchId: branchId,
        amount: amount,
        dateIssued: _date,
        reason: _reason.text.trim(),
        status: LoanStatus.active,
        monthlyInstallment: installment,
        installmentMonths: months,
      );
      await ref.read(firestoreServiceProvider).issueLoan(loan);
      if (!mounted) return;
      invalidateTotals(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ঋণ দেওয়া হয়েছে')),
      );
      context.goNamed('loans');
    } catch (e) {
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'ঋণ দেওয়া যায়নি — নেট দেখে আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesStreamProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    // F16: শাখা অ্যাডমিন শুধু নিজের সমিতি দেখে — অন্য
    // সমিতির ড্রপডাউন আইটেম দেখানো হয় না।
    final isBranchAdmin = user != null && user.isBranchAdmin;
    final effectiveBranchId =
        isBranchAdmin ? user.branchId : _branchId;
    final membersAsync =
        ref.watch(activeMembersByBranchProvider(effectiveBranchId ?? ''));
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final visibleBranches = isBranchAdmin
        ? branches.where((b) => b.id == user.branchId).toList()
        : branches;
    final members = membersAsync.valueOrNull ?? const <Member>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'কর্জে হাসানা — সুদমুক্ত ঋণ। ফেরতের পরিকল্পনাটা নিচে লিখুন।',
            style: TextStyle(fontSize: 14.5, color: Colors.grey),
          ),
          const SizedBox(height: 16),
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
              onChanged: isBranchAdmin
                  ? null
                  : (v) => setState(() {
                        _branchId = v;
                        _memberId = null;
                      }),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _memberId,
            decoration: InputDecoration(
              labelText: 'কাকে ঋণ দিচ্ছেন',
              prefixIcon: const Icon(Icons.person_outlined),
              hintText: effectiveBranchId == null ? 'আগে সমিতি বেছে নিন' : null,
            ),
            items: members
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            // m8: সমিতি না বাছলে সদস্যের ড্রপডাউন বন্ধ — নইলে
            // সব সমিতির সদস্য দেখাত, আর সমিতি বাছলে বাছাই
            // মুছে যেত।
            onChanged: effectiveBranchId == null
                ? null
                : (v) => setState(() => _memberId = v),
          ),
          // M14: সমিতিতে সদস্য না থাকলে খালি ড্রপডাউনের
          // বদলে বোঝার মতো বার্তা।
          if (effectiveBranchId != null && members.isEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'এই সমিতিতে এখনো কোনো সদস্য নেই — আগে সদস্য অনুমোদন করুন',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
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
          TextField(
            controller: _reason,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'কেন ঋণ দিচ্ছেন',
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
