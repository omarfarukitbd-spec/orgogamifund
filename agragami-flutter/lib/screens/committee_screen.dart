import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/committee_member.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/firebase_errors.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'committee/committee_member_form_dialog.dart';

/// কমিটি — সভাপতি, সম্পাদক, কোষাধ্যক্ষসহ দায়িত্বে
/// যারা আছেন, তাদের নাম আর ফোন। নামে ট্যাপ করলে
/// ফোন করা যায়। অ্যাডমিন কমিটি বসাতে, বদলাতে আর
/// সরাতে পারে (M4)।
class CommitteeScreen extends ConsumerWidget {
  const CommitteeScreen({super.key});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কল করা সম্ভব হয়নি')),
      );
    }
  }

  void _openForm(
    BuildContext context,
    List<Branch> branches, {
    CommitteeMember? existing,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => CommitteeMemberFormDialog(
        branches: branches,
        existing: existing,
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    CommitteeMember c,
    String memberName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('কমিটি থেকে সরাবেন?'),
        content: Text(
          '$memberName-এর ${c.designation} পদটি সরিয়ে দেওয়া হবে। সদস্যের রেকর্ড থাকবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('সরান', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(firestoreServiceProvider).removeCommitteeMember(
            c.id,
            by: AuthService().uidOrEmpty,
            designation: c.designation,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমিটি থেকে সরানো হয়েছে')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(e, fallback: 'সরানো যায়নি — আবার চেষ্টা করুন'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final committeeAsync = ref.watch(committeeStreamProvider);
    final userAsync = ref.watch(currentUserProvider);
    // F6: কমিটি বদলানো শুধু সুপার অ্যাডমিনের কাজ (rules:
    // committee write শুধু সুপার অ্যাডমিন) — শাখা অ্যাডমিন
    // যোগ/বদল/সরানোর বোতাম দেখে না।
    final isSuperAdmin = userAsync.valueOrNull?.isSuperAdmin ?? false;
    final branchesAsync = ref.watch(branchesStreamProvider);
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    if (committeeAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      );
    }
    if (committeeAsync.hasError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'তথ্য আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
        actionLabel: 'আবার চেষ্টা করুন',
        onAction: () => ref.invalidate(committeeStreamProvider),
      );
    }
    final committee = committeeAsync.valueOrNull ?? const <CommitteeMember>[];
    // সদস্যের নাম-ফোন শুধু কমিটিতে থাকা সদস্যদেরই আনা হয় —
    // ফিল্টার ছাড়া পুরো members পড়লে সদস্যদের জন্য
    // নিয়মে (rules) বাধা পায়।
    final memberIds =
        committee.map((c) => c.memberId).toSet().join(',');
    final membersAsync = ref.watch(membersByIdsProvider(memberIds));
    final members = membersAsync.valueOrNull ?? const <String, Member>{};

    String memberName(String id) => members[id]?.name ?? '—';

    String memberPhone(String id) => members[id]?.phone ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'সংগঠনের দায়িত্বে যারা আছেন — প্রয়োজনে সরাসরি ফোন করুন।',
            style: TextStyle(fontSize: 14.5, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (isSuperAdmin) ...[
            ElevatedButton.icon(
              onPressed: () => _openForm(context, branches),
              icon: const Icon(Icons.add_outlined),
              label: const Text('কমিটিতে যোগ করুন'),
            ),
            const SizedBox(height: 16),
          ],
          if (committee.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'কমিটির তালিকা এখনো বসানো হয়নি',
              message: 'অ্যাডমিন কমিটি বসালে এখানে দেখা যাবে।',
            )
          else
            ...committee.map(
              (c) {
                final phone = memberPhone(c.memberId);
                final photoUrl = members[c.memberId]?.photoUrl;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: phone.isEmpty ? null : () => _call(context, phone),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(Icons.person_outlined, size: 26)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memberName(c.memberId),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    c.designation,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (phone.isNotEmpty)
                              const Icon(Icons.call_outlined, color: Colors.green),
                          ],
                        ),
                        if (isSuperAdmin)
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _openForm(
                                  context,
                                  branches,
                                  existing: c,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('বদলান'),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _remove(
                                  context,
                                  ref,
                                  c,
                                  memberName(c.memberId),
                                ),
                                icon: const Icon(
                                  Icons.delete_outlined,
                                  size: 16,
                                  color: AppColors.danger,
                                ),
                                label: const Text(
                                  'সরান',
                                  style: TextStyle(color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
