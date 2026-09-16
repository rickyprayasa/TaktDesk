import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/timer_background_service.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> log;
  late TimerBackgroundService service;
  bool shouldThrow = false;

  setUp(() {
    log = <MethodCall>[];
    shouldThrow = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TimerBackgroundService.channel, (call) async {
      log.add(call);
      if (shouldThrow) {
        throw PlatformException(code: 'ERROR', message: 'Failed');
      }
      return true;
    });
    service = const TimerBackgroundService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TimerBackgroundService.channel, null);
  });

  test('startService sends expected arguments to native channel', () async {
    final result = await service.start(
      remainingSeconds: 1500.0,
      targetMinutes: 25,
      phase: PomodoroPhase.focus,
      cycleCount: 1,
      profileName: 'CLASSIC 25/5',
    );

    expect(result, isTrue);
    expect(log, hasLength(1));
    expect(log.first.method, equals('startService'));
    expect(log.first.arguments['remainingSeconds'], equals(1500.0));
    expect(log.first.arguments['targetMinutes'], equals(25));
    expect(log.first.arguments['phase'], equals('focus'));
    expect(log.first.arguments['cycleCount'], equals(1));
    expect(log.first.arguments['profileName'], equals('CLASSIC 25/5'));
    expect(log.first.arguments['alarmChimeId'], equals('braunBell'));
  });

  test('startService sends custom alarmChimeId when provided', () async {
    final result = await service.start(
      remainingSeconds: 1500.0,
      targetMinutes: 25,
      phase: PomodoroPhase.focus,
      cycleCount: 1,
      profileName: 'CLASSIC 25/5',
      alarmChimeId: 'zenGong',
    );

    expect(result, isTrue);
    expect(log, hasLength(1));
    expect(log.first.arguments['alarmChimeId'], equals('zenGong'));
  });

  test('startService returns false when platform channel throws', () async {
    shouldThrow = true;
    final result = await service.start(
      remainingSeconds: 1500.0,
      targetMinutes: 25,
      phase: PomodoroPhase.focus,
      cycleCount: 1,
      profileName: 'CLASSIC 25/5',
    );

    expect(result, isFalse);
    expect(log, hasLength(1));
  });

  test('stopService invokes stopService on native channel', () async {
    final result = await service.stop();

    expect(result, isTrue);
    expect(log, hasLength(1));
    expect(log.first.method, equals('stopService'));
  });

  test('stopService returns false when platform channel throws', () async {
    shouldThrow = true;
    final result = await service.stop();

    expect(result, isFalse);
    expect(log, hasLength(1));
  });

  test('timerBackgroundServiceProvider provides TimerBackgroundService instance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final providedService = container.read(timerBackgroundServiceProvider);
    expect(providedService, isA<TimerBackgroundService>());
  });
}
