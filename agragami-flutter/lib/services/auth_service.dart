import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import 'firebase_service.dart';
import 'firestore_service.dart';

/// গুগল দিয়ে ঢোকার ভুলগুলোর বাংলা বার্তা।
String googleSignInErrorMessage(Object e) {
  if (e is GoogleSignInException) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return AppStrings.googleCancelled;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
      case GoogleSignInExceptionCode.uiUnavailable:
        return AppStrings.googleNotAvailable;
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return AppStrings.loginWrong;
    }
  }
  if (e is FirebaseAuthException) return bengaliAuthErrorMessage(e);
  return AppStrings.loginWrong;
}

/// Firebase লগইনের ভুলগুলোর বাংলা বার্তা — লগইন, সাইন-আপ,
/// সেটআপ — সব জায়গায় একই ভাষা।
String bengaliAuthErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return AppStrings.emailInUse;
    case 'invalid-email':
      return AppStrings.validEmail;
    case 'weak-password':
      return AppStrings.passwordTooShort;
    case 'account-exists-with-different-credential':
      return AppStrings.googleAccountExistsDifferent;
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return AppStrings.loginWrong;
    case 'network-request-failed':
      return AppStrings.loginNoNetwork;
    case 'too-many-requests':
      return AppStrings.loginTooMany;
    case 'user-disabled':
      return 'এই অ্যাকাউন্ট বন্ধ আছে — অ্যাডমিনের সাথে যোগাযোগ করুন';
    default:
      return AppStrings.loginWrong;
  }
}

/// লগইন, লগআউট আর অনুমোদনের অবস্থা দেখার কাজ এখানে।
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.watchCurrentUser();
});

class AuthService {
  final FirebaseService _fb = FirebaseService.instance;
  final FirestoreService _store = FirestoreService();

  Stream<AppUser?> watchCurrentUser() {
    return _fb.auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _fb.db.collection(Collections.users).doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(user.uid, doc.data()!);
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _fb.auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final cred = await _fb.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // নতুন অ্যাকাউন্ট মানেই অনুমোদনের অপেক্ষায় — সরাসরি ঢুকতে পারবে না।
    await _store.createUserDoc(
      uid: cred.user!.uid,
      email: email,
    );
  }

  /// গুগল দিয়ে ঢোকা — বেশিরভাগ ব্যবহারকারী এটাই ব্যবহার করবে।
  /// v7 API: initialize + authenticate (মোবাইল), ওয়েবে GIS বোতাম
  /// (renderButton) থেকে authenticationEvents আসে।
  /// AuthService() প্রতিবার নতুন বানানো হয় বলে গুগলের অবস্থা
  /// static রাখা হয়েছে — নইলে এক স্ক্রিনের initialize
  /// আরেক স্ক্রিনে হারিয়ে যেতো।
  static bool _googleInitialized = false;
  static final StreamController<void> _googleCompleted =
      StreamController<void>.broadcast();
  static final StreamController<Object> _googleErrors =
      StreamController<Object>.broadcast();

  /// গুগল দিয়ে ঢোকা শেষ হলে (ডকুমেন্ট বসানোসহ) জানায় —
  /// রাউটার এটা শুনে গার্ড আবার পড়ে, যাতে নতুন ব্যবহারকারী
  /// অনুমোদনের অপেক্ষা বা আবেদনের পাতায় সঠিকভাবে যায়।
  Stream<void> get googleSignInCompleted => _googleCompleted.stream;

  /// ওয়েবের GIS বোতামে ভুল হলে এখানে আসে — লগইন স্ক্রিন
  /// এটা শুনে বাংলা বার্তা দেখায়।
  Stream<Object> get googleSignInErrors => _googleErrors.stream;

  /// অ্যাপ চালুর সময় একবার ডাকা হয় (main.dart থেকে)।
  /// গুগল সেটআপ না থাকলে (যেমন iPhone-এ plist নেই) চুপচাপ
  /// বাদ যায় — ইমেইল দিয়ে ঢোকা তখনো চলবে।
  Future<void> initGoogleSignIn() async {
    if (_googleInitialized) return;
    try {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
      // অ্যাপ চলা পর্যন্ত শুনতে থাকে — বন্ধ করার দরকার নেই।
      GoogleSignIn.instance.authenticationEvents.listen(
        (event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            try {
              await _signInToFirebaseWithGoogle(event.user);
            } catch (e) {
              // ওয়েব বোতামে ভুল হলে লগইন স্ক্রিনকে জানানো হয়।
              _googleErrors.add(e);
            }
          }
        },
        onError: (e) => _googleErrors.add(e),
      );
      // আগে গুগল দিয়ে ঢুকে থাকলে চুপচাপ ফিরিয়ে আনে।
      await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (_) {
      // এই যন্ত্রে গুগল দিয়ে ঢোকা চালু হয়নি।
    }
  }

  /// মোবাইলে (Android/iPhone) গুগল বোতাম চাপলে এটা চলে।
  /// ওয়েবে এটা চলে না — ওখানে GIS বোতাম (renderButton) ব্যবহার হয়।
  Future<void> signInWithGoogle() async {
    await initGoogleSignIn();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.providerConfigurationError,
      );
    }
    final account = await GoogleSignIn.instance.authenticate();
    await _signInToFirebaseWithGoogle(account);
  }

  /// গুগল অ্যাকাউন্ট থেকে Firebase-এ ঢোকা।
  /// নতুন ব্যবহারকারী হলে users ডকুমেন্ট বানায় — রোল সদস্য,
  /// অনুমোদন বাকি। গুগল দিয়ে কেউ অ্যাডমিন হতে পারবে না;
  /// প্রথম অ্যাডমিন শুধু /setup থেকেই হয়।
  Future<void> _signInToFirebaseWithGoogle(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final cred = await _fb.auth.signInWithCredential(credential);
    final uid = cred.user!.uid;
    final doc = await _fb.db.collection(Collections.users).doc(uid).get();
    if (!doc.exists) {
      await _store.createUserDoc(
        uid: uid,
        email: cred.user!.email ?? account.email,
      );
    }
    _googleCompleted.add(null);
  }

  /// প্রথম অ্যাডমিন বানানো — শুধু সেটআপের সময় একবার।
  /// অ্যাকাউন্ট খুলে users ডকুমেন্টে সুপার অ্যাডমিন হিসেবে বসানো হয়।
  /// ডকুমেন্ট বসাতে না পারলে অ্যাকাউন্ট মুছে ফেলা হয়, যাতে
  /// আধা তৈরি অ্যাকাউন্ট পড়ে না থাকে।
  Future<void> createFirstAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _fb.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    try {
      await _store.createFirstAdminDoc(uid: uid, name: name, email: email);
    } catch (_) {
      try {
        await cred.user!.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // গুগল থেকে বের হওয়া না গেলেও Firebase থেকে বের হতে হবে।
    }
    await _fb.auth.signOut();
  }

  User? get firebaseUser => _fb.auth.currentUser;

  /// এখন ঢুকে থাকা ব্যবহারকারীর uid — ঢুকে না থাকলে ফাঁকা।
  /// Firebase কনফিগ না থাকলে ভুল হবে না, ফাঁকা ফিরবে।
  String get uidOrEmpty {
    try {
      return _fb.auth.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }
}
