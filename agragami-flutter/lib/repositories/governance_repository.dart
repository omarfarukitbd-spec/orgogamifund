import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/committee_member.dart';
import '../models/edit_request.dart';
import '../models/member.dart';
import '../models/member_application.dart';
import '../models/membership.dart';
import '../models/notice.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import 'audit_repository.dart';
import 'member_repository.dart';

final governanceRepositoryProvider = Provider<GovernanceRepository>((ref) {
  final memberRepo = ref.watch(memberRepositoryProvider);
  final auditRepo = ref.watch(auditRepositoryProvider);
  return GovernanceRepository(
    memberRepository: memberRepo,
    auditRepository: auditRepo,
  );
});

/// সদস্য আবেদন, নোটিশ ও পরিচালনা কমিটি সংক্রান্ত ডেটাবেজ কার্যক্রমের রিপোজিটরি
class GovernanceRepository {
  final FirebaseFirestore _db;
  final StorageService _storage;
  final MemberRepository _memberRepo;
  final AuditRepository _audit;

  GovernanceRepository({
    FirebaseFirestore? db,
    StorageService? storageService,
    MemberRepository? memberRepository,
    AuditRepository? auditRepository,
  })  : _db = db ?? FirebaseService.instance.db,
        _storage = storageService ?? StorageService(),
        _memberRepo = memberRepository ?? MemberRepository(db: db),
        _audit = auditRepository ?? AuditRepository(db: db);

