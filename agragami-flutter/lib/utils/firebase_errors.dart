import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// Firebase/State ভুলকে সৎ বাংলা বার্তায় বদলানো (m1)।
/// আগে সব submit handler `catch (_)` দিয়ে একই "নেট দেখে
/// আবার চেষ্টা করুন" দেখাত — নিয়মে বাধা, ইনডেক্স না থাকা,
/// আর নেট না থাকা আলাদা করা যেত না। এখন কোড অনুযায়ী
/// আসল কারণ দেখানো হয়, আর কাঁচা ভুল debugPrint-এ যায়।
String firebaseErrorMessage(
  Object error, {
  String fallback = 'কাজটি হয়নি — আবার চেষ্টা করুন',
}) {
  debugPrint('অপারেশন ব্যর্থ: $error');
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'অনুমতি নেই — অ্যাডমিনের সাথে যোগাযোগ করুন',
      'failed-precondition' =>
        'ডেটাবেসের ইনডেক্স বসানো হয়নি — অ্যাডমিনকে জানান',
      'unavailable' => 'নেট নেই — নেট দেখে আবার চেষ্টা করুন',
      'not-found' => 'তথ্যটি পাওয়া যায়নি — তালিকা থেকে আবার খুলে দেখুন',
      'already-exists' => 'এটা আগেই আছে',
      'cancelled' => 'কাজটি বাতিল হয়েছে — আবার চেষ্টা করুন',
      'deadline-exceeded' => 'সময় শেষ হয়ে গেছে — আবার চেষ্টা করুন',
      _ => '$fallback (${error.code})',
    };
  }
  if (error is UploadFailedException) return error.message;
  if (error is StateError) {
    return switch (error.message) {
      'already-reviewed' => 'এটা আগেই যাচাই করা হয়েছে',
      'already-member' => 'আপনি এই সমিতির সদস্য',
      'payment-not-found' => 'জমাটি পাওয়া যায়নি — তালিকা থেকে আবার খুলে দেখুন',
      'loan-not-found' => 'ঋণটি পাওয়া যায়নি — তালিকা থেকে আবার খুলে দেখুন',
      'overpayment' => 'বাকির চেয়ে বেশি লেখা হয়েছে — আবার দেখুন',
      'method-in-use' => 'এই মাধ্যম দিয়ে জমা আছে — মুছা যাবে না',
      'loan-has-repayments' =>
        'কিস্তি জমা আছে এমন ঋণ মুছা যাবে না',
      'amount-below-repaid' =>
        'ফেরত দেওয়া টাকার চেয়ে কম লেখা যাবে না',
      // Phase 6: শাখা অ্যাডমিন বানানো/সরানোর রক্ষা।
      'user-not-found' => 'এই সদস্যের লগইন প্রোফাইল পাওয়া যায়নি — আবার চেষ্টা করুন',
      'cannot-change-super-admin' => 'সুপার অ্যাডমিনের রোল বদলানো যায় না',
      'cannot-change-self' => 'নিজের রোল নিজে বদলানো যায় না',
      'user-not-approved' => 'এই সদস্যের অ্যাকাউন্ট এখনো অনুমোদিত নয়',
      'already-branch-admin' => 'এই সদস্য ইতিমধ্যে এই সমিতির অ্যাডমিন',
      'admin-of-other-branch' => 'এই সদস্য অন্য একটি সমিতির অ্যাডমিন',
      'not-branch-admin' => 'এই সদস্য এই সমিতির অ্যাডমিন নন',
      'member-no-branch' => 'এই সদস্যের সমিতি জানা নেই — সমিতি ঠিক করে আবার চেষ্টা করুন',
      _ => fallback,
    };
  }
  return fallback;
}
