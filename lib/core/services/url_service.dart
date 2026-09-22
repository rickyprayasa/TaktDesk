import 'package:flutter/services.dart';

/// Service providing native deep-linking and browser navigation.
class UrlService {
  static const MethodChannel _channel = MethodChannel('com.takt.desk/focus_lock');

  /// Launches [url] in the system default browser or application handler.
  static Future<bool> openUrl(String url) async {
    try {
      final success = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves native Android hardware and OS diagnostic information.
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      return info ?? {};
    } catch (_) {
      return {};
    }
  }

  /// Dispatches email directly to support@zykl.app with pre-filled subject and diagnostic body.
  /// Attempts to launch Gmail first, with fallback to system email chooser.
  static Future<bool> sendFeedbackEmail({
    required String type,
    required String subject,
    required String body,
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('sendFeedbackEmail', {
        'type': type,
        'subject': subject,
        'body': body,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Direct deep-link to Google Play Store app listing for rating ZYKL.
  static Future<bool> openPlayStore() async {
    try {
      final success = await _channel.invokeMethod<bool>('openPlayStore');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
