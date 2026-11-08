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
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// তালিকার সারিতে আইকনের বাক্স — নরম সবুজ পটভূমিতে সবুজ আইকন।
class ListIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;

  const ListIcon({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: iconSize,
      ),
    );
  }
}
