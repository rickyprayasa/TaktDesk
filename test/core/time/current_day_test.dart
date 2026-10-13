import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/time/current_day.dart';

void main() {
  testWidgets('today moves on at midnight without any database change', (tester) async {
    final container = ProviderContainer();
    final seen = <DateTime>[];
    container.listen(currentDayProvider, (_, day) => seen.add(day), fireImmediately: true);

    final start = clock.now();
    expect(seen.single, dayOf(start));

    final untilMidnight = DateTime(start.year, start.month, start.day + 1).difference(start);
    await tester.pump(untilMidnight - const Duration(minutes: 1));
    expect(seen, hasLength(1), reason: 'still the same day a minute before midnight');

    await tester.pump(const Duration(minutes: 2));
    expect(seen, hasLength(2));
    expect(seen.last, DateTime(start.year, start.month, start.day + 1));

    await tester.pump(const Duration(hours: 24));
    expect(seen.last, DateTime(start.year, start.month, start.day + 2), reason: 'reschedules every night');
    container.dispose(); // cancels the midnight timer
  });
}
