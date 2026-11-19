import 'package:agragami_fund/l10n/app_strings.dart';
import 'package:agragami_fund/models/app_user.dart';
import 'package:agragami_fund/models/payment_method.dart';
import 'package:agragami_fund/routes/app_router.dart';
import 'package:agragami_fund/screens/not_found_screen.dart';
import 'package:agragami_fund/theme/app_theme.dart';
import 'package:agragami_fund/widgets/app_button.dart';
import 'package:agragami_fund/widgets/member_id_card.dart';
import 'package:agragami_fund/widgets/payment_method_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// m28: Phase 4-এর যাচাই — রাউটার নিয়ম, ডার্ক মোডের কার্ড,
/// বোতামের ধরন, না-পাওয়া পাতা আর তারিখের ফরম্যাট।
void main() {
  group('resolveRedirect', () {
    const approved = AppUser(
      id: 'u1',
      email: 'a@b.c',
      role: UserRole.member,
      approvalStatus: ApprovalStatus.approved,
    );
    const pending = AppUser(
      id: 'u2',
      email: 'p@b.c',
      role: UserRole.pending,
      approvalStatus: ApprovalStatus.pending,
    );
    const branchAdmin = AppUser(
      id: 'u3',
      email: 'ba@b.c',
      role: UserRole.branchAdmin,
      approvalStatus: ApprovalStatus.approved,
      branchId: 'b1',
    );
    const superAdmin = AppUser(
      id: 'u4',
      email: 'sa@b.c',
      role: UserRole.superAdmin,
      approvalStatus: ApprovalStatus.approved,
    );

    String? redirect({
      bool authResolved = true,
      bool? hasUsers = true,
      AppUser? user,
      bool signedIn = false,
      bool appLocked = false,
      required String location,
    }) {
      return resolveRedirect(
        authResolved: authResolved,
        hasUsers: hasUsers,
        user: user,
        signedIn: signedIn,
        appLocked: appLocked,
        location: location,
      );
    }

    test('auth না আসা পর্যন্ত স্প্ল্যাশ', () {
      expect(redirect(authResolved: false, location: '/home'), '/splash');
      expect(redirect(authResolved: false, location: '/splash'), isNull);
    });

    test('কেউ নেই — শুধু সেটআপ', () {
      expect(redirect(hasUsers: false, location: '/login'), '/setup');
      expect(redirect(hasUsers: false, location: '/setup'), isNull);
    });

    test('ব্যবহারকারী থাকলে সেটআপ বন্ধ', () {
      expect(redirect(location: '/setup'), '/login');
      expect(
        redirect(location: '/setup', user: approved, signedIn: true),
        '/home',
      );
    });

    test('ঢোকা হয়নি — লগইন', () {
      expect(redirect(location: '/home'), '/login');
      expect(redirect(location: '/login'), isNull);
      expect(redirect(location: '/apply'), isNull);
    });

    test('ঢোকা আছে কিন্তু প্রোফাইল নেই — pending', () {
      expect(redirect(location: '/home', signedIn: true), '/pending');
      expect(redirect(location: '/pending', signedIn: true), isNull);
    });

    test('অনুমোদন বাকি — শুধু pending/apply/login', () {
      expect(
        redirect(location: '/home', user: pending, signedIn: true),
        '/pending',
      );
      expect(
        redirect(location: '/pending', user: pending, signedIn: true),
        isNull,
      );
      expect(
        redirect(location: '/apply', user: pending, signedIn: true),
        isNull,
      );
    });

    test('অনুমোদিত — login/pending/splash থেকে হোম', () {
      expect(
        redirect(location: '/login', user: approved, signedIn: true),
        '/home',
      );
      expect(
        redirect(location: '/pending', user: approved, signedIn: true),
        '/home',
      );
      expect(
        redirect(location: '/splash', user: approved, signedIn: true),
        '/home',
      );
      expect(
        redirect(location: '/home', user: approved, signedIn: true),
        isNull,
      );
    });

    test('অ্যাপ-লক চালু — শুধু /lock', () {
      expect(
        redirect(
          location: '/home',
          user: approved,
          signedIn: true,
          appLocked: true,
        ),
        '/lock',
      );
      expect(
        redirect(
          location: '/lock',
          user: approved,
          signedIn: true,
          appLocked: true,
        ),
        isNull,
      );
      expect(
        redirect(location: '/lock', user: approved, signedIn: true),
        '/home',
      );
    });

    test('F16: সদস্য খরচ/ঋণ যোগের পাতা খুলতে পারে না', () {
      expect(
        redirect(location: '/expenses/add', user: approved, signedIn: true),
        '/home',
      );
      expect(
        redirect(location: '/loans/add', user: approved, signedIn: true),
        '/home',
      );
    });

    test('F16: অ্যাডমিন খরচ/ঋণ যোগের পাতা খুলতে পারে', () {
      expect(
        redirect(
          location: '/expenses/add',
          user: branchAdmin,
          signedIn: true,
        ),
        isNull,
      );
      expect(
        redirect(location: '/loans/add', user: branchAdmin, signedIn: true),
        isNull,
      );
      expect(
        redirect(location: '/expenses/add', user: superAdmin, signedIn: true),
        isNull,
      );
      expect(
        redirect(location: '/loans/add', user: superAdmin, signedIn: true),
        isNull,
      );
    });
  });

  group('backFallbackLocation', () {
    test('বিস্তারিত পাতা তার তালিকায় ফেরে', () {
      expect(backFallbackLocation('/samiti/abc'), '/samiti');
      expect(backFallbackLocation('/expenses/add'), '/expenses');
      expect(backFallbackLocation('/loans/add'), '/loans');
      expect(backFallbackLocation('/loans/xyz'), '/loans');
    });

    test('অন্য পাতা হোমে ফেরে, হোমে null', () {
      expect(backFallbackLocation('/profile'), '/home');
      expect(backFallbackLocation('/home'), isNull);
    });
  });

  group('PaymentMethodCard (M8)', () {
    final method = PaymentMethodConfig(
      id: 'm1',
      name: 'bKash',
      type: PaymentMethodType.mobileBanking,
      accountNumber: '01XXXXXXXXX',
      accountHolderName: 'পরীক্ষা',
      createdBy: 'admin',
      createdAt: DateTime(2026, 1, 1),
    );

    BoxDecoration cardDecoration(WidgetTester tester) {
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.borderRadius ==
                  BorderRadius.circular(16),
        ),
      );
      return container.decoration as BoxDecoration;
    }

    testWidgets('ডার্ক মোডে কার্ডের রং থিমের surface', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: PaymentMethodCard(
              method: method,
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(
        cardDecoration(tester).color,
        AppTheme.dark().colorScheme.surface,
      );
    });

    testWidgets('নির্বাচিত কার্ড primary-র হালকা ছায়া', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: PaymentMethodCard(
              method: method,
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(
        cardDecoration(tester).color,
        AppTheme.dark().colorScheme.primary.withValues(alpha: 0.12),
      );
    });
  });

  group('PrimaryButton (m7)', () {
    testWidgets('আইকন না থাকলে সাধারণ ElevatedButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(label: 'জমা দিন', onPressed: () {}),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      // আইকনের ফাঁকা জায়গা নেই — লেখা মাঝখানেই থাকে।
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('আইকন থাকলে আইকন-বোতাম', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'জমা দিন',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  testWidgets('NotFoundScreen শিরোনাম আর হোম বোতাম দেখায় (m1)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotFoundScreen()),
    );
    expect(find.text(AppStrings.notFoundTitle), findsOneWidget);
    expect(find.text(AppStrings.backHome), findsOneWidget);
  });

  test('idCardDateText দিন-মাস শূন্য দিয়ে ভরাট করে (m9)', () {
    expect(idCardDateText(DateTime(2026, 3, 5)), '05/03/2026');
    expect(idCardDateText(DateTime(2026, 11, 19)), '19/11/2026');
  });
}
