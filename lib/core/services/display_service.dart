import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final displayServiceProvider = Provider<DisplayService>((ref) {
  return const DisplayService();
});

/// True while desk clock mode has dimmed the screen: per-frame decoration (the spinning platter) can rest.
final deskClockDimmedProvider = StateProvider<bool>((ref) => false);

/// The app window's screen-on flag and brightness override (desk clock mode). Android only; no-ops elsewhere.
class DisplayService {
  static const MethodChannel channel = MethodChannel('com.zykl.app/display');

  const DisplayService();

  /// Keeps the screen from timing out while this window is visible. Lockdown has its own claim on the same flag
  /// natively, so turning this off never wakes the screen out of a lockdown.
  Future<void> setKeepScreenOn(bool enabled) async {
    try {
      await channel.invokeMethod<bool>('setKeepScreenOn', {'enabled': enabled});
    } catch (_) {}
  }

  /// Dims the window to a low brightness, or returns it to the user's own setting.
  Future<void> setDimmed(bool dimmed) async {
    try {
      await channel.invokeMethod<bool>('setDimmed', {'dimmed': dimmed});
    } catch (_) {}
  }
}
