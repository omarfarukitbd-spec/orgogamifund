import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/skeleton_loader.dart';
import 'member/edit_member_dialog.dart';
import 'profile/edit_profile_dialog.dart';
import 'profile/profile_settings_section.dart';

/// প্রোফাইল ও সেটিংস — নিজের তথ্য, পাসবই, আইডি কার্ড, থিম ও ভাষা নির্বাচন
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) => Center(
        child: Text(
          AppStrings.emptyTitle,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
      data: (user) {
        final memberId = user?.linkedMemberId;
        // M8: আলাদা করে বানানো memberDetailStreamProvider নয় —
        // শেয়ার্ড টপ-লেভেল memberStreamProvider ব্যবহার হয়।
        final memberAsync = memberId == null
            ? null
            : ref.watch(memberStreamProvider(memberId));
        final member = memberAsync?.valueOrNull;
        final isAdmin = user?.isAdmin ?? false;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                                '${AppStrings.memberCountLabel}: ${member?.id ?? '—'}',
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
                                    EditMemberDialog(member: member),
                              ),
                              icon: const Icon(
                                Icons.badge_outlined,
                                size: 16,
                              ),
                              label: const Text('সদস্য তথ্য বদলান'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // পাসবই লিংক কার্ড
              AppCard(
                onTap: () => context.go('/passbook'),
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
                onTap: () => context.go('/id-card'),
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
