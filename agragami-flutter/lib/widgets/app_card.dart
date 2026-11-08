import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
export 'ledger_tile.dart';

/// অ্যাপের সব কার্ড এক রকম দেখাবে — সাদা, গোল কোণা, নরম ছায়া।
/// প্রিভিউয়ের মতোই: সাদা পটভূমির উপর বর্ডার দিয়েই কার্ড আলাদা হয়।
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
  final bool isGold;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isGold ? AppColors.goldSoft : AppColors.greenSoft;
    final fg = isGold ? AppColors.goldDark : theme.colorScheme.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: fg, size: 23),
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
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
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

/// কুইক অ্যাকশন কার্ড — যেমন 'আমার পাসবই', 'আইডি কার্ড'।
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isGold;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isGold ? AppColors.goldSoft : AppColors.greenSoft;
    final fg = isGold ? AppColors.goldDark : theme.colorScheme.primary;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: fg, size: 23),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// একক সারির লিংক বাটন — যেমন অনুমোদন কেন্দ্র বা নোটিশ বোর্ড।
class RowLinkButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback? onTap;

  const RowLinkButton({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icColor = iconColor ?? theme.colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: icColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 22,
          ),
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
