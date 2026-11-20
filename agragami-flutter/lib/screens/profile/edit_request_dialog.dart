import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/edit_request.dart';
import '../../models/member.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/bn_digits.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../application/application_submit_handler.dart';

/// সদস্যের তথ্য সংশোধনের আবেদনের ফরম (Phase 9, G12)।
/// সাধারণ সদস্য নিজের ফোন/ঠিকানা বদলানোর আবেদন করে —
/// অ্যাডমিন অনুমোদন দিলে তবেই তথ্য বদলায়। rules (§8):
/// আবেদন শুধু নিজের linkedMemberId-এর জন্য করা যায়।
class EditRequestDialog extends ConsumerStatefulWidget {
  final Member member;

  const EditRequestDialog({super.key, required this.member});

  @override
  ConsumerState<EditRequestDialog> createState() =>
      _EditRequestDialogState();
}

class _EditRequestDialogState extends ConsumerState<EditRequestDialog> {
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.member.phone);
    _address = TextEditingController(text: widget.member.address);
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!ApplicationValidator.isPhone(_phone.text.trim())) {
      setState(() => _error = 'সঠিক মোবাইল নম্বর দিন — ০১ দিয়ে শুরু, ১১ সংখ্যা');
      return;
    }
    if (_address.text.trim().isEmpty) {
      setState(() => _error = 'ঠিকানা লিখুন');
      return;
    }
    // শুধু বদলানো ক্ষেত্রই আবেদনে যায় — কিছু না বদলালে
    // আবেদন জমা হয় না।
    final diff = EditRequest.diff(
      oldPhone: widget.member.phone,
      newPhone: toAsciiDigits(_phone.text.trim()),
      oldAddress: widget.member.address,
      newAddress: _address.text.trim(),
    );
    if (diff.changes.isEmpty) {
      setState(() => _error = 'কিছুই বদলায়নি — বদলাতে চাওয়া তথ্য লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(firestoreServiceProvider).submitEditRequest(
            request: EditRequest(
              id: '',
              memberId: widget.member.id,
              branchId: widget.member.branchId,
              requestedBy: AuthService().uidOrEmpty,
              memberName: widget.member.name,
              changes: diff.changes,
              previous: diff.previous,
              requestedAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আবেদন জমা হয়েছে — অ্যাডমিন অনুমোদন দিলে তথ্য বদলে যাবে'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'আবেদন জমা হয়নি — আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('তথ্য সংশোধনের আবেদন'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ফোন বা ঠিকানা বদলাতে চাইলে নতুন তথ্য লিখুন। অ্যাডমিন অনুমোদন দিলে তবেই বদলে যাবে।',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'ফোন নম্বর',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ঠিকানা',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
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
          label: _busy ? 'জমা হচ্ছে…' : 'আবেদন জমা দিন',
          onPressed: _busy ? null : _submit,
          icon: Icons.send_outlined,
        ),
      ],
    );
  }
}
