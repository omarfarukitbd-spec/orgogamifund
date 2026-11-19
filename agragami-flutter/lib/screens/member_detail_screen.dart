import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/admin_promotion.dart';
import '../utils/firebase_errors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
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
              const SizedBox(height: 4),
              // Phase 6: শাখা অ্যাডমিন বানানো/সরানো — শুধু
              // সুপার অ্যাডমিন দেখে; অন্যরা কিছু দেখে না।
              _AdminRoleSection(
                member: member,
                branchName: branch?.name ?? '',
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

/// শাখা অ্যাডমিন বানানো/সরানোর অংশ (Phase 6) — শুধু সুপার
/// অ্যাডমিন দেখে। সদস্যের লগইন প্রোফাইল লাইভ স্ট্রিমে পড়া
/// হয়, তাই বানানো/সরানোর পর বোতাম নিজে থেকেই বদলে যায়।
/// সিদ্ধান্তের নিয়ম [decideAdminRoleAction]-এ — UI আর
/// রিপোজিটরি দুই জায়গায় একই নিয়ম।
class _AdminRoleSection extends ConsumerStatefulWidget {
  final Member member;
  final String branchName;

  const _AdminRoleSection({
    required this.member,
    required this.branchName,
  });

  @override
  ConsumerState<_AdminRoleSection> createState() => _AdminRoleSectionState();
}

class _AdminRoleSectionState extends ConsumerState<_AdminRoleSection> {
  bool _busy = false;

  String get _branchName =>
      widget.branchName.isEmpty ? 'এই সমিতি' : widget.branchName;

  Future<void> _run(bool promote) async {
    if (_busy) return;
    final member = widget.member;
    // বোতাম শুধু লগইন থাকলেই দেখা যায় (সিদ্ধান্তের নিয়ম) —
    // তবুও এখানে আবার দেখা হয়, যাতে null কখনো রিপোজিটরিতে না যায়।
    final linkedUid = member.linkedUserId;
    if (linkedUid == null || linkedUid.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promote ? 'অ্যাডমিন বানাবেন?' : 'অ্যাডমিন থেকে সরাবেন?'),
        content: Text(
          promote
              ? '${member.name}-কে $_branchName সমিতির অ্যাডমিন বানানো হবে। '
                  'সে ওই সমিতির আবেদন অনুমোদন, জমা-খরচ-ঋণ দেখাশোনা '
                  'করতে পারবে।'
              : '${member.name}-কে $_branchName সমিতির অ্যাডমিন থেকে সরানো '
                  'হবে। সে আবার সাধারণ সদস্য হয়ে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              promote ? 'বানান' : 'সরান',
              style: promote
                  ? null
                  : const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      if (promote) {
        await service.promoteToBranchAdmin(
          targetUid: linkedUid,
          branchId: member.branchId,
          by: AuthService().uidOrEmpty,
          memberName: member.name,
        );
      } else {
        await service.demoteBranchAdmin(
          targetUid: linkedUid,
          branchId: member.branchId,
          by: AuthService().uidOrEmpty,
          memberName: member.name,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            promote
                // রোল লাইভ স্ট্রিমে আসে (watchCurrentUser) —
                // আবার লগইন করতে হয় না।
                ? '${member.name} এখন $_branchName সমিতির অ্যাডমিন — '
                    'আবার লগইন ছাড়াই তার ফোনে কার্যকর হবে।'
                : '${member.name}-কে অ্যাডমিন থেকে সরানো হয়েছে।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(
              e,
              fallback: promote
                  ? 'অ্যাডমিন বানানো যায়নি — আবার চেষ্টা করুন'
                  : 'অ্যাডমিন সরানো যায়নি — আবার চেষ্টা করুন',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewer = ref.watch(currentUserProvider).valueOrNull;
    // শুধু সুপার অ্যাডমিন — শাখা অ্যাডমিন/সদস্য এই অংশ দেখে না।
    if (viewer == null || !viewer.isSuperAdmin) {
      return const SizedBox.shrink();
    }
    final member = widget.member;
    // লগইন না থাকলে খালি id দিয়ে দেখা হয় — স্ট্রিম সাথে
    // সাথেই null দেয়, সিদ্ধান্তে "লগইন নেই" নোট আসে।
    final targetAsync =
        ref.watch(userDocProvider(member.linkedUserId ?? ''));
    return targetAsync.when(
      loading: () => const AppCard(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _noteCard(
        Icons.error_outline,
        firebaseErrorMessage(e),
        isError: true,
      ),
      data: (targetUser) {
        final decision = decideAdminRoleAction(
          linkedUserId: member.linkedUserId,
          targetUser: targetUser,
          currentUid: viewer.id,
          branchId: member.branchId,
        );
        switch (decision.state) {
          case AdminRoleSectionState.hidden:
            return const SizedBox.shrink();
          case AdminRoleSectionState.info:
            return _noteCard(Icons.info_outlined, decision.note ?? '');
          case AdminRoleSectionState.promote:
            return _actionCard(promote: true);
          case AdminRoleSectionState.demote:
            return _actionCard(promote: false);
        }
      },
    );
  }

  Widget _noteCard(IconData icon, String message, {bool isError = false}) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isError ? AppColors.danger : AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({required bool promote}) {
    final member = widget.member;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'সমিতির অ্যাডমিন',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            promote
                ? '${member.name}-কে $_branchName সমিতির অ্যাডমিন বানালে সে '
                    'ওই সমিতির আবেদন অনুমোদন, জমা-খরচ-ঋণ দেখাশোনা করতে '
                    'পারবে। কিছু মুছতে বা অন্য সমিতি দেখতে পারবে না।'
                : '${member.name} এখন $_branchName সমিতির অ্যাডমিন। সরালে '
                    'সে আবার সাধারণ সদস্য হয়ে যাবে।',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (promote)
            PrimaryButton(
              label: _busy ? AppStrings.loading : 'অ্যাডমিন বানান',
              onPressed: _busy ? null : () => _run(true),
              icon: Icons.admin_panel_settings_outlined,
            )
          else
            TextButton(
              onPressed: _busy ? null : () => _run(false),
              child: Text(
                _busy ? AppStrings.loading : 'অ্যাডমিন সরান',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
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
