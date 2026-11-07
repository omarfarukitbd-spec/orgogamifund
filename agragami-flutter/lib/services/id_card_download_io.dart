import 'dart:io';
import 'dart:typed_data';

/// মোবাইল ও কম্পিউটারে PNG নামানো — অস্থায়ী ফোল্ডারে ফাইলটি লেখা হয়।
Future<String> savePngBytes(Uint8List bytes, String fileName) async {
  final dir = Directory.systemTemp;
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  return 'ছবিটি এখানে রাখা হয়েছে: ${file.path}';
}
