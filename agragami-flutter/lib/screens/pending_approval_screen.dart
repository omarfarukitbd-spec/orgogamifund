import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/firebase_errors.dart';
import '../widgets/app_button.dart';

/// নতুন অ্যাকাউন্ট খোলার পর এই স্ক্রিন দেখাবে।
/// অ্যাডমিন অনুমোদন না দিলে ভেতরের কিছু দেখা যাবে না।
/// অনুমোদন হলে লাইভ স্ট্রিম দেখে রাউটার নিজেই হোমে পাঠায় (B3) —
/// "আবার দেখুন" বোতামটা হাতে করে যাচাইয়ের জন্য।
/// বাতিল হলে আলাদা বার্তা দেখানো হয় (B2), আর Firebase-এ ঢুকে
/// থাকলেও users ডকুমেন্ট না থাকলে "প্রোফাইল পাওয়া যায়নি" (M9)।
class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState
    extends ConsumerState<PendingApprovalScreen> {
  bool _busy = false;
  bool _refreshing = false;
  bool _recovering = false;

  Future<void> _logout() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await AppRouter.refreshAuth();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// F9: অর্ফান অ্যাকাউন্ট উদ্ধার — Firebase-এ ঢুকে আছে
  /// কিন্তু users ডকুমেন্ট নেই। pending ডকুমেন্ট বানানো
  /// হয় (অনুমোদন অ্যাডমিন দেবে); ডকুমেন্ট আগে থেকে
  /// থাকলে কিছু করা হয় না।
  Future<void> _restoreProfile() async {
    if (_recovering) return;
    final firebaseUser = ref.read(authServiceProvider).firebaseUser;
    if (firebaseUser == null) return;
    setState(() => _recovering = true);
    try {
      await ref.read(firestoreServiceProvider).restoreMissingProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
          );
      await AppRouter.refreshAuth();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(
              e,
              fallback: 'প্রোফাইল তৈরি করা যায়নি — আবার চেষ্টা করুন',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    // লোড হচ্ছে — কিছু সিদ্ধান্ত নেওয়া হয় না।
    if (userAsync.isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final signedIn = ref.read(authServiceProvider).firebaseUser != null;
    // ঢুকে নেই আর প্রোফাইলও নেই — রাউটার লগইনে পাঠাচ্ছে,
    // এর মধ্যে স্পিনার দেখানো হয়।
    if (user == null && !signedIn) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    // প্রোফাইল নেই: Firebase-এ ঢুকে আছে কিন্তু users ডকুমেন্ট নেই।
    final profileMissing = user == null && signedIn;
    final rejected = user?.approvalStatus == ApprovalStatus.rejected;

    final IconData icon;
    final String title;
    final String body;
    if (profileMissing) {
      icon = Icons.person_off_outlined;
      title = AppStrings.profileNotFoundTitle;
      body = AppStrings.profileNotFoundBody;
    } else if (rejected) {
      icon = Icons.block_outlined;
      title = AppStrings.rejectedTitle;
      body = AppStrings.rejectedBody;
    } else {
      icon = Icons.hourglass_top_outlined;
      title = AppStrings.pendingTitle;
      body = AppStrings.pendingBody;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(fontSize: 15.5, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // F9: প্রোফাইল না থাকলে এখান থেকে আবার তৈরি
              // করা যায় — অ্যাপ থেকে বেরিয়ে কোনো উপায় ছিল না।
              if (profileMissing) ...[
                PrimaryButton(
                  label: _recovering
                      ? AppStrings.loading
                      : 'প্রোফাইল আবার তৈরি করুন',
                  onPressed: _recovering ? null : _restoreProfile,
                  icon: Icons.person_add_outlined,
                ),
                const SizedBox(height: 12),
              ],
              // গুগল দিয়ে ঢুকে থাকলে আবেদন এখনো বাকি থাকতে
              // পারে — এখান থেকে ফরমটা শেষ করা যাবে।
              // প্রোফাইল না থাকলে আবেদন অর্থহীন — বোতাম লুকানো।
              if (!profileMissing) ...[
                PrimaryButton(
                  label: AppStrings.pendingCompleteApplication,
                  onPressed: () => context.goNamed('apply'),
                  icon: Icons.edit_note_outlined,
                ),
                const SizedBox(height: 12),
              ],
              SecondaryButton(
                label: _refreshing
                    ? AppStrings.loading
                    : AppStrings.checkAgain,
                onPressed: _refreshing ? null : _refresh,
                icon: Icons.refresh_outlined,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: AppStrings.logout,
                onPressed: _busy ? null : _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
