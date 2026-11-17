import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/committee_member.dart';
import '../models/member.dart';
import '../services/firestore_service.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';

/// কমিটি — সভাপতি, সম্পাদক, কোষাধ্যক্ষসহ দায়িত্বে
/// যারা আছেন, তাদের নাম আর ফোন। নামে ট্যাপ করলে
/// ফোন করা যায়।
class CommitteeScreen extends ConsumerWidget {
  const CommitteeScreen({super.key});

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(firestoreServiceProvider);
    final committeeAsync = ref.watch(
      StreamProvider<List<CommitteeMember>>((ref) => store.watchCommittee()),
    );
    final membersAsync = ref.watch(
      StreamProvider<List<Member>>((ref) => store.watchMembers()),
    );
    if (committeeAsync.isLoading || membersAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      );
    }
    final committee = committeeAsync.valueOrNull ?? const <CommitteeMember>[];
    final members = membersAsync.valueOrNull ?? const <Member>[];

    String memberName(String id) {
      final found = members.where((m) => m.id == id).toList();
      return found.isEmpty ? '—' : found.first.name;
    }

    String memberPhone(String id) {
      final found = members.where((m) => m.id == id).toList();
      return found.isEmpty ? '' : found.first.phone;
    }

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
                final photoUrl = members
                    .where((m) => m.id == c.memberId)
                    .map((m) => m.photoUrl)
                    .firstOrNull;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: phone.isEmpty ? null : () => _call(phone),
                    child: Row(
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
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
