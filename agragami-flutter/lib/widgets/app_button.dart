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
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// দ্বিতীয় বোতাম — সাদা, সবুজ বর্ডার।
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
