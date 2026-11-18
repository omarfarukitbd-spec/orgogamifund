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

  /// জমা অনুমোদন করা (রসিদ নম্বর জেনারেশনসহ)
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
    await _db.collection(Collections.payments).doc(payment.id).update({
      'status': PaymentStatus.approved.name,
      'receiptNumber': receipt,
      'reviewedBy': reviewedBy,
      'reviewedAt': now.toIso8601String(),
    });
  }

  /// জমা বাতিল করা
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
    data['updatedAt'] = DateTime.now().toIso8601String();
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
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _audit.logAudit(
      action: active
          ? 'payment_method_activated'
          : 'payment_method_deactivated',
      by: by,
      detail: '$methodName ${active ? 'চালু' : 'বন্ধ'} করা হয়েছে',
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

  /// সমস্ত অনুমোদিত জমা একবারে ফেচ করা (বকেয়া গণনার জন্য)
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
