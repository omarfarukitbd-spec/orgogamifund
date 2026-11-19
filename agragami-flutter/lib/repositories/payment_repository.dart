import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../models/payment_method.dart';
import '../services/firebase_service.dart';
import 'audit_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final auditRepo = ref.watch(auditRepositoryProvider);
  return PaymentRepository(auditRepository: auditRepo);
});

/// জমা ও পেমেন্ট মেথড সংক্রান্ত ডেটাবেজ কার্যক্রমের রিপোজিটরি
class PaymentRepository {
  final FirebaseFirestore _db;
  final AuditRepository _audit;

  PaymentRepository({
    FirebaseFirestore? db,
    AuditRepository? auditRepository,
  })  : _db = db ?? FirebaseService.instance.db,
        _audit = auditRepository ?? AuditRepository(db: db);

  /// অপেক্ষমাণ জমার লাইভ স্ট্রিম
  Stream<List<Payment>> watchPendingPayments({String? branchId}) {
    Query<Map<String, dynamic>> query = _db.collection(Collections.payments);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) {
            final list = snap.docs
                .map((d) => Payment.fromMap(d.id, d.data()))
                .where((p) => p.status == PaymentStatus.pending)
                .toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          },
        );
  }

  /// একজন নির্দিষ্ট সদস্যের সমস্ত জমা
  Stream<List<Payment>> watchMemberPayments(String memberId) {
    if (memberId.isEmpty) return const Stream.empty();
    return _db
        .collection(Collections.payments)
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Payment.fromMap(d.id, d.data())).toList(),
        );
  }

  /// জমা সাবমিট করা
  Future<String> submitPayment(Payment payment) async {
    final doc = _db.collection(Collections.payments).doc();
    await doc.set(payment.toMap());
    return doc.id;
  }

  /// জমা অনুমোদন করা (রসিদ নম্বর জেনারেশনসহ)।
  /// m5: ট্রানজ্যাকশনে হয় — জমা এখনো pending না থাকলে
  /// (আগেই যাচাই হয়ে গেছে) ব্যর্থ হয়, অনুমোদন-তারপর-বাতিল
  /// ডাবল-ট্যাপে হতে পারে না। m14: `status` আর
  /// `approvalStatus` দুটোই বদলানো হয় — পুরোনো অ্যাপ
  /// approvalStatus পড়ে, একটা বদলালে দুটো মেলে না।
  Future<void> approvePayment(
    Payment payment, {
    required String reviewedBy,
  }) async {
    final now = DateTime.now();
    final suffix = payment.id.length >= 4
        ? payment.id.substring(payment.id.length - 4).toUpperCase()
        : payment.id.toUpperCase();
    final receipt =
        'REC-${now.year}${now.month.toString().padLeft(2, '0')}-$suffix';
    final ref = _db.collection(Collections.payments).doc(payment.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('payment-not-found');
      final data = snap.data()!;
      final rawStatus =
          ((data['status'] ?? data['approvalStatus']) as String?)
              ?.toLowerCase();
      if (rawStatus != PaymentStatus.pending.name) {
        throw StateError('already-reviewed');
      }
      tx.update(ref, {
        'status': PaymentStatus.approved.name,
        'approvalStatus': PaymentStatus.approved.name.toUpperCase(),
        'receiptNumber': receipt,
        'reviewedBy': reviewedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// জমা বাতিল করা (m5/m14: approvePayment-এর মতোই
  /// ট্রানজ্যাকশন আর দুই status ফিল্ড)।
  Future<void> rejectPayment(
    String paymentId, {
    required String reason,
    required String reviewedBy,
  }) async {
    final ref = _db.collection(Collections.payments).doc(paymentId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('payment-not-found');
      final data = snap.data()!;
      final rawStatus =
          ((data['status'] ?? data['approvalStatus']) as String?)
              ?.toLowerCase();
      if (rawStatus != PaymentStatus.pending.name) {
        throw StateError('already-reviewed');
      }
      tx.update(ref, {
        'status': PaymentStatus.rejected.name,
        'approvalStatus': PaymentStatus.rejected.name.toUpperCase(),
        'rejectReason': reason,
        'reviewedBy': reviewedBy,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// জমা বদলানো (M9) — টাকা, মাস/বছর, TrxID, পাঠানোর নম্বর।
  /// অবস্থা (status) এখান থেকে বদলানো যায় না — সেটা
  /// অনুমোদনের কাজ। শুধু অ্যাডমিন করতে পারে (rules)।
  Future<void> updatePayment(
    Payment payment, {
    required String by,
  }) async {
    if (payment.id.isEmpty) return;
    await _db.collection(Collections.payments).doc(payment.id).update({
      'amount': payment.amount,
      'forMonth': payment.forMonth,
      'forYear': payment.forYear,
      'trxId': payment.trxId,
      'transactionId': payment.trxId,
      'senderMobile': payment.senderMobile,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _audit.logAudit(
      action: 'payment_updated',
      by: by,
      detail: 'জমা বদলানো হয়েছে: ${payment.amount} টাকা (${payment.id})',
    );
  }

  /// জমা মুছা (M9) — ভুল জমা সংশোধনের শেষ উপায়।
  /// হার্ড ডিলিট + অডিট লগ: সফট-ডিলিট হলে মোট হিসাব,
  /// বকেয়া, রিপোর্ট — সব পড়ার পথে মুছা জমা বাদ দিতে
  /// হতো, একটা পথ বাদ পড়লেই অঙ্ক ভুল হতো।
  /// শুধু সুপার অ্যাডমিন মুছতে পারে (rules)।
  Future<void> deletePayment(
    String paymentId, {
    required String by,
  }) async {
    if (paymentId.isEmpty) return;
    await _db.collection(Collections.payments).doc(paymentId).delete();
    await _audit.logAudit(
      action: 'payment_deleted',
      by: by,
      detail: 'জমা মুছা হয়েছে ($paymentId)',
    );
  }

  /// এই সদস্যের ওই মাসের (বাতিল নয় এমন) জমা আছে কি না (m7)।
  /// memberId দিয়ে পড়ে ক্লায়েন্টে ছাঁকা হয় — নতুন ইনডেক্স
  /// লাগে না, (memberId, date) ইনডেক্স আগেই আছে।
  Future<bool> hasPaymentForMonth({
    required String memberId,
    required int forYear,
    required int forMonth,
  }) async {
    if (memberId.isEmpty) return false;
    final snap = await _db
        .collection(Collections.payments)
        .where('memberId', isEqualTo: memberId)
        .get();
    return snap.docs.any((d) {
      final p = Payment.fromMap(d.id, d.data());
      return p.forYear == forYear &&
          p.forMonth == forMonth &&
          p.status != PaymentStatus.rejected;
    });
  }

  /// সক্রিয় পেমেন্ট মেথড তালিকা
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

  /// সমস্ত পেমেন্ট মেথড তালিকা (সক্রিয় ও নিষ্ক্রিয়)
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

  /// নতুন পেমেন্ট মেথড যুক্ত করা
  Future<String> addPaymentMethod(
    PaymentMethodConfig method, {
    required String createdBy,
  }) async {
    final doc = _db.collection(Collections.paymentMethods).doc();
    await doc.set(method.toMap());
    await _audit.logAudit(
      action: 'payment_method_added',
      by: createdBy,
      detail: '${method.name} (${method.accountNumber}) যোগ করা হয়েছে',
    );
    return doc.id;
  }

  /// পেমেন্ট মেথড আপডেট করা
  Future<void> updatePaymentMethod(
    PaymentMethodConfig method, {
    required String updatedBy,
  }) async {
    final data = method.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection(Collections.paymentMethods)
        .doc(method.id)
        .update(data);
    await _audit.logAudit(
      action: 'payment_method_updated',
      by: updatedBy,
      detail: '${method.name} (${method.accountNumber}) বদলানো হয়েছে',
    );
  }

  /// পেমেন্ট মেথড সক্রিয়/নিষ্ক্রিয় করা
  Future<void> setPaymentMethodActive(
    String methodId, {
    required bool active,
    required String by,
    required String methodName,
  }) async {
    await _db.collection(Collections.paymentMethods).doc(methodId).update({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _audit.logAudit(
      action: active
          ? 'payment_method_activated'
          : 'payment_method_deactivated',
      by: by,
      detail: '$methodName ${active ? 'চালু' : 'বন্ধ'} করা হয়েছে',
    );
  }

  /// পেমেন্ট মেথড মুছা (M9) — শুধু তখনই, যখন এই মাধ্যম
  /// দিয়ে কোনো জমা নেই। জমা থাকলে মুছলে পুরোনো জমার
  /// মাধ্যমের ছাপ ভেঙে যেত। জমা থাকলে 'method-in-use' ছোড়ে।
  Future<void> deletePaymentMethod(
    String methodId, {
    required String by,
    required String methodName,
  }) async {
    if (methodId.isEmpty) return;
    final used = await _db
        .collection(Collections.payments)
        .where('paymentMethodId', isEqualTo: methodId)
        .limit(1)
        .get();
    if (used.docs.isNotEmpty) throw StateError('method-in-use');
    await _db.collection(Collections.paymentMethods).doc(methodId).delete();
    await _audit.logAudit(
      action: 'payment_method_deleted',
      by: by,
      detail: 'পেমেন্ট মাধ্যম মুছা হয়েছে: $methodName ($methodId)',
    );
  }

  /// একই TrxID পূর্বেই ব্যবহৃত হয়েছে কি না তা যাচাই
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

  /// সমস্ত অনুমোদিত জমা একবারে ফেচ করা (বকেয়া গণনার জন্য)।
  /// স্ট্যাটাস সার্ভারে ফিল্টার করা হয় না — পুরোনো ডকুমেন্টে
  /// শুধু `approvalStatus` (যেমন "APPROVED") থাকতে পারে, সেগুলো
  /// সার্ভার-ফিল্টারে বাদ পড়ে যেত। ক্লায়েন্টে পার্স করে
  /// ছাঁকা হয়, যাতে পুরোনো জমাও বকেয়া হিসাবে ধরা পড়ে।
  Future<List<Payment>> fetchApprovedPayments({String? branchId}) async {
    Query<Map<String, dynamic>> query = _db.collection(Collections.payments);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => Payment.fromMap(d.id, d.data()))
        .where((p) => p.status == PaymentStatus.approved)
        .toList();
  }

  /// সাম্প্রতিক অনুমোদিত জমা — তারিখ অনুযায়ী নতুন থেকে পুরোনো।
  /// হোমের "সাম্প্রতিক লেনদেন" এটাই দেখায়। আগের কোডে কোনো
  /// orderBy ছিল না, ফলে দেখানো দুটো জমা ছিল এলোমেলো।
  /// (branchId, status, date) ইনডেক্স আগেই আছে।
  Future<List<Payment>> fetchRecentApprovedPayments({
    String? branchId,
    int limit = 2,
  }) async {
    var query = _db
        .collection(Collections.payments)
        .where('status', isEqualTo: PaymentStatus.approved.name)
        .orderBy('date', descending: true)
        .limit(limit);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Payment.fromMap(d.id, d.data())).toList();
  }

  /// নির্দিষ্ট মাস ও বছরের অনুমোদিত জমা আনা (রিপোর্টের জন্য)
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
}
