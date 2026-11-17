import 'dart:convert';
import 'dart:typed_data';

import 'dart:html' as html;

/// ওয়েবে PNG নামানো — ব্রাউজারের ডাউনলোড দিয়ে ফাইলটি নামে।
Future<String> savePngBytes(Uint8List bytes, String fileName) async {
  final url = 'data:image/png;base64,${base64Encode(bytes)}';
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  anchor.remove();
  return '$fileName ডাউনলোড হচ্ছে।';
}
