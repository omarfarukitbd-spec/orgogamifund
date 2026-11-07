import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agragami_fund/theme/app_theme.dart';

void main() {
  testWidgets('Kalpurush font files load', (tester) async {
    final regular =
        await rootBundle.load('assets/fonts/Kalpurush-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Kalpurush-Bold.ttf');
    expect(regular.lengthInBytes, greaterThan(100000));
    expect(bold.lengthInBytes, greaterThan(100000));
  });

  test('theme uses Kalpurush', () {
    expect(
      AppTheme.light().textTheme.bodyMedium?.fontFamily,
      'Kalpurush',
    );
  });
}
