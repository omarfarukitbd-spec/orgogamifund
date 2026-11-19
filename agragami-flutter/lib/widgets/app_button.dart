import 'package:flutter/material.dart';

/// প্রধান বোতাম — সবুজ, বড়, এক লাইনে একটা।
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // m7: আইকন না থাকলে সাধারণ ElevatedButton — icon
    // বোতামে খালি আইকনের ফাঁকা জায়গা লেখাটা ডানে সরিয়ে দিত।
    final labelStyle =
        const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600);
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: labelStyle),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label, style: labelStyle),
    );
  }
}

/// দ্বিতীয় বোতাম — সাদা, সবুজ বর্ডার।
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
