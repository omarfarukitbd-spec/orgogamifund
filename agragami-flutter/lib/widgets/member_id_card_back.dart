import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import '../utils/member_qr.dart';

/// কার্ডের পেছন দিক — সবুজ পটভূমি, জরুরি যোগাযোগ, সই ও কিউআর ছক।
class MemberIdCardBack extends StatelessWidget {
  final Member member;

  const MemberIdCardBack({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'অগ্রগামী ফান্ড',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BackLine(
                    'জরুরি যোগাযোগ',
                    '${member.emergencyContactName} — ${member.emergencyContactPhone}',
                  ),
                  _BackLine('সদস্য নম্বর', member.id),
                  const SizedBox(height: 8),
                  const Text(
                    'এই কার্ড হারালে অফিসে জানান। কার্ডটি শুধু সদস্যের পরিচয়ের জন্য।',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const Spacer(),
                  const Row(
                    children: [
                      _SignLine('সভাপতি'),
                      SizedBox(width: 20),
                      _SignLine('সম্পাদক'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // M7: আসল QR কোড — স্ক্যান করলে সদস্যের
                  // পরিচয় পাওয়া যায় (আগে মনগড়া ছক ছিল)।
                  child: QrImageView(
                    data: MemberQr.dataFor(member.id),
                    version: QrVersions.auto,
                    size: 76,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    errorStateBuilder: (context, error) => const Icon(
                      Icons.qr_code_2_outlined,
                      size: 48,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member.id,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackLine extends StatelessWidget {
  final String label;
  final String value;

  const _BackLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _SignLine extends StatelessWidget {
  final String label;

  const _SignLine(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(height: 1, color: Colors.white54),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
