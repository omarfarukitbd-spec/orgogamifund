import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../services/firebase_service.dart';

final memberRepositoryProvider =
    Provider<MemberRepository>((ref) => MemberRepository());

/// সদস্য এবং ব্যবহারকারী সংক্রান্ত ডেটাবেজ কার্যক্রমের রিপোজিটরি
class MemberRepository {
  final FirebaseFirestore _db;

  MemberRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseService.instance.db;

  /// নতুন ইউজারের ডকুমেন্ট তৈরি করা
  Future<void> createUserDoc({
    required String uid,
    required String email,
  }) async {
    final isRootAdmin = email.toLowerCase() == 'omarfaruktitbd@gmail.com' ||
        email.toLowerCase() == 'omarfarukitbd@gmail.com';
    await _db.collection(Collections.users).doc(uid).set({
      'email': email,
      'role': isRootAdmin ? UserRole.superAdmin.name : UserRole.pending.name,
      'approvalStatus': isRootAdmin
          ? ApprovalStatus.approved.name
          : ApprovalStatus.pending.name,
    });
  }

  /// সিস্টেমে কোনো ইউজার আছে কি না যাচাই
  Future<bool?> hasAnyUser() async {
    try {
      final snap = await _db.collection(Collections.users).limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return null;
    }
  }

  /// প্রথম সুপার অ্যাডমিনের ইউজার ডকুমেন্ট সেটআপ
  Future<void> createFirstAdminDoc({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection(Collections.users).doc(uid).set({
      'name': name,
      'email': email,
      'role': UserRole.superAdmin.name,
      'approvalStatus': ApprovalStatus.approved.name,
    });
  }

  /// ব্যবহারকারীর সব সমিতির সদস্যপদ পর্যবেক্ষণ
  Stream<List<Membership>> watchMyMemberships(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db
        .collection(Collections.memberships)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Membership.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// একটি নির্দিষ্ট সমিতিতে সদস্যপদ পর্যবেক্ষণ
  Stream<Membership?> watchMembership(String userId, String branchId) {
    if (userId.isEmpty || branchId.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection(Collections.memberships)
        .doc(Membership.docId(userId, branchId))
        .snapshots()
        .map(
          (doc) => doc.exists && doc.data() != null
              ? Membership.fromMap(doc.id, doc.data()!)
              : null,
        );
  }

  /// সদস্যপদ সরাসরি রিড করা
  Future<Membership?> getMembership(String userId, String branchId) async {
    if (userId.isEmpty || branchId.isEmpty) return null;
    final doc = await _db
        .collection(Collections.memberships)
        .doc(Membership.docId(userId, branchId))
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return Membership.fromMap(doc.id, doc.data()!);
  }

  /// নির্দিষ্ট সমিতির অনুমোদিত সদস্য কি না যাচাই
  Future<bool> isMemberOf(String userId, String branchId) async {
    final m = await getMembership(userId, branchId);
    return m?.isApproved ?? false;
  }

  /// ব্যবহারকারীর অনুমোদিত সমিতির আইডি তালিকা
  Future<List<String>> myApprovedBranchIds(String userId) async {
    if (userId.isEmpty) return const [];
    final snap = await _db
        .collection(Collections.memberships)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: MembershipStatus.approved.name)
        .get();
    return snap.docs
        .map((d) => (d.data()['branchId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// ব্যবহারকারীর সাথে সংযুক্ত সদস্য প্রোফাইলগুলো দেখা
  Stream<List<Member>> watchMembersForUser(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db
        .collection(Collections.members)
        .where('linkedUserId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Member.fromMap(d.id, d.data())).toList(),
        );
  }

  /// সদস্য তালিকা দেখা (সমিতি অনুযায়ী ফিল্টারসহ)
  Stream<List<Member>> watchMembers({String? branchId}) {
    var query = _db.collection(Collections.members).orderBy('name');
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) =>
              snap.docs.map((d) => Member.fromMap(d.id, d.data())).toList(),
        );
  }

  /// একজন একক সদস্যের রেকর্ড পর্যবেক্ষণ
  Stream<Member?> watchMember(String memberId) {
    if (memberId.isEmpty) return Stream.value(null);
    return _db.collection(Collections.members).doc(memberId).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Member.fromMap(doc.id, doc.data()!)
              : null,
        );
  }
}
