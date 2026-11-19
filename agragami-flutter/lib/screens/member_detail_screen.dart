import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/firestore_providers.dart';
import '../utils/firebase_errors.dart';
import '../widgets/empty_state.dart';
import '../widgets/member_id_card.dart';
import '../widgets/skeleton_loader.dart';

/// একজন সদস্যের পরিচয় — আইডি কার্ডের QR স্ক্যানে (deep link
/// orgogami://member/<id>) খোলা হয় (04-m3/F18)।
/// সদস্যের পরিচয় কার্ডটাই দেখানো হয় ([MemberIdCardFront] —
/// আইডি কার্ড স্ক্রিনের একই উইজেট), সাথে যোগাযোগের তথ্য।
/// অন্য সমিতির সদস্য হলে rules পড়তে দেয় না — তখন অনুমতি
/// নেই জানানো হয় (সমিতি-ভিত্তিক সীমা, কঠোরভাবে)।
class MemberDetailScreen extends ConsumerWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberStreamProvider(memberId));
    final user = ref.watch(currentUserProvider).valueOrNull;
    return memberAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) => EmptyState(
        icon: Icons.person_off_outlined,
        title: 'সদস্যের তথ্য দেখা যাচ্ছে না',
        message: firebaseErrorMessage(e),
      ),
      data: (member) {
        if (member == null) {
          return const EmptyState(
            icon: Icons.person_off_outlined,
            title: 'সদস্য পাওয়া যায়নি',
            message: 'এই সদস্যের রেকর্ড নেই বা মুছে ফেলা হয়েছে।',
          );
        }
        final branch = ref
            .watch(branchStreamProvider(member.branchId))
            .valueOrNull;
        final isOwn = user != null && member.linkedUserId == user.id;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MemberIdCardFront(member: member, branch: branch),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.phone_outlined, label: 'ফোন', value: member.phone),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'ঠিকানা',
                value: member.address,
              ),
              if (member.emergencyContactName.isNotEmpty)
                _InfoRow(
                  icon: Icons.contact_emergency_outlined,
                  label: 'জরুরি যোগাযোগ',
                  value:
                      '${member.emergencyContactName} — ${member.emergencyContactPhone}',
                ),
              if (isOwn) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.goNamed('passbook'),
                  icon: const Icon(Icons.book_outlined),
                  label: const Text('আমার পাসবই দেখুন'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
