import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/member_application.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';

/// সদস্য হওয়ার আবেদন — ৩ ধাপে।
/// ১. নিজের তথ্য  ২. ছবি আর এনআইডির ছবি  ৩. দেখে নিয়ে জমা।
/// জমা হলে অবস্থা pending — অ্যাডমিন অনুমোদন দিলে তবেই সদস্য হওয়া যায়।
/// সমিতির পাতা থেকে এলে ওই সমিতিটাই বাঁধা থাকে (lockedBranchId) —
/// আবেদনকারী সমিতি বদলাতে পারে না। ওই সমিতির সদস্য হয়ে থাকলে
/// বা আবেদন বাকি থাকলে আর আবেদন জমা হয় না।
class MemberApplicationScreen extends StatefulWidget {
  final String? lockedBranchId;

  const MemberApplicationScreen({super.key, this.lockedBranchId});

  @override
  State<MemberApplicationScreen> createState() =>
      _MemberApplicationScreenState();
}

class _MemberApplicationScreenState extends State<MemberApplicationScreen> {
  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  int _step = 0;
  bool _busy = false;
  String? _error;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _nid = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _branchId;
  DateTime _joinDate = DateTime.now();

  Uint8List? _photoBytes;
  Uint8List? _nidFrontBytes;
  Uint8List? _nidBackBytes;

  /// ঢুকে থাকলে নতুন অ্যাকাউন্ট লাগবে না — আগের অ্যাকাউন্টেই আবেদন যাবে।
  bool get _needsAccount => AuthService().firebaseUser == null;

  @override
  void initState() {
    super.initState();
    // সমিতির পাতা থেকে এলে ওই সমিতিটাই আগে থেকে বেছে রাখা হয়।
    _branchId = widget.lockedBranchId;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    _nid.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool _isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String? _checkInfo() {
    if (_name.text.trim().isEmpty) return 'নাম লিখুন';
    if (!_isPhone(_phone.text.trim())) {
      return 'সঠিক মোবাইল নম্বর দিন — ০১ দিয়ে শুরু, ১১ সংখ্যা';
    }
    if (_address.text.trim().isEmpty) return 'ঠিকানা লিখুন';
    if (_emergencyName.text.trim().isEmpty) {
      return 'জরুরি যোগাযোগের নাম লিখুন';
    }
    if (!_isPhone(_emergencyPhone.text.trim())) {
      return 'জরুরি যোগাযোগের সঠিক মোবাইল নম্বর দিন';
    }
    if (_branchId == null) return 'কোন সমিতিতে যোগ দিতে চান, বেছে নিন';
    if (!_isNid(_nid.text.trim())) {
      return 'সঠিক এনআইডি নম্বর দিন — ১০, ১৩ বা ১৭ সংখ্যা';
    }
    if (_needsAccount) {
      if (!_isEmail(_email.text.trim())) return AppStrings.validEmail;
      if (_password.text.length < 6) return AppStrings.passwordTooShort;
      if (_password.text != _confirmPassword.text) {
        return AppStrings.passwordsDontMatch;
      }
    }
    return null;
  }

  bool _isPhone(String value) {
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(value);
  }

  bool _isNid(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) return false;
    return value.length == 10 || value.length == 13 || value.length == 17;
  }

