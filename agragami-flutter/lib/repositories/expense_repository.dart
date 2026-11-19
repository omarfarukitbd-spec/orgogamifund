import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

final expenseRepositoryProvider =
    Provider<ExpenseRepository>((ref) => ExpenseRepository());

/// সমিতির ব্যয় সংক্রান্ত ডেটাবেজ কার্যক্রমের রিপোজিটরি
class ExpenseRepository {
  final FirebaseFirestore _db;
  final StorageService _storage;

  ExpenseRepository({
    FirebaseFirestore? db,
    StorageService? storageService,
  })  : _db = db ?? FirebaseService.instance.db,
        _storage = storageService ?? StorageService();

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
