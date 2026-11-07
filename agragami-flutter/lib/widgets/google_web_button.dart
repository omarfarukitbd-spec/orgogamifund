import 'package:flutter/material.dart';

import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button_web.dart' as impl;

/// ওয়েবে গুগলের নিজের সাইন-ইন বোতাম (GIS বোতাম)।
/// মোবাইলে এটা কিছু দেখায় না — ওখানে অ্যাপের নিজের
/// গুগল বোতাম থেকে signInWithGoogle ডাকা হয়।
Widget buildGoogleWebButton() => impl.buildGoogleWebButton();
