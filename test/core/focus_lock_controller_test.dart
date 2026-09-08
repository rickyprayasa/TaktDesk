import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/core/focus/focus_lock_state.dart';

class FakeFocusLockService extends FocusLockService {
  bool enabled = false;
  @override
  Future<bool> enableFocusLock() async {
    enabled = true;
    return true;
  }
  @override
  Future<bool> disableFocusLock() async {
    enabled = false;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusLockController', () {
    late FakeFocusLockService fakeService;
    late FocusLockController controller;

    setUp(() {
      fakeService = FakeFocusLockService();
      controller = FocusLockController(service: fakeService);
    });

    test('initial state is unlocked with 0 progress', () {
      expect(controller.state.isLocked, isFalse);
      expect(controller.state.unlockProgress, 0.0);
      expect(controller.state.isHolding, isFalse);
      expect(controller.state.sessionStartTime, isNull);
    });

    test('FocusLockState copyWith updates fields and respects clearStartTime', () {
      final now = DateTime.now();
      const s0 = FocusLockState();
      final s1 = s0.copyWith(
        isLocked: true,
        isHolding: true,
        unlockProgress: 0.5,
        sessionStartTime: now,
      );
      expect(s1.isLocked, isTrue);
      expect(s1.isHolding, isTrue);
      expect(s1.unlockProgress, 0.5);
      expect(s1.sessionStartTime, now);

      final s2 = s1.copyWith(clearStartTime: true);
      expect(s2.sessionStartTime, isNull);
      expect(s2.isLocked, isTrue);
    });

    test('engageLock sets isLocked to true and calls service', () async {
      await controller.engageLock();
      expect(controller.state.isLocked, isTrue);
      expect(fakeService.enabled, isTrue);
      expect(controller.state.sessionStartTime, isNotNull);
    });

    test('engageLock is no-op if already locked', () async {
      await controller.engageLock();
      final startTime = controller.state.sessionStartTime;
      await controller.engageLock();
      expect(controller.state.sessionStartTime, startTime);
    });

    test('updateHoldProgress updates progress when locked', () async {
      await controller.engageLock();
      controller.updateHoldProgress(0.5);
      expect(controller.state.isHolding, isTrue);
      expect(controller.state.unlockProgress, 0.5);
    });

    test('updateHoldProgress clamps values between 0.0 and 1.0', () async {
      await controller.engageLock();
      controller.updateHoldProgress(1.5);
      expect(controller.state.unlockProgress, 1.0);

      controller.updateHoldProgress(-0.5);
      expect(controller.state.unlockProgress, 0.0);
    });

    test('updateHoldProgress does nothing if not locked', () {
      controller.updateHoldProgress(0.5);
      expect(controller.state.isHolding, isFalse);
      expect(controller.state.unlockProgress, 0.0);
    });

    test('cancelHold resets unlockProgress to 0.0 and isHolding to false', () async {
      await controller.engageLock();
      controller.updateHoldProgress(0.8);
      controller.cancelHold();
      expect(controller.state.isHolding, isFalse);
      expect(controller.state.unlockProgress, 0.0);
    });

    test('cancelHold does nothing if not locked', () {
      controller.cancelHold();
      expect(controller.state.isHolding, isFalse);
      expect(controller.state.unlockProgress, 0.0);
    });

    test('completeUnlock releases lock and resets state', () async {
      await controller.engageLock();
      controller.updateHoldProgress(1.0);
      await controller.completeUnlock();
      expect(controller.state.isLocked, isFalse);
      expect(controller.state.unlockProgress, 0.0);
      expect(controller.state.isHolding, isFalse);
      expect(controller.state.sessionStartTime, isNull);
      expect(fakeService.enabled, isFalse);
    });

    test('completeUnlock does nothing if not locked', () async {
      await controller.completeUnlock();
      expect(controller.state.isLocked, isFalse);
      expect(fakeService.enabled, isFalse);
    });

    test('completeUnlock records timer session to database when provided', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final audio = AudioService(isMock: true);
      await audio.init();
      addTearDown(audio.dispose);

      final c = FocusLockController(
        service: fakeService,
        audioService: audio,
        database: db,
      );

      await c.engageLock();
      // Fast forward or simulate session started in past
      c.state = c.state.copyWith(
        sessionStartTime: DateTime.now().subtract(const Duration(seconds: 120)),
      );
      await c.completeUnlock();

      final sessions = await db.select(db.timerSessions).get();
      expect(sessions.length, 1);
      expect(sessions.first.elapsedSeconds, greaterThanOrEqualTo(120));
      expect(sessions.first.isFinished, isTrue);
    });

    test('focusLockProvider resolves correctly via Riverpod', () {
      final container = ProviderContainer(
        overrides: [
          focusLockServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final c = container.read(focusLockProvider.notifier);
      final s = container.read(focusLockProvider);
      expect(c, isA<FocusLockController>());
      expect(s.isLocked, isFalse);
    });
  });
}
