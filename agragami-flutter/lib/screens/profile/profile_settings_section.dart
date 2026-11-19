import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../main.dart';
import '../../services/biometric_service.dart';
import '../../widgets/app_card.dart';

/// প্রোফাইল স্ক্রিনের ভাষা, থিম এবং বায়োমেট্রিক নিরাপত্তা সেটিংস কম্পোনেন্ট
class ProfileSettingsSection extends ConsumerWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

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
                  ref.read(localeProvider.notifier).state =
                      Locale(code, code == 'bn' ? 'BD' : 'US');
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
                  ref.read(themeModeProvider.notifier).state =
                      selected.first;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // বায়োমেট্রিক নিরাপত্তা কার্ড
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
                          ? 'বায়োমেট্রিক নিরাপত্তা'
                          : 'Biometric Security',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppStrings.isBangla
                          ? 'ফিঙ্গারপ্রিন্ট বা ফেস আনলক'
                          : 'Fingerprint or Face Unlock',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.security_outlined),
                onPressed: () async {
                  // M8: আসল ফলাফল দেখানো হয় — "যন্ত্রে নেই" আর
                  // "বাতিল" আলাদা বার্তা পায়, আগের মতো সব false নয়।
                  final result = await ref
                      .read(biometricServiceProvider)
                      .authenticate();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(switch (result) {
                          BiometricResult.success =>
                            AppStrings.biometricSuccess,
                          BiometricResult.unavailable =>
                            AppStrings.biometricUnavailable,
                          BiometricResult.cancelled =>
                            AppStrings.biometricCancelled,
                          BiometricResult.failed =>
                            AppStrings.biometricFailed,
                        }),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
