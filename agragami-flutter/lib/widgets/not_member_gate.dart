import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'app_button.dart';

/// এখন ঢুকে থাকা ব্যবহারকারীর সব সমিতির সদস্যপদ —
/// অনুমোদিত, বাকি, বাতিল — সবই আসে।
/// ব্যক্তিগত তথ্য দেখানোর আগে স্ক্রিনগুলো এখান থেকে
/// দেখে নেয় ব্যবহারকারী ওই সমিতির সদস্য কি না।
final myMembershipsProvider = StreamProvider<List<Membership>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final uid = user?.id ?? '';
  if (uid.isEmpty) return const Stream<List<Membership>>.empty();
  return FirestoreService().watchMyMemberships(uid);
});

/// সদস্যপদের তালিকা থেকে অনুমোদিত সমিতিগুলোর id —
/// শুধু সেগুলোরই ব্যক্তিগত তথ্য দেখানো যাবে।
List<String> approvedBranchIds(List<Membership> memberships) {
  return memberships
      .where((m) => m.isApproved)
      .map((m) => m.branchId)
      .toList();
}

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
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outlined,
              size: 48,
              color: Colors.green,
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
            hasBranch
                ? AppStrings.notMemberBody
                : AppStrings.notMemberAnyBody,
            style: const TextStyle(fontSize: 15.5, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: AppStrings.joinSamiti,
            onPressed: () => hasBranch
                ? context.go('/apply?branchId=$branchId')
                : context.go('/samiti'),
            icon: Icons.person_add_outlined,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: AppStrings.viewSamitis,
            onPressed: () => context.go('/samiti'),
          ),
        ],
      ),
    );
  }
}
