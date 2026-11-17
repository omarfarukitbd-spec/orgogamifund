import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// নতুন সমিতি খোলার ফরম — শুধু অ্যাডমিন দেখতে পায়।
class CreateSamitiDialog extends StatefulWidget {
  const CreateSamitiDialog({super.key});

  @override
  State<CreateSamitiDialog> createState() => _CreateSamitiDialogState();
}

class _CreateSamitiDialogState extends State<CreateSamitiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _donationController = TextEditingController();
  SamitiPurpose _purpose = SamitiPurpose.madrasa;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _donationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await FirestoreService().createBranch(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        purpose: _purpose,
        monthlyDonation: int.parse(_donationController.text.trim()),
        by: AuthService().uidOrEmpty,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.samitiCreated)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.samitiCreateFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.createSamiti),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.samitiNameLabel,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SamitiPurpose>(
                initialValue: _purpose,
                decoration: const InputDecoration(
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
              TextFormField(
                controller: _donationController,
                decoration: const InputDecoration(
                  labelText: AppStrings.monthlyDonation,
                  suffixText: '৳',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'পরিমাণ লিখুন';
                  if (int.tryParse(v.trim()) == null) {
                    return 'শুধু সংখ্যা লিখুন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
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
