import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/features/timer/domain/timer_state.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class _Audio extends AudioService {
  final List<SoundEffect> played = [];
  _Audio() : super(isMock: true);

  @override
  void playFoley(SoundEffect effect) => played.add(effect);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Audio audio;
  late ChronoDialController controller;

  setUp(() {
    audio = _Audio();
    controller = ChronoDialController(audio);
  });

  tearDown(() => controller.dispose());

  test('winding the hand clicks the ratchet once per minute it moves, not per pan event', () {
    controller.setTargetMinutes(26);
    controller.setTargetMinutes(26);
    controller.setTargetMinutes(26);
    controller.setTargetMinutes(30);
    expect(audio.played, [SoundEffect.crownWind, SoundEffect.crownWind]);
  });

  test('winding in custom calibration clicks only on a changed value', () {
    controller.enterCustomCalibration();
    audio.played.clear();
    controller.setTargetMinutes(controller.state.targetMinutes);
    expect(audio.played, isEmpty);
    controller.setTargetMinutes(controller.state.targetMinutes + 5);
    expect(audio.played, [SoundEffect.crownWind]);
    expect(controller.state.setupStage, ChronoSetupStage.focus);
  });

  test('pressing the crown to start and to pause plays the crown push', () {
    controller.start();
    controller.pause();
    expect(audio.played, [SoundEffect.springButton, SoundEffect.springButton]);
  });
}
