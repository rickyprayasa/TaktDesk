import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('defaults to light finish chassis', () {
      final controller = ThemeController();
      expect(controller.state.isDarkMode, isFalse);
    });

    test('toggleTheme alternates between light and dark finish', () {
      final controller = ThemeController();
      controller.toggleTheme();
      expect(controller.state.isDarkMode, isTrue);
      controller.toggleTheme();
      expect(controller.state.isDarkMode, isFalse);
    });

    test('setDarkMode explicitly sets theme state', () {
      final controller = ThemeController();
      controller.setDarkMode(false);
      expect(controller.state.isDarkMode, isFalse);
      controller.setDarkMode(true);
      expect(controller.state.isDarkMode, isTrue);
    });
  });
}
