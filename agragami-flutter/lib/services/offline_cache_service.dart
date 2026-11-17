import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_service.dart';

final offlineCacheServiceProvider =
    Provider<OfflineCacheService>((ref) => OfflineCacheService());

/// অফলাইন ক্যাশ ও সিঙ্ক স্থিতি প্রোভাইডার
final offlineSyncStatusProvider = StateProvider<bool>((ref) => false);

/// অফলাইন ডেটা ক্যাশিং ও স্থানীয় সিঙ্ক ব্যবস্থাপনা সার্ভিস
class OfflineCacheService {
  final FirebaseFirestore _db;

  OfflineCacheService({FirebaseFirestore? db})
      : _db = db ?? FirebaseService.instance.db;

  /// Firestore ক্যাশ সেটিংস সক্রিয় ও অপ্টিমাইজ করা
  Future<void> configureOfflineCache() async {
    try {
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // আগেই কনফিগার থাকলে অবজ্ঞা করা হবে
    }
  }

  /// অফলাইনে ব্যবহারের জন্য নির্দিষ্ট সমিতির সদস্য ও হিসাব প্রি-ক্যাশ করা
  Future<void> prefetchBranchDataForOffline(String branchId) async {
    if (branchId.isEmpty) return;
    try {
      // সার্ভার ও ক্যাশ থেকে ফেচ করে স্থানীয় ডিস্কে সংরক্ষণ
      await Future.wait([
        _db
            .collection(Collections.branches)
            .doc(branchId)
            .get(const GetOptions(source: Source.serverAndCache)),
        _db
            .collection(Collections.members)
            .where('branchId', isEqualTo: branchId)
            .get(const GetOptions(source: Source.serverAndCache)),
        _db
            .collection(Collections.payments)
            .where('branchId', isEqualTo: branchId)
            .get(const GetOptions(source: Source.serverAndCache)),
        _db
            .collection(Collections.expenses)
            .where('branchId', isEqualTo: branchId)
            .get(const GetOptions(source: Source.serverAndCache)),
        _db
            .collection(Collections.loans)
            .where('branchId', isEqualTo: branchId)
            .get(const GetOptions(source: Source.serverAndCache)),
      ]);
    } catch (_) {
      // অফলাইন মোডে থাকলে ক্যাশ থেকেই পড়বে
    }
  }

  /// স্থানীয় ক্যাশ মেমোরি খালি করা
  Future<void> clearOfflineCache() async {
    try {
      await _db.clearPersistence();
    } catch (_) {}
  }
}
