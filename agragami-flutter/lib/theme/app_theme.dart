import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// অগ্রগামী ফান্ডের রং ও থিম টোকেন (লাইট ও ডার্ক মোড সমর্থিত)
class AppColors {
  // লাইট থিম প্যালেট
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

  // ডার্ক থিম প্যালেট
  static const Color darkBackground = Color(0xFF111412);
  static const Color darkSurface = Color(0xFF1A1D1B);
  static const Color darkSurfaceVariant = Color(0xFF242A26);
  static const Color darkLine = Color(0xFF2E3731);
  static const Color darkText = Color(0xFFE2E8E4);
  static const Color darkMuted = Color(0xFF9CA8A1);
  static const Color darkGreen = Color(0xFF34D399);
  static const Color darkGold = Color(0xFFE5C058);

  // আর্থিক স্ট্যাটাস কালার (ইনকাম, খরচ, বকেয়া)
  static Color moneyIncome(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF34D399)
        : green;
  }

  static Color moneyExpense(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF87171)
        : danger;
  }

  static Color moneyDue(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFBBF24)
        : amber;
  }

  static Color incomeContainer(BuildContext context) {
    return moneyIncome(context).withValues(alpha: 0.15);
  }

  static Color expenseContainer(BuildContext context) {
    return moneyExpense(context).withValues(alpha: 0.15);
  }

  static Color dueContainer(BuildContext context) {
    return moneyDue(context).withValues(alpha: 0.15);
  }
}

class AppTheme {
  // m5: Material 3 থিমে 2021 টাইপ স্কেল — 2014-এর
  // blackMountainView আর ব্যবহার হয় না।
  static TextTheme _textTheme(Color color) {
    final base = Typography.material2021(
      platform: TargetPlatform.android,
    ).black;
    return base.apply(
      bodyColor: color,
      displayColor: color,
      fontFamily: 'Kalpurush',
    );
  }

  /// লাইট থিম কনফিগারেশন
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.green,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      outline: AppColors.muted,
      outlineVariant: AppColors.line,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
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

  /// ডার্ক থিম কনফিগারেশন
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.darkGreen,
      onPrimary: Color(0xFF00381B),
      primaryContainer: Color(0xFF065F36),
      onPrimaryContainer: Color(0xFF86EFAC),
      secondary: AppColors.darkGold,
      onSecondary: Color(0xFF3E2D00),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkMuted,
      outline: AppColors.darkMuted,
      outlineVariant: AppColors.darkLine,
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(AppColors.darkText),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161A17),
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkLine),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkGreen,
          foregroundColor: const Color(0xFF00381B),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGreen,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.darkGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkLine, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkLine, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF161A17),
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: AppColors.darkMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 13.5),
        unselectedLabelStyle: TextStyle(fontSize: 13.5),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.darkGreen,
        unselectedLabelColor: AppColors.darkMuted,
        indicatorColor: AppColors.darkGreen,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedColor: const Color(0xFF065F36),
        disabledColor: AppColors.darkSurface,
        side: const BorderSide(color: AppColors.darkLine),
        labelStyle: const TextStyle(fontSize: 14.5, color: AppColors.darkText),
        secondaryLabelStyle: const TextStyle(fontSize: 14.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
