import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/review/review_prompter.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class _FakeRequester implements ReviewRequester {
  bool available = true;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeRequester play;
  late ReviewPrompter prompter;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    play = _FakeRequester();
    prompter = ReviewPrompter(db, play, settle: Duration.zero);
  });

  tearDown(() => db.close());

  Future<void> completeCycles(int n) async {
    for (var i = 0; i < n; i++) {
      await db.recordTimerSession(
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: DateTime(2026, 10, 1).add(Duration(hours: i)),
      );
    }
  }

  Future<bool> finish({bool locked = false, bool visible = true}) =>
      prompter.onFocusCompleted(lockedDown: () => locked, visible: () => visible);

  test('not before ten completed cycles', () async {
    await completeCycles(ReviewPrompter.minCompletedCycles - 1);
    expect(await finish(), isFalse);
    expect(play.requests, 0);
    expect(await db.reviewAskedAt(), isNull);
  });

  test('asks once at ten cycles, never again', () async {
    await completeCycles(ReviewPrompter.minCompletedCycles);
    expect(await finish(), isTrue);
    expect(play.requests, 1);
    expect(await db.reviewAskedAt(), isNotNull);

    await completeCycles(5);
    expect(await finish(), isFalse);
    expect(play.requests, 1);
  });

  test('not in lockdown, not in the background, not without Play: it asks a later time instead', () async {
    await completeCycles(ReviewPrompter.minCompletedCycles);
    expect(await finish(locked: true), isFalse);
    expect(await finish(visible: false), isFalse);
    play.available = false;
    expect(await finish(), isFalse);
    expect(play.requests, 0);
    expect(await db.reviewAskedAt(), isNull, reason: 'nothing was shown, so it may still ask');

    play.available = true;
    expect(await finish(), isTrue);
  });

  test('the timer signals a focus that ran to its end, not a reset or a break', () async {
    final timer = ChronoDialController(null, db);
    addTearDown(timer.dispose);
    var signals = 0;
    final sub = timer.focusCompleted.listen((_) => signals++);
    addTearDown(sub.cancel);

    timer.start();
    timer.tick(600);
    timer.reset();
    await pumpEventQueue();
    expect(signals, 0, reason: 'reset');

    timer.start();
    timer.tick(25 * 60);
    await pumpEventQueue();
    expect(signals, 1, reason: 'focus ran to its end');

    timer.start();
    timer.tick(5 * 60); // the break ends
    await pumpEventQueue();
    expect(signals, 1, reason: 'a break is not a focus');
    await Future<void>.delayed(const Duration(milliseconds: 20)); // let the session rows land before close
  });
}
