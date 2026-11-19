import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';

/// নিজের প্রোফাইলের নাম বদলানো (M5) — নিজের users
/// ডকুমেন্টে শুধু নাম লেখা হয়। ফোন/ঠিকানা/ছবি সদস্যের
/// রেকর্ডে থাকে — সেটা অ্যাডমিন বদলায় (সদস্য সম্পাদনা)।
class EditProfileDialog extends ConsumerStatefulWidget {
  final AppUser user;

  const EditProfileDialog({super.key, required this.user});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final TextEditingController _name;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'নাম লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(firestoreServiceProvider).updateProfileName(
            uid: widget.user.id,
            name: _name.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নাম বদলানো হয়েছে')),
      );
    } catch (e) {
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'নাম বদলানো যায়নি — আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('প্রোফাইল বদলান'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'আপনার নাম',
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ফোন নম্বর, ঠিকানা বা ছবি বদলাতে অ্যাডমিনের সাথে যোগাযোগ করুন — সেগুলো সদস্যের রেকর্ডে থাকে।',
              style: TextStyle(fontSize: 13, color: Colors.grey),
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
