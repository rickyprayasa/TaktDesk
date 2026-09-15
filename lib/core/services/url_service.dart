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
}
