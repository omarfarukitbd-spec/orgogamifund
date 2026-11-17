import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'application/application_info_step.dart';
import 'application/application_photos_step.dart';
import 'application/application_review_step.dart';
import 'application/application_step_bar.dart';
import 'application/application_submit_handler.dart';

/// সদস্য হওয়ার আবেদন — ৩ ধাপে তথ্য, ছবি ও নিশ্চিতকরণ।
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

  bool get _needsAccount => AuthService().firebaseUser == null;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickPhoto(PhotoKind kind) async {
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
          case PhotoKind.photo:
            _photoBytes = bytes;
          case PhotoKind.nidFront:
            _nidFrontBytes = bytes;
          case PhotoKind.nidBack:
            _nidBackBytes = bytes;
        }
      });
    } catch (_) {
      setState(() => _error = 'ছবি নেওয়া যায়নি — আবার চেষ্টা করুন');
    }
  }

  Future<void> _submit() async {
    if (_photoBytes == null || _nidFrontBytes == null) {
      setState(() => _error = 'নিজের ছবি ও এনআইডির সামনের ছবি দুটোই দিন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApplicationSubmitHandler.submit(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        emergencyName: _emergencyName.text.trim(),
        emergencyPhone: _emergencyPhone.text.trim(),
        branchId: _branchId!,
        joinDate: _joinDate,
        nid: _nid.text.trim(),
        needsAccount: _needsAccount,
        email: _email.text.trim(),
        password: _password.text,
        photoBytes: _photoBytes!,
        nidFrontBytes: _nidFrontBytes!,
        nidBackBytes: _nidBackBytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আবেদন জমা হয়েছে — অ্যাডমিন দেখছেন')),
      );
      context.go('/pending');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (_step == 0) {
      final problem = ApplicationValidator.validateInfo(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        emergencyName: _emergencyName.text.trim(),
        emergencyPhone: _emergencyPhone.text.trim(),
        branchId: _branchId,
        nid: _nid.text.trim(),
        needsAccount: _needsAccount,
        email: _email.text.trim(),
        password: _password.text,
        confirmPassword: _confirmPassword.text,
      );
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
        setState(() => _error = 'নিজের ছবি আর এনআইডির সামনের ছবি লাগবে');
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApplicationStepBar(step: _step),
            const SizedBox(height: 18),
            if (_step == 0)
              ApplicationInfoStep(
                name: _name,
                phone: _phone,
                address: _address,
                emergencyName: _emergencyName,
                emergencyPhone: _emergencyPhone,
                nid: _nid,
                email: _email,
                password: _password,
                confirmPassword: _confirmPassword,
                branchId: _branchId,
                lockedBranchId: widget.lockedBranchId,
                onBranchChanged: (v) => setState(() => _branchId = v),
                joinDate: _joinDate,
                onJoinDateChanged: (d) => setState(() => _joinDate = d),
                needsAccount: _needsAccount,
              ),
            if (_step == 1)
              ApplicationPhotosStep(
                photoBytes: _photoBytes,
                nidFrontBytes: _nidFrontBytes,
                nidBackBytes: _nidBackBytes,
                onPickPhoto: _pickPhoto,
              ),
            if (_step == 2)
              ApplicationReviewStep(
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                email: _email.text.trim(),
                branchId: _branchId,
                address: _address.text.trim(),
                emergencyName: _emergencyName.text.trim(),
                emergencyPhone: _emergencyPhone.text.trim(),
                nid: _nid.text.trim(),
                joinDate: _joinDate,
                photoBytes: _photoBytes,
                nidFrontBytes: _nidFrontBytes,
                nidBackBytes: _nidBackBytes,
                needsAccount: _needsAccount,
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13.5),
              ),
            ],
            const SizedBox(height: 20),
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
                    onPressed: _busy ? null : (_step == 2 ? _submit : _next),
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
}
