import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agragami_app_bar.dart';
import '../widgets/app_icon.dart';

/// অ্যাপের খোলস — মোবাইলে নিচের মেনু, কম্পিউটারে বামের সাইডবার।
/// পুরোনো অ্যাপের লেআউট কপি করা হয়নি — এটা নতুন করে সাজানো।
class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const double _desktopBreakpoint = 900;

  /// m27: শেষ দেখা ট্যাব — ট্যাব-বহির্ভূত পাতায় (যেমন
  /// /expenses/add) নিচের মেনু যাতে ভুল করে হোম না দেখায়,
  /// আগের ট্যাবই হাইলাইট থাকে।
  int _lastTabIndex = 0;

  /// ট্যাবের ইনডেক্স — ট্যাব নয় এমন পাতায় null (m27)।
  int? _indexFor(String location) {
    for (var i = 0; i < bottomNavItems.length; i++) {
      if (location.startsWith(bottomNavItems[i].path)) return i;
    }
    return null;
  }

  String _titleFor(String location) {
    if (location.startsWith('/samiti')) return AppStrings.navSamiti;
    if (location.startsWith('/deposit')) return AppStrings.navDeposit;
    if (location.startsWith('/payment-methods')) {
      return AppStrings.navPaymentMethods;
    }
    if (location.startsWith('/profile')) return AppStrings.navProfile;
    if (location.startsWith('/approval')) return AppStrings.navApproval;
    if (location.startsWith('/passbook')) return AppStrings.navPassbook;
    if (location.startsWith('/id-card')) return AppStrings.navIdCard;
    if (location.startsWith('/expenses')) return AppStrings.navExpenses;
    if (location.startsWith('/loans')) return AppStrings.navLoans;
    if (location.startsWith('/reports')) return AppStrings.navReports;
    if (location.startsWith('/notices')) return AppStrings.navNotices;
    if (location.startsWith('/member')) {
      return AppStrings.isBangla ? 'সদস্যের পরিচয়' : 'Member Profile';
    }
    if (location.startsWith('/committee')) return AppStrings.navCommittee;
    return AppStrings.navHome;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;
    // m27: ট্যাবের পাতায় এলে শেষ ট্যাব মনে রাখা — build
    // চলাকালীনই মান বসে, আলাদা setState লাগে না।
    final tabIndex = _indexFor(location);
    if (tabIndex != null) _lastTabIndex = tabIndex;

    Future<bool> showExitDialog() async {
      final isBn = AppStrings.isBangla;
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isBn ? 'অ্যাপ থেকে প্রস্থান' : 'Exit App'),
          content: Text(
            isBn
                ? 'আপনি কি নিশ্চিত যে অগ্রগামী ফান্ড অ্যাপ থেকে প্রস্থান করতে চান?'
                : 'Are you sure you want to exit Ogrogami Fund?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isBn ? 'না' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(isBn ? 'হ্যাঁ, প্রস্থান করুন' : 'Yes, Exit'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }

    void handleBack() async {
      if (context.canPop()) {
        context.pop();
        return;
      }
      // m11: ফিরে যাওয়ার নিয়ম এক জায়গায়
      // (backFallbackLocation) — অ্যাপ বারের সাথে মেলে।
      final fallback = backFallbackLocation(location);
      if (fallback != null) {
        context.go(fallback);
        return;
      }
      final exit = await showExitDialog();
      if (exit) {
        await SystemNavigator.pop();
      }
    }

    if (isDesktop) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) handleBack();
        },
        child: Scaffold(
          appBar: AgragamiAppBar(
            title: _titleFor(location),
            onBack: handleBack,
          ),
          body: Row(
            children: [
              _Sidebar(
                location: location,
                onSelect: (name) => context.goNamed(name),
              ),
              Expanded(child: widget.child),
            ],
          ),
          bottomNavigationBar: const _Footer(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleBack();
      },
      child: Scaffold(
        appBar: AgragamiAppBar(
          title: _titleFor(location),
          onBack: handleBack,
        ),
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _lastTabIndex,
          onTap: (i) => context.goNamed(bottomNavItems[i].name),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.groups_outlined),
              label: AppStrings.navSamiti,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined),
              label: AppStrings.navDeposit,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outlined),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String location;

  /// রাউটের নাম দিয়ে নেভিগেট হয় (04-m2) — path শুধু
  /// হাইলাইট বের করার জন্য থাকে।
  final void Function(String name) onSelect;

  const _Sidebar({required this.location, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      (
        path: '/home',
        name: 'home',
        icon: Icons.home_outlined,
        label: AppStrings.navHome,
        adminOnly: false
      ),
      (
        path: '/samiti',
        name: 'samiti',
        icon: Icons.groups_outlined,
        label: AppStrings.navSamiti,
        adminOnly: false
      ),
      (
        path: '/deposit',
        name: 'deposit',
        icon: Icons.payments_outlined,
        label: AppStrings.navDeposit,
        adminOnly: false
      ),
      (
        path: '/approval',
        name: 'approval',
        icon: Icons.fact_check_outlined,
        label: AppStrings.navApproval,
        adminOnly: true
      ),
      (
        path: '/payment-methods',
        name: 'paymentMethods',
        icon: Icons.account_balance_outlined,
        label: AppStrings.navPaymentMethods,
        adminOnly: true
      ),
      (
        path: '/expenses',
        name: 'expenses',
        icon: Icons.receipt_long_outlined,
        label: AppStrings.navExpenses,
        adminOnly: false
      ),
      (
        path: '/loans',
        name: 'loans',
        icon: Icons.handshake_outlined,
        label: AppStrings.navLoans,
        adminOnly: false
      ),
      (
        path: '/reports',
        name: 'reports',
        icon: Icons.bar_chart_outlined,
        label: AppStrings.navReports,
        adminOnly: false
      ),
      (
        path: '/notices',
        name: 'notices',
        icon: Icons.campaign_outlined,
        label: AppStrings.navNotices,
        adminOnly: false
      ),
      (
        path: '/committee',
        name: 'committee',
        icon: Icons.groups_outlined,
        label: AppStrings.navCommittee,
        adminOnly: false
      ),
      (
        path: '/profile',
        name: 'profile',
        icon: Icons.settings_outlined,
        label: AppStrings.navProfile,
        adminOnly: false
      ),
    ];
    // Phase 9 (G10): অ্যাডমিন-শুধু পাতার লিংক সাধারণ
    // সদস্য দেখে না — নইলে খুলে "শুধু অ্যাডমিন" খালি পাতা
    // পেত (ডেড-এন্ড লিংক)। মোবাইলের নিচের মেনুতে এই
    // লিংকগুলো এমনিতেই নেই।
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;
    final visibleItems =
        items.where((i) => !i.adminOnly || isAdmin).toList();
    // M6: সাইডবারের নিজের ইনডেক্স — এর আইটেমের সাথে
    // নিচের মেনুর ৪ আইটেমের ইনডেক্স মেলে না, তাই আলাদা
    // হিসাব। তালিকায় নেই এমন পাতায় (পাসবই, আইডি কার্ড)
    // -1 — কিছু হাইলাইট হয় না।
    var selectedIndex = -1;
    for (var i = 0; i < visibleItems.length; i++) {
      if (location.startsWith(visibleItems[i].path)) {
        selectedIndex = i;
        break;
      }
    }
    return Container(
      width: 240,
      color: AppColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                AgragamiLogo(size: 40, radius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'অগ্রগামী ফান্ড',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),
          for (var i = 0; i < visibleItems.length; i++)
            ListTile(
              leading: Icon(
                visibleItems[i].icon,
                color: i == selectedIndex ? AppColors.gold : Colors.white70,
              ),
              title: Text(
                visibleItems[i].label,
                style: TextStyle(
                  color: i == selectedIndex ? Colors.white : Colors.white70,
                  fontWeight:
                      i == selectedIndex ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              selected: i == selectedIndex,
              selectedTileColor: Colors.white.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => onSelect(visibleItems[i].name),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.greenDark,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: const Text(
        'অগ্রগামী ফান্ড — সম্পূর্ণ হালাল, সুদমুক্ত',
        style: TextStyle(color: Colors.white70, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}
