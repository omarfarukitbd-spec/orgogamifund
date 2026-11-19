import 'package:flutter/material.dart';

import '../widgets/app_icon.dart';

/// কোল্ড স্টার্টে লগইনের অবস্থা জানা না পর্যন্ত দেখানো
/// লোডিং স্ক্রিন — লগইন করা ব্যবহারকারীকে ক্ষণিকের জন্য
/// লগইন স্ক্রিন দেখিয়ে বিভ্রান্ত করা হয় না (m10)।
/// রাউটার প্রথম auth তথ্য পেলেই এখান থেকে সরিয়ে নেয়।
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AgragamiLogo(size: 96, radius: 24),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
