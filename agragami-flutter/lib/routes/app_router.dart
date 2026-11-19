import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/app_user.dart';
import '../screens/add_expense_screen.dart';
import '../screens/admin_approval_screen.dart';
import '../screens/app_lock_screen.dart';
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
import '../screens/member_detail_screen.dart';
import '../screens/not_found_screen.dart';
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
  // রাউটার Riverpod-এর বাইরে চলে — তাই শেয়ার্ড সিঙ্গেলটন
  // ইনস্ট্যান্স ব্যবহার হয়, প্রতিবার নতুন বানানো হয় না (m25)।
  final AuthService _auth = AuthService.instance;
  final FirestoreService _store = FirestoreService.instance;

  AppUser? user;

  /// users কালেকশনে কেউ আছে কি না — প্রথম সেটআপের জন্য।
  /// null মানে এখনো জানা যায়নি (যাচাই চলছে বা করা যায়নি) —
  /// null কখনো "কেউ নেই" ধরা হয় না (B1: fail closed)।
  bool? hasUsers;

  /// প্রথম auth/ব্যবহারকারী তথ্য এসেছে কি না — না আসা পর্যন্ত
  /// স্প্ল্যাশ দেখানো হয়, লগইন/হোমের সিদ্ধান্ত নেওয়া হয় না (m10)।
  bool authResolved = false;

  /// M11: অ্যাপ-লক চালু থাকলে আনলক না হওয়া পর্যন্ত শুধু
  /// /lock খোলে। লক শুধু ঢুকে থাকা অনুমোদিত ব্যবহারকারীর
  /// ওপর পড়ে — /login, /pending, /apply কখনো আটকায় না।
  bool appLocked = false;

  void setAppLocked(bool locked) {
    if (appLocked == locked) return;
    appLocked = locked;
    notifyListeners();
  }

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

  /// M11: অ্যাপ লক করা (চালু থাকলে আনলক ছাড়া ভেতরে ঢোকা যায় না)।
  static void lockApp() => _refresh.setAppLocked(true);

  /// M11: বায়োমেট্রিক যাচাইয়ের পর অ্যাপ আনলক করা।
  /// আনলকের সময় মনে রাখা হয় — বায়োমেট্রিক প্রম্পট নিজেই
  /// কিছু যন্ত্রে pause/resume ঘটায়, আনলকের ঠিক পরেই যাতে
  /// আবার লক না হয়ে যায় (main.dart-এ grace period)।
  static void unlockApp() {
    lastUnlockAt = DateTime.now();
    _refresh.setAppLocked(false);
  }

  /// M11: শেষ আনলকের সময়।
  static DateTime? lastUnlockAt;

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _refresh,
    // m1: অজানা রাস্তায় বন্ধুত্বপূর্ণ "পাওয়া যায়নি" পাতা।
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      // Phase 5 (04-m3/F18): আইডি কার্ডের QR স্ক্যানে অ্যাপ
      // orgogami://member/<id> দিয়ে খোলে — টপ-লেভেল
      // redirect রাস্তা মেলানোর আগেই চলে, তাই এখানেই
      // অ্যাপের রাস্তায় নিয়ে আসা হয়।
      final uri = state.uri;
      if (uri.scheme == 'orgogami' && uri.host == 'member') {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
        return id.isNotEmpty ? '/member/$id' : '/home';
      }
      return resolveRedirect(
        authResolved: _refresh.authResolved,
        hasUsers: _refresh.hasUsers,
        user: _refresh.user,
        signedIn: _refresh.signedIn,
        appLocked: _refresh.appLocked,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/lock',
        name: 'lock',
        builder: (context, state) => const AppLockScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) =>
            LoginScreen(notice: state.uri.queryParameters['notice']),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const FirstAdminSetupScreen(),
      ),
      GoRoute(
        path: '/pending',
        name: 'pending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/apply',
        name: 'apply',
        builder: (context, state) => MemberApplicationScreen(
          lockedBranchId: state.uri.queryParameters['branchId'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/samiti',
            name: 'samiti',
            builder: (context, state) => const SamitiListScreen(),
          ),
          GoRoute(
            path: '/samiti/:id',
            name: 'samitiDetail',
            builder: (context, state) => SamitiDetailScreen(
              branchId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/deposit',
            name: 'deposit',
            builder: (context, state) => const DepositScreen(),
          ),
          GoRoute(
            path: '/payment-methods',
            name: 'paymentMethods',
            builder: (context, state) => const PaymentMethodsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/passbook',
            name: 'passbook',
            builder: (context, state) => const PassbookScreen(),
          ),
          GoRoute(
            // Phase 5 (04-m3/F18): আইডি কার্ডের QR স্ক্যানে
            // খোলা সদস্যের পরিচয় — orgogami://member/<id>
            // redirect-এ এখানে আসে।
            path: '/member/:id',
            name: 'memberDetail',
            builder: (context, state) => MemberDetailScreen(
              memberId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/id-card',
            name: 'idCard',
            builder: (context, state) => const IdCardScreen(),
          ),
          GoRoute(
            path: '/approval',
            name: 'approval',
            builder: (context, state) => const AdminApprovalScreen(),
          ),
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            builder: (context, state) => const ExpenseListScreen(),
          ),
          GoRoute(
            path: '/expenses/add',
            name: 'addExpense',
            builder: (context, state) => const AddExpenseScreen(),
          ),
          GoRoute(
            path: '/loans',
            name: 'loans',
            builder: (context, state) => const LoanListScreen(),
          ),
          GoRoute(
            path: '/loans/add',
            name: 'addLoan',
            builder: (context, state) => const IssueLoanScreen(),
          ),
          GoRoute(
            path: '/loans/:id',
            name: 'loanDetail',
            builder: (context, state) => LoanDetailScreen(
              loanId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: '/notices',
            name: 'notices',
            builder: (context, state) => const NoticeBoardScreen(),
          ),
          GoRoute(
            path: '/committee',
            name: 'committee',
            builder: (context, state) => const CommitteeScreen(),
          ),
        ],
      ),
    ],
  );
}

