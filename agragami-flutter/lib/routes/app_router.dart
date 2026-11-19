import 'dart:async';

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
import '../screens/splash_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// অনুমোদনের অবস্থা দেখে রাস্তা বদলে দেওয়ার কাজ।
/// লগইন করা ব্যবহারকারীর অবস্থা বদলালে রাউটারকে জানিয়ে দেয়।
class _AuthRefresh extends ChangeNotifier {
  // রাউটার Riverpod-এর বাইরে চলে — তাই এখানে একটাই শেয়ার্ড
  // ইনস্ট্যান্স রাখা হয়, প্রতিবার নতুন বানানো হয় না (m11)।
  final AuthService _auth = AuthService();
  final FirestoreService _store = FirestoreService();

  AppUser? user;

  /// users কালেকশনে কেউ আছে কি না — প্রথম সেটআপের জন্য।
  /// null মানে এখনো জানা যায়নি (যাচাই চলছে বা করা যায়নি) —
  /// null কখনো "কেউ নেই" ধরা হয় না (B1: fail closed)।
  bool? hasUsers;

  /// প্রথম auth/ব্যবহারকারী তথ্য এসেছে কি না — না আসা পর্যন্ত
  /// স্প্ল্যাশ দেখানো হয়, লগইন/হোমের সিদ্ধান্ত নেওয়া হয় না (m10)।
  bool authResolved = false;

  Timer? _resubscribeTimer;

  /// Firebase-এ ঢুকে আছে কি না — users ডকুমেন্ট না থাকলেও
  /// (যেমন ডকুমেন্ট মুছে গেলে) এটা true হতে পারে।
  bool get signedIn => _auth.firebaseUser != null;

  _AuthRefresh() {
    _subscribeUserStream();
    try {
      // গুগল দিয়ে ঢোকা শেষ হলে (ডকুমেন্ট বসানোসহ) গার্ড
      // আবার পড়ে — নতুন ব্যবহারকারী যাতে সঠিক পাতায় যায়।
      // Firebase-এর auth বদলের ঘটনা ডকুমেন্ট বসানোর আগেই
      // আসতে পারে, তাই শুধু ওটার ওপর ভরসা করা যায় না।
      _auth.googleSignInCompleted.listen(
        (_) => reload(),
        onError: (_) {},
      );
    } catch (_) {}
    _loadHasUsers();
  }

  void _subscribeUserStream() {
    try {
      // সাবস্ক্রিপশন অ্যাপ চলা পর্যন্ত বাঁচে — রাখার দরকার নেই।
      _auth.watchCurrentUser().listen(
        (u) {
          user = u;
          authResolved = true;
          // লগইনের পর hasUsers আবার পড়া — এখন অ্যাডমিন হলে
          // কোয়েরিটা সফল হতে পারে (M5)।
          if (u != null) _loadHasUsers();
          notifyListeners();
        },
        onError: (_) {
          // Firestore পড়া যায়নি (যেমন নিয়মে আটকে গেছে) —
          // fail closed: ব্যবহারকারী অজানা ধরা হয়।
          user = null;
          authResolved = true;
          notifyListeners();
          // ভুলে স্ট্রিম বন্ধ হয়ে গেছে — একটু পরে আবার শোনা শুরু।
          _resubscribeTimer ??= Timer(const Duration(seconds: 5), () {
            _resubscribeTimer = null;
            _subscribeUserStream();
          });
        },
      );
    } catch (_) {
      // Firebase কনফিগ না থাকলে এখানে ভুল হবে — তখন
      // ব্যবহারকারী ঢুকে নেই ধরে লগইন স্ক্রিনেই থাকবে।
      user = null;
      authResolved = true;
      notifyListeners();
    }
  }

  Future<void> _loadHasUsers() async {
    try {
      hasUsers = await _store.hasAnyUser();
    } catch (_) {
      hasUsers = null;
    }
    notifyListeners();
  }

