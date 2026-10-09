import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_controller.dart';

/// Home-screen widget colours for a chassis theme (ARGB ints): the module chassis of the edition in the current
/// light/dark mode, readable text on it, the edition's filament (status text) and needle colours.
Map<String, Object> widgetThemePayload(ChassisThemeState theme) {
  final chassis = theme.moduleChassisColor;
  final dark = chassis.computeLuminance() < 0.45;
  return {
    'dark': dark,
    'chassis': chassis.toARGB32(),
    'text': (dark ? const Color(0xFFF2EFE9) : const Color(0xFF1B1E23)).toARGB32(),
    'muted': (dark ? const Color(0xFF8E8E93) : const Color(0xFF5E5B55)).toARGB32(),
    'accent': theme.filamentColor.toARGB32(),
    'needle': theme.needleColor.toARGB32(),
    'border': theme.borderColor.toARGB32(),
  };
}

const MethodChannel widgetThemeChannel = MethodChannel('com.zykl.app/widget_theme');

/// Sends the widget colours whenever the light/dark mode or the edition changes (and once on start).
final widgetThemeSyncProvider = Provider.autoDispose<void>((ref) {
  ref.listen<ChassisThemeState>(
    chassisThemeProvider,
    (previous, theme) {
      final payload = widgetThemePayload(theme);
      if (previous != null && _samePayload(widgetThemePayload(previous), payload)) return;
      widgetThemeChannel.invokeMethod<bool>('updateWidgetTheme', payload).catchError((Object _) => false);
    },
    fireImmediately: true,
  );
});

bool _samePayload(Map<String, Object> a, Map<String, Object> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
