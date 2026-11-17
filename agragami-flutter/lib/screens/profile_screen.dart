import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/skeleton_loader.dart';

/// প্রোফাইল — নিজের তথ্য, পাসবই, আইডি কার্ড আর লগআউট।
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) => const Center(child: Text('তথ্য আনা যায়নি')),
      data: (user) {
        final memberId = user?.linkedMemberId;
        final memberAsync = memberId == null
            ? null
            : ref.watch(
                StreamProvider(
                  (ref) => FirestoreService().watchMember(memberId),
                ),
              );
        final member = memberAsync?.valueOrNull;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage:
                          member?.photoUrl != null && member!.photoUrl!.isNotEmpty
                              ? NetworkImage(member.photoUrl!)
                              : null,
                      child: member?.photoUrl == null || member!.photoUrl!.isEmpty
                          ? const Icon(Icons.person_outlined, size: 36)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member?.name ?? 'সদস্যের নাম',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'সদস্য নম্বর: ${member?.id ?? '—'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'ফোন: ${member?.phone ?? '—'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => context.go('/passbook'),
                child: const Row(
                  children: [
                    ListIcon(icon: Icons.book_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'আমার পাসবই',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_outlined, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => context.go('/id-card'),
                child: const Row(
                  children: [
                    ListIcon(icon: Icons.badge_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'আমার আইডি কার্ড',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_outlined, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SecondaryButton(
                label: 'লগআউট',
                onPressed: () => AuthService().signOut(),
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.halalNote,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
