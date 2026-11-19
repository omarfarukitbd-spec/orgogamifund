import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../models/member.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/bn_digits.dart';
import '../../utils/firebase_errors.dart';
import '../../utils/validators.dart';

/// বিদ্যমান সমিতির তথ্য সম্পাদনের ডায়ালগ — শুধুমাত্র অ্যাডমিন ব্যবহার করতে পারবে।
/// লাইভ স্কিমার সব আর্থিক ক্ষেত্র বদলানো যায় (B8): মাসিক জমা,
/// ভর্তি ফি, জমার শেষ দিন, বিলম্ব জরিমানা, ঐচ্ছিক জমা,
/// কোষাধ্যক্ষ, ব্যাংক তথ্য, শর্তাবলি। সদস্যদের দেখার অনুমতি
/// (permissions) এখান থেকেই বদলানো যায় (F11)।
class EditSamitiDialog extends ConsumerStatefulWidget {
  final Branch branch;

  const EditSamitiDialog({super.key, required this.branch});

  @override
  ConsumerState<EditSamitiDialog> createState() => _EditSamitiDialogState();
}

class _EditSamitiDialogState extends ConsumerState<EditSamitiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _monthlyController;
  late final TextEditingController _admissionController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _lateFineController;
  late final TextEditingController _minOptionalController;
  // F36: কোষাধ্যক্ষ আর কাঁচা UID লিখে বসানো যায় না — সমিতির
  // সদস্যদের তালিকা থেকে বাছা হয়। বর্তমান UID তালিকায় না
  // থাকলে সেটাও আইটেম হিসেবে থাকে, যাতে না বদলালে মুছে না যায়।
  String? _treasurerUserId;
  late final TextEditingController _bankNameController;
  late final TextEditingController _bankBranchController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountHolderController;
  late final TextEditingController _routingController;
  late final TextEditingController _bkashController;
  late final TextEditingController _nagadController;
  late final TextEditingController _termsController;
  late SamitiPurpose _purpose;
  late bool _optionalEnabled;
  // F11: সদস্যদের দেখার অনুমতি — এখন ডায়ালগ থেকেই বদলানো যায়।
  late bool _canMembersViewTotalFund;
  late bool _canMembersViewExpenses;
  late bool _canMembersViewMemberList;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    final bank = b.bankDetails;
    _nameController = TextEditingController(text: b.name);
    _descriptionController = TextEditingController(text: b.description);
    _monthlyController =
        TextEditingController(text: '${b.monthlyDepositAmount}');
    _admissionController = TextEditingController(text: '${b.admissionFee}');
    _dueDayController = TextEditingController(text: '${b.monthlyDueDay}');
    _lateFineController = TextEditingController(text: '${b.lateFineAmount}');
    _minOptionalController =
        TextEditingController(text: '${b.minOptionalDeposit}');
    _treasurerUserId = b.treasurerUserId;
    _canMembersViewTotalFund = b.canMembersViewTotalFund;
    _canMembersViewExpenses = b.canMembersViewExpenses;
    _canMembersViewMemberList = b.canMembersViewMemberList;
    _bankNameController = TextEditingController(text: bank?.bankName ?? '');
    _bankBranchController = TextEditingController(text: bank?.branchName ?? '');
    _accountNumberController =
        TextEditingController(text: bank?.accountNumber ?? '');
    _accountHolderController =
        TextEditingController(text: bank?.accountHolderName ?? '');
    _routingController = TextEditingController(text: bank?.routingNumber ?? '');
    _bkashController = TextEditingController(text: bank?.bkashNumber ?? '');
    _nagadController = TextEditingController(text: bank?.nagadNumber ?? '');
    _termsController =
        TextEditingController(text: b.termsAndConditions.join('\n'));
    _purpose = b.purpose;
    _optionalEnabled = b.optionalDepositEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _monthlyController.dispose();
    _admissionController.dispose();
    _dueDayController.dispose();
    _lateFineController.dispose();
    _minOptionalController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _routingController.dispose();
    _bkashController.dispose();
    _nagadController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  String? _opt(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _update() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final isBn = AppStrings.isBangla;
    try {
      final terms = _termsController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await ref.read(firestoreServiceProvider).updateBranch(
        branchId: widget.branch.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        purpose: _purpose,
        monthlyDepositAmount: parseAmount(_monthlyController.text) ?? 0,
        admissionFee: parseAmount(_admissionController.text) ?? 0,
        monthlyDueDay: parseAmount(_dueDayController.text) ?? 10,
        lateFineAmount: parseAmount(_lateFineController.text) ?? 0,
        minOptionalDeposit: parseAmount(_minOptionalController.text) ?? 0,
        optionalDepositEnabled: _optionalEnabled,
        treasurerUserId: _treasurerUserId,
        canMembersViewTotalFund: _canMembersViewTotalFund,
        canMembersViewExpenses: _canMembersViewExpenses,
        canMembersViewMemberList: _canMembersViewMemberList,
        bankDetails: BankDetails(
          bankName: _opt(_bankNameController.text),
          branchName: _opt(_bankBranchController.text),
          accountNumber: _opt(_accountNumberController.text),
          accountHolderName: _opt(_accountHolderController.text),
          routingNumber: _opt(_routingController.text),
          bkashNumber: _opt(_bkashController.text),
          nagadNumber: _opt(_nagadController.text),
        ),
        termsAndConditions: terms,
        by: AuthService().uidOrEmpty,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn ? 'সমিতির তথ্য সফলভাবে আপডেট হয়েছে' : 'Samiti updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(
              e,
              fallback: isBn ? 'সমিতি আপডেট করা যায়নি' : 'Failed to update samiti',
            ),
          ),
        ),
      );
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _amountField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, suffixText: '৳'),
      keyboardType: TextInputType.number,
      inputFormatters: const [BnDigitsOnlyFormatter()],
      validator: validator ?? (v) => validateAmount(v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = AppStrings.isBangla;
    // F36: কোষাধ্যক্ষ বাছার তালিকা — এই সমিতির সক্রিয়
    // সদস্যদের মধ্যে যাদের লগইন অ্যাকাউন্ট আছে।
    final membersAsync =
        ref.watch(activeMembersByBranchProvider(widget.branch.id));
    final members = membersAsync.valueOrNull ?? const <Member>[];
    final treasurerCandidates =
        members.where((m) => m.linkedUserId != null).toList();
    final treasurerKnown = _treasurerUserId == null ||
        treasurerCandidates
            .any((m) => m.linkedUserId == _treasurerUserId);
    return AlertDialog(
      title: Text(isBn ? 'সমিতি সম্পাদনা' : 'Edit Samiti'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppStrings.samitiNameLabel,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? (isBn ? 'নাম লিখুন' : 'Enter name') : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SamitiPurpose>(
                initialValue: _purpose,
                decoration: InputDecoration(
                  labelText: AppStrings.samitiPurposeLabel,
                ),
                items: SamitiPurpose.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(samitiPurposeText(p)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _purpose = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppStrings.samitiDescriptionLabel,
                ),
                maxLines: 3,
              ),
              _sectionTitle('টাকার নিয়ম'),
              _amountField(
                controller: _monthlyController,
                label: 'মাসিক জমা',
              ),
              const SizedBox(height: 12),
              _amountField(
                controller: _admissionController,
                label: 'ভর্তি ফি (একবার)',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dueDayController,
                      decoration: const InputDecoration(
                        labelText: 'জমার শেষ দিন',
                        suffixText: 'তারিখ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: const [BnDigitsOnlyFormatter()],
                      validator: (v) => validateDueDay(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _amountField(
                      controller: _lateFineController,
                      label: 'বিলম্ব জরিমানা',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _amountField(
                      controller: _minOptionalController,
                      label: 'ঐচ্ছিক জমার ন্যূনতম',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile(
                      title: const Text(
                        'ঐচ্ছিক জমা',
                        style: TextStyle(fontSize: 13.5),
                      ),
                      value: _optionalEnabled,
                      onChanged: (v) =>
                          setState(() => _optionalEnabled = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _treasurerUserId,
                decoration: const InputDecoration(
                  labelText: 'কোষাধ্যক্ষ (ঐচ্ছিক)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('কেউ না'),
                  ),
                  ...treasurerCandidates.map(
                    (m) => DropdownMenuItem<String?>(
                      value: m.linkedUserId,
                      child: Text('${m.name} (সদস্য নং ${m.displayNumber})'),
                    ),
                  ),
                  // বর্তমান UID তালিকায় না থাকলে সেটাও থাকে —
                  // না বদলালে মুছে যায় না।
                  if (!treasurerKnown)
                    DropdownMenuItem<String?>(
                      value: _treasurerUserId,
                      child: Text('বর্তমান: $_treasurerUserId'),
                    ),
                ],
                onChanged: (v) => setState(() => _treasurerUserId = v),
              ),
              _sectionTitle('ব্যাংক তথ্য (ঐচ্ছিক)'),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'ব্যাংক'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankBranchController,
                decoration: const InputDecoration(labelText: 'শাখা'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                // F37: বাংলা অঙ্কে লিখলেও ASCII-তে জমা হয়।
                inputFormatters: const [BnDigitsInputFormatter()],
                decoration: const InputDecoration(labelText: 'অ্যাকাউন্ট নম্বর'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountHolderController,
                decoration: const InputDecoration(labelText: 'অ্যাকাউন্টের নাম'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _routingController,
                keyboardType: TextInputType.number,
                // F37: রাউটিং নম্বরও সংখ্যা — একই স্বাভাবিককরণ।
                inputFormatters: const [BnDigitsInputFormatter()],
                decoration:
                    const InputDecoration(labelText: 'রাউটিং নম্বর (ঐচ্ছিক)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bkashController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: const [BnDigitsInputFormatter()],
                      decoration:
                          const InputDecoration(labelText: 'বিকাশ নম্বর'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nagadController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: const [BnDigitsInputFormatter()],
                      decoration:
                          const InputDecoration(labelText: 'নগদ নম্বর'),
                    ),
                  ),
                ],
              ),
              _sectionTitle('শর্তাবলি (প্রতি লাইনে একটি)'),
              TextFormField(
                controller: _termsController,
                decoration: const InputDecoration(
                  labelText: 'শর্তাবলি',
                  hintText: 'প্রতি লাইনে একটি শর্ত লিখুন',
                ),
                maxLines: 5,
              ),
              _sectionTitle('সদস্যরা কী দেখতে পাবে'),
              SwitchListTile(
                title: const Text(
                  'সদস্যরা মোট তহবিল দেখতে পারবে',
                  style: TextStyle(fontSize: 14),
                ),
                value: _canMembersViewTotalFund,
                onChanged: (v) =>
                    setState(() => _canMembersViewTotalFund = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text(
                  'সদস্যরা খরচের তালিকা দেখতে পারবে',
                  style: TextStyle(fontSize: 14),
                ),
                value: _canMembersViewExpenses,
                onChanged: (v) => setState(() => _canMembersViewExpenses = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text(
                  'সদস্যরা সদস্য তালিকা দেখতে পারবে',
                  style: TextStyle(fontSize: 14),
                ),
                value: _canMembersViewMemberList,
                onChanged: (v) =>
                    setState(() => _canMembersViewMemberList = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _update,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isBn ? 'সংরক্ষণ' : 'Save'),
        ),
      ],
    );
  }
}
