import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// বিদ্যমান সমিতির তথ্য সম্পাদনের ডায়ালগ — শুধুমাত্র অ্যাডমিন ব্যবহার করতে পারবে।
class EditSamitiDialog extends StatefulWidget {
  final Branch branch;

  const EditSamitiDialog({super.key, required this.branch});

  @override
  State<EditSamitiDialog> createState() => _EditSamitiDialogState();
}

class _EditSamitiDialogState extends State<EditSamitiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _donationController;
  late SamitiPurpose _purpose;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch.name);
    _descriptionController =
        TextEditingController(text: widget.branch.description);
    _donationController = TextEditingController(
      text: widget.branch.monthlyDonation.toString(),
    );
    _purpose = widget.branch.purpose;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _donationController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final isBn = AppStrings.isBangla;
    try {
      await FirestoreService().updateBranch(
        branchId: widget.branch.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        purpose: _purpose,
        monthlyDonation: int.parse(_donationController.text.trim()),
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn ? 'সমিতি আপডেট করা যায়নি' : 'Failed to update samiti',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = AppStrings.isBangla;
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
                controller: _donationController,
                decoration: InputDecoration(
                  labelText: AppStrings.monthlyDonationLabel,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return isBn ? 'টাকার পরিমাণ লিখুন' : 'Enter amount';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) {
                    return isBn ? 'সঠিক টাকা লিখুন' : 'Enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppStrings.descriptionLabel,
                ),
                maxLines: 3,
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
