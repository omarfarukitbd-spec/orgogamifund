import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/edit_request.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'member/edit_member_dialog.dart';
import 'profile/edit_profile_dialog.dart';
import 'profile/edit_request_dialog.dart';
import 'profile/profile_settings_section.dart';

/// প্রোফাইল ও সেটিংস — নিজের তথ্য, পাসবই, আইডি কার্ড, থিম ও ভাষা নির্বাচন
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _memberId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      // F20: ভুল হলে "কিছু নেই" নয় — আসল ভুলের বার্তা আর
      // আবার চেষ্টার বোতাম দেখানো হয়।
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'প্রোফাইল আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
        actionLabel: AppStrings.tryAgain,
        onAction: () => ref.invalidate(currentUserProvider),
      ),
      data: (user) {
        final uid = user?.id ?? '';
        // Phase 9 (G8): প্রোফাইলেও membersForUserProvider —
        // linkedMemberId দিয়ে শুধু প্রথম সমিতির রেকর্ড নয়,
        // ব্যবহারকারীর সব সক্রিয় সদস্য-রেকর্ড আসে
        // (পাসবইয়ের মতো)।
        final membersAsync = uid.isEmpty
            ? null
            : ref.watch(membersForUserProvider(uid));
        if (membersAsync?.isLoading ?? false) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonCardList(),
          );
        }
        if (membersAsync?.hasError ?? false) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'সদস্যের তথ্য আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
            actionLabel: AppStrings.tryAgain,
            onAction: () => ref.invalidate(membersForUserProvider(uid)),
          );
        }
        final members = membersAsync?.valueOrNull ?? const <Member>[];
        final active = members.where((m) => m.active).toList();
        Member? member;
        if (active.length == 1) {
          member = active.first;
        } else if (active.length > 1) {
          final chosenId = _memberId ?? active.first.id;
          final chosen = active.where((m) => m.id == chosenId).toList();
          member = chosen.isEmpty ? active.first : chosen.first;
        }
        final isAdmin = user?.isAdmin ?? false;
        // Phase 9 (G12): প্রক্রিয়াধীন সংশোধন-আবেদন —
        // rules-এ আবেদন শুধু linkedMemberId-এর জন্য করা যায়।
        final linkedMemberId = user?.linkedMemberId;
        final isLinkedMember =
            member != null && linkedMemberId == member.id;
        final pendingRequestAsync = linkedMemberId == null
            ? null
            : ref.watch(
                pendingEditRequestForMemberProvider(linkedMemberId),
              );
        final pendingRequest = pendingRequestAsync?.valueOrNull;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // একাধিক সমিতির সদস্য হলে কোন সমিতির তথ্য
              // দেখবে, বেছে নেওয়া যায় (পাসবইয়ের মতো)।
              if (active.length > 1) ...[
                _ProfileMemberPicker(
                  members: active,
                  selectedId: member!.id,
                  onChanged: (id) => setState(() => _memberId = id),
                ),
                const SizedBox(height: 12),
              ],
              // ব্যবহারকারী প্রোফাইল কার্ড
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: member?.photoUrl != null &&
                                  member!.photoUrl!.isNotEmpty
                              ? NetworkImage(member.photoUrl!)
                              : null,
                          child: member?.photoUrl == null ||
                                  member!.photoUrl!.isEmpty
                              ? Icon(
                                  Icons.person_outlined,
                                  size: 36,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member?.name ??
                                    user?.name ??
                                    user?.email ??
                                    'সদস্য',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                // F15: মানুষের পড়ার মতো সদস্য
                                // নম্বর (আগে ভুল লেবেল
                                // "সদস্য সংখ্যা" + ডকুমেন্ট id)।
                                'সদস্য নম্বর: ${member?.displayNumber ?? '—'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'ফোন: ${member?.phone ?? '—'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) =>
                                  EditProfileDialog(user: user),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('নাম বদলান'),
                          ),
                          // সদস্যের রেকর্ড (ফোন/ঠিকানা/ছবি)
                          // শুধু অ্যাডমিন বদলাতে পারে (rules)।
                          if (isAdmin && member != null) ...[
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    EditMemberDialog(member: member!),
                              ),
                              icon: const Icon(
                                Icons.badge_outlined,
                                size: 16,
                              ),
                              label: const Text('সদস্য তথ্য বদলান'),
                            ),
                          ],
                          // Phase 9 (G12): সাধারণ সদস্য নিজের
                          // তথ্য বদলানোর আবেদন করতে পারে —
                          // অ্যাডমিন অনুমোদন দিলে বদলায়।
                          // rules-এ আবেদন শুধু linked সদস্য-
                          // রেকর্ডের জন্য করা যায়।
                          if (!isAdmin &&
                              member != null &&
                              isLinkedMember &&
                              pendingRequest == null) ...[
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    EditRequestDialog(member: member!),
                              ),
                              icon: const Icon(
                                Icons.edit_note_outlined,
                                size: 16,
                              ),
                              label: const Text('তথ্য সংশোধনের আবেদন'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // প্রক্রিয়াধীন সংশোধন-আবেদন থাকলে তার অবস্থা।
              if (!isAdmin && isLinkedMember && pendingRequest != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'তথ্য সংশোধনের আবেদন প্রক্রিয়াধীন',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final entry
                          in pendingRequest.changes.entries) ...[
                        Text(
                          '${editRequestFieldLabel(entry.key)}: '
                          '${pendingRequest.previous[entry.key] ?? '—'} → ${entry.value}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                      ],
                      const SizedBox(height: 4),
                      const Text(
                        'অ্যাডমিন অনুমোদন দিলে তথ্য বদলে যাবে।',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // পাসবই লিংক কার্ড
              AppCard(
                onTap: () => context.goNamed('passbook'),
                child: Row(
                  children: [
                    const ListIcon(icon: Icons.book_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.navPassbook,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // আইডি কার্ড লিংক কার্ড
              AppCard(
                onTap: () => context.goNamed('idCard'),
                child: Row(
                  children: [
                    const ListIcon(icon: Icons.badge_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.idCardTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ভাষা, থিম এবং বায়োমেট্রিক সেটিংস কম্পোনেন্ট
              const ProfileSettingsSection(),
              const SizedBox(height: 20),

              // লগআউট বোতাম
              SecondaryButton(
                label: AppStrings.logout,
                onPressed: () => AuthService().signOut(),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.halalNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// একাধিক সমিতির সদস্য হলে কোন সমিতির তথ্য দেখবে —
/// পাসবইয়ের পিকারের মতো।
class _ProfileMemberPicker extends ConsumerWidget {
  final List<Member> members;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _ProfileMemberPicker({
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesStreamProvider);
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    String branchName(String id) {
      final found = branches.where((b) => b.id == id).toList();
      return found.isEmpty ? 'সমিতি' : found.first.name;
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: 'কোন সমিতির তথ্য',
        prefixIcon: Icon(Icons.groups_outlined),
      ),
      items: members
          .map(
            (m) => DropdownMenuItem(
              value: m.id,
              child: Text(branchName(m.branchId)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
