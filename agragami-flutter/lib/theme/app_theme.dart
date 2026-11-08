import 'package:flutter/material.dart';

/// অগ্রগামী ফান্ডের রং ও থিম।
/// গাঢ় সবুজ + সাদা + সোনালি। পুরোনো অ্যাপের ডিজাইন এখানে কপি করা হয়নি।
class AppColors {
  static const Color green = Color(0xFF0B6B3A);
  static const Color greenDark = Color(0xFF084E2B);
  static const Color greenSoft = Color(0xFFE6F2EB);
  static const Color gold = Color(0xFFC9A227);
  static const Color goldSoft = Color(0xFFF7F0D8);
  static const Color goldDark = Color(0xFFA07D08);
  static const Color greenTint = Color(0xFFF2F8F4);
  static const Color ink = Color(0xFF1A1F1C);
  static const Color muted = Color(0xFF5F6B64);
  static const Color line = Color(0xFFE3E8E5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F8F7);
  static const Color danger = Color(0xFFB3261E);
  static const Color amber = Color(0xFF8A6100);
}

class AppTheme {
  static TextTheme _textTheme(Color color) {
    // কালপুরুষ — অ্যাপের ফন্ট। assets/fonts/ ফোল্ডারে রাখা আছে,
    // pubspec.yaml-এ Kalpurush ফ্যামিলি হিসেবে ঘোষণা করা আছে।
    return Typography.blackMountainView.apply(
      bodyColor: color,
      displayColor: color,
      fontFamily: 'Kalpurush',
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.green,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.green),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.green,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 13.5),
        unselectedLabelStyle: TextStyle(fontSize: 13.5),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.green,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: AppColors.green,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.greenSoft,
        disabledColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(fontSize: 14.5),
        secondaryLabelStyle: const TextStyle(fontSize: 14.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