  Future<void> _pickPhoto(_PhotoKind kind) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final name = picked.name.toLowerCase();
      if (!name.endsWith('.jpg') &&
          !name.endsWith('.jpeg') &&
          !name.endsWith('.png')) {
        setState(() => _error = 'ছবি JPG বা PNG হতে হবে');
        return;
      }
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        setState(() => _error = 'ছবিটি ৫ MB-এর বেশি — ছোট ছবি বেছে নিন');
        return;
      }
      setState(() {
        _error = null;
        switch (kind) {
          case _PhotoKind.photo:
            _photoBytes = bytes;
          case _PhotoKind.nidFront:
            _nidFrontBytes = bytes;
          case _PhotoKind.nidBack:
            _nidBackBytes = bytes;
        }
      });
    } catch (_) {
      setState(() => _error = 'ছবি নেওয়া যায়নি — আবার চেষ্টা করুন');
    }
  }

  Future<void> _submit() async {
    if (_photoBytes == null) {
      setState(() => _error = 'নিজের ছবি যোগ করুন');
      return;
    }
    if (_nidFrontBytes == null) {
      setState(() => _error = 'এনআইডির সামনের ছবি যোগ করুন');
      return;
    }
    // ঢুকে থাকলে আগেই দেখে নেওয়া হয় — ওই সমিতির সদস্য হয়ে
    // থাকলে বা আবেদন বাকি থাকলে আর আবেদন জমা হবে না।
    final loggedInUid = AuthService().uidOrEmpty;
    if (loggedInUid.isNotEmpty && _branchId != null) {
      final existing = await FirestoreService().getMembership(
        loggedInUid,
        _branchId!,
      );
      if (existing?.isApproved ?? false) {
        setState(() => _error = AppStrings.alreadyMemberOfBranch);
        return;
      }
      if (existing?.isPending ?? false) {
        setState(() => _error = AppStrings.alreadyAppliedForBranch);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    // আবেদনের সাথে অ্যাকাউন্টও খোলা হয় — তাই জমা দেওয়ার আগে
    // অ্যাকাউন্ট বানানো হয়, তারপর আবেদন লেখা হয়।
    // ইমেইলটা আগেই ধরে রাখা হলো — সাইন-আপের পর হিসাব বদলে যায়।
    final accountEmail =
        _needsAccount ? _email.text.trim() : AuthService().firebaseUser?.email;
    var createdAccount = false;
    try {
      String uid;
      final current = AuthService().firebaseUser;
      if (current != null) {
        uid = current.uid;
      } else {
        try {
          await AuthService().signUpWithEmail(
            _email.text.trim(),
            _password.text,
          );
          createdAccount = true;
          uid = AuthService().uidOrEmpty;
          if (uid.isEmpty) throw Exception('no uid');
        } on FirebaseAuthException catch (e) {
          setState(() => _error = bengaliAuthErrorMessage(e));
          return;
        }
      }
      final application = MemberApplication(
        id: '',
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        emergencyContactName: _emergencyName.text.trim(),
        emergencyContactPhone: _emergencyPhone.text.trim(),
        branchId: _branchId!,
        joinDate: _joinDate,
        nidNumber: _nid.text.trim(),
        applicantUid: uid,
        email: accountEmail,
        requestedAt: DateTime.now(),
      );
      try {
        await FirestoreService().submitMemberApplication(
          application: application,
          photoBytes: _photoBytes,
          nidFrontBytes: _nidFrontBytes,
          nidBackBytes: _nidBackBytes,
        );
      } catch (_) {
        // অ্যাকাউন্ট হয়ে গেছে, আবেদন জমা হয়নি — অ্যাকাউন্ট মুছে
        // ফেলা হলো, যাতে একই ইমেইলে আবার আবেদন করা যায়।
        // মুছতে না পারলে লগইন করে আবার চেষ্টা করতে বলা হলো।
        var deleted = false;
        if (createdAccount) {
          try {
            await AuthService().firebaseUser?.delete();
            deleted = true;
          } catch (_) {}
        }
        setState(
          () => _error = deleted
              ? 'আবেদন জমা হয়নি — নেট দেখে আবার চেষ্টা করুন'
              : AppStrings.applyFailedAfterAccount,
        );
        return;
      }
      await AppRouter.refreshAuth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আবেদন জমা হয়েছে — অ্যাডমিন দেখছেন')),
      );
      context.go('/pending');
    } catch (_) {
      setState(() => _error = 'আবেদন জমা হয়নি — নেট দেখে আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (_step == 0) {
      final problem = _checkInfo();
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
      setState(() {
        _error = null;
        _step = 1;
      });
    } else if (_step == 1) {
      if (_photoBytes == null || _nidFrontBytes == null) {
        setState(
          () => _error = 'নিজের ছবি আর এনআইডির সামনের ছবি — দুটোই লাগবে',
        );
        return;
      }
      setState(() {
        _error = null;
        _step = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সদস্য হওয়ার আবেদন')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepBar(step: _step),
            const SizedBox(height: 20),
            if (_step == 0) _infoStep(),
            if (_step == 1) _photoStep(),
            if (_step == 2) _reviewStep(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: SecondaryButton(
                      label: 'পেছনে',
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _error = null;
                                _step--;
                              }),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: _step == 2
                        ? (_busy ? AppStrings.loading : 'জমা দিন')
                        : 'পরের ধাপ',
                    onPressed: _busy
                        ? null
                        : (_step == 2 ? _submit : _next),
                    icon: _step == 2
                        ? Icons.send_outlined
                        : Icons.arrow_forward_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoStep() {
    return StreamBuilder<List<Branch>>(
      stream: FirestoreService().watchBranches(),
      builder: (context, snapshot) {
        final branches = snapshot.data ?? const <Branch>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'প্রথমে আপনার তথ্য দিন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
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
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                hintText: '01XXXXXXXXX',
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
              decoration: const InputDecoration(
                labelText: 'জরুরি যোগাযোগের মোবাইল',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.lockedBranchId != null)
              _LockedBranchTile(
                branchName: branches
                    .where((b) => b.id == widget.lockedBranchId)
                    .map((b) => b.name)
                    .firstOrNull,
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _branchId,
                decoration: const InputDecoration(
                  labelText: 'কোন সমিতি',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                items: branches
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _branchId = v),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _nid,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'এনআইডি নম্বর',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            if (_needsAccount) ...[
              const SizedBox(height: 16),
              const Text(
                'এই ইমেইল আর পাসওয়ার্ড দিয়ে পরে ঢুকতে পারবেন। '
                'অ্যাডমিন অনুমোদন দিলে তবেই ঢোকা যাবে।',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ইমেইল',
                  prefixIcon: Icon(Icons.mail_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'পাসওয়ার্ড আবার লিখুন',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('ভর্তির তারিখ'),
              subtitle: Text(
                '${_joinDate.day}/${_joinDate.month}/${_joinDate.year}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _joinDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _joinDate = picked);
                  }
                },
                child: const Text('বদলান'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _photoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'এবার ছবি যোগ করুন',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('ছবি JPG বা PNG হতে হবে, ৫ MB-এর বেশি নয়।'),
        const SizedBox(height: 16),
        _PhotoPickTile(
          label: 'নিজের ছবি',
          bytes: _photoBytes,
          onPick: () => _pickPhoto(_PhotoKind.photo),
        ),
        const SizedBox(height: 12),
        _PhotoPickTile(
          label: 'এনআইডির সামনের ছবি',
          bytes: _nidFrontBytes,
          onPick: () => _pickPhoto(_PhotoKind.nidFront),
        ),
        const SizedBox(height: 12),
        _PhotoPickTile(
          label: 'এনআইডির পেছনের ছবি (যদি থাকে)',
          bytes: _nidBackBytes,
          onPick: () => _pickPhoto(_PhotoKind.nidBack),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return StreamBuilder<List<Branch>>(
      stream: FirestoreService().watchBranches(),
      builder: (context, snapshot) {
        final branches = snapshot.data ?? const <Branch>[];
        final branchName = branches
            .where((b) => b.id == _branchId)
            .map((b) => b.name)
            .firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'দেখে নিন, তারপর জমা দিন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _ReviewRow('নাম', _name.text.trim()),
            _ReviewRow('মোবাইল', _phone.text.trim()),
            if (_needsAccount) _ReviewRow('ইমেইল', _email.text.trim()),
            if (branchName != null) _ReviewRow('সমিতি', branchName),
            _ReviewRow('ঠিকানা', _address.text.trim()),
            _ReviewRow('জরুরি যোগাযোগ',
                '${_emergencyName.text.trim()} — ${_emergencyPhone.text.trim()}'),
            _ReviewRow('এনআইডি', _nid.text.trim()),
            _ReviewRow('ভর্তির তারিখ',
                '${_joinDate.day}/${_joinDate.month}/${_joinDate.year}'),
            const SizedBox(height: 8),
            if (_photoBytes != null)
              _ReviewPhoto('নিজের ছবি', _photoBytes!),
            if (_nidFrontBytes != null)
              _ReviewPhoto('এনআইডির সামনে', _nidFrontBytes!),
            if (_nidBackBytes != null)
              _ReviewPhoto('এনআইডির পেছনে', _nidBackBytes!),
            const SizedBox(height: 12),
            const Text(
              'জমা দিলে অ্যাডমিন আপনার আবেদন দেখে অনুমোদন দেবেন। '
              'অনুমোদন হলে তবেই সদস্য হিসেবে ঢুকতে পারবেন।',
            ),
          ],
        );
      },
    );
  }
}

enum _PhotoKind { photo, nidFront, nidBack }

/// সমিতির পাতা থেকে এলে সমিতির নাম — বদলানো যায় না।
class _LockedBranchTile extends StatelessWidget {
  final String? branchName;

  const _LockedBranchTile({this.branchName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.groups_outlined),
          title: Text(branchName ?? 'সমিতি'),
          subtitle: const Text(AppStrings.lockedBranchNote),
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  final int step;

  const _StepBar({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['তথ্য', 'ছবি', 'দেখে নিন'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          _StepDot(number: i + 1, label: labels[i], done: i < step, active: i == step),
          if (i < labels.length - 1)
            const Expanded(child: Divider(thickness: 2)),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool done;
  final bool active;

  const _StepDot({
    required this.number,
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = done || active ? Colors.green : Colors.grey;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Text(
            '$number',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _PhotoPickTile extends StatelessWidget {
  final String label;
  final Uint8List? bytes;
  final VoidCallback onPick;

  const _PhotoPickTile({
    required this.label,
    required this.bytes,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: bytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bytes!, width: 56, height: 56, fit: BoxFit.cover),
            )
          : const Icon(Icons.image_outlined, size: 40),
      title: Text(label),
      subtitle: Text(bytes != null ? 'ছবি যোগ হয়েছে' : 'এখনো ছবি যোগ হয়নি'),
      trailing: OutlinedButton(
        onPressed: onPick,
        child: Text(bytes != null ? 'বদলান' : 'ছবি নিন'),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ReviewPhoto extends StatelessWidget {
  final String label;
  final Uint8List bytes;

  const _ReviewPhoto(this.label, this.bytes);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
