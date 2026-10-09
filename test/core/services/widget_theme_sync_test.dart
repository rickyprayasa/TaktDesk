import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/services/widget_theme_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark chassis: light text; light chassis: dark text; edition colours carried', () {
    const darkTheme = ChassisThemeState(isDarkMode: true);
    final dark = widgetThemePayload(darkTheme);
    expect(dark['dark'], isTrue);
    expect(dark['chassis'], darkTheme.moduleChassisColor.toARGB32());
    expect(dark['text'], 0xFFF2EFE9);
    expect(dark['needle'], darkTheme.needleColor.toARGB32());
    expect(dark['accent'], darkTheme.filamentColor.toARGB32());

    const lightTheme = ChassisThemeState(isDarkMode: false);
    final light = widgetThemePayload(lightTheme);
    expect(light['dark'], isFalse);
    expect(light['text'], 0xFF1B1E23);
    expect(light['chassis'], lightTheme.moduleChassisColor.toARGB32());
  });

  test('sync sends the colours on start and again only when they change', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetThemeChannel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetThemeChannel, null));

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(widgetThemeSyncProvider, (_, __) {});
    await Future<void>.delayed(Duration.zero);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'updateWidgetTheme');

    final notifier = container.read(chassisThemeProvider.notifier);
    final before = container.read(chassisThemeProvider);
    notifier.setDarkMode(!before.isDarkMode);
    await Future<void>.delayed(Duration.zero);
    expect(calls, hasLength(2));
    expect(calls.last.arguments['dark'], widgetThemePayload(container.read(chassisThemeProvider))['dark']);

    notifier.setDarkMode(!before.isDarkMode); // same mode again: nothing new to send
    await Future<void>.delayed(Duration.zero);
    expect(calls, hasLength(2));
  });
}
