import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_strings.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

/// থিম মোড স্টেট প্রোভাইডার (সিস্টেম, লাইট, ডার্ক)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// ভাষা স্টেট প্রোভাইডার (বাংলা ডিফল্ট, ইংরেজি সমর্থিত)
final localeProvider =
    StateProvider<Locale>((ref) => const Locale('bn', 'BD'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.instance.init();
  } catch (_) {}

  try {
    await AuthService().initGoogleSignIn();
  } catch (_) {}

  runApp(const ProviderScope(child: AgragamiFundApp()));
}

class AgragamiFundApp extends ConsumerWidget {
  const AgragamiFundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
