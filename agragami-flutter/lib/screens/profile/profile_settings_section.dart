import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../main.dart';
import '../../services/biometric_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/app_card.dart';

/// প্রোফাইল স্ক্রিনের ভাষা, থিম এবং বায়োমেট্রিক নিরাপত্তা সেটিংস কম্পোনেন্ট
class ProfileSettingsSection extends ConsumerStatefulWidget {
  const ProfileSettingsSection({super.key});

  @override
  ConsumerState<ProfileSettingsSection> createState() =>
      _ProfileSettingsSectionState();
}

class _ProfileSettingsSectionState
    extends ConsumerState<ProfileSettingsSection> {
  bool _biometricBusy = false;

  /// M11: অ্যাপ-লক চালু/বন্ধ — দুই দিকেই আগে বায়োমেট্রিক
  /// যাচাই লাগে, যাতে অন্য কেউ লক বন্ধ করে দিতে না পারে।
  Future<void> _toggleBiometricLock(bool enable) async {
    if (_biometricBusy) return;
    setState(() => _biometricBusy = true);
    try {
      final service = ref.read(biometricServiceProvider);
      if (enable && !await service.isBiometricAvailable()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.biometricUnavailable)),
        );
        return;
      }
      final result = await service.authenticate();
      if (!mounted) return;
      switch (result) {
        case BiometricResult.success:
          ref.read(biometricLockEnabledProvider.notifier).state = enable;
          await SettingsService.saveBiometricLock(enable);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enable
                    ? (AppStrings.isBangla
                        ? 'অ্যাপ-লক চালু হয়েছে — এখন থেকে অ্যাপ খুলতে ফিঙ্গারপ্রিন্ট লাগবে'
                        : 'App lock is on — unlocking will need your fingerprint')
                    : (AppStrings.isBangla
                        ? 'অ্যাপ-লক বন্ধ হয়েছে'
                        : 'App lock is off'),
              ),
            ),
          );
        case BiometricResult.unavailable:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.biometricUnavailable)),
          );
        case BiometricResult.cancelled:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.biometricCancelled)),
          );
        case BiometricResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.biometricFailed)),
          );
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final lockEnabled = ref.watch(biometricLockEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ভাষা নির্বাচন কার্ড
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.language_outlined,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.languageTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'bn',
                    label: Text(AppStrings.bangla),
                  ),
                  ButtonSegment(
                    value: 'en',
                    label: Text(AppStrings.english),
                  ),
                ],
                selected: {currentLocale.languageCode},
                onSelectionChanged: (selected) {
                  final code = selected.first;
                  final locale =
                      Locale(code, code == 'bn' ? 'BD' : 'US');
                  ref.read(localeProvider.notifier).state = locale;
                  // M6: ভাষার পছন্দ ডিভাইসে সংরক্ষিত হয়।
                  SettingsService.saveLocale(locale);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // থিম মোড নির্বাচন কার্ড
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.themeModeTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(AppStrings.themeLight),
                    icon: const Icon(Icons.light_mode_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(AppStrings.themeDark),
                    icon: const Icon(Icons.dark_mode_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(AppStrings.themeSystem),
                    icon: const Icon(Icons.brightness_auto_outlined, size: 16),
                  ),
                ],
                selected: {currentTheme},
                onSelectionChanged: (selected) {
                  final mode = selected.first;
                  ref.read(themeModeProvider.notifier).state = mode;
                  // M6: থিমের পছন্দ ডিভাইসে সংরক্ষিত হয়।
                  SettingsService.saveThemeMode(mode);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // বায়োমেট্রিক অ্যাপ-লক কার্ড (M11) — আগের ডেমো বোতামের
        // বদলে আসল টগল: চালু থাকলে অ্যাপ খুলতে ফিঙ্গারপ্রিন্ট লাগে।
        AppCard(
          child: Row(
            children: [
              Icon(
                Icons.fingerprint_outlined,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.isBangla
                          ? 'বায়োমেট্রিক অ্যাপ-লক'
                          : 'Biometric App Lock',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      lockEnabled
                          ? (AppStrings.isBangla
                              ? 'চালু আছে — অ্যাপ খুলতে ফিঙ্গারপ্রিন্ট লাগবে'
                              : 'On — fingerprint needed to open the app')
                          : (AppStrings.isBangla
                              ? 'ফিঙ্গারপ্রিন্ট বা ফেস আনলক দিয়ে অ্যাপ লক করুন'
                              : 'Lock the app with fingerprint or face unlock'),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_biometricBusy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: lockEnabled,
                  onChanged: _toggleBiometricLock,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
