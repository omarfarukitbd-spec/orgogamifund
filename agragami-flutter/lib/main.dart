import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

/// অগ্রগামী ফান্ড — ধাপ ৩।
/// ডিফল্ট ভাষা বাংলা। পুরোনো Kotlin অ্যাপের ডিজাইন কপি করা হয়নি,
/// পুরোনো কোডও ছোঁয়া হয়নি — এটা আলাদা Flutter প্রজেক্ট।
/// Firebase কনফিগ বসানো আছে (lib/firebase_options.dart) —
/// চালু না হলে অ্যাপ তবু খুলবে, লগইন আর Firestore-এর কাজ হবে না।
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.instance.init();
  } catch (_) {
    // Firebase চালু হয়নি — অ্যাপ তবু খুলবে, Firebase-এর কাজ পরে হবে।
  }
  // গুগল দিয়ে ঢোকা তৈরি রাখা — না হলে (যেমন iPhone-এ plist
  // নেই) চুপচাপ বাদ যায়, ইমেইল দিয়ে ঢোকা তখনো চলবে।
  try {
    await AuthService().initGoogleSignIn();
  } catch (_) {}
  runApp(const ProviderScope(child: AgragamiFundApp()));
}

class AgragamiFundApp extends StatelessWidget {
  const AgragamiFundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'অগ্রগামী ফান্ড',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      // বাংলা লেখা ঠিকভাবে দেখাতে locale ঠিক করা আছে।
      // flutter_localizations ছাড়া বাংলা locale-এ
      // MaterialLocalizations পাওয়া যায় না, তাই TextField-ওয়ালা
      // স্ক্রিনে লাল ভুল দেখাতো — এটা সেই ঠিক করা।
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('bn', 'BD'),
      supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
    );
  }
}
