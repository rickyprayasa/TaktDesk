import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/url_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.takt.desk/focus_lock');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('reads the installed version instead of a hardcoded one', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getDeviceInfo') return {'versionName': '1.0.2', 'versionCode': 3};
      return null;
    });
    expect(await UrlService.appVersionLabel(), 'v1.0.2 (BUILD 3)');
  });

  test('returns null when the platform gives no version', () async {
    expect(await UrlService.appVersionLabel(), isNull);
  });
}
