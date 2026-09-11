import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appWidgetServiceProvider = Provider<AppWidgetService>((ref) {
  return const AppWidgetService();
});

class AppWidgetService {
  static const MethodChannel channel = MethodChannel('com.takt.desk/app_widget');

  const AppWidgetService();

  Future<bool> updateWidgetData({
    required int cyclesCompleted,
    required int cyclesTarget,
    required int minutesFocused,
    required String status,
  }) async {
    try {
      final res = await channel.invokeMethod<bool>('updateWidgetData', {
        'cyclesCompleted': cyclesCompleted,
        'cyclesTarget': cyclesTarget,
        'minutesFocused': minutesFocused,
        'status': status,
      });
      return res ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
