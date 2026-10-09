import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/display_service.dart';
import 'package:takt_desk/features/desk/presentation/desk_clock_host.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class _Dial extends ChronoDialController {
  void setRunning(bool running) => state = state.copyWith(isRunning: running);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];
  late _Dial dial;
  late DeskPreferencesController prefs;
  late int presses;

  setUp(() {
    calls.clear();
    presses = 0;
    dial = _Dial();
    prefs = DeskPreferencesController();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DisplayService.channel, (call) async {
      final args = call.arguments as Map;
      calls.add('${call.method}:${args.values.single}');
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DisplayService.channel, null);
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chronoDialControllerProvider.overrideWith((ref) => dial),
          deskPreferencesControllerProvider.overrideWith((ref) => prefs),
        ],
        child: MaterialApp(
          home: DeskClockHost(
            child: Center(
              child: ElevatedButton(
                key: const ValueKey('desk_button'),
                onPressed: () => presses++,
                child: const Text('DESK'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Offset shiftOf(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.descendant(of: find.byType(DeskClockHost), matching: find.byType(Transform)).first,
    );
    final t = transform.transform.getTranslation();
    return Offset(t.x, t.y);
  }

  testWidgets('off by default: a running timer leaves the screen alone', (tester) async {
    await pumpHost(tester);
    dial.setRunning(true);
    await tester.pump(const Duration(seconds: 120));
    expect(calls, isEmpty);
    expect(find.byKey(const ValueKey('desk_clock_veil')), findsNothing);
  });

  testWidgets('keeps the screen on, dims after a minute, shifts, and wakes on the first touch', (tester) async {
    await prefs.setDeskClockMode(true);
    await pumpHost(tester);
    dial.setRunning(true);
    await tester.pump();
    expect(calls, ['setKeepScreenOn:true']);

    await tester.pump(const Duration(seconds: 59));
    expect(calls, ['setKeepScreenOn:true']);
    await tester.pump(const Duration(seconds: 1));
    expect(calls.last, 'setDimmed:true');
    expect(shiftOf(tester), Offset.zero);

    await tester.pump(const Duration(seconds: 60));
    expect(shiftOf(tester), DeskClockHost.shifts[1]);

    // The waking touch is swallowed by the veil: the desk button is not pressed.
    await tester.tap(find.byKey(const ValueKey('desk_button')), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 700));
    expect(calls.last, 'setDimmed:false');
    expect(presses, 0);
    expect(shiftOf(tester), Offset.zero);

    // Awake again: touches reach the desk.
    await tester.tap(find.byKey(const ValueKey('desk_button')));
    expect(presses, 1);

    dial.setRunning(false);
    await tester.pump();
    expect(calls.last, 'setKeepScreenOn:false');
    expect(find.byKey(const ValueKey('desk_clock_veil')), findsNothing);
  });

  testWidgets('stopping while dimmed restores brightness and lets the screen sleep', (tester) async {
    await prefs.setDeskClockMode(true);
    await pumpHost(tester);
    dial.setRunning(true);
    await tester.pump(const Duration(seconds: 61));
    expect(calls.last, 'setDimmed:true');

    dial.setRunning(false);
    await tester.pump();
    expect(calls.sublist(calls.length - 2), ['setKeepScreenOn:false', 'setDimmed:false']);
  });

  testWidgets('turning the mode off mid-session releases the screen', (tester) async {
    await prefs.setDeskClockMode(true);
    await pumpHost(tester);
    dial.setRunning(true);
    await tester.pump();
    await prefs.setDeskClockMode(false);
    await tester.pump();
    expect(calls, ['setKeepScreenOn:true', 'setKeepScreenOn:false']);
    dial.setRunning(false);
    await tester.pump();
  });
}
