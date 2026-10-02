import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/services/timer_background_service.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class _RecordingAudio extends AudioService {
  final List<String> chimes = [];
  _RecordingAudio() : super(isMock: true);

  @override
  void playAlarmChime(String chimeId) => chimes.add(chimeId);
}

class _FakeBackground extends TimerBackgroundService {
  NativeTimerStatus? next;
  _FakeBackground();

  @override
  Future<bool> start({
    required double remainingSeconds,
    required int targetMinutes,
    required PomodoroPhase phase,
    required int cycleCount,
    required String profileName,
    String alarmChimeId = 'braunBell',
  }) async =>
      true;

  @override
  Future<bool> stop() async => true;

  @override
  Future<NativeTimerStatus?> status() async => next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingAudio audio;
  late _FakeBackground background;
  late ChronoDialController controller;

  setUp(() {
    audio = _RecordingAudio();
    background = _FakeBackground();
    controller = ChronoDialController(audio, null, null, null, null, background);
    controller.start();
  });

  tearDown(() => controller.dispose());

  test('catches up when Dart fell behind the native deadline', () async {
    background.next = const NativeTimerStatus(remainingSeconds: 600, running: true);
    await controller.resyncWithNative();
    expect(controller.state.remainingSeconds, closeTo(600, 0.01));
    expect(controller.state.isRunning, isTrue);
  });

  test('gives time back after a forward wall-clock jump', () async {
    controller.tick(1000); // Dart over-counted
    background.next = const NativeTimerStatus(remainingSeconds: 1400, running: true);
    await controller.resyncWithNative();
    expect(controller.state.remainingSeconds, closeTo(1400, 0.01));
  });

  test('session finished natively advances the phase without a second chime', () async {
    background.next = const NativeTimerStatus(remainingSeconds: -30, running: false);
    await controller.resyncWithNative();
    expect(controller.state.phase, PomodoroPhase.shortBreak);
    expect(controller.state.isRunning, isFalse);
    expect(audio.chimes, isEmpty);
  });

  test('no native session leaves the countdown untouched', () async {
    background.next = null;
    final before = controller.state.remainingSeconds;
    await controller.resyncWithNative();
    expect(controller.state.remainingSeconds, before);
  });
}
