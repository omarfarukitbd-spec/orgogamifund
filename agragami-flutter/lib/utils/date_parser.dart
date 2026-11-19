import 'package:cloud_firestore/cloud_firestore.dart';

/// ফায়ারবেস থেকে আসা তারিখ পার্স করার নিরাপদ হেল্পার।
/// অ্যান্ড্রয়েড (Long/Timestamp) এবং ফ্লাটার (ISO String) উভয়ের ডেটা নিখুঁতভাবে হ্যান্ডেল করে।

/// তারিখ না পাওয়া গেলে বা ভুল থাকলে এই চিহ্ন-তারিখ
/// ফেরত দেওয়া হয় — ১৯৭০-০১-০১। আগে এখানে
/// `DateTime.now()` ফেরত দেওয়া হতো, ফলে তারিখ ছাড়া
/// পেমেন্ট "আজকের" হয়ে যেত আর বকেয়া হিসাব ভুল হতো।
/// এই চিহ্ন দেখলে UI "তারিখ নেই" দেখাবে আর হিসাব থেকে
/// ওই তারিখ বাদ দেবে — কখনো আজকের তারিখ ধরা হবে না।
final DateTime missingDateSentinel =
    DateTime.fromMillisecondsSinceEpoch(0);

/// তারিখটা কি আসল তারিখ নাকি "তারিখ নেই" চিহ্ন?
bool isMissingDate(DateTime date) =>
    date.millisecondsSinceEpoch == 0;

/// ঐচ্ছিক তারিখ পার্স করা — না থাকলে বা ভুল থাকলে null।
DateTime? parseFirestoreDateOrNull(dynamic value) {
  if (value == null) return null;
  final parsed = parseFirestoreDate(value);
  return isMissingDate(parsed) ? null : parsed;
}

DateTime parseFirestoreDate(dynamic value, [DateTime? fallback]) {
  if (value == null) return fallback ?? missingDateSentinel;

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is num) {
    final intVal = value.toInt();
    // যদি সেকেন্ডে থাকে (কমপক্ষে ১০ ডিজিট কিন্তু ১৩ ডিজিট নয়)
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

  return fallback ?? missingDateSentinel;
}
