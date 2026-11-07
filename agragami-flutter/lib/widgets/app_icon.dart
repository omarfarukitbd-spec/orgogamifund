import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// সব আইকন এক স্টাইলে — আউটলাইন ভেক্টর আইকন।
/// ইমোজি কোথাও ব্যবহার করা যাবে না।
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const AppIcon(this.icon, {super.key, this.size = 24, this.color = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color);
  }
}

/// রঙিন টাইলের ভেতরে আইকন — কার্ড আর তালিকায় ব্যবহার হবে।
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;

  const IconTile({
    super.key,
    required this.icon,
    this.background = AppColors.greenSoft,
    this.color = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

/// সংগঠনের আসল লোগো — assets/images/agragami_logo.png।
/// ক্রিম পেছনের লোগো গোল কোণার সাদা বাক্সে বসে, যাতে থিমে মিশে যায়।
class AgragamiLogo extends StatelessWidget {
  final double size;
  final double radius;

  const AgragamiLogo({super.key, this.size = 48, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/agragami_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
