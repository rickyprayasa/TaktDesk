import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class _FakeLockService extends FocusLockService {
  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FocusLockController lock;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    lock = FocusLockController(service: _FakeLockService(), audioService: AudioService(isMock: true), database: db);
  });

  tearDown(() async {
    lock.dispose();
    await db.close();
  });

  Future<void> backdateLock(Duration d) async {
    lock.state = lock.state.copyWith(sessionStartTime: DateTime.now().subtract(d));
  }

  test('lockdown without a timer is recorded as lockdown-only focus', () async {
    await lock.engageLock();
    await backdateLock(const Duration(minutes: 10));
    await lock.completeUnlock();
    final rows = await db.select(db.timerSessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.isLockdownOnly, isTrue);
  });

  test('lockdown shorter than a minute is not recorded', () async {
    await lock.engageLock();
    await backdateLock(const Duration(seconds: 20));
    await lock.completeUnlock();
    expect(await db.select(db.timerSessions).get(), isEmpty);
  });

  test('a 25 min timer session under lockdown is recorded once, by the timer', () async {
    final chrono = ChronoDialController(AudioService(isMock: true), db, lock);
    lock.isTimerRunning = () => chrono.mounted && chrono.isCountingDown;
    addTearDown(chrono.dispose);

    await lock.engageLock();
    chrono.start();
    await backdateLock(const Duration(minutes: 25));
    chrono.tick(25 * 60.0); // completes the focus cycle
    await lock.completeUnlock();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final rows = await db.select(db.timerSessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.isLockdownOnly, isFalse);
    expect(rows.single.isFinished, isTrue);
    expect(rows.single.elapsedSeconds, 25 * 60);
  });

  test('timer started after locking still suppresses the lock record', () async {
    final chrono = ChronoDialController(AudioService(isMock: true), db, lock);
    lock.isTimerRunning = () => chrono.mounted && chrono.isCountingDown;
    addTearDown(chrono.dispose);

    await lock.engageLock();
    await backdateLock(const Duration(minutes: 30));
    chrono.start();
    chrono.pause();
    await lock.completeUnlock();
    expect(await db.select(db.timerSessions).get(), isEmpty);
  });

  group('abandoned sessions', () {
    test('reset after >= 1 min of focus records an unfinished session', () async {
      final chrono = ChronoDialController(AudioService(isMock: true), db);
      addTearDown(chrono.dispose);
      chrono.start();
      chrono.tick(10 * 60.0);
      chrono.reset();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final rows = await db.select(db.timerSessions).get();
      expect(rows, hasLength(1));
      expect(rows.single.isFinished, isFalse);
      expect(rows.single.elapsedSeconds, 600);
    });

    test('reset within the first minute records nothing', () async {
      final chrono = ChronoDialController(AudioService(isMock: true), db);
      addTearDown(chrono.dispose);
      chrono.start();
      chrono.tick(30);
      chrono.reset();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await db.select(db.timerSessions).get(), isEmpty);
    });
  });
}
