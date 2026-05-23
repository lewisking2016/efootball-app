import 'package:flutter_test/flutter_test.dart';

import 'package:efootball_app/theme/app_theme.dart';

void main() {
  test('app theme uses the platform default font', () {
    final theme = AppTheme.lightTheme;

    expect(theme.textTheme.bodyMedium?.fontFamily, isNot('Inter'));
    expect(theme.textTheme.bodyMedium?.fontFamily, isNot('Outfit'));
    expect(theme.appBarTheme.titleTextStyle?.fontFamily, isNot('Inter'));
    expect(theme.appBarTheme.titleTextStyle?.fontFamily, isNot('Outfit'));
  });
}
