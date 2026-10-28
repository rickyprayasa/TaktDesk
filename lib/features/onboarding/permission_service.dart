import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) => const PermissionService());

enum NotificationPermission { granted, denied, notRequired }

/// Notification permission for the first-run walkthrough (MainActivity, com.zykl.app/permissions).
class PermissionService {
  static const MethodChannel channel = MethodChannel('com.zykl.app/permissions');

  const PermissionService();

  Future<NotificationPermission> notificationStatus() async {
    try {
      return switch (await channel.invokeMethod<String>('notificationStatus')) {
        'granted' => NotificationPermission.granted,
        'notRequired' => NotificationPermission.notRequired,
        _ => NotificationPermission.denied,
      };
    } catch (_) {
      return NotificationPermission.notRequired;
    }
  }

  /// Shows Android's dialog; true when notifications are allowed afterwards.
  Future<bool> requestNotifications() async {
    try {
      return await channel.invokeMethod<bool>('requestNotifications') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// After "Don't allow" twice Android stops asking; the app's notification settings are the way back.
  Future<void> openNotificationSettings() async {
    try {
      await channel.invokeMethod<bool>('openNotificationSettings');
    } catch (_) {}
  }
}
