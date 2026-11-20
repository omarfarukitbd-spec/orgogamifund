import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_parser.dart';

/// সদস্যের তথ্য সংশোধনের আবেদন (Phase 9, G12)।
/// Firestore কালেকশন: editRequests
/// rules (§8): সদস্য নিজের linkedMemberId-এর জন্য আবেদন
/// করে (memberId মিলতে হয়); অ্যাডমিন যাচাই করে অনুমোদন
/// বা বাতিল করে। অনুমোদন হলে [changes]-এর ক্ষেত্রগুলো
/// সদস্যের রেকর্ডে বসে।
enum EditRequestStatus { pending, approved, rejected }

class EditRequest {
  final String id;

  /// যে সদস্যের রেকর্ড বদলাবে — rules-এ আবেদনকারীর
  /// linkedMemberId-এর সাথে মিলতে হয়।
  final String memberId;

  /// সদস্যের সমিতি — যাচাইয়ের পাতায় শাখা-ফিল্টারের জন্য।
  final String branchId;

  /// আবেদনকারীর uid (তথ্যের জন্য)।
  final String? requestedBy;

  /// সদস্যের নাম — যাচাইয়ের পাতায় দেখানোর জন্য, যাতে
  /// প্রতি আবেদনে সদস্যের ডকুমেন্ট পড়তে না হয়।
  final String memberName;

  /// বদলাতে চাওয়া নতুন মান — শুধু বদলানো ক্ষেত্র থাকে,
  /// যেমন {'phone': '01...', 'address': '...'}।
  final Map<String, String> changes;

  /// বদলানো ক্ষেত্রগুলোর পুরোনো মান — যাচাইয়ের পাতায়
  /// "পুরোনো → নতুন" দেখানোর জন্য।
  final Map<String, String> previous;

  final EditRequestStatus status;
  final DateTime requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectReason;

  const EditRequest({
    required this.id,
    required this.memberId,
    required this.branchId,
    this.requestedBy,
    required this.memberName,
    required this.changes,
    required this.previous,
    this.status = EditRequestStatus.pending,
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectReason,
  });

  /// বদলানো ক্ষেত্রগুলো বের করা — খাঁটি ফাংশন, যাতে টেস্ট
  /// করা যায়। শুধু সত্যিকারের বদলানো ক্ষেত্র আসে; কিছু না
  /// বদলালে দুটো ম্যাপই খালি থাকে। মানগুলো আগেই স্বাভাবিক
  /// করা (trim, বাংলা অঙ্ক → ASCII) ধরা হয়।
  static ({
    Map<String, String> changes,
    Map<String, String> previous,
  }) diff({
    required String oldPhone,
    required String newPhone,
    required String oldAddress,
    required String newAddress,
  }) {
    final changes = <String, String>{};
    final previous = <String, String>{};
    if (newPhone.trim() != oldPhone.trim()) {
      changes['phone'] = newPhone.trim();
      previous['phone'] = oldPhone.trim();
    }
    if (newAddress.trim() != oldAddress.trim()) {
      changes['address'] = newAddress.trim();
      previous['address'] = oldAddress.trim();
    }
    return (changes: changes, previous: previous);
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return {};
    final out = <String, String>{};
    for (final entry in value.entries) {
      out[entry.key.toString()] = entry.value?.toString() ?? '';
    }
    return out;
  }

  factory EditRequest.fromMap(String id, Map<String, dynamic> data) {
    return EditRequest(
      id: id,
      memberId: (data['memberId'] as String?) ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      requestedBy: data['requestedBy'] as String?,
      memberName: (data['memberName'] as String?) ?? '',
      changes: _stringMap(data['changes']),
      previous: _stringMap(data['previous']),
      status: EditRequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => EditRequestStatus.pending,
      ),
      requestedAt: parseFirestoreDate(data['requestedAt']),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: parseFirestoreDateOrNull(data['reviewedAt']),
      rejectReason: data['rejectReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'branchId': branchId,
      'requestedBy': requestedBy,
      'memberName': memberName,
      'changes': changes,
      'previous': previous,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reviewedBy': reviewedBy,
      'reviewedAt':
          reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'rejectReason': rejectReason,
    };
  }
}

/// সংশোধন-আবেদনের অবস্থার বাংলা নাম।
String editRequestStatusText(EditRequestStatus status) {
  switch (status) {
    case EditRequestStatus.pending:
      return 'অপেক্ষায়';
    case EditRequestStatus.approved:
      return 'অনুমোদিত';
    case EditRequestStatus.rejected:
      return 'বাতিল';
  }
}

/// বদলানো ক্ষেত্রের বাংলা লেবেল — যাচাইয়ের পাতায় দেখানো হয়।
String editRequestFieldLabel(String field) {
  switch (field) {
    case 'phone':
      return 'ফোন';
    case 'address':
      return 'ঠিকানা';
    default:
      return field;
  }
}
