import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_strings.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

/// থিম মোড স্টেট প্রোভাইডার (সিস্টেম, লাইট, ডার্ক)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// ভাষা স্টেট প্রোভাইডার (বাংলা ডিফল্ট, ইংরেজি সমর্থিত)
final localeProvider = StateProvider<Locale>((ref) => const Locale('bn', 'BD'));

/// M11: বায়োমেট্রিক অ্যাপ-লক চালু আছে কি না — ডিফল্ট বন্ধ।
final biometricLockEnabledProvider = StateProvider<bool>((ref) => false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // m13: ধরা না পড়া ভুল লগ করা — নইলে রিলিজে অ্যাপ
  // হঠাৎ বন্ধ হয়ে যেত, কেন বোঝা যেত না।
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exception}');
    FlutterError.presentError(details);
  };
  // বিল্ডের ভুলে ধূসর পর্দার বদলে বন্ধুত্বপূর্ণ বার্তা।
  ErrorWidget.builder = (details) => _StartupErrorWidget(
        message: AppStrings.somethingWrong,
        body: AppStrings.restartAppHint,
        detail: kDebugMode ? details.exception.toString() : null,
      );
  await runZonedGuarded<Future<void>>(() async {
    // M3: Firebase চালু না হলে ভুলটা ধরে রাখা হয় — অ্যাপ
    // তবু খুলে খালি তালিকা দেখায় না, ভুলের পাতা দেখায়।
    Object? firebaseError;
    try {
      await FirebaseService.instance.init();
    } catch (e) {
      firebaseError = e;
      debugPrint('Firebase init failed: $e');
    }

    try {
      await AuthService.instance.initGoogleSignIn();
    } catch (e) {
      // গুগল দিয়ে ঢোকা না হলেও ইমেইল দিয়ে ঢোকা যায় —
      // ভুলটা শুধু লগ করা হয়, অ্যাপ আটকায় না।
      debugPrint('Google sign-in init failed: $e');
    }

    // M6: সংরক্ষিত সেটিংস চালুর আগেই পড়া হয় — থিম, ভাষা
    // আর লকের পছন্দ অ্যাপ বন্ধ করলেও মনে থাকে।
    final settings = await SettingsService.load();
    final readNotificationIds = await SettingsService.loadReadNotificationIds();
    AppStrings.currentLocale = settings.locale;

    runApp(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => settings.themeMode),
          localeProvider.overrideWith((ref) => settings.locale),
          biometricLockEnabledProvider.overrideWith(
            (ref) => settings.biometricLockEnabled,
          ),
          readNotificationIdsProvider.overrideWith(
            (ref) => readNotificationIds,
          ),
        ],
        child: AgragamiFundApp(initError: firebaseError),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught async error: $error');
  });
}

class AgragamiFundApp extends ConsumerStatefulWidget {
  /// M3: Firebase চালুর ভুল — null না হলে ভুলের পাতা দেখায়।
  final Object? initError;

  const AgragamiFundApp({super.key, this.initError});

  @override
  ConsumerState<AgragamiFundApp> createState() => _AgragamiFundAppState();
}

