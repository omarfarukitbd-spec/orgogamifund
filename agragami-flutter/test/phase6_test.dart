import 'package:agragami_fund/models/app_user.dart';
import 'package:agragami_fund/utils/admin_promotion.dart';
import 'package:agragami_fund/utils/firebase_errors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 6-এর যাচাই — শাখা অ্যাডমিন বানানো/সরানোর সিদ্ধান্ত
/// (decideAdminRoleAction) আর তার ভুল-বার্তাগুলো। সিদ্ধান্তটা
/// শুদ্ধ ফাংশন, Firestore ছাড়াই পরীক্ষা করা যায় — UI আর
/// রিপোজিটরি দুই জায়গায় একই নিয়ম চলে।
void main() {
  AppUser user({
    String id = 'u-target',
    UserRole role = UserRole.member,
    ApprovalStatus status = ApprovalStatus.approved,
    String? branchId = 'b1',
  }) {
    return AppUser(
      id: id,
      email: 'target@example.com',
      role: role,
      branchId: branchId,
      approvalStatus: status,
    );
  }

  // targetUser ইচ্ছা করে required — null পাঠানো আর না
  // পাঠানো আলাদা জিনিস, `?? user()` দিলে null-পরীক্ষাটাই
  // কখনো null পেত না।
  AdminRoleDecision decide({
    String? linkedUserId = 'u-target',
    required AppUser? targetUser,
    String currentUid = 'u-admin',
    String branchId = 'b1',
  }) {
    return decideAdminRoleAction(
      linkedUserId: linkedUserId,
      targetUser: targetUser,
      currentUid: currentUid,
      branchId: branchId,
    );
  }

  group('decideAdminRoleAction', () {
    test('লগইন অ্যাকাউন্ট না থাকলে বোতাম নয়, কারণসহ নোট', () {
      final d = decide(linkedUserId: null, targetUser: null);
      expect(d.state, AdminRoleSectionState.info);
      expect(d.note, contains('লগইন অ্যাকাউন্ট নেই'));
    });

    test('খালি লগইন id-ও একই নোট দেয়', () {
      final d = decide(linkedUserId: '', targetUser: null);
      expect(d.state, AdminRoleSectionState.info);
      expect(d.note, contains('লগইন অ্যাকাউন্ট নেই'));
    });

    test('প্রোফাইল ডকুমেন্ট না পেলে আন্দাজে এগোয় না', () {
      final d = decide(targetUser: null);
      expect(d.state, AdminRoleSectionState.info);
      expect(d.note, contains('পাওয়া যায়নি'));
    });

    test('সমিতি জানা না থাকলে তথ্য দেখায়, বোতাম নয়', () {
      final d = decide(targetUser: user(), branchId: '');
      expect(d.state, AdminRoleSectionState.info);
      expect(d.note, contains('সমিতি জানা নেই'));
    });

    test('নিজের অ্যাকাউন্টে অংশটাই লুকানো থাকে', () {
      final d = decide(targetUser: user(), currentUid: 'u-target');
      expect(d.state, AdminRoleSectionState.hidden);
      expect(d.note, isNull);
    });

    test('সুপার অ্যাডমিনের ওপর অংশটাই লুকানো থাকে', () {
      final d = decide(targetUser: user(role: UserRole.superAdmin));
      expect(d.state, AdminRoleSectionState.hidden);
      expect(d.note, isNull);
    });

    test('অনুমোদিত না হলে অ্যাডমিন বানানো যায় না', () {
      final d = decide(
        targetUser: user(status: ApprovalStatus.pending),
      );
      expect(d.state, AdminRoleSectionState.info);
      expect(d.note, contains('অনুমোদিত নয়'));
    });

    test('অনুমোদিত সদস্য হলে "অ্যাডমিন বানান" দেখায়', () {
      final d = decide(targetUser: user());
      expect(d.state, AdminRoleSectionState.promote);
    });

    test('রোল pending কিন্তু অনুমোদিত হলে বানানো যায়', () {
      final d = decide(
        targetUser: user(role: UserRole.pending),
      );
      expect(d.state, AdminRoleSectionState.promote);
    });

    test('এই সমিতির অ্যাডমিন হলে "অ্যাডমিন সরান" দেখায়', () {
      final d = decide(
        targetUser: user(role: UserRole.branchAdmin, branchId: 'b1'),
      );
      expect(d.state, AdminRoleSectionState.demote);
    });

    test('branchId না থাকা অ্যাডমিনকেও এখান থেকে সরানো যায়', () {
      final d = decide(
        targetUser: user(role: UserRole.branchAdmin, branchId: null),
      );
      expect(d.state, AdminRoleSectionState.demote);
    });

    test('অন্য সমিতির অ্যাডমিনকে চুপচাপ বদলানো হয় না', () {
      final d = decide(
        targetUser: user(role: UserRole.branchAdmin, branchId: 'b2'),
      );
      expect(d.state, AdminRoleSectionState.info);
      expect(d.note, contains('অন্য একটি সমিতির অ্যাডমিন'));
    });
  });

  group('firebaseErrorMessage — অ্যাডমিন বদলের ভুল', () {
    test('নিজের রোল বদলের চেষ্টা', () {
      expect(
        firebaseErrorMessage(StateError('cannot-change-self')),
        'নিজের রোল নিজে বদলানো যায় না',
      );
    });

    test('সুপার অ্যাডমিনের রোল বদলের চেষ্টা', () {
      expect(
        firebaseErrorMessage(StateError('cannot-change-super-admin')),
        'সুপার অ্যাডমিনের রোল বদলানো যায় না',
      );
    });

    test('আগেই এই সমিতির অ্যাডমিন', () {
      expect(
        firebaseErrorMessage(StateError('already-branch-admin')),
        'এই সদস্য ইতিমধ্যে এই সমিতির অ্যাডমিন',
      );
    });

    test('অন্য সমিতির অ্যাডমিন', () {
      expect(
        firebaseErrorMessage(StateError('admin-of-other-branch')),
        'এই সদস্য অন্য একটি সমিতির অ্যাডমিন',
      );
    });

    test('এই সমিতির অ্যাডমিন নন', () {
      expect(
        firebaseErrorMessage(StateError('not-branch-admin')),
        'এই সদস্য এই সমিতির অ্যাডমিন নন',
      );
    });

    test('প্রোফাইল পাওয়া যায়নি', () {
      expect(
        firebaseErrorMessage(StateError('user-not-found')),
        contains('পাওয়া যায়নি'),
      );
    });
  });
}
