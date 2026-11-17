import 'dart:typed_data';

/// এই প্ল্যাটফর্মে PNG নামানো যায় না — এমন হলে এটা ডাকা হয়।
Future<String> savePngBytes(Uint8List bytes, String fileName) async {
  return 'এই ডিভাইসে ছবি হিসেবে নামানো যাচ্ছে না — PDF হিসেবে নিন।';
}
