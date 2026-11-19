import 'package:flutter/material.dart';

import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button_web.dart' as impl;

/// ওয়েবে গুগলের নিজের সাইন-ইন বোতাম (GIS বোতাম)।
/// মোবাইলে এটা কিছু দেখায় না — ওখানে অ্যাপের নিজের
/// গুগল বোতাম থেকে signInWithGoogle ডাকা হয়।
/// busy হলে ওয়েবে বোতামের বদলে লোডিং দেখানো হয় (m12)।
Widget buildGoogleWebButton({bool busy = false}) =>
    impl.buildGoogleWebButton(busy: busy);
