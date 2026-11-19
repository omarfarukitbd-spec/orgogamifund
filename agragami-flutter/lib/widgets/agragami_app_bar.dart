import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../services/notification_service.dart';
import 'app_icon.dart';

/// সব স্ক্রিনে একক হেডার — লোগো, নাম, হালাল নোট ও রিয়েল-টাইম নোটিফিকেশন বেল
class AgragamiAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool? showBackButton;
  final VoidCallback? onBack;

  const AgragamiAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    final notifications = ref.read(notificationsListProvider);
    final isBn = AppStrings.isBangla;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBn ? 'নোটিফিকেশন সেন্টার' : 'Notifications',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                // m10: সব পড়া হিসেবে দাগানো — ব্যাজ শূন্য হয়।
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      markAllNotificationsRead(ref);
                      Navigator.pop(ctx);
                    },
                    child: Text(AppStrings.markAllRead),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    isBn ? 'কোনো নতুন নোটিফিকেশন নেই' : 'No new notifications',
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = notifications[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        child: Icon(
                          item.type == NotificationType.approval
                              ? Icons.how_to_reg_outlined
                              : (item.type == NotificationType.deposit
                                  ? Icons.payment_outlined
                                  : Icons.campaign_outlined),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item.body,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (item.route != null) {
                          context.go(item.route!);
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    String location = '';
    try {
      location = GoRouterState.of(context).uri.toString();
    } catch (_) {}
    const rootRoutes = {'/home', '/samiti', '/deposit', '/profile'};
    final isSubRoute = showBackButton ??
        (location.isNotEmpty && !rootRoutes.contains(location));

    Widget? leadingWidget;
    if (isSubRoute) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'ফিরে যান',
        onPressed: onBack ??
            () {
              if (context.canPop()) {
                context.pop();
              } else {
                // m11: ফিরে যাওয়ার নিয়ম এক জায়গায়
                // (backFallbackLocation) — খোলসের সাথে মেলে।
                context.go(backFallbackLocation(location) ?? '/home');
              }
            },
      );
    }

    return AppBar(
      leading: leadingWidget,
      title: Row(
        children: [
          if (!isSubRoute) ...[
            const AgragamiLogo(size: 36, radius: 9),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.halalNote,
                  style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: actions ??
          [
            IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => _showNotificationsSheet(context, ref),
            ),
          ],
    );
  }
}
