import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import 'audit_repository.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final auditRepo = ref.watch(auditRepositoryProvider);
  return MemberRepository(auditRepository: auditRepo);
});

/// সদস্য এবং ব্যবহারকারী সংক্রান্ত ডেটাবেজ কার্যক্রমের রিপোজিটরি
class MemberRepository {
  final FirebaseFirestore _db;
  final StorageService _storage;
  final AuditRepository _audit;

  MemberRepository({
    FirebaseFirestore? db,
    StorageService? storageService,
    AuditRepository? auditRepository,
  })  : _db = db ?? FirebaseService.instance.db,
        _storage = storageService ?? StorageService(),
        _audit = auditRepository ?? AuditRepository(db: db);

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

  /// Phase 5 (F9): Auth অ্যাকাউন্ট আছে কিন্তু users ডকুমেন্ট
  /// নেই — এমন "অনাথ" অ্যাকাউন্টের প্রোফাইল আবার তৈরি করা।
  /// ট্রানজ্যাকশনে পড়ে-তারপর-লেখা হয়, তাই ডকুমেন্ট থাকলে
  /// কিছু করা হয় না (আগের রোল/অনুমোদন মুছে যাবে না)।
  /// rules অনুযায়ী নতুন ডকুমেন্ট pending-ই হয় — অনুমোদন
  /// অ্যাডমিন দেবে। ডকুমেন্ট বানানো হলে true ফেরে।
  Future<bool> restoreMissingProfile({
    required String uid,
    required String email,
  }) async {
    final ref = _db.collection(Collections.users).doc(uid);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return false;
      tx.set(ref, {
        'email': email,
        'role': UserRole.pending.name,
        'approvalStatus': ApprovalStatus.pending.name,
      });
      return true;
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

  /// সক্রিয় সদস্যের তালিকা (F3) — rules সদস্যদের শুধু
  /// status == 'active' ডকুমেন্ট পড়তে দেয়, তাই সদস্য-মুখী
  /// তালিকায় (সদস্য তালিকা, বকেয়া, ঋণ) এই প্রশ্নই ব্যবহার
  /// করা হয়। নইলে একজন নিষ্ক্রিয় সদস্য থাকলেই পুরো প্রশ্ন
  /// permission-denied খায় (rules ফিল্টার নয়)। অ্যাডমিনের
  /// তালিকায় [watchMembers] থাকে — সেখানে নিষ্ক্রিয় সদস্যও
  /// দেখা দরকার। (branchId, status) কম্পোজিট ইনডেক্স আগেই আছে।
  Stream<List<Member>> watchActiveMembers({String? branchId}) {
    Query<Map<String, dynamic>> query = _db
        .collection(Collections.members)
        .where('status', isEqualTo: 'active')
        .limit(500);
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

  /// সদস্যের রেকর্ড বদলানো (B7) — নাম, ফোন, ঠিকানা, এনআইডি,
  /// জরুরি যোগাযোগ, ভর্তির তারিখ, ছবি, সক্রিয়/নিষ্ক্রিয়।
  /// ছবি দিলে আগে Cloudinary-তে তোলা হয় — আপলোড ব্যর্থ হলে
  /// UploadFailedException ছোড়া হয়, রেকর্ড বদলানো হয় না।
  /// শুধু অ্যাডমিন করতে পারে (rules: members update অ্যাডমিন)।
  Future<void> updateMember({
    required String memberId,
    required Map<String, dynamic> data,
    Uint8List? photoBytes,
    String by = '',
  }) async {
    if (memberId.isEmpty) return;
    final updates = Map<String, dynamic>.from(data);
    if (photoBytes != null) {
      final photoUrl = await _storage.uploadBytes(
        'members/$memberId/photo.jpg',
        photoBytes,
      );
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
    }
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection(Collections.members)
        .doc(memberId)
        .update(updates);
    // Phase 5 (F35): সদস্য নিষ্ক্রিয়/সক্রিয় করলে তার
    // সদস্যপদও একইভাবে বদলায় — নইলে নিষ্ক্রিয় সদস্য অ্যাপে
    // ঢুকে সমিতির তথ্য দেখতে থাকে (পড়ার অনুমতি সদস্যপদ
    // দিয়ে ঠিক হয়)।
    final newStatus = updates['status'] as String?;
    if (newStatus == 'left' || newStatus == 'active') {
      await _syncMembershipStatus(memberId, newStatus == 'active');
    }
    await _audit.logAudit(
      action: 'member_updated',
      by: by,
      detail: 'সদস্যের তথ্য বদলানো হয়েছে ($memberId)',
    );
  }

  /// সদস্যের সক্রিয়/নিষ্ক্রিয় অবস্থা তার সদস্যপদেও লেখা হয়।
  /// নিষ্ক্রিয় হলে সদস্যপদ 'rejected' হয় — 'left' নামে কোনো
  /// অবস্থা memberships-এ নেই, আর না-চেনা অবস্থা fromMap-এ
  /// pending হয়ে যেত (আরো খারাপ)। 'rejected' হলে পড়ার
  /// অনুমতি বন্ধ হয়, আর M1 পথে সে আবার আবেদন করতে পারে।
  /// সদস্যপদ না থাকলে (পুরোনো সদস্য) কিছু করা হয় না।
  Future<void> _syncMembershipStatus(String memberId, bool active) async {
    try {
      final doc =
          await _db.collection(Collections.members).doc(memberId).get();
      final data = doc.data();
      if (data == null) return;
      final linkedUserId = data['linkedUserId'] as String?;
      final branchId = data['branchId'] as String?;
      if (linkedUserId == null ||
          linkedUserId.isEmpty ||
          branchId == null ||
          branchId.isEmpty) {
        return;
      }
      final ref = _db
          .collection(Collections.memberships)
          .doc(Membership.docId(linkedUserId, branchId));
      final existing = await ref.get();
      if (!existing.exists) return;
      await ref.update({
        'status': active
            ? MembershipStatus.approved.name
            : MembershipStatus.rejected.name,
        if (active) 'rejectReason': FieldValue.delete(),
        if (!active) 'rejectReason': 'সদস্যপদ নিষ্ক্রিয় করা হয়েছে',
      });
    } catch (_) {
      // সদস্যপদ লেখা না গেলে সদস্য রেকর্ডের বদলটাই আসল —
      // সেটা আগেই হয়ে গেছে।
    }
  }

  /// নিজের প্রোফাইলের নাম বদলানো (M5) — নিজের users ডকুমেন্টে
  /// শুধু নাম লেখা হয়। rules নিজেকে role/approvalStatus/
  /// branchId/linkedMemberId ছাড়া বাকি সব বদলাতে দেয়।
  Future<void> updateProfileName({
    required String uid,
    required String name,
  }) async {
    if (uid.isEmpty) return;
    await _db.collection(Collections.users).doc(uid).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// একজন ব্যবহারকারীর users ডকুমেন্টের লাইভ স্ট্রিম (Phase 6) —
  /// সদস্যের পরিচয় পাতায় তার বর্তমান রোল দেখানোর জন্য।
  /// rules: users ডকুমেন্ট নিজে বা সুপার অ্যাডমিন পড়তে পারে।
  /// ডকুমেন্ট না থাকলে null ফেরে।
  Stream<AppUser?> watchUserDoc(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _db.collection(Collections.users).doc(uid).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? AppUser.fromMap(uid, doc.data()!)
              : null,
        );
  }

  /// একজন ব্যবহারকারীর users ডকুমেন্ট একবার পড়া (Phase 6) —
  /// অ্যাডমিন বানানো/সরানোর রক্ষাগুলো যাচাইয়ের জন্য।
  Future<AppUser?> getUserDoc(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _db.collection(Collections.users).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  /// সদস্যকে শাখা অ্যাডমিন বানানো (Phase 6) — শুধু সুপার
  /// অ্যাডমিনের কাজ। rules-এ users update শুধু সুপার অ্যাডমিন
  /// করতে পারে, তাই ডাকা ব্যক্তির অনুমতি সার্ভারেই যাচাই হয়;
  /// এখানে যাচাই হয় লক্ষ্য-ব্যক্তির দিকের রক্ষাগুলো —
  /// UI-এর ওপর ভরসা করে নয়, ট্রানজ্যাকশনের ভেতর পড়ে-তারপর-লিখে:
  /// ডকুমেন্ট থাকতে হবে, অনুমোদিত হতে হবে, সুপার অ্যাডমিন
  /// বা নিজের অ্যাকাউন্ট হওয়া যাবে না, আর অন্য সমিতির
  /// অ্যাডমিনকে চুপচাপ এই সমিতিতে আনা যাবে না। রোল শুধু
  /// 'branchAdmin' হয় — অ্যাপ থেকে কাউকে superAdmin বানানো
  /// যায় না। সফল হলে অডিট লগে লেখা হয়।
  Future<void> promoteToBranchAdmin({
    required String targetUid,
    required String branchId,
    required String by,
    String memberName = '',
  }) async {
    if (targetUid.isEmpty) {
      throw StateError('user-not-found');
    }
    if (branchId.isEmpty) {
      throw StateError('member-no-branch');
    }
    final ref = _db.collection(Collections.users).doc(targetUid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) {
        throw StateError('user-not-found');
      }
      final target = AppUser.fromMap(targetUid, snap.data()!);
      if (target.role == UserRole.superAdmin) {
        throw StateError('cannot-change-super-admin');
      }
      if (targetUid == by) {
        throw StateError('cannot-change-self');
      }
      if (!target.canEnter) {
        throw StateError('user-not-approved');
      }
      if (target.role == UserRole.branchAdmin) {
        if (target.branchId == branchId) {
          throw StateError('already-branch-admin');
        }
        throw StateError('admin-of-other-branch');
      }
      tx.update(ref, {
        'role': UserRole.branchAdmin.name,
        'branchId': branchId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await _audit.logAudit(
      action: 'admin_promoted',
      by: by,
      detail: '${memberName.isEmpty ? targetUid : memberName} '
          '($targetUid) কে $branchId সমিতির অ্যাডমিন বানানো হয়েছে',
    );
  }

  /// শাখা অ্যাডমিনকে সরিয়ে সাধারণ সদস্য করা (Phase 6) —
  /// শুধু সুপার অ্যাডমিনের কাজ। রোল 'member' হয়, branchId
  /// আগেরটাই থাকে (সদস্য হিসেবে ওই সমিতিতেই থাকে)।
  /// রক্ষাগুলো [promoteToBranchAdmin]-এর মতোই, আর শুধু এই
  /// সমিতির অ্যাডমিনকেই এখান থেকে সরানো যায়।
  Future<void> demoteBranchAdmin({
    required String targetUid,
    required String branchId,
    required String by,
    String memberName = '',
  }) async {
    if (targetUid.isEmpty) {
      throw StateError('user-not-found');
    }
    if (branchId.isEmpty) {
      throw StateError('member-no-branch');
    }
    final ref = _db.collection(Collections.users).doc(targetUid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) {
        throw StateError('user-not-found');
      }
      final target = AppUser.fromMap(targetUid, snap.data()!);
      if (target.role == UserRole.superAdmin) {
        throw StateError('cannot-change-super-admin');
      }
      if (targetUid == by) {
        throw StateError('cannot-change-self');
      }
      if (target.role != UserRole.branchAdmin ||
          (target.branchId != null && target.branchId != branchId)) {
        throw StateError('not-branch-admin');
      }
      tx.update(ref, {
        'role': UserRole.member.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await _audit.logAudit(
      action: 'admin_demoted',
      by: by,
      detail: '${memberName.isEmpty ? targetUid : memberName} '
          '($targetUid) কে $branchId সমিতির অ্যাডমিন থেকে সরানো হয়েছে',
    );
  }
}
