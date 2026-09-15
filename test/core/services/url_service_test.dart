import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/url_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UrlService', () {
    const MethodChannel channel = MethodChannel('com.takt.desk/focus_lock');
    final List<MethodCall> log = <MethodCall>[];
    bool? mockResult = true;
    bool throwException = false;

    setUp(() {
      log.clear();
      mockResult = true;
      throwException = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (throwException) {
          throw PlatformException(code: 'URL_ERROR', message: 'Failed to open URL');
        }
        if (methodCall.method == 'openUrl') {
          return mockResult;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('openUrl dispatches openUrl with URL string over focus_lock channel and returns true', () async {
      final result = await UrlService.openUrl('https://zykl.app');
      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, equals('openUrl'));
      expect(log.first.arguments, equals({'url': 'https://zykl.app'}));
    });

    test('openUrl returns false when channel returns false', () async {
      mockResult = false;
      final result = await UrlService.openUrl('https://invalid.url');
      expect(result, isFalse);
      expect(log, hasLength(1));
      expect(log.first.method, equals('openUrl'));
      expect(log.first.arguments, equals({'url': 'https://invalid.url'}));
    });

    test('openUrl returns false when channel returns null', () async {
      mockResult = null;
      final result = await UrlService.openUrl('https://zykl.app');
      expect(result, isFalse);
    });

    test('openUrl returns false when channel throws exception', () async {
      throwException = true;
      final result = await UrlService.openUrl('https://zykl.app');
      expect(result, isFalse);
    });
  });
}
