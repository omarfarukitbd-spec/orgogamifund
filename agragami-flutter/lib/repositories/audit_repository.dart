import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_service.dart';

final auditRepositoryProvider =
    Provider<AuditRepository>((ref) => AuditRepository());

/// সিস্টেমে কে কখন কী পরিবর্তন করেছে তা সংরক্ষণ করার অডিট লগ রিপোজিটরি
class AuditRepository {
  final FirebaseFirestore _db;

  AuditRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseService.instance.db;

  Future<void> logAudit({
    required String action,
    required String by,
    required String detail,
  }) async {
    try {
      await _db.collection(Collections.auditLogs).add({
        'action': action,
        'by': by,
        'detail': detail,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // লগ ব্যর্থ হলেও মূল অপারেশন বাধাগ্রস্ত হবে না
    }
  }
}
