import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

/// সদস্য আবেদনের প্রথম ধাপ — ব্যক্তিগত তথ্য ফরম
class ApplicationInfoStep extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController address;
  final TextEditingController emergencyName;
  final TextEditingController emergencyPhone;
  final TextEditingController nid;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final String? branchId;
  final String? lockedBranchId;
  final ValueChanged<String?> onBranchChanged;
  final DateTime joinDate;
  final ValueChanged<DateTime> onJoinDateChanged;
  final bool needsAccount;

  const ApplicationInfoStep({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    required this.emergencyName,
    required this.emergencyPhone,
    required this.nid,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.branchId,
    required this.lockedBranchId,
    required this.onBranchChanged,
    required this.joinDate,
    required this.onJoinDateChanged,
    required this.needsAccount,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Branch>>(
      stream: FirestoreService().watchBranches(),
      builder: (context, snapshot) {
        final branches = snapshot.data ?? const <Branch>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'প্রথমে আপনার তথ্য দিন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'পুরো নাম',
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                hintText: '01XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ঠিকানা',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emergencyName,
              decoration: const InputDecoration(
                labelText: 'জরুরি যোগাযোগের নাম',
                prefixIcon: Icon(Icons.contact_phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emergencyPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'জরুরি যোগাযোগের মোবাইল',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (lockedBranchId != null)
              _LockedBranchTile(
                branchName: branches
                    .where((b) => b.id == lockedBranchId)
                    .map((b) => b.name)
                    .firstOrNull,
              )
            else
              DropdownButtonFormField<String>(
                initialValue: branchId,
                decoration: const InputDecoration(
                  labelText: 'কোন সমিতি',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                items: branches
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: onBranchChanged,
              ),
            const SizedBox(height: 12),
            TextField(
              controller: nid,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'এনআইডি নম্বর',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            if (needsAccount) ...[
              const SizedBox(height: 16),
              const Text(
                'এই ইমেইল আর পাসওয়ার্ড দিয়ে পরে ঢুকতে পারবেন। অ্যাডমিন অনুমোদন দিলে তবেই ঢোকা যাবে।',
                style: TextStyle(fontSize: 13.5, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ইমেইল',
                  prefixIcon: Icon(Icons.mail_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'পাসওয়ার্ড আবার লিখুন',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
            ],
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const ListIcon(
                  icon: Icons.calendar_month_outlined,
                  size: 44,
                ),
                title: const Text(
                  'ভর্তির তারিখ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${joinDate.day}/${joinDate.month}/${joinDate.year}',
                  style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: joinDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      onJoinDateChanged(picked);
                    }
                  },
                  child: const Text('বদলান'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LockedBranchTile extends StatelessWidget {
  final String? branchName;

  const _LockedBranchTile({this.branchName});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const ListIcon(icon: Icons.groups_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branchName ?? 'সমিতি',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  AppStrings.lockedBranchNote,
                  style: TextStyle(fontSize: 13.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outlined, size: 20, color: AppColors.muted),
        ],
      ),
    );
  }
}
