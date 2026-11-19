import 'package:agragami_fund/l10n/app_strings.dart';
import 'package:agragami_fund/models/expense.dart';
import 'package:agragami_fund/models/loan.dart';
import 'package:agragami_fund/models/payment.dart';
import 'package:agragami_fund/services/statement_export_service.dart';
import 'package:agragami_fund/utils/bn_digits.dart';
import 'package:agragami_fund/utils/dues.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 5-এর যাচাই — বকেয়া ইঞ্জিন (F21-এর জায়গা),
/// মাসিক CSV (F23-এর জায়গা) আর বাংলা-অঙ্ক ফরম্যাটার (F19)।
void main() {
  Payment payment({
    required int forMonth,
    required int forYear,
    required int amount,
    PaymentStatus status = PaymentStatus.approved,
  }) {
    return Payment(
      id: 'p-$forYear-$forMonth-${status.name}',
      memberId: 'm1',
      branchId: 'b1',
      type: PaymentType.monthly,
      amount: amount,
      method: PaymentMethodKind.cash,
      forMonth: forMonth,
      forYear: forYear,
      date: DateTime(forYear, forMonth, 5),
      recordedBy: 'u1',
      status: status,
    );
  }

  group('memberDuesPerMonth', () {
    test('পুরো জমা দিলে বকেয়া ০', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(2026, 1, 5),
        branchStart: null,
        monthlyAmount: 200,
        payments: [
          payment(forMonth: 1, forYear: 2026, amount: 200),
          payment(forMonth: 2, forYear: 2026, amount: 200),
        ],
        asOf: DateTime(2026, 2, 15),
      );
      expect(result, isNotNull);
      expect(result!.totalDue, 0);
      expect(result.paidMonths, 2);
      expect(result.dueMonths, 0);
      expect(result.expectedMonths, 2);
    });

    test('আংশিক জমা — বাকিটা বকেয়া থাকে', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(2026, 1, 5),
        branchStart: null,
        monthlyAmount: 200,
        payments: [payment(forMonth: 1, forYear: 2026, amount: 100)],
        asOf: DateTime(2026, 1, 15),
      );
      expect(result!.totalDue, 100);
      expect(result.paidMonths, 0);
      expect(result.dueMonths, 1);
    });

    test('যাচাইাধীন (pending) জমা বকেয়া কমায় না', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(2026, 1, 5),
        branchStart: null,
        monthlyAmount: 200,
        payments: [
          payment(
            forMonth: 1,
            forYear: 2026,
            amount: 200,
            status: PaymentStatus.pending,
          ),
        ],
        asOf: DateTime(2026, 1, 15),
      );
      expect(result!.totalDue, 200);
      expect(result.dueMonths, 1);
    });

    test('যোগদানের আগের মাস বকেয়া ধরা হয় না', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(2026, 2, 5),
        branchStart: null,
        monthlyAmount: 200,
        payments: const [],
        asOf: DateTime(2026, 3, 15),
      );
      expect(result!.expectedMonths, 2);
      expect(result.totalDue, 400);
    });

    test('চলতি মাস dueDay-এর আগে ধরা হয় না', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(2026, 1, 5),
        branchStart: null,
        monthlyAmount: 200,
        payments: const [],
        dueDay: 10,
        asOf: DateTime(2026, 3, 5),
      );
      // মার্চ এখনো dueDay পেরোয়নি — জানুয়ারি+ফেব্রুয়ারি।
      expect(result!.expectedMonths, 2);
      expect(result.totalDue, 400);
    });

    test('যোগদানের তারিখ জানা না থাকলে null — আন্দাজে হিসাব নয়', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(1970, 1, 1),
        branchStart: null,
        monthlyAmount: 200,
        payments: const [],
        asOf: DateTime(2026, 2, 15),
      );
      expect(result, isNull);
    });

    test('বকেয়া প্রতিটি মাসের জন্য জরিমানা', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(2026, 1, 5),
        branchStart: null,
        monthlyAmount: 200,
        payments: const [],
        lateFineAmount: 50,
        asOf: DateTime(2026, 2, 15),
      );
      expect(result!.totalDue, 400);
      expect(result.lateFine, 100);
      expect(result.totalWithFine, 500);
    });

    test('এক মাসের বেশি জমা অন্য মাসে যায় না (M6 নীতি)', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(2026, 1, 5),
        branchStart: null,
        monthlyAmount: 200,
        payments: [payment(forMonth: 1, forYear: 2026, amount: 400)],
        asOf: DateTime(2026, 2, 15),
      );
      expect(result!.paidMonths, 1);
      expect(result.totalDue, 200);
    });

    test('সমিতি পরে শুরু হলে সেখান থেকে গোনা হয়', () {
      final result = memberDuesPerMonth(
        joinDate: DateTime(2026, 1, 5),
        branchStart: DateTime(2026, 2, 1),
        monthlyAmount: 200,
        payments: const [],
        asOf: DateTime(2026, 2, 15),
      );
      expect(result!.expectedMonths, 1);
      expect(result.totalDue, 200);
    });
  });

  group('generateMonthlyStatementCsv (F23)', () {
    late StatementExportService service;

    setUp(() {
      AppStrings.currentLocale = const Locale('bn', 'BD');
      service = StatementExportService();
    });

    String buildCsv() {
      return service.generateMonthlyStatementCsv(
        year: 2026,
        month: 2,
        branchName: 'পরীক্ষা সমিতি',
        payments: [
          payment(forMonth: 2, forYear: 2026, amount: 200),
          // যাচাইাধীন জমা — CSV-তে আসা যাবে না।
          payment(
            forMonth: 2,
            forYear: 2026,
            amount: 777,
            status: PaymentStatus.pending,
          ),
        ],
        expenses: [
          Expense(
            id: 'e1',
            branchId: 'b1',
            category: 'মাদ্রাসা উন্নয়ন',
            amount: 150,
            date: DateTime(2026, 2, 10),
            description: 'ছাদের কাজ',
            recordedBy: 'u1',
          ),
        ],
        loans: [
          Loan(
            id: 'l1',
            memberId: 'm1',
            branchId: 'b1',
            amount: 1000,
            dateIssued: DateTime(2026, 2, 3),
            reason: 'ব্যবসা',
            status: LoanStatus.active,
            repayments: [
              LoanRepayment(
                amount: 400,
                date: DateTime(2026, 2, 20),
                method: 'cash',
              ),
            ],
          ),
          // জানুয়ারির ঋণ — ফেব্রুয়ারির হিসাবে আসা যাবে না।
          Loan(
            id: 'l2',
            memberId: 'm2',
            branchId: 'b1',
            amount: 8888,
            dateIssued: DateTime(2026, 1, 15),
            reason: 'চিকিৎসা',
            status: LoanStatus.active,
          ),
        ],
      );
    }

    test('যাচাইাধীন জমা আয় হিসেবে গোনা হয় না', () {
      final csv = buildCsv();
      expect(csv, contains('মোট জমা,,,,,200'));
      expect(csv, isNot(contains('777')));
    });

    test('ঋণের প্রবাহ মাস-ছাঁকা দিয়ে আসে', () {
      final csv = buildCsv();
      expect(csv, contains('মোট ঋণ দেওয়া হয়েছে,,,1000'));
      expect(csv, contains('মোট কিস্তি ফেরত,,,400'));
      expect(csv, isNot(contains('8888')));
    });

    test('নীট স্থিতি PDF-এর সূত্রের সাথে মেলে', () {
      final csv = buildCsv();
      // প্রাপ্তি 200 + 400 = 600; ব্যয় 150 + 1000 = 1150;
      // নীট 600 − 1150 = −550।
      expect(csv, contains('মোট প্রাপ্তি,600 টাকা'));
      expect(csv, contains('মোট ব্যয়,1150 টাকা'));
      expect(csv, contains('নীট স্থিতি,-550 টাকা'));
    });
  });

  group('BnDigitsOnlyFormatter (F19)', () {
    const formatter = BnDigitsOnlyFormatter();

    test('বাংলা অঙ্ক বদলালেও কার্সর একই জায়গায় থাকে', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(
          text: '১২৩',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(result.text, '123');
      expect(result.selection.baseOffset, 1);
      expect(result.selection.extentOffset, 1);
    });

    test('বাদ পড়া অক্ষরের পর কার্সর ঠিক জায়গায় সরে', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(
          text: '১a২৩',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(result.text, '123');
      // 'a' বাদ গেছে — কার্সর '১'-এর পরে, অর্থাৎ অফসেট ১।
      expect(result.selection.baseOffset, 1);
    });
  });
}
