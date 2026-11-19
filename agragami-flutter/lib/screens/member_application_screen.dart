import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/cloudinary_config.dart';
import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/firebase_errors.dart';
import '../widgets/app_button.dart';
import 'application/application_account_step.dart';
import 'application/application_info_step.dart';
import 'application/application_photos_step.dart';
import 'application/application_review_step.dart';
import 'application/application_step_bar.dart';
import 'application/application_submit_handler.dart';

/// সদস্য হওয়ার আবেদন — অ্যাকাউন্ট নেই এমন কেউ এলে ৪ ধাপে
/// (অ্যাকাউন্ট, তথ্য, ছবি, যাচাই), ঢুকে থাকলে ৩ ধাপে
/// (তথ্য, ছবি, যাচাই)। অ্যাকাউন্ট আগে খোলা হয় (B1) —
/// সমিতির তালিকা শুধু সাইন-ইন করা ব্যবহারকারী দেখতে পায়,
/// তাই অ্যাকাউন্ট ছাড়া সমিতি বাছা যেত না।
class MemberApplicationScreen extends ConsumerStatefulWidget {
  final String? lockedBranchId;

  const MemberApplicationScreen({super.key, this.lockedBranchId});

  @override
  ConsumerState<MemberApplicationScreen> createState() =>
      _MemberApplicationScreenState();
}

