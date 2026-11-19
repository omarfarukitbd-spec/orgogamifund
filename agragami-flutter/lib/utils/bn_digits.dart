import 'package:flutter/services.dart';

/// বাংলা (আর আরবি) সংখ্যাকে ASCII সংখ্যায় বদলানো (M3)।
/// বাংলা কিবোর্ড দিয়ে লেখা '১০০০' বা '০১৭১২৩৪৫৬৭৮' int.tryParse
/// আর `\d` রেগেক্সে ধরা পড়ে না (Dart-এর `\d` শুধু ASCII) — তাই
/// সব সংখ্যার ক্ষেত্রে লেখার সীমায় (boundary) একবার স্বাভাবিক
/// করা হয়, যাতে যাচাই আর সংরক্ষণ দুটোই ঠিক থাকে।

const _bnDigits = '০১২৩৪৫৬৭৮৯';
const _arDigits = '٠١٢٣٤٥٦٧٨٩';
const _asciiDigits = '0123456789';

/// শুধু অঙ্ক বদলায়, অক্ষর-সংখ্যা একই থাকে — ফলে TextField-এ
/// লেখার সময় কার্সরের অবস্থান বদলায় না।
String convertDigitsToAscii(String s) {
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    final bnIndex = _bnDigits.indexOf(ch);
    if (bnIndex >= 0) {
      buf.write(_asciiDigits[bnIndex]);
      continue;
    }
    final arIndex = _arDigits.indexOf(ch);
    if (arIndex >= 0) {
      buf.write(_asciiDigits[arIndex]);
      continue;
    }
    buf.write(ch);
  }
  return buf.toString();
}

/// সংখ্যা হিসেবে পড়ার মতো করে স্বাভাবিক করা: বাংলা/আরবি
/// অঙ্ক ASCII করা হয়, কমা আর স্পেস বাদ দেওয়া হয়।
String toAsciiDigits(String s) {
  return convertDigitsToAscii(s).replaceAll(RegExp(r'[,\s]'), '');
}

/// বাংলা অঙ্কসহ লেখা থেকে সংখ্যা পড়া — '১,০০০' → 1000।
/// পড়া না গেলে null।
int? parseAmount(String s) => int.tryParse(toAsciiDigits(s.trim()));

/// TextField-এ লেখার সাথে সাথে বাংলা অঙ্ক ASCII-তে বদলে দেয়।
/// FilteringTextInputFormatter.digitsOnly-এর বদলে এটা ব্যবহার
/// করতে হয় — digitsOnly বাংলা অঙ্ক টাইপই করতে দেয় না।
class BnDigitsInputFormatter extends TextInputFormatter {
  const BnDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = convertDigitsToAscii(newValue.text);
    if (converted == newValue.text) return newValue;
    return newValue.copyWith(text: converted);
  }
}

/// শুধু সংখ্যা নেওয়ার ফরম্যাটার — বাংলা অঙ্ক টাইপ করলে
/// ASCII-তে বদলে নেয়, অন্য অক্ষর বাদ দেয়।
class BnDigitsOnlyFormatter extends TextInputFormatter {
  const BnDigitsOnlyFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = convertDigitsToAscii(newValue.text);
    // F19: কার্সর ধরে রাখা — অঙ্ক বদল ১:১, কিন্তু বাদ
    // পড়া অক্ষর কার্সর সরিয়ে দেয়। কার্সরের আগের অক্ষর
    // গুনে কতটা অঙ্ক টিকেছে, সেটাই নতুন অবস্থান।
    int mapOffset(int offset) {
      var kept = 0;
      final limit = offset.clamp(0, converted.length);
      for (var i = 0; i < limit; i++) {
        final code = converted.codeUnitAt(i);
        if (code >= 0x30 && code <= 0x39) kept++;
      }
      return kept;
    }

    final digitsOnly = converted.replaceAll(RegExp(r'[^0-9]'), '');
    final selection = newValue.selection;
    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection(
        baseOffset: mapOffset(selection.baseOffset),
        extentOffset: mapOffset(selection.extentOffset),
      ),
      composing: TextRange.empty,
    );
  }
}
