import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/config/app_security_config.dart';

void main() {
  group('AppSecurityConfig', () {
    test('evaluates developer and simulation flags consistent with test environment', () {
      // In flutter_test, kDebugMode is true by default
      expect(kDebugMode, isTrue);
      expect(AppSecurityConfig.isProSimulationEnabled, equals(kDebugMode));
      expect(AppSecurityConfig.showDeveloperTools, equals(kDebugMode));
    });
  });
}
