import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import 'firestore_providers.dart';

enum NotificationType {
  approval,
  deposit,
  notice,
  loan,
  system,
}

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final String? route;
  final bool isRead;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.route,
    this.isRead = false,
  });
}

/// অ্যাপের নোটিফিকেশন ফিড প্রোভাইডার
final notificationsListProvider =
    Provider.autoDispose<List<AppNotificationItem>>((ref) {
  final isBn = AppStrings.isBangla;
  final pendingApps =
      ref.watch(pendingApplicationsProvider(null)).valueOrNull ?? [];
  final pendingPayments = ref.watch(pendingPaymentsProvider).valueOrNull ?? [];
  final notices = ref.watch(noticesStreamProvider).valueOrNull ?? [];

  final items = <AppNotificationItem>[];

  // অপেক্ষমাণ আবেদন নোটিফিকেশন
  if (pendingApps.isNotEmpty) {
    items.add(
      AppNotificationItem(
        id: 'pending_apps_${pendingApps.length}',
        title: isBn
            ? '${pendingApps.length}টি সদস্য আবেদন অপেক্ষমাণ'
            : '${pendingApps.length} Pending Applications',
        body: isBn
            ? 'নতুন সদস্যপদ যাচাই ও অনুমোদনের জন্য অপেক্ষা করছে।'
            : 'New member applications awaiting review.',
        timestamp: pendingApps.first.requestedAt,
        type: NotificationType.approval,
        route: '/approval',
      ),
    );
  }

  // অপেক্ষমাণ জমা নোটিফিকেশন
  if (pendingPayments.isNotEmpty) {
    items.add(
      AppNotificationItem(
        id: 'pending_payments_${pendingPayments.length}',
        title: isBn
            ? '${pendingPayments.length}টি জমা যাচাই বাকি'
            : '${pendingPayments.length} Pending Deposits',
        body: isBn
            ? 'সদস্যদের পাঠানো জমা যাচাই করে অনুমোদন দিন।'
            : 'Member deposits awaiting transaction verification.',
        timestamp: pendingPayments.first.date,
        type: NotificationType.deposit,
        route: '/approval',
      ),
    );
  }

  // সাম্প্রতিক নোটিশ
  for (final n in notices.take(3)) {
    items.add(
      AppNotificationItem(
        id: 'notice_${n.id}',
        title: n.title,
        body: n.body,
        timestamp: n.postedAt,
        type: NotificationType.notice,
        route: '/notices',
      ),
    );
  }

  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
});

/// অপঠিত নোটিফিকেশন সংখ্যা প্রোভাইডার (টপ বার ব্যাজের জন্য)
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsListProvider);
  return list.where((n) => !n.isRead).length;
});
