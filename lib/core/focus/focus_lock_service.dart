import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final focusLockServiceProvider = Provider<FocusLockService>((ref) {
  return FocusLockService();
});

class FocusLockService {
  static const MethodChannel channel = MethodChannel('com.takt.desk/focus_lock');

  Future<bool> enableFocusLock() async {
    try {
      final res = await channel.invokeMethod<bool>('enableFocusLock');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disableFocusLock() async {
    try {
      final res = await channel.invokeMethod<bool>('disableFocusLock');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isLockTaskPermitted() async {
    try {
      final res = await channel.invokeMethod<bool>('isLockTaskPermitted');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isNotificationPolicyAccessGranted() async {
    try {
      final res = await channel.invokeMethod<bool>('isNotificationPolicyAccessGranted');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openNotificationPolicySettings() async {
    try {
      final res = await channel.invokeMethod<bool>('openNotificationPolicySettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
