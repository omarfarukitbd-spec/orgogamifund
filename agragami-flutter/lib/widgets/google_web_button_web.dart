import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// ওয়েবে গুগলের নিজের সাইন-ইন বোতাম — GIS-এর নিয়মে
/// ওয়েবে অ্যাপের নিজের বোতামে ঢোকা যায় না, গুগলের
/// বোতামই ব্যবহার করতে হয়। বোতাম চাপলে
/// authenticationEvents দিয়ে ঢোকা সম্পূর্ণ হয়।
/// busy হলে বোতামের বদলে লোডিং দেখানো হয় (m12)।
Widget buildGoogleWebButton({bool busy = false}) {
  return SizedBox(
    height: 48,
    child: Center(
      child: busy
          ? const CircularProgressIndicator()
          : const _GoogleWebButton(),
    ),
  );
}

class _GoogleWebButton extends StatelessWidget {
  const _GoogleWebButton();

  @override
  Widget build(BuildContext context) {
    // GIS বোতামের চওড়া স্পষ্ট করে বসানো হয় (m12) — ডিফল্ট
    // চওড়া সরু ওয়েব ভিউতে উপচে যেতে পারে। পাওয়া জায়গা
    // অনুযায়ী 200–320px-এর মধ্যে রাখা হয়।
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final width =
            maxWidth.isFinite ? maxWidth.clamp(200.0, 320.0) : 280.0;
        return web.renderButton(
          configuration: web.GSIButtonConfiguration(
            minimumWidth: width,
            theme: web.GSIButtonTheme.outline,
            size: web.GSIButtonSize.large,
            text: web.GSIButtonText.signinWith,
            shape: web.GSIButtonShape.rectangular,
          ),
        );
      },
    );
  }
}