class _MemberApplicationScreenState
    extends ConsumerState<MemberApplicationScreen> {
  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  int _step = 0;
  bool _busy = false;
  String? _error;
  late final bool _showAccountStep;

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

  /// ধাপের নম্বর — অ্যাকাউন্ট ধাপ থাকলে সব এক ঘর সরে যায়।
  int get _infoStep => _showAccountStep ? 1 : 0;
  int get _photosStep => _infoStep + 1;
  int get _reviewStep => _photosStep + 1;

  bool get _onAccountStep => _showAccountStep && _step == 0;
  bool get _accountCreated => AuthService().firebaseUser != null;

  @override
  void initState() {
    super.initState();
    _branchId = widget.lockedBranchId;
    // অ্যাকাউন্ট ধাপ দেখানো হবে কি না — প্রথমবারেই ঠিক করা
    // হয়, পরে অ্যাকাউন্ট খুললেও ধাপের নম্বর বদলায় না।
    _showAccountStep = AuthService().firebaseUser == null;
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
      // m3: ফাইলের নামের এক্সটেনশন দেখে বাতিল করা হয় না —
      // pickImage আগেই JPEG-এ রূপান্তর করে দেয়, কিছু গ্যালারি
      // .webp বা এক্সটেনশন ছাড়া নাম দেয়।
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

  /// ছবি সরানো (Phase 5: ছবি ব্যর্থ হলে এড়ানোর পথ) —
  /// বাছা ছবি মুছে ফেলা যায়, যাতে ছবি ছাড়াই আবেদন
  /// জমা দেওয়া যায়।
  void _removePhoto(PhotoKind kind) {
    setState(() {
      switch (kind) {
        case PhotoKind.photo:
          _photoBytes = null;
        case PhotoKind.nidFront:
          _nidFrontBytes = null;
        case PhotoKind.nidBack:
          _nidBackBytes = null;
      }
    });
  }

  /// অ্যাকাউন্ট ধাপ: ইমেইল-পাসওয়ার্ডে অ্যাকাউন্ট খোলা।
  /// খোলা হয়ে গেলে পরের ধাপে যাওয়া হয় — সমিতির তালিকা
  /// তখন দেখা যাবে, কারণ ব্যবহারকারী এখন সাইন-ইন করা।
  Future<void> _createAccount() async {
    if (_accountCreated) {
      setState(() {
        _error = null;
        _step = _infoStep;
      });
      return;
    }
    final problem = ApplicationValidator.validateAccount(
      email: _email.text.trim(),
      password: _password.text,
      confirmPassword: _confirmPassword.text,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService().signUpWithEmail(
        _email.text.trim(),
        _password.text,
      );
      await AppRouter.refreshAuth();
      if (!mounted) return;
      setState(() {
        _error = null;
        _step = _infoStep;
      });
    } on FirebaseAuthException catch (e) {
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
      setState(() => _error = bengaliAuthErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: AppStrings.applyAccountFailed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    // m4: সমিতি না বাছা থাকলে জোর করে unwrap নয় —
    // আগেই ভুল দেখিয়ে ফেরা হয়।
    final branchId = _branchId;
    if (branchId == null) {
      setState(() => _error = 'কোন সমিতিতে যোগ দিতে চান, বেছে নিন');
      return;
    }
    // ছবি ঐচ্ছিক (M7) — ছবি ছাড়াই আবেদন জমা হয়।
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _submitOnce(branchId: branchId, withPhotos: true);
    } on UploadFailedException catch (_) {
      // Phase 5 (ছবি ব্যর্থ হলে এড়ানোর পথ): ছবি আপলোড
      // না হলে আবেদন আটকে থাকে না — খরচ/নোটিশের মতো
      // "ছবি ছাড়াই জমা দিন" বেছে নেওয়া যায়। আপলোড
      // লেখার আগে হয়, তাই ব্যর্থতায় কিছু লেখা হয়নি —
      // ছবি ছাড়া আবার জমা দেওয়া নিরাপদ।
      if (!mounted) return;
      final submitWithout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ছবি আপলোড হয়নি'),
          content: const Text(
            'ছবিগুলো আপলোড করা যায়নি। ছবি ছাড়াই আবেদন জমা দেবেন?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ছবি ছাড়াই জমা দিন'),
            ),
          ],
        ),
      );
      if (submitWithout != true) {
        if (!mounted) return;
        setState(() => _error = 'ছবি আপলোড হয়নি — আবার চেষ্টা করুন');
        return;
      }
      try {
        await _submitOnce(branchId: branchId, withPhotos: false);
      } catch (e) {
        if (!mounted) return;
        _showSubmitError(e);
      }
    } catch (e) {
      if (!mounted) return;
      _showSubmitError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// একবার জমা দেওয়ার চেষ্টা। সফল হলে স্ন্যাকবার দেখিয়ে
  /// অপেক্ষার পাতায় পাঠানো হয়।
  Future<void> _submitOnce({
    required String branchId,
    required bool withPhotos,
  }) async {
    await ApplicationSubmitHandler.submit(
      store: ref.read(firestoreServiceProvider),
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      emergencyName: _emergencyName.text.trim(),
      emergencyPhone: _emergencyPhone.text.trim(),
      branchId: branchId,
      joinDate: _joinDate,
      nid: _nid.text.trim(),
      photoBytes: withPhotos ? _photoBytes : null,
      nidFrontBytes: withPhotos ? _nidFrontBytes : null,
      nidBackBytes: withPhotos ? _nidBackBytes : null,
    );
    if (!mounted) return;
    // ছবি দিয়েও Cloudinary সেট করা না থাকলে ছবি জমা হয়নি —
    // ব্যবহারকারীকে জানিয়ে দিই, আবেদন তবুও জমা হয়েছে।
    final photosSkipped = withPhotos &&
        (_photoBytes != null ||
            _nidFrontBytes != null ||
            _nidBackBytes != null) &&
        !CloudinaryConfig.isConfigured;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          photosSkipped
              ? 'আবেদন জমা হয়েছে — তবে ছবি আপলোড হয়নি, কারণ ছবি আপলোড এখনো সেট করা হয়নি'
              : 'আবেদন জমা হয়েছে — অ্যাডমিন দেখছেন',
        ),
      ),
    );
    context.goNamed('pending');
  }

  void _showSubmitError(Object e) {
    final err = e is Exception
        ? e.toString().replaceAll('Exception: ', '')
        : firebaseErrorMessage(e, fallback: 'আবেদন জমা হয়নি — আবার চেষ্টা করুন');
    setState(() => _error = err);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err)),
    );
  }

  void _next() {
    if (_onAccountStep) {
      _createAccount();
      return;
    }
    if (_step == _infoStep) {
      final problem = ApplicationValidator.validateInfo(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        emergencyName: _emergencyName.text.trim(),
        emergencyPhone: _emergencyPhone.text.trim(),
        branchId: _branchId,
        nid: _nid.text.trim(),
      );
      if (problem != null) {
        setState(() => _error = problem);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(problem)),
        );
        return;
      }
      setState(() {
        _error = null;
        _step = _photosStep;
      });
    } else if (_step == _photosStep) {
      // ছবি ঐচ্ছিক (M7) — ছবি না দিলেও পরের ধাপে যাওয়া যায়।
      setState(() {
        _error = null;
        _step = _reviewStep;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void handleBack() {
      if (_step > 0) {
        setState(() {
          _error = null;
          _step--;
        });
      } else {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed('samiti');
        }
      }
    }

    final isReview = _step == _reviewStep;
    final nextLabel = isReview
        ? (_busy ? AppStrings.loading : 'জমা দিন')
        : _onAccountStep
            ? (_busy
                ? AppStrings.loading
                : (_accountCreated ? 'পরের ধাপ' : 'অ্যাকাউন্ট খুলুন'))
            : 'পরের ধাপ';

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) {
          setState(() {
            _error = null;
            _step--;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('সদস্য হওয়ার আবেদন'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'ফিরে যান',
            onPressed: handleBack,
          ),
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApplicationStepBar(
              step: _step,
              labels: _showAccountStep
                  ? const ['অ্যাকাউন্ট', 'তথ্য', 'ছবি', 'যাচাই']
                  : const ['তথ্য', 'ছবি', 'যাচাই'],
            ),
            const SizedBox(height: 18),
            if (_onAccountStep)
              ApplicationAccountStep(
                email: _email,
                password: _password,
                confirmPassword: _confirmPassword,
                accountCreated: _accountCreated,
              ),
            if (_step == _infoStep)
              ApplicationInfoStep(
                name: _name,
                phone: _phone,
                address: _address,
                emergencyName: _emergencyName,
                emergencyPhone: _emergencyPhone,
                nid: _nid,
                branchId: _branchId,
                lockedBranchId: widget.lockedBranchId,
                onBranchChanged: (v) => setState(() => _branchId = v),
                joinDate: _joinDate,
                onJoinDateChanged: (d) => setState(() => _joinDate = d),
              ),
            if (_step == _photosStep)
              ApplicationPhotosStep(
                photoBytes: _photoBytes,
                nidFrontBytes: _nidFrontBytes,
                nidBackBytes: _nidBackBytes,
                onPickPhoto: _pickPhoto,
                onRemovePhoto: _removePhoto,
              ),
            if (isReview)
              ApplicationReviewStep(
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                email: AuthService().firebaseUser?.email ??
                    _email.text.trim(),
                branchId: _branchId,
                address: _address.text.trim(),
                emergencyName: _emergencyName.text.trim(),
                emergencyPhone: _emergencyPhone.text.trim(),
                nid: _nid.text.trim(),
                joinDate: _joinDate,
                photoBytes: _photoBytes,
                nidFrontBytes: _nidFrontBytes,
                nidBackBytes: _nidBackBytes,
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
                    label: nextLabel,
                    onPressed: _busy ? null : (isReview ? _submit : _next),
                    icon: isReview
                        ? Icons.send_outlined
                        : Icons.arrow_forward_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
