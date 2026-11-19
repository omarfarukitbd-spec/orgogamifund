import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_strings.dart';
import '../../models/member_application.dart';
import '../../models/membership.dart';
import '../../routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/bn_digits.dart';

class ApplicationValidator {
  static bool isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  /// বাংলা অঙ্কেও চলে (M3) — যাচাইয়ের আগে ASCII-তে নেওয়া হয়।
  static bool isPhone(String value) {
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(toAsciiDigits(value));
  }

  static bool isNid(String value) {
    final ascii = toAsciiDigits(value);
    if (!RegExp(r'^\d+$').hasMatch(ascii)) return false;
    return ascii.length == 10 || ascii.length == 13 || ascii.length == 17;
  }

  static String? validateInfo({
    required String name,
    required String phone,
    required String address,
    required String emergencyName,
    required String emergencyPhone,
    required String? branchId,
    required String nid,
  }) {
    if (name.isEmpty) return 'নাম লিখুন';
    if (!isPhone(phone)) return 'সঠিক মোবাইল নম্বর দিন — ০১ দিয়ে শুরু, ১১ সংখ্যা';
    if (address.isEmpty) return 'ঠিকানা লিখুন';
    if (emergencyName.isEmpty) return 'জরুরি যোগাযোগের নাম লিখুন';
    if (!isPhone(emergencyPhone)) return 'জরুরি যোগাযোগের সঠিক মোবাইল নম্বর দিন';
    if (branchId == null) return 'কোন সমিতিতে যোগ দিতে চান, বেছে নিন';
    if (!isNid(nid)) return 'সঠিক এনআইডি নম্বর দিন — ১০, ১৩ বা ১৭ সংখ্যা';
    return null;
  }

  static String? validateAccount({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (!isEmail(email)) return 'সঠিক ইমেইল দিন';
    if (password.length < 6) return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
    if (password != confirmPassword) return 'দুটো পাসওয়ার্ড মেলেনি';
    return null;
  }
}

class ApplicationSubmitHandler {
  /// আবেদন জমা দেওয়া। অ্যাকাউন্ট আগেই খোলা থাকে (B1:
  /// অ্যাকাউন্ট-আগে প্রবাহ) — এখানে আর অ্যাকাউন্ট বানানো
  /// হয় না, আর জমা ব্যর্থ হলে অ্যাকাউন্ট মুছেও ফেলা হয় না
  /// (B2): ব্যর্থ হলে ব্যবহারকারী একই অ্যাকাউন্ট দিয়ে
  /// আবার চেষ্টা করতে পারে, অপেক্ষার পাতা থেকেও আবেদনে
  /// ফেরা যায়।
  static Future<void> submit({
    required FirestoreService store,
    required String name,
    required String phone,
    required String address,
    required String emergencyName,
    required String emergencyPhone,
    required String branchId,
    required DateTime joinDate,
    required String nid,
    // ছবি ঐচ্ছিক (M7) — ছবি ছাড়াই আবেদন জমা হয়।
    required Uint8List? photoBytes,
    required Uint8List? nidFrontBytes,
    required Uint8List? nidBackBytes,
  }) async {
    final current = AuthService().firebaseUser;
    if (current == null) {
      throw Exception('অ্যাকাউন্ট খোলা হয়নি — প্রথম ধাপে অ্যাকাউন্ট খুলুন');
    }
    final uid = current.uid;

    // B2: আগের পরীক্ষায় permission-denied হলে "সদস্যপদ নেই"
    // ধরা হয় — না থাকা ডকুমেন্টের পরীক্ষা যেন আবেদন আটকায় না।
    Membership? existing;
    try {
      existing = await store.getMembership(uid, branchId);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      existing = null;
    }
    if (existing?.isApproved ?? false) {
      throw Exception(AppStrings.alreadyMemberOfBranch);
    }
    if (existing?.isPending ?? false) {
      throw Exception(AppStrings.alreadyAppliedForBranch);
    }

    // M3: ফোন আর এনআইডি ASCII-তে স্বাভাবিক করে রাখা হয় —
    // বাংলা অঙ্কে লিখলেও সংরক্ষিত মান একই রকম থাকে।
    final application = MemberApplication(
      id: '',
      name: name,
      phone: toAsciiDigits(phone),
      address: address,
      emergencyContactName: emergencyName,
      emergencyContactPhone: toAsciiDigits(emergencyPhone),
      branchId: branchId,
      joinDate: joinDate,
      nidNumber: toAsciiDigits(nid),
      applicantUid: uid,
      email: current.email,
      requestedAt: DateTime.now(),
    );

    await store.submitMemberApplication(
      application: application,
      photoBytes: photoBytes,
      nidFrontBytes: nidFrontBytes,
      nidBackBytes: nidBackBytes,
    );

    await AppRouter.refreshAuth();
  }
}
