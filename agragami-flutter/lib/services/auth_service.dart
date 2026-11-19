import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import 'firebase_service.dart';
import 'firestore_service.dart';

/// গুগল দিয়ে ঢোকার ভুলগুলোর বাংলা বার্তা।
String googleSignInErrorMessage(Object e) {
  debugPrint('Google Sign-In caught error: $e');
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

  /// লাইভ ব্যবহারকারী স্ট্রিম — Auth বদলালে সংশ্লিষ্ট users
  /// ডকুমেন্টের snapshots() শোনা হয়, যাতে অ্যাডমিন অনুমোদন
  /// দিলে আবার লগইন না করেই অ্যাপ তা জেনে যায় (B3)।
  /// asyncExpand আগের ভেতরের স্ট্রিম বাতিল করে দেয় —
  /// rxdart-এর switchMap-এর মতোই আচরণ, নতুন ডিপেন্ডেন্সি ছাড়া।
  /// ডকুমেন্ট না থাকলে null ফেরে — কখনো মনগড়া ইউজার বানানো
  /// হয় না; ডকুমেন্ট বানায় শুধু সাইন-আপ / গুগল সাইন-ইন /
  /// সেটআপের স্পষ্ট ফ্লো (M9)। Firestore পড়তে না পারলে স্ট্রিমে
  /// error যায়, যাতে UI "তথ্য পড়া যায়নি" দেখাতে পারে।
  Stream<AppUser?> watchCurrentUser() {
    return _fb.auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<AppUser?>.value(null);
      return _fb.db
          .collection(Collections.users)
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists && doc.data() != null
              ? AppUser.fromMap(user.uid, doc.data()!)
              : null);
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
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Account creation did not return a user.',
      );
    }
    // নতুন অ্যাকাউন্ট মানেই অনুমোদনের অপেক্ষায় — সরাসরি ঢুকতে পারবে না।
    await _store.createUserDoc(
      uid: user.uid,
      email: email,
    );
  }

  /// পাসওয়ার্ড ভুলে গেলে রিসেট লিংক পাঠানো (M10)।
  Future<void> sendPasswordResetEmail(String email) async {
    await _fb.auth.sendPasswordResetEmail(email: email);
  }

  /// গুগল দিয়ে ঢোকা — বেশিরভাগ ব্যবহারকারী এটাই ব্যবহার করবে।
  /// v7 API: initialize + authenticate (মোবাইল), ওয়েবে GIS বোতাম
  /// (renderButton) থেকে authenticationEvents আসে। দুই ফ্লো-ই
  /// authenticationEvents দিয়ে জানায় — তাই Firebase-এ ঢোকা
  /// শুধু লিসেনারের কাজ, signInWithGoogle শুধু UI চালায় (M2)।
  /// AuthService() প্রতিবার নতুন বানানো হয় বলে গুগলের অবস্থা
  /// static রাখা হয়েছে — নইলে এক স্ক্রিনের initialize
  /// আরেক স্ক্রিনে হারিয়ে যেতো।
  static bool _googleInitialized = false;
  static bool _googleInitFailed = false;

  /// গুগল সাইন-ইন চালু হয়েছে কি না — লগইন স্ক্রিন এটা দেখে
  /// গুগল বোতাম দেখাবে না লুকাবে ঠিক করে (m5: tri-state)।
  static bool get isGoogleSignInAvailable => _googleInitialized;
  static bool get isGoogleSignInFailed => _googleInitFailed;

  // নিচের কন্ট্রোলারগুলো অ্যাপ চলা পর্যন্ত বাঁচে — ইচ্ছা করেই
  // কখনো বন্ধ করা হয় না (অ্যাপ-লাইফটাইম সিঙ্গেলটন, m11)।
  static final StreamController<void> _googleStarted =
      StreamController<void>.broadcast();
  static final StreamController<void> _googleCompleted =
      StreamController<void>.broadcast();
  static final StreamController<Object> _googleErrors =
      StreamController<Object>.broadcast();

  /// গুগল সাইন-ইন শুরু হলে জানায় (ওয়েবে GIS বোতাম চাপলে বা
  /// মোবাইলে authenticate() থেকে ইভেন্ট এলে) — লগইন স্ক্রিন
  /// এটা শুনে লোডিং দেখায় (m12)।
  Stream<void> get googleSignInStarted => _googleStarted.stream;

  /// গুগল দিয়ে ঢোকা শেষ হলে (ডকুমেন্ট বসানোসহ) জানায় —
  /// রাউটার এটা শুনে গার্ড আবার পড়ে, যাতে নতুন ব্যবহারকারী
  /// অনুমোদনের অপেক্ষা বা আবেদনের পাতায় সঠিকভাবে যায়।
  Stream<void> get googleSignInCompleted => _googleCompleted.stream;

  /// ওয়েবের GIS বোতামে ভুল হলে এখানে আসে — লগইন স্ক্রিন
  /// এটা শুনে বাংলা বার্তা দেখায়।
  Stream<Object> get googleSignInErrors => _googleErrors.stream;

  /// অ্যাপ চালুর সময় একবার ডাকা হয় (main.dart থেকে)।
  /// গুগল সেটআপ না থাকলে (যেমন iPhone-এ plist নেই) ব্যর্থতা
  /// রেকর্ড করা হয় — ইমেইল দিয়ে ঢোকা তখনো চলবে, আর
  /// লগইন স্ক্রিন গুগল বোতামের বদলে জানিয়ে দেবে (m5)।
  Future<void> initGoogleSignIn() async {
    if (_googleInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: DefaultFirebaseOptions.googleServerClientId,
      );
    } catch (e) {
      // এই যন্ত্রে গুগল দিয়ে ঢোকা চালু হয়নি।
      _googleInitFailed = true;
      debugPrint('Google Sign-In init failed: $e');
      return;
    }
    _googleInitialized = true;
    _googleInitFailed = false;
    // অ্যাপ চলা পর্যন্ত শুনতে থাকে — বন্ধ করার দরকার নেই।
    GoogleSignIn.instance.authenticationEvents.listen(
      (event) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _googleStarted.add(null);
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
    try {
      await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (_) {
      // চুপচাপ ফেরানো না গেলে ব্যবহারকারী নিজে ঢুকবে।
    }
  }

  /// মোবাইলে (Android/iPhone) গুগল বোতাম চাপলে এটা চলে।
  /// ওয়েবে এটা চলে না — ওখানে GIS বোতাম (renderButton) ব্যবহার হয়।
  /// Firebase-এ ঢোকা শুধু authenticationEvents লিসেনারের কাজ (M2) —
  /// এখানে শুধু প্ল্যাটফর্ম UI চালু করে শেষ হওয়ার অপেক্ষা করা হয়।
  Future<void> signInWithGoogle() async {
    await initGoogleSignIn();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.providerConfigurationError,
      );
    }
    // ইভেন্ট মিস না হয় — authenticate() ডাকার আগেই শোনা শুরু।
    final completer = Completer<void>();
    final subDone = googleSignInCompleted.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });
    final subFailed = googleSignInErrors.listen((e) {
      if (!completer.isCompleted) completer.completeError(e);
    });
    try {
      await GoogleSignIn.instance.authenticate();
      await completer.future.timeout(const Duration(seconds: 30));
    } finally {
      await subDone.cancel();
      await subFailed.cancel();
    }
  }

  /// গুগল অ্যাকাউন্ট থেকে Firebase-এ ঢোকা।
  /// নতুন ব্যবহারকারী হলে users ডকুমেন্ট বানায় — রোল pending,
  /// অনুমোদন বাকি। গুগল দিয়ে কেউ অ্যাডমিন হতে পারবে না;
  /// রোল আসে শুধু Firestore ডকুমেন্ট থেকে (M6)।
  Future<void> _signInToFirebaseWithGoogle(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final cred = await _fb.auth.signInWithCredential(credential);
    final fbUser = cred.user;
    if (fbUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Google sign-in did not return a user.',
      );
    }
    final uid = fbUser.uid;
    final email = fbUser.email ?? account.email;
    final doc = await _fb.db.collection(Collections.users).doc(uid).get();
    if (!doc.exists) {
      await _store.createUserDoc(
        uid: uid,
        email: email,
      );
    }
    _googleCompleted.add(null);
  }

  /// প্রথম অ্যাডমিন বানানো — শুধু সেটআপের সময় একবার।
  /// অ্যাকাউন্ট খুলে users ডকুমেন্টে সুপার অ্যাডমিন হিসেবে বসানো হয়।
  /// ডকুমেন্ট বসাতে না পারলে অ্যাকাউন্ট মুছে ফেলা হয়, যাতে
  /// আধা তৈরি অ্যাকাউন্ট পড়ে না থাকে।
  ///
  /// সতর্কতা: শক্ত করা Firestore rules-এ (role == 'pending' ছাড়া
  /// users create নিষেধ) ক্লায়েন্ট থেকে superAdmin লেখা যায় না —
  /// প্রথম অ্যাডমিন Firebase Console / Admin SDK দিয়ে বানাতে হয়।
  /// /setup রাউট এখন fail-closed (B1): hasUsers প্রমাণিতভাবে
  /// false না হলে খোলেই না।
  Future<void> createFirstAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _fb.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Account creation did not return a user.',
      );
    }
    final uid = user.uid;
    try {
      await _store.createFirstAdminDoc(uid: uid, name: name, email: email);
    } catch (_) {
      try {
        await user.delete();
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
