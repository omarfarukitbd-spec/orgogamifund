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

  /// নতুন ইউজারের ডকুমেন্ট তৈরি করা — সবসময় pending।
  /// Firestore rules শুধু role == 'pending' দিয়ে users ডকুমেন্ট
  /// বানাতে দেয়; অ্যাডমিন অনুমোদন দিলে পরে রোল বদলায়।
  /// ইমেইল দেখে কাউকে অ্যাডমিন বানানো হয় না (M6) — আগে এখানে
  /// hardcode করা ইমেইলে (বানান ভুলসহ) superAdmin বসানো হতো।
  Future<void> createUserDoc({
    required String uid,
    required String email,
  }) async {
    await _db.collection(Collections.users).doc(uid).set({
      'email': email,
      'role': UserRole.pending.name,
      'approvalStatus': ApprovalStatus.pending.name,
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

  /// প্রথম সুপার অ্যাডমিনের ইউজার ডকুমেন্ট সেটআপ।
  /// সতর্কতা: শক্ত করা Firestore rules-এ (role == 'pending' ছাড়া
  /// users create নিষেধ) এই লেখা ক্লায়েন্ট থেকে ব্যর্থ হবে —
  /// প্রথম অ্যাডমিন Firebase Console / Admin SDK দিয়ে বানাতে হয়।
  /// /setup রাউট এখন fail-closed (B1)।
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

  /// ব্যবহারকারীর সব সমিতির সদস্যপদ পর্যবেক্ষণ (অ্যান্ড্রয়েড ও ফ্লাটার ডুয়াল সাপোর্ট)।
  /// members থেকে পাওয়া সদস্যপদ শুধু মেমরিতেই থাকে —
  /// পড়ার পথ থেকে আর Firestore-এ লেখা হয় না। আগের কোড
  /// প্রতিবার approved সদস্যপদ লিখতে চাইত, নিয়মে
  /// (rules) সেটা বাধা পেত, আর প্রতিটি snapshot-এ আবার
  /// একই ব্যর্থ লেখা চলত।
  Stream<List<Membership>> watchMyMemberships(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    // members খোঁজা একবার করে রাখা হয় — সদস্যপদের
    // সমিতি-সেট না বদলালে আবার পড়া হয় না।
    List<Member>? cachedMembers;
    Set<String>? cachedBranchIds;
    return _db
        .collection(Collections.memberships)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snap) async {
      final explicitMemberships = snap.docs
          .map((d) => Membership.fromMap(d.id, d.data()))
          .toList();
      final branchIds =
          explicitMemberships.map((m) => m.branchId).toSet();

      // অ্যান্ড্রয়েড অ্যাপের সাথে সামঞ্জস্য: members কালেকশনে লিঙ্কড থাকা সদস্যপদ রিড করা
      try {
        if (cachedMembers == null ||
            cachedBranchIds == null ||
            cachedBranchIds!.length != branchIds.length ||
            !cachedBranchIds!.containsAll(branchIds)) {
          final memberDocs = await _db
              .collection(Collections.members)
              .where('linkedUserId', isEqualTo: userId)
              .get();
          cachedMembers = memberDocs.docs
              .map((d) => Member.fromMap(d.id, d.data()))
              .toList();
          cachedBranchIds = branchIds;
        }

        for (final member in cachedMembers!) {
          if (member.branchId.isEmpty) continue;

          final alreadyExists = explicitMemberships.any(
            (m) => m.branchId == member.branchId,
          );

          if (!alreadyExists) {
            final status = member.active
                ? MembershipStatus.approved
                : MembershipStatus.rejected;
            explicitMemberships.add(Membership(
              id: Membership.docId(userId, member.branchId),
              userId: userId,
              branchId: member.branchId,
              status: status,
              memberId: member.id,
              appliedAt: member.joinDate,
              approvedAt: member.joinDate,
            ));
          }
        }
      } catch (_) {}

      return explicitMemberships;
    });
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
        .asyncMap((doc) async {
      if (doc.exists && doc.data() != null) {
        return Membership.fromMap(doc.id, doc.data()!);
      }
      try {
        final memberDocs = await _db
            .collection(Collections.members)
            .where('linkedUserId', isEqualTo: userId)
            .where('branchId', isEqualTo: branchId)
            .limit(1)
            .get();
        if (memberDocs.docs.isNotEmpty) {
          final member = Member.fromMap(
            memberDocs.docs.first.id,
            memberDocs.docs.first.data(),
          );
          final status = member.active
              ? MembershipStatus.approved
              : MembershipStatus.rejected;
          // মেমরিতেই থাকে — পড়ার পথ থেকে লেখা হয় না।
          return Membership(
            id: Membership.docId(userId, branchId),
            userId: userId,
            branchId: branchId,
            status: status,
            memberId: member.id,
            appliedAt: member.joinDate,
            approvedAt: member.joinDate,
          );
        }
      } catch (_) {}
      return null;
    });
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

  /// সদস্য তালিকা দেখা (সমিতি অনুযায়ী ফিল্টারসহ, সর্বোচ্চ ৫০০ জন)।
  Stream<List<Member>> watchMembers({String? branchId}) {
    Query<Map<String, dynamic>> query =
        _db.collection(Collections.members).limit(500);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) {
            final list = snap.docs.map((d) => Member.fromMap(d.id, d.data())).toList();
            list.sort((a, b) => a.name.compareTo(b.name));
            return list;
          },
        );
  }

  /// কয়েকজন সদস্যের রেকর্ড একবারে আনা (কমিটি স্ক্রিনে
  /// নাম-ফোন দেখানোর জন্য)। যে ডকুমেন্ট পড়ার অনুমতি নেই
  /// (অন্য সমিতির সদস্য) সেটা চুপচাপ বাদ যায় — পুরো
  /// তালিকা ভাঙে না।
  Future<Map<String, Member>> fetchMembersByIds(List<String> ids) async {
    final result = <String, Member>{};
    final unique = ids.where((id) => id.isNotEmpty).toSet();
    await Future.wait(unique.map((id) async {
      try {
        final doc =
            await _db.collection(Collections.members).doc(id).get();
        if (doc.exists && doc.data() != null) {
          result[id] = Member.fromMap(doc.id, doc.data()!);
        }
      } catch (_) {
        // পড়ার অনুমতি নেই বা ডকুমেন্ট নেই — বাদ যায়।
      }
    }));
    return result;
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