class _AgragamiFundAppState extends ConsumerState<AgragamiFundApp>
    with WidgetsBindingObserver {
  /// অ্যাপ সত্যিই ব্যাকগ্রাউন্ডে গিয়েছিল কি না — শুধু
  /// inactive হওয়া (যেমন বায়োমেট্রিক প্রম্পট) লকের কারণ নয়।
  bool _wasPaused = false;

  /// M3: চালুর ভুলের বর্তমান অবস্থা — আবার চেষ্টায়
  /// সফল হলে null হয়ে সাধারণ অ্যাপ দেখায়।
  Object? _initError;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _initError = widget.initError;
    WidgetsBinding.instance.addObserver(this);
    // M11: লক চালু থাকলে অ্যাপ চালুর সময় লক অবস্থায় শুরু —
    // রাউটার গার্ড শুধু ঢুকে থাকা অনুমোদিত ব্যবহারকারীকে /lock-এ
    // পাঠায়, লগইন/আবেদনের পাতা আটকায় না। চালুর ভুল থাকলে
    // লক লাগানো হয় না — ভুলের পাতাই দেখা যাবে।
    if (_initError == null && ref.read(biometricLockEnabledProvider)) {
      AppRouter.lockApp();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// M3: Firebase আবার চালুর চেষ্টা — সফল হলে সাধারণ অ্যাপ,
  /// ব্যর্থ হলে নতুন ভুলসহ একই পাতা।
  Future<void> _retryInit() async {
    setState(() => _retrying = true);
    try {
      await FirebaseService.instance.init();
      if (!mounted) return;
      setState(() {
        _initError = null;
        _retrying = false;
      });
    } catch (e) {
      debugPrint('Firebase init retry failed: $e');
      if (!mounted) return;
      setState(() {
        _initError = e;
        _retrying = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
      return;
    }
    // ব্যাকগ্রাউন্ড থেকে ফিরলে অনুমোদনের অবস্থা আবার পড়া (B3) —
    // অ্যাডমিন এর মধ্যে অনুমোদন দিলে অ্যাপ তা জেনে যাবে।
    // চালুর ভুল থাকলে রিফ্রেশ করা হয় না — Firebase-ই নেই।
    if (state == AppLifecycleState.resumed) {
      if (_initError == null) AppRouter.refreshAuth();
      // M11: ব্যাকগ্রাউন্ড থেকে ফিরলে আবার লক — তবে আনলকের
      // ঠিক পরের কয়েক সেকেন্ড নয় (বায়োমেট্রিক প্রম্পট নিজেই
      // কিছু যন্ত্রে pause/resume ঘটায়)।
      final wasPaused = _wasPaused;
      _wasPaused = false;
      if (!wasPaused) return;
      if (_initError != null) return;
      if (!ref.read(biometricLockEnabledProvider)) return;
      final lastUnlock = AppRouter.lastUnlockAt;
      if (lastUnlock != null &&
          DateTime.now().difference(lastUnlock) < const Duration(seconds: 5)) {
        return;
      }
      AppRouter.lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    // M4: ভাষা বদলালে স্ট্যাটিক স্ট্রিংসও বদলায় — build-এর
    // ভেতরে সাইড-এফেক্ট না করে listener-এ বসানো হয়।
    ref.listen(localeProvider, (_, next) {
      AppStrings.currentLocale = next;
    });

    // M3: Firebase চালু হয়নি — ভুলের পাতা, আবার চেষ্টার বোতামসহ।
    if (_initError != null) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: locale,
        supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
        home: Scaffold(
          body: SafeArea(
            child: _StartupErrorWidget(
              message: AppStrings.startupErrorTitle,
              body: AppStrings.startupErrorBody,
              detail: _initError.toString(),
              onRetry: _retryInit,
              retrying: _retrying,
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      // M4: ভাষা বদলালে পুরো অ্যাপ আবার বসে — সব রাস্তার
      // লেখা নতুন ভাষায় আসে। AppStrings স্ট্যাটিক, তাই
      // locale বদলে নিজে থেকে rebuild হয় না; key বদলালে
      // Flutter সব পাতা নতুন করে বানায় (রাউটারের অবস্থা
      // static GoRouter-এ থাকে, তাই বর্তমান পাতা হারায় না)।
      key: ValueKey(locale),
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

/// ভুলের পাতা — M3-এর চালুর ভুল আর m13-এর বিল্ড ভুল,
/// দুই জায়গায় একই চেহারা।
class _StartupErrorWidget extends StatelessWidget {
  final String message;
  final String? body;
  final String? detail;
  final VoidCallback? onRetry;
  final bool retrying;

  const _StartupErrorWidget({
    required this.message,
    this.body,
    this.detail,
    this.onRetry,
    this.retrying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, textAlign: TextAlign.center),
            ],
            if (detail != null) ...[
              const SizedBox(height: 12),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: retrying ? null : onRetry,
                child: retrying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
