import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/member_application.dart';
import '../models/notice.dart';
import '../models/payment.dart';
import '../utils/admin_branch_scope.dart';
import 'auth_service.dart';
import 'firestore_providers.dart';
import 'settings_service.dart';

/// m10: পড়া নোটিফিকেশনের id — SettingsService-এ সংরক্ষিত
/// থাকে, চালুর সময় main.dart-এ পড়ে override করা হয়।
final readNotificationIdsProvider =
    StateProvider<Set<String>>((ref) => const {});

/// m10: সব নোটিফিকেশন পড়া হিসেবে দাগানো — id গুলো
/// সংরক্ষিত হয়, ব্যাজ যাতে আবার না গোনে।
Future<void> markAllNotificationsRead(WidgetRef ref) async {
  final items = ref.read(notificationsListProvider);
  final ids = <String>{
    ...ref.read(readNotificationIdsProvider),
    ...items.map((i) => i.id),
  };
  ref.read(readNotificationIdsProvider.notifier).state = ids;
  await SettingsService.saveReadNotificationIds(ids);
}

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

  /// যে রাউটে যাবে — রাউটের নাম (04-m2: পথের স্ট্রিং
  /// নয়, goNamed-এর জন্য নাম ব্যবহার হয়)।
  final String? routeName;
  final bool isRead;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.routeName,
    this.isRead = false,
  });
}

/// অ্যাপের নোটিফিকেশন ফিড প্রোভাইডার
final notificationsListProvider =
    Provider.autoDispose<List<AppNotificationItem>>((ref) {
  final isBn = AppStrings.isBangla;
  final readIds = ref.watch(readNotificationIdsProvider);
  // Phase 5 (02-M2): অপেক্ষমাণ আবেদন/জমার প্রশ্ন শুধু
  // অ্যাডমিনের জন্য — সদস্যের কাছে এগুলো নিয়মে (rules)
  // বাধা পায়, আর অ্যাপ বার প্রতিটি স্ক্রিনে এটা দেখত।
  // শাখা অ্যাডমিন শুধু নিজের সমিতির অপেক্ষমাণ কাজ দেখে।
  final user = ref.watch(currentUserProvider).valueOrNull;
  final isAdmin = user?.isAdmin ?? false;
  final scopeBranchId = user?.isSuperAdmin == true ? null : user?.branchId;
  final pendingApps = isAdmin
      ? ref.watch(pendingApplicationsProvider(scopeBranchId)).valueOrNull ??
          []
      : const <MemberApplication>[];
  final pendingPayments = isAdmin
      ? ref.watch(pendingPaymentsProvider(scopeBranchId)).valueOrNull ?? []
      : const <Payment>[];
  // Phase 8 (G5): বেলে শুধু নিজের সমিতির নোটিশ আসে —
  // সুপার অ্যাডমিন সব দেখে, শাখা অ্যাডমিন নিজের সমিতি +
  // অনুমোদিত সদস্যপদ, সদস্য শুধু অনুমোদিত সমিতি। "সবার
  // জন্য" (org) নোটিশ সবাই দেখে।
  final memberships =
      ref.watch(myMembershipsProvider).valueOrNull ?? const [];
  final noticeScope = scopedBranchIds(
    isSuperAdmin: user?.isSuperAdmin ?? false,
    isBranchAdmin: user?.isBranchAdmin ?? false,
    adminBranchId: user?.branchId,
    approvedIds: approvedBranchIds(memberships),
  );
  final notices = (ref.watch(noticesStreamProvider).valueOrNull ?? [])
      .where(
        (n) =>
            noticeScope == null ||
            n.scope == NoticeScope.org ||
            (n.branchId != null && noticeScope.contains(n.branchId)),
      )
      .toList();

  final items = <AppNotificationItem>[];

  // অপেক্ষমাণ আবেদন নোটিফিকেশন
  if (pendingApps.isNotEmpty) {
    final id = 'pending_apps_${pendingApps.length}';
    items.add(
      AppNotificationItem(
        id: id,
        isRead: readIds.contains(id),
        title: isBn
            ? '${pendingApps.length}টি সদস্য আবেদন অপেক্ষমাণ'
            : '${pendingApps.length} Pending Applications',
        body: isBn
            ? 'নতুন সদস্যপদ যাচাই ও অনুমোদনের জন্য অপেক্ষা করছে।'
            : 'New member applications awaiting review.',
        timestamp: pendingApps.first.requestedAt,
        type: NotificationType.approval,
        routeName: 'approval',
      ),
    );
  }

  // অপেক্ষমাণ জমা নোটিফিকেশন
  if (pendingPayments.isNotEmpty) {
    final id = 'pending_payments_${pendingPayments.length}';
    items.add(
      AppNotificationItem(
        id: id,
        isRead: readIds.contains(id),
        title: isBn
            ? '${pendingPayments.length}টি জমা যাচাই বাকি'
            : '${pendingPayments.length} Pending Deposits',
        body: isBn
            ? 'সদস্যদের পাঠানো জমা যাচাই করে অনুমোদন দিন।'
            : 'Member deposits awaiting transaction verification.',
        timestamp: pendingPayments.first.date,
        type: NotificationType.deposit,
        routeName: 'approval',
      ),
    );
  }

  // সাম্প্রতিক নোটিশ
  for (final n in notices.take(3)) {
    final id = 'notice_${n.id}';
    items.add(
      AppNotificationItem(
        id: id,
        isRead: readIds.contains(id),
        title: n.title,
        body: n.body,
        timestamp: n.postedAt,
        type: NotificationType.notice,
        routeName: 'notices',
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
