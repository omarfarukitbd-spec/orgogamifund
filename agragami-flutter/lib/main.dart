import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_strings.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

/// থিম মোড স্টেট প্রোভাইডার (সিস্টেম, লাইট, ডার্ক)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// ভাষা স্টেট প্রোভাইডার (বাংলা ডিফল্ট, ইংরেজি সমর্থিত)
final localeProvider =
    StateProvider<Locale>((ref) => const Locale('bn', 'BD'));

/// M11: বায়োমেট্রিক অ্যাপ-লক চালু আছে কি না — ডিফল্ট বন্ধ।
final biometricLockEnabledProvider = StateProvider<bool>((ref) => false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.instance.init();
  } catch (_) {}

  try {
    await AuthService().initGoogleSignIn();
  } catch (_) {}

  // M6: সংরক্ষিত সেটিংস চালুর আগেই পড়া হয় — থিম, ভাষা
  // আর লকের পছন্দ অ্যাপ বন্ধ করলেও মনে থাকে।
  final settings = await SettingsService.load();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => settings.themeMode),
        localeProvider.overrideWith((ref) => settings.locale),
        biometricLockEnabledProvider.overrideWith(
          (ref) => settings.biometricLockEnabled,
        ),
      ],
      child: const AgragamiFundApp(),
    ),
  );
}

class AgragamiFundApp extends ConsumerStatefulWidget {
  const AgragamiFundApp({super.key});

  @override
  ConsumerState<AgragamiFundApp> createState() => _AgragamiFundAppState();
}

class _AgragamiFundAppState extends ConsumerState<AgragamiFundApp>
    with WidgetsBindingObserver {
  /// অ্যাপ সত্যিই ব্যাকগ্রাউন্ডে গিয়েছিল কি না — শুধু
  /// inactive হওয়া (যেমন বায়োমেট্রিক প্রম্পট) লকের কারণ নয়।
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // M11: লক চালু থাকলে অ্যাপ চালুর সময় লক অবস্থায় শুরু —
    // রাউটার গার্ড শুধু ঢুকে থাকা অনুমোদিত ব্যবহারকারীকে /lock-এ
    // পাঠায়, লগইন/আবেদনের পাতা আটকায় না।
    if (ref.read(biometricLockEnabledProvider)) {
      AppRouter.lockApp();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
      return;
    }
    // ব্যাকগ্রাউন্ড থেকে ফিরলে অনুমোদনের অবস্থা আবার পড়া (B3) —
    // অ্যাডমিন এর মধ্যে অনুমোদন দিলে অ্যাপ তা জেনে যাবে।
    if (state == AppLifecycleState.resumed) {
      AppRouter.refreshAuth();
      // M11: ব্যাকগ্রাউন্ড থেকে ফিরলে আবার লক — তবে আনলকের
      // ঠিক পরের কয়েক সেকেন্ড নয় (বায়োমেট্রিক প্রম্পট নিজেই
      // কিছু যন্ত্রে pause/resume ঘটায়)।
      final wasPaused = _wasPaused;
      _wasPaused = false;
      if (!wasPaused) return;
      if (!ref.read(biometricLockEnabledProvider)) return;
      final lastUnlock = AppRouter.lastUnlockAt;
      if (lastUnlock != null &&
          DateTime.now().difference(lastUnlock) <
              const Duration(seconds: 5)) {
        return;
      }
      AppRouter.lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    AppStrings.currentLocale = locale;

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: locale,
      supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
    );
  }
}
