/// বকেয়া হিসাবের ছোট হিসাবগুলো এক জায়গায়,
/// যাতে পাসবই আর রিপোর্টে একই নিয়মে হিসাব হয়।
library;

/// সমিতি শুরুর আগে কেউ সদস্য হতে পারে না — তাই বকেয়া গোনা
/// শুরু হয় সদস্যের যোগদানের তারিখ আর সমিতির শুরুর তারিখের
/// মধ্যে যেটা পরে, সেখান থেকে।
DateTime effectiveStart(DateTime joinDate, DateTime? branchStart) {
  if (branchStart == null) return joinDate;
  return branchStart.isAfter(joinDate) ? branchStart : joinDate;
}

/// এক মাসের প্রথম দিন থেকে আরেক মাসের প্রথম দিন পর্যন্ত
/// মাস গুনে — দুই প্রান্তের মাসই ধরা হয়।
int monthsBetweenInclusive(DateTime from, DateTime to) {
  final months = (to.year - from.year) * 12 + (to.month - from.month) + 1;
  return months > 0 ? months : 0;
}

/// কোনো সদস্যের মোট বকেয়া টাকা।
/// মাসিক দান × যত মাস পার হয়েছে − অনুমোদিত জমা।
int memberDues({
  required DateTime joinDate,
  required DateTime? branchStart,
  required int monthlyDonation,
  required int approvedTotal,
  DateTime? asOf,
}) {
  final now = asOf ?? DateTime.now();
  final months = monthsBetweenInclusive(effectiveStart(joinDate, branchStart), now);
  final expected = monthlyDonation * months;
  final rest = expected - approvedTotal;
  return rest > 0 ? rest : 0;
}
