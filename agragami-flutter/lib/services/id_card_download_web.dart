import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// ওয়েবে PNG নামানো — ব্রাউজারের ডাউনলোড দিয়ে ফাইলটি নামে।
/// Phase 5 (F34): dart:html-এর বদলে package:web ব্যবহার হয়
/// (dart:html আর রক্ষণাবেক্ষণ হয় না)। base64 data-URL-এর
/// বদলে Blob + object URL ব্যবহার হয় — বড় ছবিতেও নিরাপদ।
Future<String> savePngBytes(Uint8List bytes, String fileName) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  try {
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..click();
    anchor.remove();
  } finally {
    web.URL.revokeObjectURL(url);
  }
  return '$fileName ডাউনলোড হচ্ছে।';
}
