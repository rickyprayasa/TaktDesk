import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/haptics/haptic_service.dart';
import 'package:takt_desk/features/settings/presentation/settings_controller.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AudioService audioService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    audioService = AudioService(isMock: true);
    HapticService.enabled = true;
  });

  tearDown(() async {
    await db.close();
  });

  test('SettingsController loads defaults and toggles foley and haptics', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isTrue);
    expect(container.read(deskPreferencesControllerProvider).hapticsEnabled, isTrue);

    await controller.setFoleyEnabled(false);
    expect(container.read(deskPreferencesControllerProvider).foleyEnabled, isFalse);
    expect(audioService.foleyEnabled, isFalse);

    await controller.setHapticsEnabled(false);
    expect(container.read(deskPreferencesControllerProvider).hapticsEnabled, isFalse);
    expect(HapticService.enabled, isFalse);
  });

  test('SettingsController adjusts volume and parallax setting and updates database', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    await controller.setVolume(0.42);
    expect(container.read(deskPreferencesControllerProvider).soundVolume, equals(0.42));
    expect(audioService.volume, equals(0.42));

    await controller.setVolume(1.5);
    expect(container.read(deskPreferencesControllerProvider).soundVolume, equals(1.0));
    await controller.setVolume(-0.2);
    expect(container.read(deskPreferencesControllerProvider).soundVolume, equals(0.0));

    await controller.setParallaxEnabled(false);
    expect(container.read(deskPreferencesControllerProvider).parallaxEnabled, isFalse);

    final persisted = await db.watchPreferences().first;
    expect(persisted, isNotNull);
    expect(persisted!.soundVolume, equals(0.0));
    expect(persisted.parallaxEnabled, isFalse);
  });

  test('SettingsController restores persisted preferences on init', () async {
    await db.updatePreferences(
      soundVolume: 0.35,
      foleyEnabled: false,
      hapticsEnabled: false,
      parallaxEnabled: false,
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    final state = container.read(deskPreferencesControllerProvider);
    expect(state.soundVolume, equals(0.35));
    expect(state.foleyEnabled, isFalse);
    expect(state.hapticsEnabled, isFalse);
    expect(state.parallaxEnabled, isFalse);
    expect(audioService.volume, equals(0.35));
    expect(audioService.foleyEnabled, isFalse);
    expect(HapticService.enabled, isFalse);
  });

  test('SettingsController clearAllSessions deletes all recorded timer sessions', () async {
    await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: DateTime.now(),
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.clearAllSessions();

    final sessions = await db.watchAllTimerSessions().first;
    expect(sessions, isEmpty);
  });

  test('todayFocusStatsProvider reacts to today sessions and computes quadrantProgress', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final yesterday = startOfDay.subtract(const Duration(hours: 3));

    // Yesterday session (should be excluded)
    await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: yesterday,
    );

    // Today session 1: finished 25 min (1500s)
    await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: startOfDay.add(const Duration(minutes: 10)),
    );

    // Today session 2: finished 25 min (1500s)
    await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: startOfDay.add(const Duration(minutes: 50)),
    );

    // Today session 3: unfinished 5 min (300s)
    await db.recordTimerSession(
      targetMinutes: 5,
      elapsedSeconds: 300,
      isFinished: false,
      startedAt: startOfDay.add(const Duration(minutes: 90)),
    );

    final stats = await container.read(todayFocusStatsProvider.future);
    expect(stats.completedCount, equals(2));
    expect(stats.totalMinutes, equals(55)); // (1500 + 1500 + 300) / 60 = 55
    expect(stats.quadrantProgress, equals(2)); // 2 % 4 = 2
  });

  test('lifetimeFocusStatsProvider computes total completed sessions and total hours', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    await db.recordTimerSession(
      targetMinutes: 30,
      elapsedSeconds: 1800,
      isFinished: true,
      startedAt: DateTime(2026, 1, 1, 10, 0),
    );

    await db.recordTimerSession(
      targetMinutes: 30,
      elapsedSeconds: 1800,
      isFinished: true,
      startedAt: DateTime(2026, 1, 2, 10, 0),
    );

    final stats = await container.read(lifetimeFocusStatsProvider.future);
    expect(stats.totalSessions, equals(2));
    expect(stats.totalHours, closeTo(1.0, 0.001)); // 3600 seconds = 1.0 hour
  });

  test('AudioService and HapticService respect enabled flags', () async {
    await audioService.init();
    audioService.setFoleyEnabled(false);
    expect(audioService.foleyEnabled, isFalse);
    // Should not throw or crash when disabled
    audioService.playFoley(SoundEffect.dialClick);

    HapticService.enabled = false;
    expect(HapticService.enabled, isFalse);
    await HapticService.dialTick();
    await HapticService.mechanicalPress();
    await HapticService.paperTorn();
    await HapticService.stampDone();
    await HapticService.tick();
    await HapticService.selectionClick();
    await HapticService.impactLight();
    await HapticService.impactHeavy();
    await HapticService.lightClick();
    await HapticService.heavyClick();
  });

  test('SettingsController initializes default selectedEdition and isProSimulated', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(deskPreferencesControllerProvider);
    expect(state.selectedEdition, equals('braunClassic'));
    expect(state.isProSimulated, isTrue);
  });

  test('SettingsController setHardwareEdition updates state, ThemeController, and database', () async {
    final themeController = ThemeController();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
        chassisThemeProvider.overrideWith((ref) => themeController),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    await controller.setHardwareEdition(HardwareEditionType.titaniumStealth);

    expect(container.read(deskPreferencesControllerProvider).selectedEdition, equals('titaniumStealth'));
    expect(themeController.state.edition.type, equals(HardwareEditionType.titaniumStealth));

    final persisted = await db.watchPreferences().first;
    expect(persisted, isNotNull);
    expect(persisted!.selectedEdition, equals('titaniumStealth'));
  });

  test('SettingsController setProSimulated updates state, ThemeController, and database', () async {
    final themeController = ThemeController();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
        chassisThemeProvider.overrideWith((ref) => themeController),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    await controller.setProSimulated(false);

    expect(container.read(deskPreferencesControllerProvider).isProSimulated, isFalse);
    expect(themeController.state.isProUnlocked, isFalse);

    final persisted = await db.watchPreferences().first;
    expect(persisted, isNotNull);
    expect(persisted!.isProSimulated, isFalse);
  });

  test('SettingsController restores selectedEdition and isProSimulated on init', () async {
    await db.updatePreferences(
      selectedEdition: 'bauhausHeritage',
      isProSimulated: true,
    );

    final themeController = ThemeController();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
        chassisThemeProvider.overrideWith((ref) => themeController),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    final state = container.read(deskPreferencesControllerProvider);
    expect(state.selectedEdition, equals('bauhausHeritage'));
    expect(state.isProSimulated, isTrue);
    expect(themeController.state.edition.type, equals(HardwareEditionType.bauhausHeritage));
    expect(themeController.state.isProUnlocked, isTrue);
  });

  test('attempting setHardwareEdition to premium fails when isProSimulated is false', () async {
    final themeController = ThemeController();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
        chassisThemeProvider.overrideWith((ref) => themeController),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();
    await controller.setProSimulated(false);

    expect(container.read(deskPreferencesControllerProvider).isProSimulated, isFalse);
    expect(themeController.state.isProUnlocked, isFalse);

    final applied = await controller.setHardwareEdition(HardwareEditionType.titaniumStealth);

    expect(applied, isFalse);
    expect(container.read(deskPreferencesControllerProvider).selectedEdition, equals('braunClassic'));
    expect(themeController.state.edition.type, equals(HardwareEditionType.braunClassic));

    final persisted = await db.watchPreferences().first;
    expect(persisted!.selectedEdition, equals('braunClassic'));
  });

  test('calling setProSimulated(false) on premium edition reverts to braunClassic across state, theme, and DB', () async {
    final themeController = ThemeController();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
        chassisThemeProvider.overrideWith((ref) => themeController),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    final applied = await controller.setHardwareEdition(HardwareEditionType.titaniumStealth);
    expect(applied, isTrue);
    expect(container.read(deskPreferencesControllerProvider).selectedEdition, equals('titaniumStealth'));
    expect(themeController.state.edition.type, equals(HardwareEditionType.titaniumStealth));

    await controller.setProSimulated(false);

    expect(container.read(deskPreferencesControllerProvider).isProSimulated, isFalse);
    expect(container.read(deskPreferencesControllerProvider).selectedEdition, equals('braunClassic'));
    expect(themeController.state.edition.type, equals(HardwareEditionType.braunClassic));
    expect(themeController.state.isProUnlocked, isFalse);

    final persisted = await db.watchPreferences().first;
    expect(persisted!.selectedEdition, equals('braunClassic'));
    expect(persisted.isProSimulated, isFalse);
  });

  test('restoring SQLite state with premium edition but isProSimulated false falls back to braunClassic', () async {
    await db.updatePreferences(
      selectedEdition: 'titaniumStealth',
      isProSimulated: false,
    );

    final themeController = ThemeController();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
        chassisThemeProvider.overrideWith((ref) => themeController),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    final state = container.read(deskPreferencesControllerProvider);
    expect(state.selectedEdition, equals('braunClassic'));
    expect(state.isProSimulated, isFalse);
    expect(themeController.state.edition.type, equals(HardwareEditionType.braunClassic));
    expect(themeController.state.isProUnlocked, isFalse);
  });

  test('calling setProSimulated(false) reverts premium vinyl track to Track 0 (Lo-fi Rain)', () async {
    final themeController = ThemeController();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
        chassisThemeProvider.overrideWith((ref) => themeController),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    final vinylController = container.read(vinylProvider.notifier);
    // Track 4 is Campfire Embers (premium)
    final equipped = vinylController.selectTrack(4, isPro: true);
    expect(equipped, isTrue);
    expect(container.read(vinylProvider).selectedTrackIndex, equals(4));
    expect(container.read(vinylProvider).currentTrack.name, equals('Campfire Embers'));

    // Revoke Pro clearance
    await controller.setProSimulated(false);

    // Should have reverted to Track 0 (Lo-fi Rain)
    expect(container.read(vinylProvider).selectedTrackIndex, equals(0));
    expect(container.read(vinylProvider).currentTrack.name, equals('Lo-fi Rain'));
  });

  test('SettingsController manages alarmChimeId preference with default braunBell and persistence', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audioService),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(deskPreferencesControllerProvider.notifier);
    await controller.init();

    // Default
    expect(container.read(deskPreferencesControllerProvider).alarmChimeId, equals('braunBell'));

    // Set to tibetanBowl
    await controller.setAlarmChime('tibetanBowl');
    expect(container.read(deskPreferencesControllerProvider).alarmChimeId, equals('tibetanBowl'));

    // Verify persisted
    final persisted = await db.watchPreferences().first;
    expect(persisted, isNotNull);
    expect(persisted!.alarmChimeId, equals('tibetanBowl'));
  });
}
