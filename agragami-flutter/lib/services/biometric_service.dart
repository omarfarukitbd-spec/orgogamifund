import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../l10n/app_strings.dart';

final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService());

/// বায়োমেট্রিক নিরাপত্তা (ফিঙ্গারপ্রিন্ট / ফেস আইডি) প্রমাণীকরণ সার্ভিস
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// ডিভাইসে বায়োমেট্রিক সমর্থন আছে কি না যাচাই
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// নিবন্ধিত বায়োমেট্রিক সেন্সর প্রকারভেদ আনা
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// বায়োমেট্রিক অথেনটিকেশন প্রম্পট চালু করা
  Future<bool> authenticate({String? customPrompt}) async {
    final isBn = AppStrings.isBangla;
    final reason = customPrompt ??
        (isBn
            ? 'অগ্রগামী ফান্ড অ্যাপে ঢুকতে আপনার ফিঙ্গারপ্রিন্ট বা ফেস আইডি দিন'
            : 'Authenticate to access Ogrogami Fund');

    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// সক্রিয় বায়োমেট্রিক সেশন বাতিল করা
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
