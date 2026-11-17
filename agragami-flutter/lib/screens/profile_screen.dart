import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/skeleton_loader.dart';

final memberDetailStreamProvider =
    StreamProvider.autoDispose.family<Member?, String>(
  (ref, id) => ref.watch(firestoreServiceProvider).watchMember(id),
);

/// প্রোফাইল ও সেটিংস — নিজের তথ্য, পাসবই, আইডি কার্ড, থিম ও ভাষা নির্বাচন
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

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
        final memberAsync = memberId == null
            ? null
            : ref.watch(memberDetailStreamProvider(memberId));
        final member = memberAsync?.valueOrNull;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ব্যবহারকারী প্রোফাইল কার্ড
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                            member?.name ?? user?.email ?? 'সদস্য',
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

              // ভাষা নির্বাচন কার্ড
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language_outlined,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.languageTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'bn',
                          label: Text(AppStrings.bangla),
                        ),
                        ButtonSegment(
                          value: 'en',
                          label: Text(AppStrings.english),
                        ),
                      ],
                      selected: {currentLocale.languageCode},
                      onSelectionChanged: (selected) {
                        final code = selected.first;
                        ref.read(localeProvider.notifier).state =
                            Locale(code, code == 'bn' ? 'BD' : 'US');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // থিম মোড নির্বাচন কার্ড
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.themeModeTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(AppStrings.themeLight),
                          icon: const Icon(Icons.light_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(AppStrings.themeDark),
                          icon: const Icon(Icons.dark_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(AppStrings.themeSystem),
                          icon: const Icon(Icons.brightness_auto_outlined, size: 16),
                        ),
                      ],
                      selected: {currentTheme},
                      onSelectionChanged: (selected) {
                        ref.read(themeModeProvider.notifier).state =
                            selected.first;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // লগআউট বোতাম
              SecondaryButton(
                label: 'লগআউট',
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
