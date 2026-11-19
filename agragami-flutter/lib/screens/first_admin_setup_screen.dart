import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_icon.dart';

/// প্রথমবারের সেটআপ — অ্যাপের প্রথম অ্যাডমিনের অ্যাকাউন্ট।
/// কেউ থাকলে এই পাতা খোলে না — রাউটার আর এই স্ক্রিন নিজে,
/// দুই জায়গাতেই যাচাই করা হয়। যাচাই করা না গেলেও খোলে না
/// (B1: fail closed — অজানা মানেই বন্ধ)। অ্যাডমিন তৈরি হলে আর
/// কখনো এই পাতায় আসা যাবে না।
class FirstAdminSetupScreen extends ConsumerStatefulWidget {
  const FirstAdminSetupScreen({super.key});

  @override
  ConsumerState<FirstAdminSetupScreen> createState() =>
      _FirstAdminSetupScreenState();
}

class _FirstAdminSetupScreenState
    extends ConsumerState<FirstAdminSetupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAlreadyDone();
  }

  Future<void> _checkAlreadyDone() async {
    final hasUsers = await ref.read(firestoreServiceProvider).hasAnyUser();
    if (!mounted) return;
    // B1 fail-closed: ফরম খুলবে শুধু প্রমাণিতভাবে কেউ না থাকলে।
    // কেউ আছে বা যাচাই করা যায়নি — দুই ক্ষেত্রেই লগইনে ফেরত।
    if (hasUsers != false) {
      context.goNamed('login', queryParameters: {'notice': 'setup-blocked'});
      return;
    }
    setState(() => _checking = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'নাম লিখুন');
      return;
    }
    if (!isValidEmail(_email.text.trim())) {
      setState(() => _error = AppStrings.validEmail);
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = AppStrings.passwordTooShort);
      return;
    }
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = AppStrings.passwordsDontMatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // জমা দেওয়ার ঠিক আগেও একবার দেখে নেওয়া — এর মধ্যে
      // কেউ অ্যাডমিন বানিয়ে ফেললে আর দ্বিতীয়জন বানানো যাবে না।
      // যাচাই করা না গেলেও এগোনো হয় না (B1: fail closed)।
      final hasUsers = await ref.read(firestoreServiceProvider).hasAnyUser();
      if (hasUsers != false) {
        if (!mounted) return;
        // m13: এরর সেট করে নেভিগেট নয় — বার্তাটা লগইন
        // স্ক্রিনে পাঠানো হয়, যাতে দেখা যায়।
        context.goNamed('login', queryParameters: {'notice': 'setup-blocked'});
        return;
      }
      await ref.read(authServiceProvider).createFirstAdmin(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      await AppRouter.refreshAuth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.setupDone)),
      );
      context.goNamed('home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = bengaliAuthErrorMessage(e));
    } on FirebaseException catch (e) {
      // F17: সৎ বার্তা — অ্যাপ থেকে superAdmin বানানো rules
      // দিয়ে বন্ধ (ইচ্ছাকৃত)। এটাকে "নেটের সমস্যা" বলা
      // ঠিক নয়: প্রথম অ্যাডমিন Console থেকে বানাতে হয়।
      if (!mounted) return;
      setState(
        () => _error = e.code == 'permission-denied'
            ? 'প্রথম অ্যাডমিন Firebase Console থেকে বানাতে হয় — অ্যাপ থেকে বানানো যায় না'
            : 'অ্যাডমিন অ্যাকাউন্ট বানানো যায়নি — নেট দেখে আবার চেষ্টা করুন',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'অ্যাডমিন অ্যাকাউন্ট বানানো যায়নি — নেট দেখে আবার চেষ্টা করুন',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AgragamiLogo(size: 104, radius: 26)),
              const SizedBox(height: 16),
              Text(
                AppStrings.setupTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.setupSubtitle,
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_checking)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: AppStrings.setupName,
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppStrings.email,
                    prefixIcon: const Icon(Icons.mail_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppStrings.password,
                    prefixIcon: const Icon(Icons.lock_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppStrings.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _busy ? AppStrings.loading : AppStrings.setupButton,
                  onPressed: _busy ? null : _submit,
                  icon: Icons.admin_panel_settings_outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
