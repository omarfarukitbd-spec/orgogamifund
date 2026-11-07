import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/agragami_app_bar.dart';

/// অ্যাপের খোলস — মোবাইলে নিচের মেনু, কম্পিউটারে বামের সাইডবার।
/// পুরোনো অ্যাপের লেআউট কপি করা হয়নি — এটা নতুন করে সাজানো।
class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  static const double _desktopBreakpoint = 900;

  int _indexFor(String location) {
    for (var i = 0; i < bottomNavItems.length; i++) {
      if (location.startsWith(bottomNavItems[i].path)) return i;
    }
    return 0;
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
    if (location.startsWith('/committee')) return AppStrings.navCommittee;
    return AppStrings.navHome;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        appBar: AgragamiAppBar(title: _titleFor(location)),
        body: Row(
          children: [
            _Sidebar(
              selectedIndex: _indexFor(location),
              onSelect: (path) => context.go(path),
            ),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: const _Footer(),
      );
    }

    return Scaffold(
      appBar: AgragamiAppBar(title: _titleFor(location)),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexFor(location),
        onTap: (i) => context.go(bottomNavItems[i].path),
        items: bottomNavItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(String path) onSelect;

  const _Sidebar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...bottomNavItems,
      const BottomNavItem(
        path: '/approval',
        icon: Icons.fact_check_outlined,
        label: 'অনুমোদন কেন্দ্র',
      ),
      const BottomNavItem(
        path: '/payment-methods',
        icon: Icons.account_balance_outlined,
        label: 'পেমেন্ট মাধ্যম',
      ),
      const BottomNavItem(
        path: '/expenses',
        icon: Icons.receipt_long_outlined,
        label: 'খরচ',
      ),
      const BottomNavItem(
        path: '/loans',
        icon: Icons.handshake_outlined,
        label: 'ঋণ',
      ),
      const BottomNavItem(
        path: '/reports',
        icon: Icons.bar_chart_outlined,
        label: 'রিপোর্ট',
      ),
      const BottomNavItem(
        path: '/notices',
        icon: Icons.campaign_outlined,
        label: 'নোটিশ',
      ),
      const BottomNavItem(
        path: '/committee',
        icon: Icons.groups_outlined,
        label: 'কমিটি',
      ),
      const BottomNavItem(
        path: '/profile',
        icon: Icons.settings_outlined,
        label: 'সেটিংস',
      ),
    ];
    return Container(
      width: 240,
      color: AppColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'অগ্রগামী ফান্ড',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++)
            ListTile(
              leading: Icon(
                items[i].icon,
                color: i == selectedIndex ? AppColors.gold : Colors.white70,
              ),
              title: Text(
                items[i].label,
                style: TextStyle(
                  color: i == selectedIndex ? Colors.white : Colors.white70,
                  fontWeight:
                      i == selectedIndex ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              selected: i == selectedIndex,
              onTap: () => onSelect(items[i].path),
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
