import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';

/// Firebase-এর সাথে সংযোগের একমাত্র জায়গা।
/// আগের Firebase প্রজেক্ট ogrogami-fund-ই ব্যবহার হবে।
/// কনফিগ lib/firebase_options.dart আর android/app/google-services.json-এ আছে।

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _ready = false;
  bool get isReady => _ready;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get db => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// অ্যাপ চালুর সময় একবার ডাকতে হবে।
  /// কনফিগ না থাকলে বা নেট না থাকলে ব্যর্থ হবে — তখন অ্যাপ
  /// তবু খুলবে, Firebase-এর কাজ হবে না (main.dart-এ ধরা আছে)।
  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    db.settings = const Settings(persistenceEnabled: true);
    _ready = true;
  }
}

/// Firestore কালেকশনের নাম — আগের Kotlin অ্যাপের নামের সাথে
/// একই রাখা হয়েছে, যাতে পুরোনো ডেটা বদলাতে না হয়।
class Collections {
  static const String branches = 'branches';
  static const String members = 'members';
  /// একজনের এক সমিতির সদস্যপদ — id: `${userId}_${branchId}`।
  static const String memberships = 'memberships';
  static const String memberApplications = 'memberApplications';
  static const String payments = 'payments';
  static const String paymentMethods = 'paymentMethods';
  static const String expenses = 'expenses';
  static const String loans = 'loans';
  static const String users = 'users';
  static const String notices = 'notices';
  static const String committee = 'committee';
  static const String auditLogs = 'auditLogs';
}
