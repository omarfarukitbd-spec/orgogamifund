import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ডিভাইসে সেটিংস সংরক্ষণ (M6, M11) — থিম, ভাষা আর
/// বায়োমেট্রিক লকের পছন্দ অ্যাপ বন্ধ করলেও মনে থাকে।
/// আগে এগুলো শুধু মেমরিতে ছিল, প্রতিবার চালু করলে ভুলে যেত।
class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  final bool biometricLockEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('bn', 'BD'),
    this.biometricLockEnabled = false,
  });
}

class SettingsService {
  static const _themeKey = 'themeMode';
  static const _localeKey = 'localeCode';
  static const _biometricLockKey = 'biometricLockEnabled';

  /// চালুর সময় সংরক্ষিত সেটিংস পড়া — পড়তে না পারলে
  /// ডিফল্ট (সিস্টেম থিম, বাংলা, লক বন্ধ) ফেরত যায়।
  static Future<AppSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);
      final themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      );
      final localeCode = prefs.getString(_localeKey);
      final locale = localeCode == 'en'
          ? const Locale('en', 'US')
          : const Locale('bn', 'BD');
      return AppSettings(
        themeMode: themeMode,
        locale: locale,
        biometricLockEnabled: prefs.getBool(_biometricLockKey) ?? false,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {}
  }

  static Future<void> saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (_) {}
  }

  static Future<void> saveBiometricLock(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricLockKey, enabled);
    } catch (_) {}
  }

  /// m10: পড়া নোটিফিকেশনের id সংরক্ষণ — ব্যাজ যাতে
  /// পড়া নোটিফিকেশন আবার না গোনে।
  static const _readNotificationsKey = 'readNotificationIds';

  static Future<Set<String>> loadReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_readNotificationsKey)?.toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveReadNotificationIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readNotificationsKey, ids.toList());
    } catch (_) {}
  }
}
