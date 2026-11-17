import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// ওয়েবে গুগলের নিজের সাইন-ইন বোতাম — GIS-এর নিয়মে
/// ওয়েবে অ্যাপের নিজের বোতামে ঢোকা যায় না, গুগলের
/// বোতামই ব্যবহার করতে হয়। বোতাম চাপলে
/// authenticationEvents দিয়ে ঢোকা সম্পূর্ণ হয়।
Widget buildGoogleWebButton() {
  return const SizedBox(
    height: 48,
    child: Center(child: _GoogleWebButton()),
  );
}

class _GoogleWebButton extends StatelessWidget {
  const _GoogleWebButton();

  @override
  Widget build(BuildContext context) => web.renderButton();
}
