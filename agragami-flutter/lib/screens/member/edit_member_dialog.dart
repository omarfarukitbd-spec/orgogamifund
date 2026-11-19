import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings.dart';
import '../../models/member.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/bn_digits.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../application/application_submit_handler.dart';

/// সদস্যের তথ্য বদলানো (B7) — নাম, ফোন, ঠিকানা, এনআইডি,
/// জরুরি যোগাযোগ, ভর্তির তারিখ, ছবি, সক্রিয়/নিষ্ক্রিয়।
/// শুধু অ্যাডমিন ব্যবহার করে (rules: members update অ্যাডমিন)।
/// নিষ্ক্রিয় করলে সদস্য 'left' হয় — রেকর্ড মুছে যায় না,
/// বকেয়া/জমার হিসাব আগের মতোই থাকে।
class EditMemberDialog extends ConsumerStatefulWidget {
  final Member member;

  const EditMemberDialog({super.key, required this.member});

  @override
  ConsumerState<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends ConsumerState<EditMemberDialog> {
  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _nid;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyPhone;
  // Phase 5 (F21): ভর্তির তারিখ জানা না থাকলে null থাকে —
  // 1970 sentinel (তারিখ জানা নেই) কখনো "আজকের তারিখ"
  // বানানো হয় না, আর না বদলালে Firestore-এ লেখাও হয় না।
  DateTime? _joinDate;
  late bool _active;
  Uint8List? _photoBytes;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _name = TextEditingController(text: m.name);
    _phone = TextEditingController(text: m.phone);
    _address = TextEditingController(text: m.address);
    _nid = TextEditingController(text: m.nidNumber);
    _emergencyName = TextEditingController(text: m.emergencyContactName);
    _emergencyPhone = TextEditingController(text: m.emergencyContactPhone);
    _joinDate = m.joinDate.year < 2000 ? null : m.joinDate;
    _active = m.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _nid.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        if (!mounted) return;
        setState(() => _error = 'ছবিটি ৫ MB-এর বেশি — ছোট ছবি বেছে নিন');
        return;
      }
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _error = null;
      });
    } catch (e) {
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'ছবি নেওয়া যায়নি — আবার চেষ্টা করুন',
        ),
      );
    }
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      // তারিখ জানা না থাকলে আজকের তারিখ থেকে বাছা শুরু হয় —
      // বাছলেই তবে সেটা লেখা হয়, না বাছলে "তারিখ নেই"-ই থাকে।
      initialDate: _joinDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _joinDate = picked);
  }

  Future<void> _save({required bool withPhoto}) async {
    final joinDate = _joinDate;
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': toAsciiDigits(_phone.text.trim()),
      'address': _address.text.trim(),
      'nid': toAsciiDigits(_nid.text.trim()),
      'emergencyContact': {
        'name': _emergencyName.text.trim(),
        'phone': toAsciiDigits(_emergencyPhone.text.trim()),
      },
      // F21: তারিখ জানা না থাকলে ক্ষেত্রটা লেখা হয় না —
      // পুরোনো 1970 sentinel যেমন আছে তেমনই থাকে।
      if (joinDate != null) 'joinDate': Timestamp.fromDate(joinDate),
      'status': _active ? 'active' : 'left',
    };
    await ref.read(firestoreServiceProvider).updateMember(
          memberId: widget.member.id,
          data: data,
          photoBytes: withPhoto ? _photoBytes : null,
          by: AuthService().uidOrEmpty,
        );
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'নাম লিখুন');
      return;
    }
    if (!ApplicationValidator.isPhone(_phone.text.trim())) {
      setState(() => _error = 'সঠিক মোবাইল নম্বর দিন — ০১ দিয়ে শুরু, ১১ সংখ্যা');
      return;
    }
    if (_address.text.trim().isEmpty) {
      setState(() => _error = 'ঠিকানা লিখুন');
      return;
    }
    if (!ApplicationValidator.isNid(_nid.text.trim())) {
      setState(() => _error = 'সঠিক এনআইডি নম্বর দিন — ১০, ১৩ বা ১৭ সংখ্যা');
      return;
    }
    if (_emergencyName.text.trim().isEmpty) {
      setState(() => _error = 'জরুরি যোগাযোগের নাম লিখুন');
      return;
    }
    if (!ApplicationValidator.isPhone(_emergencyPhone.text.trim())) {
      setState(() => _error = 'জরুরি যোগাযোগের সঠিক মোবাইল নম্বর দিন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _save(withPhoto: true);
      if (!mounted) return;
      invalidateTotals(ref);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সদস্যের তথ্য বদলানো হয়েছে')),
      );
    } on UploadFailedException catch (_) {
      // ছবি আপলোড হয়নি — ছবি ছাড়াই বদলানো যাবে কি না জিজ্ঞেস করা হয়।
      if (!mounted) return;
      final saveWithout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ছবি আপলোড হয়নি'),
          content: const Text(
            'নতুন ছবিটা আপলোড করা যায়নি। ছবি ছাড়াই তথ্য বদলাবেন?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ছবি ছাড়াই বদলান'),
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
        await _save(withPhoto: false);
        if (!mounted) return;
        invalidateTotals(ref);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সদস্যের তথ্য বদলানো হয়েছে')),
        );
      } catch (e) {
        // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
        if (!mounted) return;
        setState(
          () => _error = firebaseErrorMessage(
            e,
            fallback: 'সদস্যের তথ্য বদলানো যায়নি — আবার চেষ্টা করুন',
          ),
        );
      }
    } catch (e) {
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'সদস্যের তথ্য বদলানো যায়নি — আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.member.photoUrl;
    return AlertDialog(
      title: const Text('সদস্যের তথ্য বদলান'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.greenSoft,
                  backgroundImage: _photoBytes != null
                      ? MemoryImage(_photoBytes!)
                      : (photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null),
                  child: _photoBytes == null &&
                          (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(
                          Icons.person_outline,
                          color: AppColors.green,
                          size: 32,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('ছবি বদলান'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'পুরো নাম',
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: const [BnDigitsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
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
            const SizedBox(height: 12),
            TextField(
              controller: _nid,
              keyboardType: TextInputType.number,
              inputFormatters: const [BnDigitsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'এনআইডি নম্বর',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyName,
              decoration: const InputDecoration(
                labelText: 'জরুরি যোগাযোগের নাম',
                prefixIcon: Icon(Icons.contact_phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyPhone,
              keyboardType: TextInputType.phone,
              inputFormatters: const [BnDigitsInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'জরুরি যোগাযোগের মোবাইল',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const ListIcon(
                  icon: Icons.calendar_month_outlined,
                  size: 44,
                ),
                title: const Text(
                  'ভর্তির তারিখ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  // F21: তারিখ জানা না থাকলে "তারিখ নেই" দেখায়।
                  _joinDate == null
                      ? 'তারিখ নেই'
                      : '${_joinDate!.day}/${_joinDate!.month}/${_joinDate!.year}',
                  style:
                      const TextStyle(fontSize: 13.5, color: AppColors.muted),
                ),
                trailing: TextButton(
                  onPressed: _pickJoinDate,
                  child: const Text('বদলান'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('সক্রিয় সদস্য'),
              subtitle: Text(
                _active
                    ? 'সদস্য সক্রিয় আছে'
                    : 'নিষ্ক্রিয় — সদস্য তালিকা আর বকেয়ায় ধরা হবে না',
              ),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              contentPadding: EdgeInsets.zero,
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
          label: _busy ? AppStrings.loading : AppStrings.save,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
