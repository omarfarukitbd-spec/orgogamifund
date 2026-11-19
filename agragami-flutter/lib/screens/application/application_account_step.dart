import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// সদস্য আবেদনের ০ নম্বর ধাপ — অ্যাকাউন্ট খোলা (B1)।
/// সমিতির তালিকা শুধু সাইন-ইন করা ব্যবহারকারী দেখতে পায়
/// (branch ডকুমেন্টে ব্যাংক নম্বর থাকে, পাবলিক পড়া দেওয়া
/// যাবে না) — তাই অ্যাকাউন্ট ছাড়া কেউ আবেদন করলে আগে
/// অ্যাকাউন্ট খোলা হয়, তারপর সমিতি বাছার ধাপ আসে।
/// অ্যাকাউন্ট খুললেই অনুমোদন হয় না — আবেদন জমা দিয়ে
/// অ্যাডমিনের অনুমোদনের অপেক্ষা করতে হয়।
class ApplicationAccountStep extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool accountCreated;

  const ApplicationAccountStep({
    super.key,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.accountCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'প্রথমে আপনার অ্যাকাউন্ট খুলুন',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'এই ইমেইল আর পাসওয়ার্ড দিয়ে পরে অ্যাপে ঢুকতে পারবেন। অ্যাডমিন অনুমোদন দিলে তবেই ঢোকা যাবে।',
          style: TextStyle(fontSize: 13.5, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        if (accountCreated)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenSoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outlined, color: AppColors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'অ্যাকাউন্ট খোলা হয়েছে — এবার আপনার তথ্য দিন।',
                    style: TextStyle(fontSize: 14.5),
                  ),
                ),
              ],
            ),
          )
        else ...[
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
      ],
    );
  }
}
