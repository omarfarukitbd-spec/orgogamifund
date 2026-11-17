import 'package:cloud_firestore/cloud_firestore.dart';

/// ফায়ারবেস থেকে আসা তারিখ পার্স করার নিরাপদ হেল্পার।
/// অ্যান্ড্রয়েড (Long/Timestamp) এবং ফ্লাটার (ISO String) উভয়ের ডেটা নিখুঁতভাবে হ্যান্ডেল করে।
DateTime parseFirestoreDate(dynamic value, [DateTime? fallback]) {
  if (value == null) return fallback ?? DateTime.now();

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is num) {
    final intVal = value.toInt();
    // যদি সেকেন্ডে থাকে (কমপক্ষে ১০ ডিজিট কিন্তু ১৩ ডিজিট নয়)
    if (intVal < 10000000000) {
      return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
    }
    return DateTime.fromMillisecondsSinceEpoch(intVal);
  }

  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    // সংখ্যা হিসেবে স্ট্রিং থাকলে
    final numVal = int.tryParse(value);
    if (numVal != null) {
      if (numVal < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numVal * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(numVal);
    }
  }

  return fallback ?? DateTime.now();
}
