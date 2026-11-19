import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../models/member.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../member/edit_member_dialog.dart';
import '../passbook_screen.dart';

/// সদস্য বা অ্যাডমিনের জন্য ভেতরের হিসাব — সদস্য তালিকা,
/// মোট জমা, মোট খরচ, তহবিলের টাকা ও লেনদেন।
class SamitiMemberDetail extends ConsumerStatefulWidget {
  final Branch branch;
  final bool isAdmin;

  const SamitiMemberDetail({
    super.key,
    required this.branch,
    required this.isAdmin,
  });

  @override
  ConsumerState<SamitiMemberDetail> createState() => _SamitiMemberDetailState();
}

class _SamitiMemberDetailState extends ConsumerState<SamitiMemberDetail> {
  bool _recounting = false;

  Future<void> _recount() async {
    if (_recounting) return;
    setState(() => _recounting = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .recountMemberCount(widget.branch.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.recountDone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(
              e,
              fallback: 'সদস্য সংখ্যা মেলানো যায়নি — আবার চেষ্টা করুন',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _recounting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.branch;
    final isAdmin = widget.isAdmin;
    final totalsAsync = ref.watch(homeTotalsByBranchProvider(branch.id));
    final membersAsync = ref.watch(membersByBranchProvider(branch.id));
    final totals = totalsAsync.valueOrNull;
    final members = membersAsync.valueOrNull ?? const <Member>[];

    String value(int? amount, {bool money = true}) {
      if (amount == null) return '—';
      return money ? formatTaka(amount) : '$amount';
    }

    // তহবিল = জমা − খরচ − বকেয়া ঋণ (রিপোর্টের সাথে মিলিয়ে)।
    final fund = totals?.fund;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totalsAsync.hasError) ...[
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'হিসাব আনা যায়নি — নেট দেখে আবার চেষ্টা করুন।',
                  style: TextStyle(fontSize: 14.5),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(
                  homeTotalsByBranchProvider(branch.id),
                ),
                child: Text(AppStrings.tryAgain),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'মোট জমা হয়েছে',
                value: value(totals?.approvedTotal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.receipt_long_outlined,
                label: 'মোট খরচ',
                value: value(totals?.expenseTotal),
                isGold: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.groups_outlined,
                label: 'সক্রিয় সদস্য',
                value: value(totals?.activeMembers, money: false),
                isGold: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'এখন তহবিলে আছে',
                value: fund == null ? '—' : formatTaka(fund),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'জমা দিন',
                onPressed: () => context.go('/deposit'),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecondaryButton(
                label: 'পাসবই',
                onPressed: () => context.go('/passbook'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'সদস্যরা (${members.length} জন)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (membersAsync.isLoading)
          const SkeletonCardList()
        else if (membersAsync.hasError)
          EmptyState(
            icon: Icons.error_outline,
            title: 'তথ্য আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
            actionLabel: AppStrings.tryAgain,
            onAction: () => ref.invalidate(
              membersByBranchProvider(branch.id),
            ),
          )
        else if (members.isEmpty)
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'এখনো কোনো সদস্য নেই',
          )
        else
          ...members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                // B7: অ্যাডমিন সদস্যের কার্ডে ট্যাপ করলে
                // সম্পাদনার ডায়ালগ খোলে।
                onTap: isAdmin
                    ? () => showDialog(
                          context: context,
                          builder: (_) => EditMemberDialog(member: m),
                        )
                    : null,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.greenSoft,
                      backgroundImage:
                          m.photoUrl != null && m.photoUrl!.isNotEmpty
                              ? NetworkImage(m.photoUrl!)
                              : null,
                      child: m.photoUrl == null || m.photoUrl!.isEmpty
                          ? const Icon(
                              Icons.person_outline,
                              color: AppColors.green,
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ফোন: ${m.phone}',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          if (!m.active)
                            const Text(
                              'নিষ্ক্রিয় সদস্য',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.danger,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.muted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          TextButton(
            // m2: গোনার সময় বোতাম বন্ধ, ভুল হলে জানানো হয়।
            onPressed: _recounting ? null : _recount,
            child: Text(
              _recounting ? AppStrings.loading : AppStrings.recountMembers,
            ),
          ),
        ],
      ],
    );
  }
}
