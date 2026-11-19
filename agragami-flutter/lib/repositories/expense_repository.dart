import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import 'audit_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final auditRepo = ref.watch(auditRepositoryProvider);
  return ExpenseRepository(auditRepository: auditRepo);
});

/// সমিতির ব্যয় সংক্রান্ত ডেটাবেজ কার্যক্রমের রিপোজিটরি
class ExpenseRepository {
  final FirebaseFirestore _db;
  final StorageService _storage;
  final AuditRepository _audit;

  ExpenseRepository({
    FirebaseFirestore? db,
    StorageService? storageService,
    AuditRepository? auditRepository,
  })  : _db = db ?? FirebaseService.instance.db,
        _storage = storageService ?? StorageService(),
        _audit = auditRepository ?? AuditRepository(db: db);

  /// সমস্ত ব্যয়ের লাইভ স্ট্রিম (সর্বোচ্চ ২০০টি — সংখ্যা
  /// বাড়লে পেজিনেশন লাগবে)।
  Stream<List<Expense>> watchExpenses({String? branchId}) {
    var query = _db
        .collection(Collections.expenses)
        .orderBy('date', descending: true)
        .limit(200);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    return query.snapshots().map(
          (snap) =>
              snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList(),
        );
  }

  /// সাম্প্রতিক খরচ — তারিখ অনুযায়ী নতুন থেকে পুরোনো।
  /// হোমের "সাম্প্রতিক লেনদেন" এটাই দেখায়।
  Future<List<Expense>> fetchRecentExpenses({
    String? branchId,
    int limit = 2,
  }) async {
    var query = _db
        .collection(Collections.expenses)
        .orderBy('date', descending: true)
        .limit(limit);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList();
  }

  /// নতুন ব্যয় লিপিবদ্ধ করা (ভাউচার ছবি আপলোডসহ)
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

  /// খরচ বদলানো (M9) — ধরন, টাকা, তারিখ, বিবরণ।
  /// নতুন রসিদের ছবি দিলে আগের ছবির জায়গায় বসে;
  /// না দিলে আগের ছবিই থাকে।
  Future<void> updateExpense({
    required Expense expense,
    Uint8List? receiptBytes,
    String by = '',
  }) async {
    if (expense.id.isEmpty) return;
    String? attachmentUrl = expense.attachmentUrl;
    if (receiptBytes != null) {
      attachmentUrl = await _storage.uploadBytes(
        'expenses/${expense.id}/receipt.jpg',
        receiptBytes,
      );
    }
    final data = expense.toMap();
    data['attachmentUrl'] = attachmentUrl;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(Collections.expenses).doc(expense.id).update(data);
    await _audit.logAudit(
      action: 'expense_updated',
      by: by,
      detail: 'খরচ বদলানো হয়েছে: ${expense.amount} টাকা (${expense.id})',
    );
  }

  /// খরচ মুছা (M9) — ভুল খরচ সংশোধনের শেষ উপায়।
  /// হার্ড ডিলিট + অডিট লগ (জমার মতোই কারণ)।
  /// শুধু সুপার অ্যাডমিন মুছতে পারে (rules)।
  Future<void> deleteExpense(
    String expenseId, {
    required String by,
  }) async {
    if (expenseId.isEmpty) return;
    await _db.collection(Collections.expenses).doc(expenseId).delete();
    await _audit.logAudit(
      action: 'expense_deleted',
      by: by,
      detail: 'খরচ মুছা হয়েছে ($expenseId)',
    );
  }

  /// নির্দিষ্ট মাস ও বছরের ব্যয় আনা (রিপোর্টের জন্য)।
  /// মাসের তারিখ-সীমা সার্ভারেই ফিল্টার করা হয় —
  /// (branchId, date) ইনডেক্স আছে, তাই পুরো কালেকশন
  /// নামিয়ে ক্লায়েন্টে ছাঁকতে হয় না।
  Future<List<Expense>> fetchExpensesForMonth({
    required int year,
    required int month,
    String? branchId,
  }) async {
    final start = Timestamp.fromDate(DateTime(year, month, 1));
    final end = Timestamp.fromDate(
      month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1),
    );
    Query<Map<String, dynamic>> query = _db
        .collection(Collections.expenses)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date', descending: true);
    if (branchId != null) {
      query = query.where('branchId', isEqualTo: branchId);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList();
  }
}
