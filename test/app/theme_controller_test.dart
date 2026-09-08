import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('defaults to dark obsidian chassis', () {
      final controller = ThemeController();
      expect(controller.state.isDarkMode, isTrue);
    });

    test('toggleTheme alternates between dark and light finish', () {
      final controller = ThemeController();
      controller.toggleTheme();
      expect(controller.state.isDarkMode, isFalse);
      controller.toggleTheme();
      expect(controller.state.isDarkMode, isTrue);
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