/// রিডিরেক্ট সিদ্ধান্ত — খাঁটি ফাংশন, যাতে টেস্ট করা যায় (m28)।
/// null মানে রিডিরেক্ট নেই; স্ট্রিং মানে যেতে হবে ওই পাতায়।
/// গার্ডের নিয়ম: ঢুকে না থাকলে লগইন; অনুমোদন না পেলে শুধু
/// /pending, /apply আর /login; কেউ না থাকলে (প্রমাণিত) শুধু
/// /setup; অজানা মানেই সেটআপ বন্ধ (B1 fail-closed)।
String? resolveRedirect({
  required bool authResolved,
  required bool? hasUsers,
  required AppUser? user,
  required bool signedIn,
  required bool appLocked,
  required String location,
}) {
  // m10: প্রথম তথ্য না আসা পর্যন্ত স্প্ল্যাশ — লগইন স্ক্রিন
  // ক্ষণিকের জন্য দেখিয়ে বিভ্রান্ত করা হয় না।
  if (!authResolved) {
    return location == '/splash' ? null : '/splash';
  }
  // কেউ নেই — প্রথম অ্যাডমিন না বানানো পর্যন্ত শুধু সেটআপ।
  // (শুধু প্রমাণিত false হলেই — null মানে অজানা, সেটআপ নয়।)
  if (hasUsers == false) {
    return location == '/setup' ? null : '/setup';
  }
  // B1 fail-closed: সেটআপ খুলবে শুধু hasUsers == false
  // প্রমাণিত হলে। এখানে আসা মানেই hasUsers true বা অজানা —
  // দুই ক্ষেত্রেই সেটআপ বন্ধ।
  if (location == '/setup') {
    return user == null ? '/login' : '/home';
  }
  const open = ['/login', '/apply'];
  if (user == null) {
    // Firebase-এ ঢুকে আছে কিন্তু users ডকুমেন্ট নেই
    // (মুছে গেছে বা বানানো যায়নি) — প্রোফাইল-নেই অবস্থা।
    if (signedIn) {
      return location == '/pending' ? null : '/pending';
    }
    return open.contains(location) ? null : '/login';
  }
  // B2: অনুমোদন ছাড়া ভেতরে ঢোকা যাবে না — pending/rejected
  // শুধু /pending, /apply আর /login দেখতে পারে।
  if (!user.canEnter) {
    const allowed = ['/pending', '/apply', '/login'];
    return allowed.contains(location) ? null : '/pending';
  }
  // M11: অ্যাপ-লক চালু থাকলে আনলক না হওয়া পর্যন্ত শুধু /lock।
  if (appLocked) {
    return location == '/lock' ? null : '/lock';
  }
  if (location == '/lock') {
    return '/home';
  }
  if (location == '/login' || location == '/pending' || location == '/splash') {
    return '/home';
  }
  // Phase 5 (F16): খরচ যোগ আর ঋণ দেওয়া শুধু অ্যাডমিনের
  // কাজ — সদস্য সরাসরি লিংক দিয়ে খুললেও হোমে ফেরে।
  if ((location == '/expenses/add' || location == '/loans/add') &&
      !user.isAdmin) {
    return '/home';
  }
  return null;
}

/// m11: ফিরে যাওয়ার শেয়ার্ড নিয়ম — পেছনে যাওয়ার কিছু না
/// থাকলে কোন পাতায় যাবে। /home-এ null ফেরে (সেখানে খোলস
/// প্রস্থানের ডায়ালগ দেখায়)। home_shell আর agragami_app_bar
/// দুই জায়গায় একই ফাংশন চলে, যাতে নিয়ম আলাদা না হয়।
String? backFallbackLocation(String location) {
  if (location.startsWith('/samiti/') && location != '/samiti') {
    return '/samiti';
  }
  if (location.startsWith('/expenses/add')) {
    return '/expenses';
  }
  if (location.startsWith('/loans/add') ||
      (location.startsWith('/loans/') && location != '/loans')) {
    return '/loans';
  }
  if (location != '/home') return '/home';
  return null;
}

/// নিচের মেনুর ৪টা আইটেম — মোবাইলে এটাই প্রধান নেভিগেশন।
/// Phase 5 (04-m2): পথের স্ট্রিংয়ের পাশে রাউটের নামও থাকে —
/// নেভিগেশন goNamed দিয়ে হয়, যাতে রাস্তা বদলালে এক জায়গায় বদলায়।
class BottomNavItem {
  final String path;
  final String name;
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.path,
    required this.name,
    required this.icon,
    required this.label,
  });
}

const List<BottomNavItem> bottomNavItems = [
  BottomNavItem(
      path: '/home', name: 'home', icon: Icons.home_outlined, label: 'হোম'),
  BottomNavItem(
      path: '/samiti',
      name: 'samiti',
      icon: Icons.groups_outlined,
      label: 'সমিতি'),
  BottomNavItem(
      path: '/deposit',
      name: 'deposit',
      icon: Icons.payments_outlined,
      label: 'জমা দিন'),
  BottomNavItem(
      path: '/profile',
      name: 'profile',
      icon: Icons.person_outlined,
      label: 'প্রোফাইল'),
];
