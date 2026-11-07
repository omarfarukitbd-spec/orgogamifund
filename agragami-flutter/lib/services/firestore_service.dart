import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/branch.dart';
import '../models/committee_member.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../models/member_application.dart';
import '../models/membership.dart';
import '../models/notice.dart';
import '../models/payment.dart';
import '../models/payment_method.dart';
import 'firebase_service.dart';
import 'storage_service.dart';

/// Firestore থেকে পড়া ও লেখা — সব এখানে।
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseService.instance.db;
  final StorageService _storage = StorageService();

  Future<void> createUserDoc({required String uid, required String email}) async {
    await _db.collection(Collections.users).doc(uid).set({
      'email': email,
      'role': UserRole.pending.name,
      'approvalStatus': ApprovalStatus.pending.name,
    });
  }

  /// users কালেকশনে কেউ আছে কি না — প্রথম অ্যাডমিন সেটআপের জন্য।
  /// true মানে কেউ আছে, false মানে কেউ নেই, null মানে যাচাই করা যায়নি
  /// (যেমন: নেট নেই, বা নিয়মে পড়ার অনুমতি নেই)।
  Future<bool?> hasAnyUser() async {
    try {
      final snap =
          await _db.collection(Collections.users).limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return null;
    }
  }

  /// প্রথম অ্যাডমিনের রেকর্ড — রোল সুপার অ্যাডমিন, অনুমোদন দেওয়া।
  /// শুধু সেটআপের সময় একবার ডাকা হয়।
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

  Stream<List<Branch>> watchBranches() {
    return _db.collection(Collections.branches).snapshots().map(
          (snap) => snap.docs.map((d) => Branch.fromMap(d.id, d.data())).toList(),
        );
  }

  /// নতুন সমিতি খোলা — শুধু অ্যাডমিনের জন্য। অ্যাপে সমিতি
  /// তৈরির আর কোনো পথ নেই, তাই খালি তালিকায় অ্যাডমিন
  /// এখান থেকেই প্রথম সমিতি খুলতে পারে।
  Future<void> createBranch({
    required String name,
    required String description,
    required SamitiPurpose purpose,
    required int monthlyDonation,
    required String by,
  }) async {
    final branch = Branch(
      id: '',
      name: name,
      description: description,
      purpose: purpose,
      monthlyDonation: monthlyDonation,
      startDate: DateTime.now(),
    );
    final data = branch.toMap()
      ..['createdAt'] = DateTime.now().toIso8601String();
    final ref = await _db.collection(Collections.branches).add(data);
    await _logAudit(
      action: 'create_branch',
      by: by,
      detail: 'সমিতি: $name (${ref.id})',
    );
  }

  /// একটি সমিতি — বিস্তারিত পাতায় লাগে। নাম, উদ্দেশ্য,
  /// মাসিক দান আর সদস্য সংখ্যা — এগুলো সবার জন্য খোলা।
  Stream<Branch?> watchBranch(String branchId) {
    return _db.collection(Collections.branches).doc(branchId).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Branch.fromMap(doc.id, doc.data()!)
              : null,
        );
  }

  // ---------- সদস্যপদ — সমিতি অনুযায়ী আলাদা ----------

  /// একজন ব্যবহারকারীর সব সমিতির সদস্যপদ — অনুমোদিত,
  /// বাকি, বাতিল — সবই আসে। স্ক্রিনে ছেঁকে নেওয়া হয়।
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

  /// এক সমিতিতে একজন ব্যবহারকারীর সদস্যপদ — একটাই থাকে।
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

  Future<Membership?> getMembership(String userId, String branchId) async {
    if (userId.isEmpty || branchId.isEmpty) return null;
    final doc = await _db
        .collection(Collections.memberships)
        .doc(Membership.docId(userId, branchId))
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return Membership.fromMap(doc.id, doc.data()!);
  }

  /// ওই সমিতির অনুমোদিত সদস্য কি না — ব্যক্তিগত তথ্য
  /// দেখানোর আগে এটাই দেখা হয়। অ্যাডমিন সব সমিতিই দেখতে পায়।
  Future<bool> isMemberOf(String userId, String branchId) async {
    final m = await getMembership(userId, branchId);
    return m?.isApproved ?? false;
  }

  /// একজন ব্যবহারকারী যেসব সমিতির অনুমোদিত সদস্য —
  /// শুধু সেগুলোরই ব্যক্তিগত তথ্য দেখানো যাবে।
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

  /// একজন ব্যবহারকারীর সদস্যের রেকর্ডগুলো — এক সমিতিতে একটা।
  /// পাসবই আর আইডি কার্ডে লাগে; একাধিক সমিতির সদস্য হলে
  /// একাধিক রেকর্ড আসে, স্ক্রিনে সমিতি বেছে নেওয়া যায়।
  Stream<List<Member>> watchMembersForUser(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db
        .collection(Collections.members)
        .where('linkedUserId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Member.fromMap(d.id, d.data())).toList(),
        );
  }

  /// সমিতির সদস্য সংখ্যা আবার গুনে সমিতির ডকুমেন্টে বসানো —
  /// পুরোনো সমিতির সংখ্যা মেলাতে অ্যাডমিন ব্যবহার করবে।
  /// অনুমোদনের সময় সংখ্যাটা এমনিতেই বাড়ে।
  Future<void> recountMemberCount(String branchId) async {
    final snap = await _db
        .collection(Collections.members)
        .where('branchId', isEqualTo: branchId)
        .where('status', isEqualTo: 'active')
        .get();
    await _db.collection(Collections.branches).doc(branchId).update({
      'memberCount': snap.docs.length,
    });
  }

  Stream<List<Member>> watchMembers({String? branchId}) {
    var query = _db.collection(Collections.members).orderBy('name');
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => Member.fromMap(d.id, d.data())).toList(),
        );
  }

  /// একজন সদস্যের রেকর্ড — পাসবই আর আইডি কার্ডে লাগে।
  Stream<Member?> watchMember(String memberId) {
    return _db.collection(Collections.members).doc(memberId).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Member.fromMap(doc.id, doc.data()!)
              : null,
        );
  }

  Stream<List<Payment>> watchPendingPayments({String? branchId}) {
    var query = _db
        .collection(Collections.payments)
        .where('status', isEqualTo: PaymentStatus.pending.name)
        .orderBy('date', descending: true);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => Payment.fromMap(d.id, d.data())).toList(),
        );
  }

  /// একজন সদস্যের সব জমা — নতুনটা আগে।
  Stream<List<Payment>> watchMemberPayments(String memberId) {
    return _db
        .collection(Collections.payments)
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Payment.fromMap(d.id, d.data())).toList(),
        );
  }

  /// একজন সদস্যের কর্জে হাসানা ঋণগুলো।
  Stream<List<Loan>> watchMemberLoans(String memberId) {
    return _db
        .collection(Collections.loans)
        .where('memberId', isEqualTo: memberId)
        .orderBy('dateIssued', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Loan.fromMap(d.id, d.data())).toList(),
        );
  }

  /// অনুমোদন বাকি আবেদন — নতুনটা আগে। সমিতি বেছে দিলে
  /// শুধু ওই সমিতিরটা — অনুমোদন কেন্দ্রে সমিতি ধরে দেখা যায়।
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

  /// সদস্য হওয়ার আবেদন জমা দেওয়া।
  /// ছবিগুলো আগে Storage-এ তুলে তারপর আবেদনের ডকুমেন্ট বসানো হয়।
  /// অবস্থা pending থাকে — অ্যাডমিন অনুমোদন না দিলে সদস্য হওয়া যায় না।
  /// আবেদনের সাথে ওই সমিতির সদস্যপদও pending হিসেবে বসে —
  /// একই সমিতিতে দ্বিতীয়বার আবেদন করলে নতুন আবেদন নয়,
  /// আগের সদস্যপদের সাথেই নতুন আবেদনটা জুড়ে যায়।
  /// ওই সমিতির অনুমোদিত সদস্য হয়ে থাকলে আবেদন জমা হয় না।
  Future<String> submitMemberApplication({
    required MemberApplication application,
    Uint8List? photoBytes,
    Uint8List? nidFrontBytes,
    Uint8List? nidBackBytes,
  }) async {
    final uid = application.applicantUid;
    if (uid != null && uid.isNotEmpty) {
      final existing = await getMembership(uid, application.branchId);
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

  /// আবেদন অনুমোদন — আবেদন approved হয়, members-এ সদস্য তৈরি হয়,
  /// ওই সমিতির সদস্যপদ approved হয়, সমিতির সদস্য সংখ্যা বাড়ে,
  /// আর আবেদনকারীর users ডকুমেন্টে সদস্য হিসেবে যুক্ত হয়।
  /// অন্য সমিতির সদস্যপদে এর কোনো প্রভাব পড়ে না।
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
      // users ডকুমেন্টে সদস্য হিসেবে যুক্ত করা — প্রথম অনুমোদনেই
      // শুধু সদস্য নম্বর আর সমিতি বসে; পরে অন্য সমিতির অনুমোদনে
      // আগেরটা মুছে যায় না।
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
      // merge দিয়ে বসানো — আবেদনকারীর users ডকুমেন্ট কোনো কারণে
      // না থাকলেও অনুমোদন আটকাবে না।
      batch.set(userRef, userData, SetOptions(merge: true));
    }
    // সমিতির সদস্য সংখ্যা — সবাই দেখতে পায়, তাই সংখ্যাটা
    // সমিতির ডকুমেন্টেই রাখা হয়।
    batch.update(
      _db.collection(Collections.branches).doc(application.branchId),
      {'memberCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  /// আবেদন বাতিল — কারণ লিখে রাখা হয়, যাতে আবেদনকারী জানতে পারে।
  /// ওই সমিতির সদস্যপদও বাতিল হয় — পরে আবার আবেদন করা যায়।
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

  /// জমা পাঠানো — অবস্থা pending, অ্যাডমিন যাচাই করে অনুমোদন দেবেন।
  Future<String> submitPayment(Payment payment) async {
    final doc = _db.collection(Collections.payments).doc();
    await doc.set(payment.toMap());
    return doc.id;
  }

  /// জমা অনুমোদন — রসিদ নম্বর বসে: REC-বছরমাস-XXXX।
  Future<void> approvePayment(Payment payment, {required String reviewedBy}) async {
    final now = DateTime.now();
    final suffix = payment.id.length >= 4
        ? payment.id.substring(payment.id.length - 4).toUpperCase()
        : payment.id.toUpperCase();
    final receipt =
        'REC-${now.year}${now.month.toString().padLeft(2, '0')}-$suffix';
    await _db.collection(Collections.payments).doc(payment.id).update({
      'status': PaymentStatus.approved.name,
      'receiptNumber': receipt,
      'reviewedBy': reviewedBy,
      'reviewedAt': now.toIso8601String(),
    });
  }

  /// জমা বাতিল — কারণ লিখে রাখা হয়।
  Future<void> rejectPayment(
    String paymentId, {
    required String reason,
    required String reviewedBy,
  }) async {
    await _db.collection(Collections.payments).doc(paymentId).update({
      'status': PaymentStatus.rejected.name,
      'rejectReason': reason,
      'reviewedBy': reviewedBy,
      'reviewedAt': DateTime.now().toIso8601String(),
    });
  }

  // ---------- পেমেন্ট মাধ্যম ----------

  /// সদস্যের জমা দেওয়ার জন্য চালু মাধ্যমগুলো।
  /// সমিতি বেছে দিলে ওই সমিতিরটা আর সবার জন্য খোলা মাধ্যম — দুটোই আসে।
  /// বন্ধ মাধ্যম এখানে আসে না — সদস্য শুধু চালু মাধ্যমেই জমা দিতে পারে।
  Stream<List<PaymentMethodConfig>> watchActivePaymentMethods({
    String? branchId,
  }) {
    return _db
        .collection(Collections.paymentMethods)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final all = snap.docs
          .map((d) => PaymentMethodConfig.fromMap(d.id, d.data()))
          .toList();
      final scoped = branchId == null
          ? all
          : all.where((m) => m.branchId == null || m.branchId == branchId);
      final sorted = scoped.toList()
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
        });
      return sorted;
    });
  }

  /// অ্যাডমিনের জন্য সব মাধ্যম — চালু আর বন্ধ, সবই।
  Stream<List<PaymentMethodConfig>> watchAllPaymentMethods() {
    return _db.collection(Collections.paymentMethods).snapshots().map((snap) {
      final all = snap.docs
          .map((d) => PaymentMethodConfig.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
        });
      return all;
    });
  }

  /// নতুন পেমেন্ট মাধ্যম যোগ করা — শুধু অ্যাডমিন।
  /// কী করা হলো, auditLogs-এ লিখে রাখা হয়।
  Future<String> addPaymentMethod(
    PaymentMethodConfig method, {
    required String createdBy,
  }) async {
    final doc = _db.collection(Collections.paymentMethods).doc();
    await doc.set(method.toMap());
    await _logAudit(
      action: 'payment_method_added',
      by: createdBy,
      detail: '${method.name} (${method.accountNumber}) যোগ করা হয়েছে',
    );
    return doc.id;
  }

  /// পেমেন্ট মাধ্যম বদলানো — শুধু অ্যাডমিন।
  Future<void> updatePaymentMethod(
    PaymentMethodConfig method, {
    required String updatedBy,
  }) async {
    final data = method.toMap();
    data['updatedAt'] = DateTime.now().toIso8601String();
    await _db
        .collection(Collections.paymentMethods)
        .doc(method.id)
        .update(data);
    await _logAudit(
      action: 'payment_method_updated',
      by: updatedBy,
      detail: '${method.name} (${method.accountNumber}) বদলানো হয়েছে',
    );
  }

  /// মাধ্যম চালু বা বন্ধ করা — শুধু অ্যাডমিন।
  /// বন্ধ করলেও আগের জমার হিসাব মুছে না, শুধু নতুন
  /// জমায় ওই মাধ্যম আর দেখা যায় না। মুছে ফেলা হয় না।
  Future<void> setPaymentMethodActive(
    String methodId, {
    required bool active,
    required String by,
    required String methodName,
  }) async {
    await _db.collection(Collections.paymentMethods).doc(methodId).update({
      'isActive': active,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _logAudit(
      action: active
          ? 'payment_method_activated'
          : 'payment_method_deactivated',
      by: by,
      detail: '$methodName ${active ? 'চালু' : 'বন্ধ'} করা হয়েছে',
    );
  }

  /// একই TrxID দিয়ে ওই মাধ্যমেই আগেই জমা দেওয়া হয়েছে কি না।
  /// থাকলে জমা দেওয়ার আগে সদস্যকে সতর্ক করা হয়।
  /// সমিতি ধরে খোঁজা হয় — অন্য সমিতির জমা এখানে আসে না।
  Future<bool> trxIdAlreadyUsed({
    required String paymentMethodId,
    required String trxId,
    required String branchId,
  }) async {
    final snap = await _db
        .collection(Collections.payments)
        .where('branchId', isEqualTo: branchId)
        .where('trxId', isEqualTo: trxId)
        .get();
    return snap.docs.any(
      (d) => (d.data()['paymentMethodId'] as String?) == paymentMethodId,
    );
  }

  /// অডিট লগ — কে, কখন, কী বদলালো।
  Future<void> _logAudit({
    required String action,
    required String by,
    required String detail,
  }) async {
    try {
      await _db.collection(Collections.auditLogs).add({
        'action': action,
        'by': by,
        'detail': detail,
        'at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // লগ লেখা না গেলেও আসল কাজ থামবে না।
    }
  }

  // ---------- খরচ ----------

  /// সব খরচ — নতুনটা আগে। সমিতি বেছে দিলে শুধু ওই সমিতিরটা।
  Stream<List<Expense>> watchExpenses({String? branchId}) {
    var query = _db.collection(Collections.expenses).orderBy('date', descending: true);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList(),
        );
  }

  /// খরচ লেখা — রসিদের ছবি থাকলে আগে Storage-এ তোলা হয়।
  Future<String> submitExpense({
    required Expense expense,
    Uint8List? receiptBytes,
  }) async {
    final doc = _db.collection(Collections.expenses).doc();
    String? attachmentUrl;
    if (receiptBytes != null) {
      attachmentUrl = await _storage.uploadBytes(
        'expenses/${doc.id}/receipt.jpg',
        receiptBytes,
      );
    }
    final data = expense.toMap();
    data['attachmentUrl'] = attachmentUrl;
    await doc.set(data);
    return doc.id;
  }

  // ---------- কর্জে হাসানা ঋণ ----------

  /// সব ঋণ — নতুনটা আগে। সমিতি বেছে দিলে শুধু ওই সমিতিরটা।
  Stream<List<Loan>> watchLoans({String? branchId}) {
    var query = _db.collection(Collections.loans).orderBy('dateIssued', descending: true);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => Loan.fromMap(d.id, d.data())).toList(),
        );
  }

  /// একটি ঋণ — বিস্তারিত স্ক্রিনে লাগে।
  Stream<Loan?> watchLoan(String loanId) {
    return _db.collection(Collections.loans).doc(loanId).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Loan.fromMap(doc.id, doc.data()!)
              : null,
        );
  }

  /// ঋণ দেওয়া — সুদমুক্ত। অবস্থা active থাকে।
  Future<String> issueLoan(Loan loan) async {
    final doc = _db.collection(Collections.loans).doc();
    await doc.set(loan.toMap());
    return doc.id;
  }

  /// কিস্তি জমা নেওয়া — একই লেনদেনে কিস্তি যোগ হয় আর
  /// বাকি শূন্য হলে অবস্থা repaid হয়। কী করা হলো,
  /// auditLogs-এ লিখে রাখা হয়।
  Future<void> recordRepayment(
    String loanId,
    LoanRepayment repayment, {
    String recordedBy = '',
  }) async {
    final ref = _db.collection(Collections.loans).doc(loanId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return;
      final loan = Loan.fromMap(snap.id, snap.data()!);
      final updated = [...loan.repayments, repayment];
      final repaid = updated.fold(0, (sum, r) => sum + r.amount);
      tx.update(ref, {
        'repayments': updated.map((r) => r.toMap()).toList(),
        'status':
            repaid >= loan.amount ? LoanStatus.repaid.name : LoanStatus.active.name,
      });
    });
    await _logAudit(
      action: 'loan_repayment_recorded',
      by: recordedBy,
      detail:
          'ঋণের কিস্তি ${repayment.amount} টাকা (${repayment.methodLabel}) জমা নেওয়া হয়েছে',
    );
  }

  // ---------- নোটিশ ও কমিটি ----------

  /// নোটিশ — নতুনটা আগে। সমিতি বেছে দিলে ওই সমিতিরটা
  /// আর সবার জন্য লেখা নোটিশ — দুটোই আসে।
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

  /// নোটিশ লেখা — সংযুক্তি থাকলে আগে Storage-এ তোলা হয়।
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

  /// কমিটির তালিকা।
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

  // ---------- হোমের মোট হিসাব ----------

  /// হোমের তিনটি সংখ্যা একবারে — অনুমোদিত জমার মোট,
  /// খরচের মোট, সক্রিয় সদস্যের সংখ্যা।
  /// ডেটা আনা না গেলে (যেমন Firebase কনফিগ নেই) খালি
  /// মান ফেরে, যাতে হোমে '—' দেখানো যায়।
  Future<HomeTotals> fetchHomeTotals({String? branchId}) async {
    try {
      var paymentsQuery = _db
          .collection(Collections.payments)
          .where('status', isEqualTo: PaymentStatus.approved.name);
      Query<Map<String, dynamic>> expensesQuery =
          _db.collection(Collections.expenses);
      var membersQuery = _db
          .collection(Collections.members)
          .where('status', isEqualTo: 'active');
      if (branchId != null) {
        paymentsQuery =
            paymentsQuery.where('branchId', isEqualTo: branchId);
        expensesQuery =
            expensesQuery.where('branchId', isEqualTo: branchId);
        membersQuery = membersQuery.where('branchId', isEqualTo: branchId);
      }
      final results = await Future.wait([
        paymentsQuery.get(),
        expensesQuery.get(),
        membersQuery.get(),
      ]);
      final approvedTotal = results[0].docs.fold<int>(
        0,
        (sum, d) => sum + ((d.data()['amount'] as num?)?.toInt() ?? 0),
      );
      final expenseTotal = results[1].docs.fold<int>(
        0,
        (sum, d) => sum + ((d.data()['amount'] as num?)?.toInt() ?? 0),
      );
      return HomeTotals(
        approvedTotal: approvedTotal,
        expenseTotal: expenseTotal,
        activeMembers: results[2].docs.length,
      );
    } catch (_) {
      return const HomeTotals();
    }
  }

  /// বকেয়া হিসাবের জন্য সব অনুমোদিত জমা একবারে।
  /// কোন সদস্য কোন মাসের জমা দিয়েছে — সেটা এখান থেকে মেলানো হয়।
  Future<List<Payment>> fetchApprovedPayments({String? branchId}) async {
    var query = _db
        .collection(Collections.payments)
        .where('status', isEqualTo: PaymentStatus.approved.name);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Payment.fromMap(d.id, d.data())).toList();
  }

  /// রিপোর্টের জন্য এক মাসের অনুমোদিত জমা, খরচ আর ঋণ —
  /// একবারে আনা হয়, স্ক্রিনে ছেঁকে নেওয়া হয়।
  Future<List<Payment>> fetchPaymentsForMonth({
    required int year,
    required int month,
    String? branchId,
  }) async {
    var query = _db
        .collection(Collections.payments)
        .where('forYear', isEqualTo: year)
        .where('forMonth', isEqualTo: month);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Payment.fromMap(d.id, d.data())).toList();
  }

  Future<List<Expense>> fetchExpensesForMonth({
    required int year,
    required int month,
    String? branchId,
  }) async {
    // সমিতি দেওয়া থাকলে সার্ভারেই ছেঁকে আনা হয় — অন্য সমিতির
    // খরচ ডিভাইসে আসেই না।
    Query<Map<String, dynamic>> query =
        _db.collection(Collections.expenses);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => Expense.fromMap(d.id, d.data()))
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  Future<List<Loan>> fetchLoans({String? branchId}) async {
    var query = _db.collection(Collections.loans).orderBy('dateIssued', descending: true);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Loan.fromMap(d.id, d.data())).toList();
  }
}

/// হোমের মোট হিসাব — কোনোটা আনা না গেলে null থাকে।
class HomeTotals {
  final int? approvedTotal;
  final int? expenseTotal;
  final int? activeMembers;

  const HomeTotals({this.approvedTotal, this.expenseTotal, this.activeMembers});
}
