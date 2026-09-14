import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/vinyl/domain/soundscape_mixer_state.dart';
import 'package:takt_desk/features/vinyl/presentation/soundscape_mixer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AudioService mockAudio;
  late ProviderContainer container;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockAudio = AudioService(isMock: true);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(mockAudio),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('SoundscapeMixerState defaults to 0.80 primary, 0.35 crackle, 0.25 binaural and unmuted', () {
    const state = SoundscapeMixerState();
    expect(state.primaryVolume, 0.80);
    expect(state.crackleVolume, 0.35);
    expect(state.binauralVolume, 0.25);
    expect(state.isPrimaryMuted, isFalse);
    expect(state.isCrackleMuted, isFalse);
    expect(state.isBinauralMuted, isFalse);
    expect(state.effectivePrimary, 0.80);
    expect(state.effectiveCrackle, 0.35);
    expect(state.effectiveBinaural, 0.25);
  });

  test('effective gain collapses to 0.0 when channel is muted', () {
    const state = SoundscapeMixerState(
      primaryVolume: 0.90,
      isPrimaryMuted: true,
      crackleVolume: 0.50,
      isCrackleMuted: true,
    );
    expect(state.effectivePrimary, 0.0);
    expect(state.effectiveCrackle, 0.0);
    expect(state.effectiveBinaural, 0.25);
  });

  test('SoundscapeMixerController updates volumes and toggles mutes', () async {
    final controller = container.read(soundscapeMixerProvider.notifier);

    controller.setPrimaryVolume(0.65);
    expect(container.read(soundscapeMixerProvider).primaryVolume, 0.65);
    expect(mockAudio.primaryVolume, 0.65);

    controller.setCrackleVolume(0.50);
    expect(container.read(soundscapeMixerProvider).crackleVolume, 0.50);
    expect(mockAudio.crackleVolume, 0.50);

    controller.setBinauralVolume(0.10);
    expect(container.read(soundscapeMixerProvider).binauralVolume, 0.10);
    expect(mockAudio.binauralVolume, 0.10);

    controller.toggleCrackleMute();
    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isTrue);
    expect(container.read(soundscapeMixerProvider).effectiveCrackle, 0.0);
    expect(mockAudio.crackleVolume, 0.0);

    controller.toggleCrackleMute();
    expect(container.read(soundscapeMixerProvider).isCrackleMuted, isFalse);
    expect(container.read(soundscapeMixerProvider).effectiveCrackle, 0.50);
    expect(mockAudio.crackleVolume, 0.50);
  });

  test('SoundscapeMixerController persists changes to AppDatabase', () async {
    final controller = container.read(soundscapeMixerProvider.notifier);

    controller.setPrimaryVolume(0.70);
    controller.setCrackleVolume(0.40);
    controller.setBinauralVolume(0.20);
    controller.togglePrimaryMute();

    // Allow async persist to complete
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final prefs = await db.getDeskPreferences();
    expect(prefs, isNotNull);
    expect(prefs!.primaryVolume, 0.70);
    expect(prefs.crackleVolume, 0.40);
    expect(prefs.binauralVolume, 0.20);
    expect(prefs.primaryMuted, isTrue);
    expect(prefs.crackleMuted, isFalse);
    expect(prefs.binauralMuted, isFalse);
  });

  test('SoundscapeMixerController clamps volumes between 0.0 and 1.0', () {
    final controller = container.read(soundscapeMixerProvider.notifier);

    controller.setPrimaryVolume(1.5);
    expect(container.read(soundscapeMixerProvider).primaryVolume, 1.0);

    controller.setPrimaryVolume(-0.2);
    expect(container.read(soundscapeMixerProvider).primaryVolume, 0.0);

    controller.setCrackleVolume(2.0);
    expect(container.read(soundscapeMixerProvider).crackleVolume, 1.0);

    controller.setCrackleVolume(-1.0);
    expect(container.read(soundscapeMixerProvider).crackleVolume, 0.0);

    controller.setBinauralVolume(3.0);
    expect(container.read(soundscapeMixerProvider).binauralVolume, 1.0);

    controller.setBinauralVolume(-0.5);
    expect(container.read(soundscapeMixerProvider).binauralVolume, 0.0);
  });

  test('SoundscapeMixerController toggles primary and binaural mutes', () {
    final controller = container.read(soundscapeMixerProvider.notifier);

    controller.togglePrimaryMute();
    expect(container.read(soundscapeMixerProvider).isPrimaryMuted, isTrue);
    expect(container.read(soundscapeMixerProvider).effectivePrimary, 0.0);

    controller.togglePrimaryMute();
    expect(container.read(soundscapeMixerProvider).isPrimaryMuted, isFalse);
    expect(container.read(soundscapeMixerProvider).effectivePrimary, 0.80);

    controller.toggleBinauralMute();
    expect(container.read(soundscapeMixerProvider).isBinauralMuted, isTrue);
    expect(container.read(soundscapeMixerProvider).effectiveBinaural, 0.0);

    controller.toggleBinauralMute();
    expect(container.read(soundscapeMixerProvider).isBinauralMuted, isFalse);
    expect(container.read(soundscapeMixerProvider).effectiveBinaural, 0.25);
  });

  test('SoundscapeMixerController loads existing preferences on init', () async {
    await db.updateDeskPreferences(
      primaryVolume: 0.55,
      crackleVolume: 0.45,
      binauralVolume: 0.15,
      primaryMuted: false,
      crackleMuted: true,
      binauralMuted: false,
    );

    final secondContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(mockAudio),
      ],
    );

    secondContainer.read(soundscapeMixerProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = secondContainer.read(soundscapeMixerProvider);
    expect(state.primaryVolume, 0.55);
    expect(state.crackleVolume, 0.45);
    expect(state.binauralVolume, 0.15);
    expect(state.isPrimaryMuted, isFalse);
    expect(state.isCrackleMuted, isTrue);
    expect(state.isBinauralMuted, isFalse);
    expect(state.effectiveCrackle, 0.0);

    secondContainer.dispose();
  });

  test('SoundscapeMixerState copyWith and equality work correctly', () {
    const state1 = SoundscapeMixerState();
    final state2 = state1.copyWith(primaryVolume: 0.60, isPrimaryMuted: true);

    expect(state2.primaryVolume, 0.60);
    expect(state2.crackleVolume, 0.35);
    expect(state2.binauralVolume, 0.25);
    expect(state2.isPrimaryMuted, isTrue);
    expect(state2.isCrackleMuted, isFalse);
    expect(state2.isBinauralMuted, isFalse);

    const state3 = SoundscapeMixerState(
      primaryVolume: 0.60,
      isPrimaryMuted: true,
    );
    expect(state2, equals(state3));
    expect(state2.hashCode, equals(state3.hashCode));
    expect(state1 == state2, isFalse);
  });
}
