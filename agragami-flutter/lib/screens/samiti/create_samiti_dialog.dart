import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/bn_digits.dart';
import '../../utils/firebase_errors.dart';
import '../../utils/validators.dart';

/// নতুন সমিতি খোলার ফরম — শুধু অ্যাডমিন দেখতে পায়।
/// লাইভ স্কিমার আর্থিক নিয়মগুলো খোলার সময়ই বসানো যায়
/// (B8) — নতুন সমিতিতেও পুরোনো সমিতির মতো একই ক্ষেত্র থাকে।
class CreateSamitiDialog extends ConsumerStatefulWidget {
  const CreateSamitiDialog({super.key});

  @override
  ConsumerState<CreateSamitiDialog> createState() =>
      _CreateSamitiDialogState();
}

class _CreateSamitiDialogState extends ConsumerState<CreateSamitiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _donationController = TextEditingController();
  final _admissionController = TextEditingController(text: '0');
  final _dueDayController = TextEditingController(text: '10');
  final _lateFineController = TextEditingController(text: '0');
  final _minOptionalController = TextEditingController(text: '0');
  SamitiPurpose _purpose = SamitiPurpose.madrasa;
  bool _optionalEnabled = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _donationController.dispose();
    _admissionController.dispose();
    _dueDayController.dispose();
    _lateFineController.dispose();
    _minOptionalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(firestoreServiceProvider).createBranch(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        purpose: _purpose,
        monthlyDepositAmount: parseAmount(_donationController.text) ?? 0,
        admissionFee: parseAmount(_admissionController.text) ?? 0,
        monthlyDueDay: parseAmount(_dueDayController.text) ?? 10,
        lateFineAmount: parseAmount(_lateFineController.text) ?? 0,
        minOptionalDeposit: parseAmount(_minOptionalController.text) ?? 0,
        optionalDepositEnabled: _optionalEnabled,
        by: AuthService().uidOrEmpty,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.samitiCreated)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(e, fallback: AppStrings.samitiCreateFailed),
          ),
        ),
      );
    }
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
    return AlertDialog(
      title: Text(AppStrings.createSamiti),
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
                    (v == null || v.trim().isEmpty) ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SamitiPurpose>(
                initialValue: _purpose,
                decoration: InputDecoration(
                  labelText: AppStrings.samitiPurposeLabel,
                ),
                items: SamitiPurpose.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(samitiPurposeText(p)),
                      ),
                    )
                    .toList(),
                onChanged: (p) {
                  if (p != null) setState(() => _purpose = p);
                },
              ),
              const SizedBox(height: 12),
              _amountField(
                controller: _donationController,
                label: AppStrings.monthlyDonation,
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
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppStrings.samitiDescriptionLabel,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'খোলা হচ্ছে…' : AppStrings.createSamiti),
        ),
      ],
    );
  }
}
