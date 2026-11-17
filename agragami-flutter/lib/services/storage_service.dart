import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_service.dart';

/// ছবি আপলোড — সদস্যের ছবি, এনআইডির ছবি, খরচের রসিদ।
/// ফরম থেকে ছবি আসে bytes হিসেবে — মোবাইল, ওয়েব, কম্পিউটার
/// সব জায়গাতেই একইভাবে কাজ করে।
class StorageService {
  final FirebaseStorage _storage = FirebaseService.instance.storage;

  /// ছবির bytes সরাসরি Storage-এ তোলা — ওয়েবেও চলে।
  Future<String?> uploadBytes(String path, Uint8List bytes) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print('Firebase Storage upload failed: $e');
      return null;
    }
  }

  Future<String?> uploadMemberPhoto(String memberId, File file) async {
    try {
      final ref = _storage.ref().child('members/$memberId/photo.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print('Firebase Storage member photo upload failed: $e');
      return null;
    }
  }

  Future<String?> uploadNidPhoto(String memberId, File file, String side) async {
    try {
      final ref = _storage.ref().child('members/$memberId/nid_$side.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print('Firebase Storage NID photo upload failed: $e');
      return null;
    }
  }

  Future<String?> uploadExpenseReceipt(String expenseId, File file) async {
    try {
      final ref = _storage.ref().child('expenses/$expenseId/receipt.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print('Firebase Storage expense receipt upload failed: $e');
      return null;
    }
  }
}
