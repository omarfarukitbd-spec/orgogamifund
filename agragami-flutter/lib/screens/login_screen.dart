import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_icon.dart';
import '../widgets/google_web_button.dart';

/// লগইন স্ক্রিন — ইমেইল/পাসওয়ার্ড আর গুগল।
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  late final Future<bool?> _hasUsersFuture;
  StreamSubscription<Object>? _googleErrorSub;

  @override
  void initState() {
    super.initState();
    // কেউ না থাকলে নিচে সেটআপের লিংক দেখাবে।
    // যাচাই করা না গেলে (নেট বা নিয়মের কারণে) লিংক দেখানো হয়,
    // সেটআপের পাতা নিজে আবার যাচাই করে নেয়।
    try {
      _hasUsersFuture = FirestoreService().hasAnyUser();
    } catch (_) {
      _hasUsersFuture = Future.value(null);
    }
    // ওয়েবে গুগলের বোতাম চাপলে ভুল হলে এখানে বার্তা আসে।
    _googleErrorSub = AuthService().googleSignInErrors.listen((e) {
      if (mounted) {
        setState(() => _error = googleSignInErrorMessage(e));
      }
    });
  }

  /// মোবাইলে গুগল বোতাম চাপলে এটা চলে।
  /// ওয়েবে গুগলের নিজের বোতাম (GIS) থেকে ঢোকা হয়,
  /// সেখানে এই ফাংশন ডাকা হয় না।
  Future<void> _googleLogin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService().signInWithGoogle();
      await AppRouter.refreshAuth();
      if (!mounted) return;
      // অনুমোদন না থাকলে রাউটার গার্ড নিজেই pending স্ক্রিনে পাঠাবে।
      context.go('/home');
    } catch (e) {
      setState(() => _error = googleSignInErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService().signInWithEmail(
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      // অনুমোদন না থাকলে রাউটার গার্ড নিজেই pending স্ক্রিনে পাঠাবে।
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = bengaliAuthErrorMessage(e));
    } catch (_) {
      setState(() => _error = AppStrings.loginWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _googleErrorSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Center(child: AgragamiLogo(size: 96, radius: 24)),
                const SizedBox(height: 16),
                Text(
                  AppStrings.loginTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.halalNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppStrings.email,
                    prefixIcon: Icon(Icons.mail_outlined),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'সঠিক ইমেইল দিন' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.password,
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'পাসওয়ার্ড ৬ অক্ষরের বেশি হতে হবে' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _busy ? AppStrings.loading : AppStrings.loginButton,
                  onPressed: _busy ? null : _login,
                  icon: Icons.login_outlined,
                ),
                const SizedBox(height: 12),
                // ওয়েবে গুগলের নিজের বোতাম (GIS বোতাম) দেখায় —
                // ওয়েবে অ্যাপের বোতামে গুগল দিয়ে ঢোকা যায় না।
                // মোবাইলে অ্যাপের বোতাম থেকে signInWithGoogle চলে।
                if (kIsWeb)
                  buildGoogleWebButton()
                else
                  SecondaryButton(
                    label: AppStrings.loginWithGoogle,
                    onPressed: _busy ? null : _googleLogin,
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/apply'),
                  child: const Text(AppStrings.noAccount),
                ),
                FutureBuilder<bool?>(
                  future: _hasUsersFuture,
                  builder: (context, snapshot) {
                    // কেউ আছে জানা গেলেই শুধু লুকানো হয়।
                    if (snapshot.data == true) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: () => context.go('/setup'),
                      child: const Text(AppStrings.firstSetupLink),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
