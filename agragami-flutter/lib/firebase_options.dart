// Firebase কনফিগ — অগ্রগামী ফান্ড প্রজেক্ট (ogrogami-fund)।
// রিপো omarfarukitbd-spec/orgogamifund-এর google-services.json থেকে নেওয়া,
// পুরোনো Kotlin অ্যাপের Firebase প্রজেক্টের সাথে একই — তাই পুরোনো
// Firestore ডেটা যেমন আছে তেমনই ব্যবহার হবে।
// এই ফাইল .gitignore-এ আছে — রিপোতে তুলবেন না।
// iOS: রিপোতে GoogleService-Info.plist নেই, তাই iOS অপশন এখানে নেই।
// iPhone-এ চালাতে Firebase Console থেকে iOS অ্যাপ নিবন্ধন করে
// `flutterfire configure` চালাতে হবে।
// Web: Firebase Console-এ আলাদা Web অ্যাপ নিবন্ধিত নেই, তাই Web-এও
// Android অ্যাপের appId ব্যবহার করা হয়েছে — Auth/Firestore চলে,
// পরে `flutterfire configure` দিয়ে আসল Web appId বসানো যাবে।

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase-এর ডিফল্ট অপশন — প্ল্যাটফর্ম অনুযায়ী বেছে নেওয়া হয়।
class DefaultFirebaseOptions {
  /// গুগল সাইন-ইনের serverClientId — Android-এর google-services.json-এর
  /// type-3 (web) OAuth ক্লায়েন্ট। auth_service.dart এখান থেকে নেয়,
  /// যাতে ওয়েব আর মোবাইলের কনফিগ আলাদা হয়ে না যায় (M7)।
  static const String googleServerClientId =
      '1063848074047-ksr0cpftlh74bd30tqioj4blgm6vhst5.apps.googleusercontent.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS-এর Firebase কনফিগ এখনো বসানো হয়নি — '
          'Firebase Console থেকে iOS অ্যাপ নিবন্ধন করে '
          'GoogleService-Info.plist বসাতে হবে।',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS-এর Firebase কনফিগ বসানো হয়নি।');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows-এর Firebase কনফিগ বসানো হয়নি।');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux-এর Firebase কনফিগ বসানো হয়নি।');
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Fuchsia সমর্থিত নয়।');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXKSOPoAwbj8ZhxcWRyyAtszeW_e8k8QU',
    appId: '1:1063848074047:android:0e86f4e89e6bcd6c8a118a',
    messagingSenderId: '1063848074047',
    projectId: 'ogrogami-fund',
    storageBucket: 'ogrogami-fund.firebasestorage.app',
    databaseURL: 'https://ogrogami-fund-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXKSOPoAwbj8ZhxcWRyyAtszeW_e8k8QU',
    appId: '1:1063848074047:android:0e86f4e89e6bcd6c8a118a',
    messagingSenderId: '1063848074047',
    projectId: 'ogrogami-fund',
    authDomain: 'ogrogami-fund.firebaseapp.com',
    storageBucket: 'ogrogami-fund.firebasestorage.app',
    databaseURL: 'https://ogrogami-fund-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
