import 'package:agragami_fund/utils/admin_branch_scope.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 8-এর যাচাই — শাখা-ভিত্তিক স্কোপের শেয়ার্ড নিয়ম
/// (scopedBranchIds আর isAdminForBranch)। G3/G4/G5-এর
/// স্কোপ আর G1-এর শাখা-ভিত্তিক অ্যাডমিন-পরীক্ষা এই দুই
/// ফাংশন দিয়েই চলে।
void main() {
  group('scopedBranchIds', () {
    test('সুপার অ্যাডমিন — null, মানে সব সমিতি', () {
      expect(
        scopedBranchIds(
          isSuperAdmin: true,
          isBranchAdmin: false,
          adminBranchId: null,
          approvedIds: const ['b1'],
        ),
        isNull,
      );
    });

    test('শাখা অ্যাডমিন — নিজের সমিতি + অনুমোদিত সদস্যপদ', () {
      final ids = scopedBranchIds(
        isSuperAdmin: false,
        isBranchAdmin: true,
        adminBranchId: 'a',
        approvedIds: const ['b', 'c'],
      );
      expect(ids, containsAll(['a', 'b', 'c']));
      expect(ids!.length, 3);
    });

    test('শাখা অ্যাডমিন নিজের সমিতির সদস্যও হলে দুইবার আসে না', () {
      final ids = scopedBranchIds(
        isSuperAdmin: false,
        isBranchAdmin: true,
        adminBranchId: 'a',
        approvedIds: const ['a', 'b'],
      );
      expect(ids, containsAll(['a', 'b']));
      expect(ids!.length, 2);
    });

    test('শাখা অ্যাডমিনের সমিতি বাঁধা না থাকলে শুধু সদস্যপদ', () {
      final ids = scopedBranchIds(
        isSuperAdmin: false,
        isBranchAdmin: true,
        adminBranchId: null,
        approvedIds: const ['b'],
      );
      expect(ids, ['b']);
    });

    test('শাখা অ্যাডমিনের সমিতি নেই, সদস্যপদও নেই — খালি তালিকা', () {
      final ids = scopedBranchIds(
        isSuperAdmin: false,
        isBranchAdmin: true,
        adminBranchId: null,
        approvedIds: const [],
      );
      expect(ids, isEmpty);
    });

    test('সাধারণ সদস্য — শুধু অনুমোদিত সদস্যপদ', () {
      final ids = scopedBranchIds(
        isSuperAdmin: false,
        isBranchAdmin: false,
        adminBranchId: null,
        approvedIds: const ['b', 'c'],
      );
      expect(ids, ['b', 'c']);
    });
  });

  group('isAdminForBranch', () {
    test('সুপার অ্যাডমিন সব সমিতির অ্যাডমিন', () {
      expect(
        isAdminForBranch(
          isSuperAdmin: true,
          isBranchAdmin: false,
          adminBranchId: null,
          branchId: 'x',
        ),
        isTrue,
      );
    });

    test('শাখা অ্যাডমিন নিজের সমিতির অ্যাডমিন', () {
      expect(
        isAdminForBranch(
          isSuperAdmin: false,
          isBranchAdmin: true,
          adminBranchId: 'a',
          branchId: 'a',
        ),
        isTrue,
      );
    });

    test('শাখা অ্যাডমিন অন্য সমিতির অ্যাডমিন নয়', () {
      expect(
        isAdminForBranch(
          isSuperAdmin: false,
          isBranchAdmin: true,
          adminBranchId: 'a',
          branchId: 'b',
        ),
        isFalse,
      );
    });

    test('শাখা অ্যাডমিনের সমিতি বাঁধা না থাকলে কোনো সমিতিরই নয়', () {
      expect(
        isAdminForBranch(
          isSuperAdmin: false,
          isBranchAdmin: true,
          adminBranchId: null,
          branchId: 'a',
        ),
        isFalse,
      );
    });

    test('সাধারণ সদস্য কোনো সমিতির অ্যাডমিন নয়', () {
      expect(
        isAdminForBranch(
          isSuperAdmin: false,
          isBranchAdmin: false,
          adminBranchId: null,
          branchId: 'a',
        ),
        isFalse,
      );
    });
  });
}
