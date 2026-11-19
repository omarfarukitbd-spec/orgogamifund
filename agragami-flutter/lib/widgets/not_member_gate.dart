import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import 'app_button.dart';

/// সদস্য নয় — তাই তথ্য দেখানো যাবে না।
/// কোনো নাম, টাকার সংখ্যা বা বকেয়া এখানে আসে না —
/// শুধু আবেদনের বোতাম। সমিতি ঠিক করা থাকলে ওই সমিতির
/// আবেদন ফরমে যায়, না থাকলে সমিতির তালিকায় যায়।
class NotMemberGate extends StatelessWidget {
  final String? branchId;
  final String? branchName;

  const NotMemberGate({super.key, this.branchId, this.branchName});

  @override
  Widget build(BuildContext context) {
    final hasBranch = branchId != null && branchId!.isNotEmpty;
    // m6: থিম থেকে রং — হার্ড-কোড করা সবুজ/ধূসর ডার্ক
    // মোডে ফিকে দেখাত।
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outlined,
              size: 48,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasBranch
                ? AppStrings.notMemberTitle
                : AppStrings.notMemberAnyTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            hasBranch ? AppStrings.notMemberBody : AppStrings.notMemberAnyBody,
            style: TextStyle(fontSize: 15.5, color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: AppStrings.joinSamiti,
            onPressed: () => hasBranch
                ? context.goNamed(
                    'apply',
                    queryParameters: {'branchId': branchId!},
                  )
                : context.goNamed('samiti'),
            icon: Icons.person_add_outlined,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: AppStrings.viewSamitis,
            onPressed: () => context.goNamed('samiti'),
          ),
        ],
      ),
    );
  }
}
