import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/cloudinary_config.dart';

/// ছবি আপলোড করতে না পারলে এই ব্যতিক্রম ছোড়া হয়।
/// আগে ব্যর্থ হলে নিঃশব্দে null ফিরত — আবেদন/খরচ/নোটিশ
/// ছবি ছাড়াই জমা হয়ে যেত আর ব্যবহারকারী জানতেও পারত না।
/// এখন ব্যর্থতা দেখা যায়, যাতে ব্যবহারকারী ছবি ছাড়া
/// জমা দেবে না আবার চেষ্টা করবে — সেটা বেছে নিতে পারে।
class UploadFailedException implements Exception {
  final String message;
  const UploadFailedException([
    this.message = 'ছবি আপলোড হয়নি — আবার চেষ্টা করুন',
  ]);

  @override
  String toString() => message;
}

/// ছবি আপলোড — সদস্যের ছবি, এনআইডির ছবি, খরচের রসিদ, নোটিশের ছবি।
/// ফরম থেকে ছবি আসে bytes হিসেবে — মোবাইল, ওয়েব, কম্পিউটার
/// সব জায়গাতেই একইভাবে কাজ করে।
///
/// আপলোড যায় Cloudinary-র ফ্রি টিয়ারে, unsigned upload preset দিয়ে
/// (Firebase Storage এই প্রজেক্টে নেই — Spark প্ল্যানে বাকেট বানানো যায় না)।
/// অ্যাপে কোনো API key/secret থাকে না; শুধু cloud name আর preset নাম
/// ([CloudinaryConfig]) লাগে। আপলোড সফল হলে Cloudinary-র `secure_url`
/// ফেরত আসে — সেই URL-ই Firestore-এ photoUrl/attachmentUrl হিসেবে জমা হয়।
///
/// - [CloudinaryConfig] এখনো placeholder থাকলে আপলোড স্কিপ করে null ফেরায় —
///   ফর্ম তবুও জমা হয়; UI "ছবি আপলোড এখনো সেট করা হয়নি" জানিয়ে দেয়।
/// - সেটআপ থাকার পর আপলোড ব্যর্থ হলে [UploadFailedException] ছোড়া হয়,
///   কখনো নিঃশব্দে null ফেরত দেওয়া হয় না।
class StorageService {
  static const _uploadTimeout = Duration(seconds: 60);

  /// ছবির bytes Cloudinary-তে তোলা — ওয়েবেও চলে।
  /// [path] শুধু ফাইলের নাম হিসেবে ব্যবহার হয় (যেমন 'photo.jpg')।
  /// সফল হলে ছবির URL, সেটআপ না থাকলে null; ব্যর্থ হলে
  /// [UploadFailedException] ছোড়ে।
  Future<String?> uploadBytes(String path, Uint8List bytes) async {
    if (!CloudinaryConfig.isConfigured) {
      debugPrint('Cloudinary সেট করা হয়নি — ছবি আপলোড স্কিপ: $path');
      return null;
    }
    final fileName = path.split('/').last;
    try {
      final request = http.MultipartRequest('POST', CloudinaryConfig.uploadUri)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );
      final streamed = await request.send().timeout(_uploadTimeout);
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        debugPrint('Cloudinary আপলোড ব্যর্থ (${streamed.statusCode}): $body');
        throw const UploadFailedException(
          'ছবি আপলোড হয়নি — সার্ভার ত্রুটি, আবার চেষ্টা করুন',
        );
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw const UploadFailedException(
          'ছবি আপলোড হয়নি — ছবির লিংক পাওয়া যায়নি',
        );
      }
      return url;
    } on UploadFailedException {
      rethrow;
    } catch (e) {
      debugPrint('Cloudinary আপলোড ব্যর্থ: $e');
      throw const UploadFailedException(
        'ছবি আপলোড হয়নি — ইন্টারনেট দেখে আবার চেষ্টা করুন',
      );
    }
  }

  Future<String?> uploadMemberPhoto(String memberId, File file) async {
    final bytes = await file.readAsBytes();
    return uploadBytes('members/$memberId/photo.jpg', bytes);
  }

  Future<String?> uploadNidPhoto(
    String memberId,
    File file,
    String side,
  ) async {
    final bytes = await file.readAsBytes();
    return uploadBytes('members/$memberId/nid_$side.jpg', bytes);
  }

  Future<String?> uploadExpenseReceipt(String expenseId, File file) async {
    final bytes = await file.readAsBytes();
    return uploadBytes('expenses/$expenseId/receipt.jpg', bytes);
  }
}
