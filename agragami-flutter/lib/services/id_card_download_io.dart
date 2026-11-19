import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// মোবাইল/কম্পিউটারে PNG শেয়ার করা (F24) — আগের কোড
/// ছবিটা অস্থায়ী ফোল্ডারে (systemTemp) লিখে তার ভেতরের
/// পথ সফল হিসেবে দেখাত — ব্যবহারকারী ওই ফাইল খুঁজেই
/// পেত না। এখন শেয়ার মেনু খোলে — সেখান থেকে গ্যালারিতে
/// রাখা, হোয়াটসঅ্যাপে পাঠানো বা যেকোনো অ্যাপে দেওয়া যায়।
Future<String> savePngBytes(Uint8List bytes, String fileName) async {
  await Share.shareXFiles(
    [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
    subject: fileName,
  );
  return 'শেয়ার মেনু খোলা হয়েছে — ছবিটি গ্যালারিতে রাখতে বা পাঠাতে পারেন।';
}
