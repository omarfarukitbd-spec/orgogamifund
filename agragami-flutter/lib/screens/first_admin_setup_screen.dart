import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_icon.dart';

/// প্রথমবারের সেটআপ — অ্যাপের প্রথম অ্যাডমিনের অ্যাকাউন্ট।
/// কেউ থাকলে এই পাতা খোলে না — রাউটার আর এই স্ক্রিন নিজে,
/// দুই জায়গাতেই যাচাই করা হয়। অ্যাডমিন তৈরি হলে আর
/// কখনো এই পাতায় আসা যাবে না।
class FirstAdminSetupScreen extends StatefulWidget {
  const FirstAdminSetupScreen({super.key});

  @override
  State<FirstAdminSetupScreen> createState() => _FirstAdminSetupScreenState();
}

class _FirstAdminSetupScreenState extends State<FirstAdminSetupScreen> {
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
    final hasUsers = await FirestoreService().hasAnyUser();
    if (!mounted) return;
    if (hasUsers == true) {
      // অ্যাডমিন আগেই তৈরি হয়েছে — লগইন পাতায় পাঠানো হলো।
      context.go('/login');
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

  bool _isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'নাম লিখুন');
      return;
    }
    if (!_isEmail(_email.text.trim())) {
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
      final hasUsers = await FirestoreService().hasAnyUser();
      if (hasUsers == true) {
        if (!mounted) return;
        setState(() => _error = AppStrings.setupAlreadyExists);
        context.go('/login');
        return;
      }
      await AuthService().createFirstAdmin(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      await AppRouter.refreshAuth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.setupDone)),
      );
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = bengaliAuthErrorMessage(e));
    } catch (_) {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Center(child: AgragamiLogo(size: 96, radius: 24)),
              const SizedBox(height: 16),
              Text(
                AppStrings.setupTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.setupSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_checking)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: AppStrings.setupName,
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppStrings.email,
                    prefixIcon: Icon(Icons.mail_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.password,
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.confirmPassword,
                    prefixIcon: Icon(Icons.lock_outlined),
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
