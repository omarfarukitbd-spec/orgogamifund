import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_strings.dart';
import '../../models/member_application.dart';
import '../../routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ApplicationValidator {
  static bool isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  static bool isPhone(String value) {
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(value);
  }

  static bool isNid(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) return false;
    return value.length == 10 || value.length == 13 || value.length == 17;
  }

  static String? validateInfo({
    required String name,
    required String phone,
    required String address,
    required String emergencyName,
    required String emergencyPhone,
    required String? branchId,
    required String nid,
    required bool needsAccount,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (name.isEmpty) return 'নাম লিখুন';
    if (!isPhone(phone)) return 'সঠিক মোবাইল নম্বর দিন — ০১ দিয়ে শুরু, ১১ সংখ্যা';
    if (address.isEmpty) return 'ঠিকানা লিখুন';
    if (emergencyName.isEmpty) return 'জরুরি যোগাযোগের নাম লিখুন';
    if (!isPhone(emergencyPhone)) return 'জরুরি যোগাযোগের সঠিক মোবাইল নম্বর দিন';
    if (branchId == null) return 'কোন সমিতিতে যোগ দিতে চান, বেছে নিন';
    if (!isNid(nid)) return 'সঠিক এনআইডি নম্বর দিন — ১০, ১৩ বা ১৭ সংখ্যা';
    if (needsAccount) {
      if (!isEmail(email)) return AppStrings.validEmail;
      if (password.length < 6) return AppStrings.passwordTooShort;
      if (password != confirmPassword) return AppStrings.passwordsDontMatch;
    }
    return null;
  }
}

class ApplicationSubmitHandler {
  static Future<void> submit({
    required String name,
    required String phone,
    required String address,
    required String emergencyName,
    required String emergencyPhone,
    required String branchId,
    required DateTime joinDate,
    required String nid,
    required bool needsAccount,
    required String email,
    required String password,
    required Uint8List photoBytes,
    required Uint8List nidFrontBytes,
    required Uint8List? nidBackBytes,
  }) async {
    final loggedInUid = AuthService().uidOrEmpty;
    if (loggedInUid.isNotEmpty) {
      final existing =
          await FirestoreService().getMembership(loggedInUid, branchId);
      if (existing?.isApproved ?? false) {
        throw Exception(AppStrings.alreadyMemberOfBranch);
      }
      if (existing?.isPending ?? false) {
        throw Exception(AppStrings.alreadyAppliedForBranch);
      }
    }

    final accountEmail =
        needsAccount ? email : AuthService().firebaseUser?.email;
    var createdAccount = false;
    String uid;

    final current = AuthService().firebaseUser;
    if (current != null) {
      uid = current.uid;
    } else {
      try {
        await AuthService().signUpWithEmail(email, password);
        createdAccount = true;
        uid = AuthService().uidOrEmpty;
        if (uid.isEmpty) throw Exception('no uid');
      } on FirebaseAuthException catch (e) {
        throw Exception(bengaliAuthErrorMessage(e));
      }
    }

    final application = MemberApplication(
      id: '',
      name: name,
      phone: phone,
      address: address,
      emergencyContactName: emergencyName,
      emergencyContactPhone: emergencyPhone,
      branchId: branchId,
      joinDate: joinDate,
      nidNumber: nid,
      applicantUid: uid,
      email: accountEmail,
      requestedAt: DateTime.now(),
    );

    try {
      await FirestoreService().submitMemberApplication(
        application: application,
        photoBytes: photoBytes,
        nidFrontBytes: nidFrontBytes,
        nidBackBytes: nidBackBytes,
      );
    } catch (_) {
      if (createdAccount) {
        try {
          await AuthService().firebaseUser?.delete();
        } catch (_) {}
      }
      throw Exception(AppStrings.applyFailedAfterAccount);
    }

    await AppRouter.refreshAuth();
  }
}
