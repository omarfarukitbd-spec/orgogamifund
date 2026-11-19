import 'bn_digits.dart';

/// শেয়ার্ড ফর্ম যাচাই — লগইন আর প্রথম সেটআপে ইমেইল
/// যাচাইয়ের নিয়ম আলাদা ছিল (m2), এখন একটাই নিয়ম।
bool isValidEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
}

/// টাকার পরিমাণ যাচাই — সমিতি খোলা আর বদলানো দুই
/// ডায়ালগেই একই নিয়ম (m10)। ০ বৈধ — দান ছাড়া সমিতি
/// হতে পারে, আর ০ দিয়ে খোলা সমিতি পরে বদলানো যায়।
/// বাংলা অঙ্কও চলে।
String? validateAmount(String? value, {String emptyMessage = 'পরিমাণ লিখুন'}) {
  if (value == null || value.trim().isEmpty) return emptyMessage;
  final n = parseAmount(value);
  if (n == null || n < 0) return 'সঠিক টাকা লিখুন';
  return null;
}

/// মাসের দিন (১–৩১) যাচাই — মাসিক জমার শেষ তারিখের জন্য।
String? validateDueDay(String? value) {
  if (value == null || value.trim().isEmpty) return 'দিন লিখুন (১–৩১)';
  final n = parseAmount(value);
  if (n == null || n < 1 || n > 31) return '১ থেকে ৩১-এর মধ্যে দিন';
  return null;
}
