import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';

/// নতুন অ্যাকাউন্ট খোলার পর এই স্ক্রিন দেখাবে।
/// অ্যাডমিন অনুমোদন না দিলে ভেতরের কিছু দেখা যাবে না।
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.hourglass_top_outlined,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.pendingTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(AppStrings.pendingBody, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              // গুগল দিয়ে ঢুকে থাকলে আবেদন এখনো বাকি থাকতে
              // পারে — এখান থেকে ফরমটা শেষ করা যাবে।
              PrimaryButton(
                label: AppStrings.pendingCompleteApplication,
                onPressed: () => context.go('/apply'),
                icon: Icons.edit_note_outlined,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'লগআউট',
                onPressed: () => AuthService().signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
