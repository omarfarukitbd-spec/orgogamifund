import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/app_user.dart';
import '../screens/add_expense_screen.dart';
import '../screens/admin_approval_screen.dart';
import '../screens/committee_screen.dart';
import '../screens/deposit_screen.dart';
import '../screens/expense_list_screen.dart';
import '../screens/first_admin_setup_screen.dart';
import '../screens/home_shell.dart';
import '../screens/home_screen.dart';
import '../screens/id_card_screen.dart';
import '../screens/issue_loan_screen.dart';
import '../screens/loan_detail_screen.dart';
import '../screens/loan_list_screen.dart';
import '../screens/login_screen.dart';
import '../screens/member_application_screen.dart';
import '../screens/notice_board_screen.dart';
import '../screens/passbook_screen.dart';
import '../screens/payment_methods_screen.dart';
import '../screens/pending_approval_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/report_screen.dart';
import '../screens/samiti_detail_screen.dart';
import '../screens/samiti_list_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// অনুমোদনের অবস্থা দেখে রাস্তা বদলে দেওয়ার কাজ।
/// লগইন করা ব্যবহারকারীর অবস্থা বদলালে রাউটারকে জানিয়ে দেয়।
class _AuthRefresh extends ChangeNotifier {
  AppUser? user;

  /// users কালেকশনে কেউ আছে কি না — প্রথম সেটআপের জন্য।
  /// null মানে এখনো জানা যায়নি (যাচাই চলছে বা করা যায়নি)।
  bool? hasUsers;

  _AuthRefresh() {
    try {
      AuthService().watchCurrentUser().listen(
        (u) {
          user = u;
          notifyListeners();
        },
        onError: (_) {},
      );
    } catch (_) {
      // Firebase কনফিগ না থাকলে এখানে ভুল হবে — তখন
      // ব্যবহারকারী ঢুকে নেই ধরে লগইন স্ক্রিনেই থাকবে।
    }
    try {
      // গুগল দিয়ে ঢোকা শেষ হলে (ডকুমেন্ট বসানোসহ) গার্ড
      // আবার পড়ে — নতুন ব্যবহারকারী যাতে সঠিক পাতায় যায়।
      // Firebase-এর auth বদলের ঘটনা ডকুমেন্ট বসানোর আগেই
      // আসতে পারে, তাই শুধু ওটার ওপর ভরসা করা যায় না।
      AuthService().googleSignInCompleted.listen(
        (_) => reload(),
        onError: (_) {},
      );
    } catch (_) {}
    _loadHasUsers();
  }

  Future<void> _loadHasUsers() async {
    try {
      hasUsers = await FirestoreService().hasAnyUser();
    } catch (_) {
      hasUsers = null;
    }
    notifyListeners();
  }

  /// সাইন-আপ বা সেটআপের পর লগইনের অবস্থা আবার পড়া —
  /// অ্যাকাউন্ট খোলার সাথে সাথেই গার্ড যাতে নতুন অবস্থা দেখে।
  Future<void> reload() async {
    try {
      user = await AuthService()
          .watchCurrentUser()
          .first
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    notifyListeners();
  }
}

/// অ্যাপের সব রাস্তা এখানে।
/// গার্ড: ঢুকে না থাকলে লগইন। ঢুকে থাকলে হোম আর সমিতির
/// তালিকা সবার জন্য খোলা — সমিতির ভেতরের তথ্য (পাসবই,
/// খরচ, ঋণ, রিপোর্ট) স্ক্রিনে সমিতির সদস্যপদ দেখে আটকায়,
/// রাস্তায় নয়। প্রথমবার — কেউ না থাকলে শুধু সেটআপের পাতা খোলে।
class AppRouter {
  static final _refresh = _AuthRefresh();

  /// সাইন-আপ বা সেটআপের পর লগইনের অবস্থা আবার পড়া।
  static Future<void> refreshAuth() => _refresh.reload();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _refresh,
    redirect: (context, state) {
      final user = _refresh.user;
      final loc = state.matchedLocation;
      final hasUsers = _refresh.hasUsers;
      // কেউ নেই — প্রথম অ্যাডমিন না বানানো পর্যন্ত শুধু সেটআপ।
      if (hasUsers == false) {
        return loc == '/setup' ? null : '/setup';
      }
      // অ্যাডমিন তৈরি হয়ে গেছে — সেটআপ আর খুলবে না।
      if (loc == '/setup') {
        if (hasUsers == true) return user == null ? '/login' : '/home';
        return null;
      }
      const open = ['/login', '/apply'];
      if (user == null) {
        return open.contains(loc) ? null : '/login';
      }
      if (loc == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const FirstAdminSetupScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/apply',
        builder: (context, state) => MemberApplicationScreen(
          lockedBranchId: state.uri.queryParameters['branchId'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/samiti',
            builder: (context, state) => const SamitiListScreen(),
          ),
          GoRoute(
            path: '/samiti/:id',
            builder: (context, state) => SamitiDetailScreen(
              branchId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/deposit',
            builder: (context, state) => const DepositScreen(),
          ),
          GoRoute(
            path: '/payment-methods',
            builder: (context, state) => const PaymentMethodsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/passbook',
            builder: (context, state) => const PassbookScreen(),
          ),
          GoRoute(
            path: '/id-card',
            builder: (context, state) => const IdCardScreen(),
          ),
          GoRoute(
            path: '/approval',
            builder: (context, state) => const AdminApprovalScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpenseListScreen(),
          ),
          GoRoute(
            path: '/expenses/add',
            builder: (context, state) => const AddExpenseScreen(),
          ),
          GoRoute(
            path: '/loans',
            builder: (context, state) => const LoanListScreen(),
          ),
          GoRoute(
            path: '/loans/add',
            builder: (context, state) => const IssueLoanScreen(),
          ),
          GoRoute(
            path: '/loans/:id',
            builder: (context, state) => LoanDetailScreen(
              loanId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: '/notices',
            builder: (context, state) => const NoticeBoardScreen(),
          ),
          GoRoute(
            path: '/committee',
            builder: (context, state) => const CommitteeScreen(),
          ),
        ],
      ),
    ],
  );
}

/// নিচের মেনুর ৪টা আইটেম — মোবাইলে এটাই প্রধান নেভিগেশন।
class BottomNavItem {
  final String path;
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.path,
    required this.icon,
    required this.label,
  });
}

const List<BottomNavItem> bottomNavItems = [
  BottomNavItem(path: '/home', icon: Icons.home_outlined, label: 'হোম'),
  BottomNavItem(path: '/samiti', icon: Icons.groups_outlined, label: 'সমিতি'),
  BottomNavItem(path: '/deposit', icon: Icons.payments_outlined, label: 'জমা দিন'),
  BottomNavItem(path: '/profile', icon: Icons.person_outlined, label: 'প্রোফাইল'),
];
