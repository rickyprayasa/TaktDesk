import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/analytics/domain/focus_analytics_models.dart';
import 'package:takt_desk/features/analytics/presentation/focus_analytics_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bars add up to the total: minutes are rounded per bar, not per session', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day, 9);
    for (var i = 0; i < 10; i++) {
      await db.into(db.timerSessions).insert(TimerSessionsCompanion.insert(
            targetMinutes: 25,
            elapsedSeconds: 90,
            startedAt: Value(day.add(Duration(minutes: i * 3))),
          ));
    }
    final controller = FocusAnalyticsController(db);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    controller.setPeriod(FocusAnalyticsPeriod.day);
    final state = controller.state;
    final barsTotal = state.bars.fold<int>(0, (sum, b) => sum + b.valueMinutes);
    expect(barsTotal, 15, reason: 'ten 90 s sessions are 15 minutes');
    controller.dispose();
    await db.close();
  });
}
