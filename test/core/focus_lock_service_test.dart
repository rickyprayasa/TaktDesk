import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusLockService', () {
    late FocusLockService service;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      service = FocusLockService();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(FocusLockService.channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'enableFocusLock':
            return true;
          case 'disableFocusLock':
            return true;
          case 'isLockTaskPermitted':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(FocusLockService.channel, null);
    });

    test('FocusLockService registers channel com.takt.desk/focus_lock', () {
      expect(FocusLockService.channel.name, equals('com.takt.desk/focus_lock'));
    });

    test('enableFocusLock sends method call and returns true', () async {
      final result = await service.enableFocusLock();
      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'enableFocusLock');
    });

    test('disableFocusLock sends method call and returns true', () async {
      final result = await service.disableFocusLock();
      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'disableFocusLock');
    });

    test('isLockTaskPermitted sends method call and returns true', () async {
      final result = await service.isLockTaskPermitted();
      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'isLockTaskPermitted');
    });

    test('handles missing channel gracefully with fallback', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(FocusLockService.channel, (MethodCall methodCall) async {
        throw MissingPluginException();
      });

      final result = await service.enableFocusLock();
      expect(result, isFalse);
    });
  });
}
