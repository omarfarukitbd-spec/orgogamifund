import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_icon.dart';
import '../widgets/google_web_button.dart';

/// লগইন স্ক্রিন — ইমেইল/পাসওয়ার্ড আর গুগল।
class LoginScreen extends ConsumerStatefulWidget {
  /// সেটআপ থেকে ফিরে এলে বার্তা দেখানোর জন্য (m13) —
  /// যেমন 'setup-blocked' মানে অ্যাডমিন আগেই তৈরি হয়েছে।
  final String? notice;

  const LoginScreen({super.key, this.notice});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;
  late final Future<bool?> _hasUsersFuture;
  StreamSubscription<Object>? _googleErrorSub;
  StreamSubscription<void>? _googleStartedSub;
  StreamSubscription<void>? _googleCompletedSub;

  @override
  void initState() {
    super.initState();
    if (widget.notice == 'setup-blocked') {
      _error = AppStrings.setupAlreadyExists;
    }
    // কেউ না থাকলে নিচে সেটআপের লিংক দেখাবে।
    // যাচাই করা না গেলে লিংক দেখানো হয় না — সেটআপের পাতা
    // নিজেও fail-closed যাচাই করে (B1, m3)।
    try {
      _hasUsersFuture = ref.read(firestoreServiceProvider).hasAnyUser();
    } catch (_) {
      _hasUsersFuture = Future.value(null);
    }
    final auth = ref.read(authServiceProvider);
    // ওয়েবে গুগলের বোতাম চাপলে ভুল হলে এখানে বার্তা আসে।
    _googleErrorSub = auth.googleSignInErrors.listen((e) {
      if (mounted) {
        setState(() {
          _error = googleSignInErrorMessage(e);
          _busy = false;
        });
      }
    });
    // ওয়েবে GIS বোতাম চাপলে লোডিং দেখানো (m12)।
    _googleStartedSub = auth.googleSignInStarted.listen((_) {
      if (mounted) setState(() => _busy = true);
    });
    _googleCompletedSub = auth.googleSignInCompleted.listen((_) {
      if (mounted) setState(() => _busy = false);
    });
  }

  /// মোবাইলে গুগল বোতাম চাপলে এটা চলে।
  /// ওয়েবে গুগলের নিজের বোতাম (GIS) থেকে ঢোকা হয়,
  /// সেখানে এই ফাংশন ডাকা হয় না।
  /// নেভিগেশন এখানে করা হয় না — রাউটার লাইভ ব্যবহারকারী
  /// স্ট্রিম দেখে নিজেই /home বা /pending-এ পাঠায় (M1)।
  Future<void> _googleLogin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = googleSignInErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithEmail(
        _email.text.trim(),
        _password.text,
      );
      // নেভিগেশন নয় — রাউটার গার্ড অনুমোদন দেখে নিজেই
      // /home বা /pending-এ পাঠাবে (M1, B2)।
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = bengaliAuthErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppStrings.loginWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// পাসওয়ার্ড ভুলে গেলে রিসেট লিংক পাঠানো (M10)।
  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _error = AppStrings.resetLinkEnterEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.resetLinkSent)),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = bengaliAuthErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppStrings.loginWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _googleErrorSub?.cancel();
    _googleStartedSub?.cancel();
    _googleCompletedSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 30),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AgragamiLogo(size: 104, radius: 26)),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appTagline,
                    style: const TextStyle(fontSize: 15, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.halalNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).nextFocus(),
                    decoration: InputDecoration(
                      labelText: AppStrings.email,
                      prefixIcon: const Icon(Icons.mail_outlined),
                    ),
                    validator: (v) => (v == null || !isValidEmail(v))
                        ? AppStrings.validEmail
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? AppStrings.passwordTooShort
                        : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _forgotPassword,
                      child: Text(AppStrings.forgotPassword),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _busy ? AppStrings.loading : AppStrings.loginButton,
                    onPressed: _busy ? null : _login,
                    icon: Icons.login_outlined,
                  ),
                  const SizedBox(height: 12),
                  // ওয়েবে গুগলের নিজের বোতাম (GIS বোতাম) দেখায় —
                  // ওয়েবে অ্যাপের বোতামে গুগল দিয়ে ঢোকা যায় না।
                  // মোবাইলে অ্যাপের বোতাম থেকে signInWithGoogle চলে।
                  // গুগল সেটআপ না থাকলে বোতামের বদলে জানানো হয় (m5)।
                  if (AuthService.isGoogleSignInFailed)
                    Text(
                      AppStrings.googleNotAvailable,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.muted),
                      textAlign: TextAlign.center,
                    )
                  else if (kIsWeb)
                    buildGoogleWebButton(busy: _busy)
                  else
                    SecondaryButton(
                      label: AppStrings.loginWithGoogle,
                      onPressed: _busy ? null : _googleLogin,
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _busy ? null : () => context.goNamed('apply'),
                    child: Text(AppStrings.noAccount),
                  ),
                  FutureBuilder<bool?>(
                    future: _hasUsersFuture,
                    builder: (context, snapshot) {
                      // শুধু প্রমাণিতভাবে কেউ না থাকলেই দেখানো হয় —
                      // লোড হওয়ার সময় বা যাচাই না গেলে কিছু না (m3)।
                      if (snapshot.data != false) {
                        return const SizedBox.shrink();
                      }
                      return TextButton(
                        onPressed: _busy ? null : () => context.goNamed('setup'),
                        child: Text(AppStrings.firstSetupLink),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
