import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/committee_member.dart';
import '../models/member_application.dart';
import '../models/membership.dart';
import '../models/notice.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import 'member_repository.dart';

final governanceRepositoryProvider = Provider<GovernanceRepository>((ref) {
  final memberRepo = ref.watch(memberRepositoryProvider);
  return GovernanceRepository(memberRepository: memberRepo);
});

/// সদস্য আবেদন, নোটিশ ও পরিচালনা কমিটি সংক্রান্ত ডেটাবেজ কার্যক্রমের রিপোজিটরি
class GovernanceRepository {
  final FirebaseFirestore _db;
  final StorageService _storage;
  final MemberRepository _memberRepo;

  GovernanceRepository({
    FirebaseFirestore? db,
    StorageService? storageService,
    MemberRepository? memberRepository,
  })  : _db = db ?? FirebaseService.instance.db,
        _storage = storageService ?? StorageService(),
        _memberRepo = memberRepository ?? MemberRepository(db: db);

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
      final existing = await _memberRepo.getMembership(uid, application.branchId);
      if (existing?.isApproved ?? false) {
        throw StateError('already-member');
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
    await doc.set(data);
    if (uid != null && uid.isNotEmpty) {
      await _db
          .collection(Collections.memberships)
          .doc(Membership.docId(uid, application.branchId))
          .set({
        'userId': uid,
        'branchId': application.branchId,
        'status': MembershipStatus.pending.name,
        'applicationId': doc.id,
        'appliedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }
    return doc.id;
  }

  /// আবেদন অনুমোদন করা (সদস্য তৈরি, সদস্যপদ অনুমোদন ও সংখ্যা আপডেট)
  Future<void> approveApplication(
    MemberApplication application, {
    required String reviewedBy,
  }) async {
    final batch = _db.batch();
    final appRef =
        _db.collection(Collections.memberApplications).doc(application.id);
    batch.update(appRef, {
      'status': ApplicationStatus.approved.name,
      'reviewedBy': reviewedBy,
      'reviewedAt': DateTime.now().toIso8601String(),
    });
    final memberRef = _db.collection(Collections.members).doc();
    batch.set(memberRef, application.toMemberMap());
    final uid = application.applicantUid;
    if (uid != null && uid.isNotEmpty) {
      batch.set(
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
          'approvedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      final userRef = _db.collection(Collections.users).doc(uid);
      final existingUser = await userRef.get();
      final hasMember = existingUser.data()?['linkedMemberId'] != null &&
          (existingUser.data()!['linkedMemberId'] as String).isNotEmpty;
      final userData = <String, dynamic>{
        'email': application.email,
        'role': UserRole.member.name,
        'approvalStatus': ApprovalStatus.approved.name,
      };
      if (!hasMember) {
        userData['linkedMemberId'] = memberRef.id;
        userData['branchId'] = application.branchId;
      }
      batch.set(userRef, userData, SetOptions(merge: true));
    }
    batch.update(
      _db.collection(Collections.branches).doc(application.branchId),
      {'memberCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  /// আবেদন বাতিল করা
  Future<void> rejectApplication(
    String applicationId, {
    required String reason,
    required String reviewedBy,
  }) async {
    final appRef =
        _db.collection(Collections.memberApplications).doc(applicationId);
    final appSnap = await appRef.get();
    final data = appSnap.data();
    await appRef.update({
      'status': ApplicationStatus.rejected.name,
      'rejectReason': reason,
      'reviewedBy': reviewedBy,
      'reviewedAt': DateTime.now().toIso8601String(),
    });
    final uid = data?['applicantUid'] as String?;
    final branchId = data?['branchId'] as String?;
    if (uid != null &&
        uid.isNotEmpty &&
        branchId != null &&
        branchId.isNotEmpty) {
      await _db
          .collection(Collections.memberships)
          .doc(Membership.docId(uid, branchId))
          .set({
        'userId': uid,
        'branchId': branchId,
        'status': MembershipStatus.rejected.name,
        'applicationId': applicationId,
        'rejectReason': reason,
      }, SetOptions(merge: true));
    }
  }

  /// নোটিশ লাইভ স্ট্রিম (সকল বা সমিতিভিত্তিক)
  Stream<List<Notice>> watchNotices({String? branchId}) {
    return _db
        .collection(Collections.notices)
        .orderBy('postedAt', descending: true)
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

  /// পরিচালনা কমিটির তালিকা পর্যবেক্ষণ
  Stream<List<CommitteeMember>> watchCommittee({String? branchId}) {
    var query = _db.collection(Collections.committee).orderBy('designation');
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => CommitteeMember.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
