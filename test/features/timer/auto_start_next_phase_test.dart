import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/services/timer_background_service.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_phase.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class _Audio extends AudioService {
  final List<SoundEffect> foley = [];
  final List<String> chimes = [];
  _Audio() : super(isMock: true);

  @override
  void playFoley(SoundEffect effect) => foley.add(effect);

  @override
  void playAlarmChime(String chimeId) => chimes.add(chimeId);
}

class _Background extends TimerBackgroundService {
  final List<String> calls = [];
  final List<bool> autoFlags = [];
  NativeTimerStatus? next;

  @override
  Future<bool> start({
    required double remainingSeconds,
    required int targetMinutes,
    required PomodoroPhase phase,
    required int cycleCount,
    required String profileName,
    String alarmChimeId = 'braunBell',
    bool autoStartNext = false,
  }) async {
    calls.add('start:${phase.name}:$targetMinutes');
    autoFlags.add(autoStartNext);
    return true;
  }

  @override
  Future<bool> stop() async {
    calls.add('stop');
    return true;
  }

  @override
  Future<NativeTimerStatus?> status() async => next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Audio audio;
  late _Background background;
  late DeskPreferencesController prefs;
  late ChronoDialController controller;

  setUp(() {
    audio = _Audio();
    background = _Background();
    prefs = DeskPreferencesController();
    controller = ChronoDialController(audio, null, null, prefs, null, background);
  });

  tearDown(() => controller.dispose());

  test('off (default): the phase ends in standby and the native countdown stops', () {
    controller.start();
    controller.tick(25 * 60);
    expect(controller.state.phase, PomodoroPhase.shortBreak);
    expect(controller.state.isRunning, isFalse);
    expect(background.calls, ['start:focus:25', 'stop']);
    expect(background.autoFlags, [false]);
  });

  test('on: the break starts right after the focus, in place, without a button sound', () async {
    await prefs.setAutoStartNextPhase(true);
    controller.start();
    audio.foley.clear();
    controller.tick(25 * 60);

    expect(controller.state.phase, PomodoroPhase.shortBreak);
    expect(controller.state.isRunning, isTrue);
    expect(controller.state.remainingSeconds, 5 * 60);
    // No stop between the phases: the service keeps running and restarts the countdown in place.
    expect(background.calls, ['start:focus:25', 'start:shortBreak:5']);
    expect(background.autoFlags, [true, true]);
    expect(audio.chimes, hasLength(1));
    expect(audio.foley, isNot(contains(SoundEffect.springButton)));

    controller.tick(5 * 60);
    expect(controller.state.phase, PomodoroPhase.focus);
    expect(controller.state.cycleCount, 2);
    expect(controller.state.isRunning, isTrue);
  });

  test('on: a phase the native alarm finished while Dart slept also rolls into the next one', () async {
    await prefs.setAutoStartNextPhase(true);
    controller.start();
    background.next = const NativeTimerStatus(remainingSeconds: -2, running: false);
    await controller.resyncWithNative();
    expect(controller.state.phase, PomodoroPhase.shortBreak);
    expect(controller.state.isRunning, isTrue);
    expect(audio.chimes, isEmpty, reason: 'native already rang');
  });
}
