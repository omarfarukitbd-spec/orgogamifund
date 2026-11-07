import 'package:flutter/material.dart';

/// অ্যাপের সব কার্ড এক রকম দেখাবে — সাদা, গোল কোণা, নরম ছায়া।
/// প্রিভিউয়ের মতোই: সাদা পটভূমির উপর ছায়া দিয়েই কার্ড আলাদা হয়।
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// সংখ্যা দেখানোর কার্ড — মোট তহবিল, মোট সদস্য, বকেয়া।
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? note;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodyMedium),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
