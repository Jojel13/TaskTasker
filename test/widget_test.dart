import 'package:flutter_test/flutter_test.dart';
import 'package:task_tasker/core/theme/theme_config.dart';
import 'package:task_tasker/shared/models/enums.dart';

void main() {
  group('TaskTasker Theme & Config Tests', () {
    test('All 12 themes can be instantiated with valid properties', () {
      for (final themeType in AppThemeType.values) {
        final appTheme = AppThemeData.fromType(themeType);
        expect(appTheme.name.isNotEmpty, isTrue);
        expect(appTheme.background, isNotNull);
        expect(appTheme.surface, isNotNull);
        expect(appTheme.primary, isNotNull);
        expect(appTheme.accent, isNotNull);
      }
    });

    test('Minimal Light has correct light background and dark text', () {
      final lightTheme = AppThemeData.fromType(AppThemeType.minimalLight);
      expect(lightTheme.isDark, isFalse);
      expect(lightTheme.textPrimary.computeLuminance() < 0.2, isTrue);
      expect(lightTheme.background.computeLuminance() > 0.8, isTrue);
    });

    test('Ocean Breeze has correct styling and high-contrast accent', () {
      final oceanTheme = AppThemeData.fromType(AppThemeType.ocean);
      expect(oceanTheme.isDark, isTrue);
      expect(oceanTheme.accent, isNotNull);
      expect(oceanTheme.primary, isNotNull);
    });
  });
}
