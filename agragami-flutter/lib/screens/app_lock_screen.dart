import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/app_button.dart';

/// অ্যাপ-লক স্ক্রিন (M11) — বায়োমেট্রিক লক চালু থাকলে
/// অ্যাপ খুলতে বা ব্যাকগ্রাউন্ড থেকে ফিরতে এই পাতা আসে।
/// ফিঙ্গারপ্রিন্ট/ফেস আনলক না হলে ভেতরের কোনো তথ্য দেখা যায় না।
/// বায়োমেট্রিক একদম না চললে লগআউট করে আবার ঢোকা যায়।
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // পাতা খুলেই যাচাইয়ের প্রম্পট দেখানো হয় — ব্যবহারকারীকে
    // আলাদা করে বোতাম চাপতে হয় না।
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(biometricServiceProvider).authenticate();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case BiometricResult.success:
        AppRouter.unlockApp();
      case BiometricResult.unavailable:
        setState(() => _error = AppStrings.biometricUnavailable);
      case BiometricResult.cancelled:
        // বাতিল করলে লকই থাকে — ভুল বার্তা দেখানো হয় না।
        break;
      case BiometricResult.failed:
        setState(() => _error = AppStrings.biometricFailed);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('লগআউট করবেন?'),
        content: const Text(
          'লগআউট করলে আবার ইমেইল/গুগল দিয়ে ঢুকতে হবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('লগআউট'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    await AuthService().signOut();
    // লগআউটের পর লক রাখার মানে নেই — রাউটার লগইনে পাঠাবে।
    AppRouter.unlockApp();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.fingerprint_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.isBangla ? 'অ্যাপ লক করা আছে' : 'App is locked',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.isBangla
                    ? 'ঢুকতে আপনার ফিঙ্গারপ্রিন্ট বা ফেস আনলক দিন'
                    : 'Use your fingerprint or face unlock to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: AppStrings.isBangla ? 'আনলক করুন' : 'Unlock',
                icon: Icons.lock_open_outlined,
                onPressed: _busy ? null : _unlock,
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: _busy ? null : _signOut,
                child: Text(
                  AppStrings.isBangla
                      ? 'বায়োমেট্রিক চলছে না? লগআউট করুন'
                      : 'Biometric not working? Sign out',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
