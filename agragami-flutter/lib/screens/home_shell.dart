import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/agragami_app_bar.dart';
import '../widgets/app_icon.dart';

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
      } else if (location.startsWith('/samiti/') && location != '/samiti') {
        context.go('/samiti');
      } else if (location.startsWith('/expenses/add')) {
        context.go('/expenses');
      } else if (location.startsWith('/loans/add') ||
          (location.startsWith('/loans/') && location != '/loans')) {
        context.go('/loans');
      } else if (location != '/home') {
        context.go('/home');
      } else {
        final exit = await showExitDialog();
        if (exit) {
          await SystemNavigator.pop();
        }
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
                selectedIndex: _indexFor(location),
                onSelect: (path) => context.go(path),
              ),
              Expanded(child: child),
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
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _indexFor(location),
          onTap: (i) => context.go(bottomNavItems[i].path),
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

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(String path) onSelect;

  const _Sidebar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = [
      (path: '/home', icon: Icons.home_outlined, label: AppStrings.navHome),
      (path: '/samiti', icon: Icons.groups_outlined, label: AppStrings.navSamiti),
      (path: '/deposit', icon: Icons.payments_outlined, label: AppStrings.navDeposit),
      (path: '/approval', icon: Icons.fact_check_outlined, label: AppStrings.navApproval),
      (path: '/payment-methods', icon: Icons.account_balance_outlined, label: AppStrings.navPaymentMethods),
      (path: '/expenses', icon: Icons.receipt_long_outlined, label: AppStrings.navExpenses),
      (path: '/loans', icon: Icons.handshake_outlined, label: AppStrings.navLoans),
      (path: '/reports', icon: Icons.bar_chart_outlined, label: AppStrings.navReports),
      (path: '/notices', icon: Icons.campaign_outlined, label: AppStrings.navNotices),
      (path: '/committee', icon: Icons.groups_outlined, label: AppStrings.navCommittee),
      (path: '/profile', icon: Icons.settings_outlined, label: AppStrings.navProfile),
    ];
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
              selectedTileColor: Colors.white.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