  /// অপেক্ষমাণ সদস্য আবেদনের লাইভ স্ট্রিম
  Stream<List<MemberApplication>> watchPendingApplications({
    String? branchId,
  }) {
    var query = _db
        .collection(Collections.memberApplications)
        .where('status', isEqualTo: ApplicationStatus.pending.name)
        .orderBy('requestedAt', descending: true);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => MemberApplication.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// নতুন সদস্য আবেদন জমা দেওয়া (ছবি ও এনআইডি আপলোডসহ)
  Future<String> submitMemberApplication({
    required MemberApplication application,
    Uint8List? photoBytes,
    Uint8List? nidFrontBytes,
    Uint8List? nidBackBytes,
  }) async {
    final uid = application.applicantUid;
    if (uid != null && uid.isNotEmpty) {
      // B2: আগের পরীক্ষায় permission-denied হলে "সদস্যপদ নেই"
      // ধরা হয় — শক্ত করা rules-এ নিজের না থাকা ডকুমেন্ট পড়া
      // যায়, তবুও পুরোনো rules-এও আবেদন আটকায় না।
      Membership? existing;
      try {
        existing = await _memberRepo.getMembership(uid, application.branchId);
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        existing = null;
      }
      if (existing?.isApproved ?? false) {
        throw StateError('already-member');
      }
      // পুরোনো সদস্য (member ডকুমেন্ট আছে, membership নেই)
      // আবার আবেদন করতে পারবে না।
      try {
        final legacyMembers = await _db
            .collection(Collections.members)
            .where('linkedUserId', isEqualTo: uid)
            .where('branchId', isEqualTo: application.branchId)
            .limit(1)
            .get();
        if (legacyMembers.docs.isNotEmpty) {
          final legacyMember = Member.fromMap(
            legacyMembers.docs.first.id,
            legacyMembers.docs.first.data(),
          );
          if (legacyMember.active) throw StateError('already-member');
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        // পুরোনো সদস্যের খোঁজ পড়া যায়নি — সদস্যপদের
        // পরীক্ষাই এখানে মূল রক্ষা, তাই আবেদন চলতে দেওয়া হয়।
      }
    }
    final doc = _db.collection(Collections.memberApplications).doc();
    String? photoUrl;
    String? nidFrontUrl;
    String? nidBackUrl;
    if (photoBytes != null) {
      photoUrl = await _storage.uploadBytes(
        'memberApplications/${doc.id}/photo.jpg',
        photoBytes,
      );
    }
    if (nidFrontBytes != null) {
      nidFrontUrl = await _storage.uploadBytes(
        'memberApplications/${doc.id}/nid_front.jpg',
        nidFrontBytes,
      );
    }
    if (nidBackBytes != null) {
      nidBackUrl = await _storage.uploadBytes(
        'memberApplications/${doc.id}/nid_back.jpg',
        nidBackBytes,
      );
    }
    final data = application.toMap();
    data['photoUrl'] = photoUrl;
    data['nidFrontUrl'] = nidFrontUrl;
    data['nidBackUrl'] = nidBackUrl;
    // M1: আবেদন আর সদস্যপদ একই batch-এ লেখা হয় — সদস্যপদ
    // লিখতে না পারলে আবেদনও থাকে না, অনাথ আবেদন হয় না।
    // বাতিলের পর আবার আবেদনে পুরোনো rejectReason মুছে যায়।
    final batch = _db.batch();
    batch.set(doc, data);
    if (uid != null && uid.isNotEmpty) {
      batch.set(
        _db
            .collection(Collections.memberships)
            .doc(Membership.docId(uid, application.branchId)),
        {
          'userId': uid,
          'branchId': application.branchId,
          'status': MembershipStatus.pending.name,
          'applicationId': doc.id,
          'appliedAt': FieldValue.serverTimestamp(),
          'rejectReason': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    return doc.id;
  }

  /// আবেদন অনুমোদন করা (সদস্য তৈরি, সদস্যপদ অনুমোদন ও সংখ্যা আপডেট)।
  /// B5: ট্রানজ্যাকশনে হয় — আবেদন এখনো pending না থাকলে
  /// (আগেই যাচাই হয়ে গেছে) ব্যর্থ হয়, ডাবল-ট্যাপে দুই
  /// সদস্য হয় না। M10: রোল শুধু pending ব্যবহারকারীরই
  /// member হয় — branchAdmin দ্বিতীয় সমিতিতে আবেদন করলে
  /// তার অ্যাডমিন রোল হারায় না।
  Future<void> approveApplication(
    MemberApplication application, {
    required String reviewedBy,
  }) async {
    final appRef =
        _db.collection(Collections.memberApplications).doc(application.id);
    final memberRef = _db.collection(Collections.members).doc();
    final uid = application.applicantUid;
    await _db.runTransaction((tx) async {
      final appSnap = await tx.get(appRef);
      if (!appSnap.exists ||
          appSnap.data()?['status'] != ApplicationStatus.pending.name) {
        throw StateError('already-reviewed');
      }
      // ট্রানজ্যাকশনে সব পড়া লেখার আগে করতে হয় — তাই
      // users ডকুমেন্ট আর branch ডকুমেন্টও এখানেই পড়ে
      // নেওয়া হয়।
      DocumentSnapshot<Map<String, dynamic>>? userSnap;
      if (uid != null && uid.isNotEmpty) {
        userSnap = await tx.get(
          _db.collection(Collections.users).doc(uid),
        );
      }
      final branchSnap = await tx.get(
        _db.collection(Collections.branches).doc(application.branchId),
      );
      tx.update(appRef, {
        'status': ApplicationStatus.approved.name,
        'reviewedBy': reviewedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      // Phase 5 (F15): মানুষের পড়ার মতো সদস্য নম্বর —
      // সমিতির বর্তমান সদস্য সংখ্যা + ১। একই ট্রানজ্যাকশনে
      // সংখ্যা বাড়ে, তাই দুই অনুমোদন একসাথে হলে দ্বিতীয়টা
      // আবার চেষ্টা করে পরের নম্বর পায়।
      final branchData = branchSnap.data();
      final memberNumber =
          ((branchData?['memberCount'] as num?)?.toInt() ?? 0) + 1;
      tx.set(memberRef, application.toMemberMap(memberNumber: memberNumber));
      if (uid != null && uid.isNotEmpty) {
        tx.set(
          _db
              .collection(Collections.memberships)
              .doc(Membership.docId(uid, application.branchId)),
          {
            'userId': uid,
            'branchId': application.branchId,
            'status': MembershipStatus.approved.name,
            'applicationId': application.id,
            'memberId': memberRef.id,
            'approvedBy': reviewedBy,
            'approvedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        final existingData = userSnap?.data();
        final hasMember = existingData?['linkedMemberId'] != null &&
            (existingData!['linkedMemberId'] as String).isNotEmpty;
        final userData = <String, dynamic>{
          'email': application.email,
          'approvalStatus': ApprovalStatus.approved.name,
        };
        final existingRole = existingData?['role'] as String?;
        if (existingRole == null ||
            existingRole == UserRole.pending.name) {
          userData['role'] = UserRole.member.name;
        }
        if (!hasMember) {
          userData['linkedMemberId'] = memberRef.id;
          userData['branchId'] = application.branchId;
        }
        tx.set(
          _db.collection(Collections.users).doc(uid),
          userData,
          SetOptions(merge: true),
        );
      }
      // Phase 5 (F1): branch ডকুমেন্ট থাকলে তবেই সংখ্যা
      // বাড়ানো হয় — শাখা অ্যাডমিনের rules শুধু memberCount
      // ১ বাড়ানোর update দিতে পারে, ডকুমেন্ট বানাতে পারে
      // না। (আগের মন্তব্য ভুল ছিল: ডকুমেন্ট না থাকলে
      // set(merge) create হয়ে যেত, আর শাখা অ্যাডমিনের
      // ক্ষেত্রে পুরো অনুমোদনই ভেঙে যেত।)
      if (branchSnap.exists) {
        tx.set(
          _db.collection(Collections.branches).doc(application.branchId),
          {'memberCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
    });
  }

  /// আবেদন বাতিল করা (m11: batch-এ হয় — আবেদন আর সদস্যপদ
  /// দুটোই একসাথে বদলায়, একটা হয়ে আরেকটা বাকি থাকে না)।
  Future<void> rejectApplication(
    String applicationId, {
    required String reason,
    required String reviewedBy,
  }) async {
    final appRef =
        _db.collection(Collections.memberApplications).doc(applicationId);
    final appSnap = await appRef.get();
    final data = appSnap.data();
    final batch = _db.batch();
    batch.update(appRef, {
      'status': ApplicationStatus.rejected.name,
      'rejectReason': reason,
      'reviewedBy': reviewedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    final uid = data?['applicantUid'] as String?;
    final branchId = data?['branchId'] as String?;
    if (uid != null &&
        uid.isNotEmpty &&
        branchId != null &&
        branchId.isNotEmpty) {
      batch.set(
        _db
            .collection(Collections.memberships)
            .doc(Membership.docId(uid, branchId)),
        {
          'userId': uid,
          'branchId': branchId,
          'status': MembershipStatus.rejected.name,
          'applicationId': applicationId,
          'rejectReason': reason,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// নোটিশ লাইভ স্ট্রিম (সকল বা সমিতিভিত্তিক, সর্বোচ্চ ২০০টি)
  Stream<List<Notice>> watchNotices({String? branchId}) {
    return _db
        .collection(Collections.notices)
        .orderBy('postedAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) {
      final all =
          snap.docs.map((d) => Notice.fromMap(d.id, d.data())).toList();
      if (branchId == null) return all;
      return all
          .where((n) => n.scope == NoticeScope.org || n.branchId == branchId)
          .toList();
    });
  }

  /// নতুন নোটিশ পোস্ট করা (সংযুক্তি আপলোডসহ)
  Future<String> submitNotice({
    required Notice notice,
    Uint8List? attachmentBytes,
  }) async {
    final doc = _db.collection(Collections.notices).doc();
    String? attachmentUrl;
    if (attachmentBytes != null) {
      attachmentUrl = await _storage.uploadBytes(
        'notices/${doc.id}/attachment.jpg',
        attachmentBytes,
      );
    }
    final data = notice.toMap();
    data['attachmentUrl'] = attachmentUrl;
    await doc.set(data);
    return doc.id;
  }

  /// নোটিশ মোছা (Phase 9, G11) — rules: শুধু সুপার অ্যাডমিন।
  Future<void> deleteNotice(
    String noticeId, {
    required String by,
    String title = '',
  }) async {
    if (noticeId.isEmpty) return;
    await _db.collection(Collections.notices).doc(noticeId).delete();
    await _audit.logAudit(
      action: 'notice_deleted',
      by: by,
      detail: 'নোটিশ মোছা হয়েছে: $title ($noticeId)',
    );
  }

  /// সদস্যের তথ্য সংশোধনের আবেদন জমা (Phase 9, G12)।
  /// rules (§8): memberId আবেদনকারীর linkedMemberId-এর
  /// সাথে মিলতে হয়। একই সদস্যের প্রক্রিয়াধীন আবেদন
  /// থাকলে 'already-pending' ছোড়ে — ডাবল-ট্যাপে দুই
  /// আবেদন জমা হয় না।
  Future<String> submitEditRequest({
    required EditRequest request,
  }) async {
    final existing = await _db
        .collection(Collections.editRequests)
        .where('memberId', isEqualTo: request.memberId)
        .get();
    final hasPending = existing.docs.any(
      (d) => d.data()['status'] == EditRequestStatus.pending.name,
    );
    if (hasPending) throw StateError('already-pending');
    final doc = _db.collection(Collections.editRequests).doc();
    await doc.set(request.toMap());
    return doc.id;
  }

  /// অপেক্ষমাণ সংশোধন-আবেদনের লাইভ স্ট্রিম (Phase 9, G12)।
  /// editRequests-এর কোনো composite index নেই, তাই
  /// status-ফিল্টারের সাথে orderBy করা হয় না — নতুন-আগে
  /// সাজানো আর সমিতি-ফিল্টার ক্লায়েন্টে করা হয়।
  Stream<List<EditRequest>> watchPendingEditRequests({String? branchId}) {
    return _db
        .collection(Collections.editRequests)
        .where('status', isEqualTo: EditRequestStatus.pending.name)
        .snapshots()
        .map((snap) {
      var list = snap.docs
          .map((d) => EditRequest.fromMap(d.id, d.data()))
          .toList();
      if (branchId != null) {
        list = list.where((r) => r.branchId == branchId).toList();
      }
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return list;
    });
  }

  /// একজন সদস্যের প্রক্রিয়াধীন সংশোধন-আবেদন (Phase 9,
  /// G12) — প্রোফাইলে "আবেদন প্রক্রিয়াধীন" অবস্থা
  /// দেখানোর জন্য। memberId দিয়ে এক-ক্ষেত্রের প্রশ্ন —
  /// composite index লাগে না।
  Stream<EditRequest?> watchPendingEditRequestForMember(String memberId) {
    return _db
        .collection(Collections.editRequests)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snap) {
      final pending = snap.docs
          .map((d) => EditRequest.fromMap(d.id, d.data()))
          .where((r) => r.status == EditRequestStatus.pending)
          .toList();
      if (pending.isEmpty) return null;
      pending.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return pending.first;
    });
  }

  /// সংশোধন-আবেদন অনুমোদন (Phase 9, G12) — ট্রানজ্যাকশনে
  /// হয়: আবেদন এখনো pending না থাকলে 'already-reviewed'
  /// ছোড়ে (ডাবল-ট্যাপে দুইবার প্রয়োগ হয় না); সদস্যের
  /// রেকর্ডে শুধু অনুমোদিত ক্ষেত্র (ফোন, ঠিকানা) বসে আর
  /// আবেদন approved হয়। বদলানো মান আবেদনের লাইভ
  /// স্ন্যাপশট থেকে নেওয়া হয়, পাঠানো অবজেক্ট থেকে নয়।
  Future<void> approveEditRequest(
    EditRequest request, {
    required String reviewedBy,
  }) async {
    final reqRef =
        _db.collection(Collections.editRequests).doc(request.id);
    final memberRef =
        _db.collection(Collections.members).doc(request.memberId);
    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists ||
          reqSnap.data()?['status'] != EditRequestStatus.pending.name) {
        throw StateError('already-reviewed');
      }
      final changes =
          Map<String, dynamic>.from((reqSnap.data()?['changes'] as Map?) ?? {});
      // শুধু অনুমোদিত ক্ষেত্রই বদলায় — ফোন আর ঠিকানা।
      // অন্য কোনো ক্ষেত্র আবেদনে এলেও সদস্যের রেকর্ডে বসে না।
      final allowed = <String, dynamic>{};
      if (changes['phone'] is String) allowed['phone'] = changes['phone'];
      if (changes['address'] is String) {
        allowed['address'] = changes['address'];
      }
      if (allowed.isNotEmpty) tx.update(memberRef, allowed);
      tx.update(reqRef, {
        'status': EditRequestStatus.approved.name,
        'reviewedBy': reviewedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
    await _audit.logAudit(
      action: 'edit_request_approved',
      by: reviewedBy,
      detail: 'সদস্যের তথ্য সংশোধনের আবেদন অনুমোদন (${request.memberName})',
    );
  }

  /// সংশোধন-আবেদন বাতিল (Phase 9, G12) — আগেই যাচাই
  /// হয়ে থাকলে 'already-reviewed' ছোড়ে।
  Future<void> rejectEditRequest(
    String requestId, {
    required String reason,
    required String reviewedBy,
  }) async {
    final reqRef =
        _db.collection(Collections.editRequests).doc(requestId);
    final reqSnap = await reqRef.get();
    if (!reqSnap.exists ||
        reqSnap.data()?['status'] != EditRequestStatus.pending.name) {
      throw StateError('already-reviewed');
    }
    await reqRef.update({
      'status': EditRequestStatus.rejected.name,
      'rejectReason': reason,
      'reviewedBy': reviewedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    await _audit.logAudit(
      action: 'edit_request_rejected',
      by: reviewedBy,
      detail: 'সদস্যের তথ্য সংশোধনের আবেদন বাতিল ($requestId)',
    );
  }

  /// পরিচালনা কমিটির তালিকা পর্যবেক্ষণ (সর্বোচ্চ ২০০ জন)
  Stream<List<CommitteeMember>> watchCommittee({String? branchId}) {
    var query = _db
        .collection(Collections.committee)
        .orderBy('designation')
        .limit(200);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => CommitteeMember.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// কমিটিতে নতুন দায়িত্বশীল যোগ করা (M4)।
  /// rules: committee লেখা শুধু সুপার অ্যাডমিন করতে পারে।
  Future<String> addCommitteeMember(
    CommitteeMember member, {
    required String by,
  }) async {
    final doc = _db.collection(Collections.committee).doc();
    await doc.set(member.toMap());
    await _audit.logAudit(
      action: 'committee_member_added',
      by: by,
      detail: 'কমিটিতে ${member.designation} যোগ করা হয়েছে (${doc.id})',
    );
    return doc.id;
  }

  /// কমিটির দায়িত্ব বদলানো (M4) — পদ বা মেয়াদ।
  Future<void> updateCommitteeMember(
    CommitteeMember member, {
    required String by,
  }) async {
    if (member.id.isEmpty) return;
    await _db
        .collection(Collections.committee)
        .doc(member.id)
        .update(member.toMap());
    await _audit.logAudit(
      action: 'committee_member_updated',
      by: by,
      detail: 'কমিটির ${member.designation} বদলানো হয়েছে (${member.id})',
    );
  }

  /// কমিটি থেকে সরানো (M4) — সদস্যের রেকর্ড থাকে,
  /// শুধু কমিটির দায়িত্বটা মুছে যায়।
  Future<void> removeCommitteeMember(
    String committeeMemberId, {
    required String by,
    String designation = '',
  }) async {
    if (committeeMemberId.isEmpty) return;
    await _db.collection(Collections.committee).doc(committeeMemberId).delete();
    await _audit.logAudit(
      action: 'committee_member_removed',
      by: by,
      detail: 'কমিটি থেকে $designation সরানো হয়েছে ($committeeMemberId)',
    );
  }
}
