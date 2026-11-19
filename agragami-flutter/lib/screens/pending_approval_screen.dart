import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
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
              // গুগল দিয়ে ঢুকে থাকলে আবেদন এখনো বাকি থাকতে
              // পারে — এখান থেকে ফরমটা শেষ করা যাবে।
              // প্রোফাইল না থাকলে আবেদন অর্থহীন — বোতাম লুকানো।
              if (!profileMissing) ...[
                PrimaryButton(
                  label: AppStrings.pendingCompleteApplication,
                  onPressed: () => context.go('/apply'),
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