  /// সাইন-আপ বা সেটআপের পর লগইনের অবস্থা আবার পড়া —
  /// অ্যাকাউন্ট খোলার সাথে সাথেই গার্ড যাতে নতুন অবস্থা দেখে।
  Future<void> reload() async {
    try {
      user = await _auth
          .watchCurrentUser()
          .first
          .timeout(const Duration(seconds: 5));
      authResolved = true;
      // সেটআপ/সাইন-আপের পর hasUsers-ও বদলে গিয়ে থাকতে পারে।
      _loadHasUsers();
      notifyListeners();
    } catch (e) {
      // সময় শেষ বা পড়া যায়নি — আগের অবস্থাই রাখা হয়,
      // বাসি তথ্যে রিডিরেক্ট জোর করা হয় না (m7)।
      debugPrint('AppRouter reload failed/timed out: $e');
    }
  }
}

/// অ্যাপের সব রাস্তা এখানে।
/// গার্ড: ঢুকে না থাকলে লগইন। ঢুকে থাকলেও অনুমোদন না পেলে
/// শুধু /pending, /apply আর /login — অনুমোদিতরাই হোমসহ
/// ভেতরের পাতা দেখতে পারে (B2)। সমিতির ভেতরের তথ্য (পাসবই,
/// খরচ, ঋণ, রিপোর্ট) স্ক্রিনে সমিতির সদস্যপদ দেখে আটকায়,
/// রাস্তায় নয়। প্রথমবার — কেউ না থাকলে (প্রমাণিত) শুধু
/// সেটআপের পাতা খোলে; অজানা মানেই সেটআপ বন্ধ (B1)।
class AppRouter {
  static final _refresh = _AuthRefresh();

  /// সাইন-আপ বা সেটআপের পর লগইনের অবস্থা আবার পড়া।
  static Future<void> refreshAuth() => _refresh.reload();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _refresh,
    redirect: (context, state) {
      final user = _refresh.user;
      final loc = state.matchedLocation;
      final hasUsers = _refresh.hasUsers;
      // m10: প্রথম তথ্য না আসা পর্যন্ত স্প্ল্যাশ — লগইন স্ক্রিন
      // ক্ষণিকের জন্য দেখিয়ে বিভ্রান্ত করা হয় না।
      if (!_refresh.authResolved) {
        return loc == '/splash' ? null : '/splash';
      }
      // কেউ নেই — প্রথম অ্যাডমিন না বানানো পর্যন্ত শুধু সেটআপ।
      // (শুধু প্রমাণিত false হলেই — null মানে অজানা, সেটআপ নয়।)
      if (hasUsers == false) {
        return loc == '/setup' ? null : '/setup';
      }
      // B1 fail-closed: সেটআপ খুলবে শুধু hasUsers == false
      // প্রমাণিত হলে। এখানে আসা মানেই hasUsers true বা অজানা —
      // দুই ক্ষেত্রেই সেটআপ বন্ধ।
      if (loc == '/setup') {
        return user == null ? '/login' : '/home';
      }
      const open = ['/login', '/apply'];
      if (user == null) {
        // Firebase-এ ঢুকে আছে কিন্তু users ডকুমেন্ট নেই
        // (মুছে গেছে বা বানানো যায়নি) — প্রোফাইল-নেই অবস্থা।
        if (_refresh.signedIn) {
          return loc == '/pending' ? null : '/pending';
        }
        return open.contains(loc) ? null : '/login';
      }
      // B2: অনুমোদন ছাড়া ভেতরে ঢোকা যাবে না — pending/rejected
      // শুধু /pending, /apply আর /login দেখতে পারে।
      if (!user.canEnter) {
        const allowed = ['/pending', '/apply', '/login'];
        return allowed.contains(loc) ? null : '/pending';
      }
      if (loc == '/login' || loc == '/pending' || loc == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(notice: state.uri.queryParameters['notice']),
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
