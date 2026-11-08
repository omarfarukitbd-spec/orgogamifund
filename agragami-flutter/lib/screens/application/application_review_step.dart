import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/branch.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

/// সদস্য আবেদনের তৃতীয় ধাপ — দেখে নিয়ে জমা দিন
class ApplicationReviewStep extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String? branchId;
  final String address;
  final String emergencyName;
  final String emergencyPhone;
  final String nid;
  final DateTime joinDate;
  final Uint8List? photoBytes;
  final Uint8List? nidFrontBytes;
  final Uint8List? nidBackBytes;
  final bool needsAccount;

  const ApplicationReviewStep({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.branchId,
    required this.address,
    required this.emergencyName,
    required this.emergencyPhone,
    required this.nid,
    required this.joinDate,
    required this.photoBytes,
    required this.nidFrontBytes,
    required this.nidBackBytes,
    required this.needsAccount,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Branch>>(
      stream: FirestoreService().watchBranches(),
      builder: (context, snapshot) {
        final branches = snapshot.data ?? const <Branch>[];
        final branchName = branches
            .where((b) => b.id == branchId)
            .map((b) => b.name)
            .firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'দেখে নিন, তারপর জমা দিন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _ReviewRow('নাম', name),
            _ReviewRow('মোবাইল', phone),
            if (needsAccount && email.isNotEmpty) _ReviewRow('ইমেইল', email),
            if (branchName != null) _ReviewRow('সমিতি', branchName),
            _ReviewRow('ঠিকানা', address),
            _ReviewRow('জরুরি যোগাযোগ', '$emergencyName — $emergencyPhone'),
            _ReviewRow('এনআইডি', nid),
            _ReviewRow(
              'ভর্তির তারিখ',
              '${joinDate.day}/${joinDate.month}/${joinDate.year}',
            ),
            const SizedBox(height: 8),
            if (photoBytes != null) _ReviewPhoto('নিজের ছবি', photoBytes!),
            if (nidFrontBytes != null)
              _ReviewPhoto('এনআইডির সামনে', nidFrontBytes!),
            if (nidBackBytes != null)
              _ReviewPhoto('এনআইডির পেছনে', nidBackBytes!),
            const SizedBox(height: 12),
            const Text(
              'জমা দিলে অ্যাডমিন আপনার আবেদন দেখে অনুমোদন দেবেন। অনুমোদন হলে তবেই সদস্য হিসেবে ঢুকতে পারবেন।',
              style: TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14.5, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPhoto extends StatelessWidget {
  final String label;
  final Uint8List bytes;

  const _ReviewPhoto(this.label, this.bytes);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
