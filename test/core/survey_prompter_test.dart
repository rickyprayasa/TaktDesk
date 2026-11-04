import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/review/survey_prompter.dart';
import 'package:takt_desk/features/settings/presentation/widgets/focus_survey_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SurveyPrompter prompter;
  final now = DateTime(2026, 11, 4, 12);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    prompter = SurveyPrompter(db, settle: Duration.zero);
  });

  tearDown(() async {
    prompter.dispose();
    await db.close();
  });

  Future<void> completeCycles(int n, {required DateTime from}) async {
    for (var i = 0; i < n; i++) {
      await db.recordTimerSession(
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: from.add(Duration(minutes: 30 * i)),
      );
    }
  }

  Future<SurveyKind?> finish({required bool isPro, bool locked = false, bool visible = true}) => withClock(
        Clock.fixed(now),
        () => prompter.onFocusCompleted(isPro: isPro, lockedDown: () => locked, visible: () => visible),
      );

  group('free desk', () {
    test('not before fifteen completed cycles, then once', () async {
      final events = <SurveyKind>[];
      final sub = prompter.prompts.listen(events.add);
      addTearDown(sub.cancel);

      await completeCycles(SurveyPrompter.freeMinCycles - 1, from: DateTime(2026, 10, 1));
      expect(await finish(isPro: false), isNull);

      await completeCycles(1, from: DateTime(2026, 10, 20));
      expect(await finish(isPro: false), SurveyKind.free);
      expect(await db.freeSurveyAskedAt(), now);

      expect(await finish(isPro: false), isNull);
      await pumpEventQueue();
      expect(events, [SurveyKind.free]);
    });

    test('not in lockdown, not in the background, not on the day of the Play review: it asks a later time', () async {
      await completeCycles(SurveyPrompter.freeMinCycles, from: DateTime(2026, 10, 1));
      expect(await finish(isPro: false, locked: true), isNull);
      expect(await finish(isPro: false, visible: false), isNull);
      await db.markReviewAsked(now.subtract(const Duration(hours: 2)));
      expect(await finish(isPro: false), isNull);
      expect(await db.freeSurveyAskedAt(), isNull, reason: 'nothing was shown, so it may still ask');

      await db.markReviewAsked(now.subtract(const Duration(days: 2)));
      expect(await finish(isPro: false), SurveyKind.free);
    });
  });

  group('Studio PRO', () {
    test('counts only cycles since PRO switched on, asks on the third, once', () async {
      await completeCycles(20, from: DateTime(2026, 10, 1));
      final proOn = DateTime(2026, 11, 1);
      await db.markProSeen(proOn);
      await db.markProSeen(DateTime(2026, 11, 3));
      expect(await db.proSeenAt(), proOn, reason: 'the first time is kept');

      await completeCycles(SurveyPrompter.proCyclesWithPro - 1, from: proOn.add(const Duration(hours: 1)));
      expect(await finish(isPro: true), isNull);

      await completeCycles(1, from: DateTime(2026, 11, 2));
      expect(await finish(isPro: true), SurveyKind.pro);
      expect(await db.proSurveyAskedAt(), now);
      expect(await finish(isPro: true), isNull);
      expect(await db.freeSurveyAskedAt(), isNull, reason: 'a PRO owner is never asked why they stay free');
    });

    test('without a recorded switch-on it starts counting now', () async {
      await completeCycles(10, from: DateTime(2026, 10, 1));
      expect(await finish(isPro: true), isNull);
      expect(await db.proSeenAt(), now);
    });

    test('a free user who already answered and then buys is asked the PRO survey too', () async {
      await completeCycles(SurveyPrompter.freeMinCycles, from: DateTime(2026, 10, 1));
      expect(await finish(isPro: false), SurveyKind.free);
      await db.markProSeen(DateTime(2026, 11, 1));
      await completeCycles(SurveyPrompter.proCyclesWithPro, from: DateTime(2026, 11, 2));
      expect(await finish(isPro: true), SurveyKind.pro);
    });
  });

  group('dialog', () {
    Future<List<Map<String, String>>> pumpDialog(WidgetTester tester, SurveyKind kind) async {
      final sent = <Map<String, String>>[];
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFocusSurveyDialog(
              context,
              kind: kind,
              sendEmail: ({required type, required subject, required body}) async {
                sent.add({'subject': subject, 'body': body});
                return true;
              },
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return sent;
    }

    testWidgets('SEND waits for both answers, then emails them and closes', (tester) async {
      final sent = await pumpDialog(tester, SurveyKind.pro);
      expect(find.text('WHAT MADE STUDIO PRO WORTH IT?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('survey_send')));
      await tester.pump();
      expect(sent, isEmpty);

      for (final key in ['survey_use_STUDY', 'survey_reason_THE SOUNDSCAPES']) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('survey_send')));
      // The device-info lookup goes through a platform channel.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(sent.single['subject'], '[ZYKL Survey] Studio PRO');
      expect(sent.single['body'], contains('I focus on: STUDY'));
      expect(sent.single['body'], contains('PRO was worth it for: THE SOUNDSCAPES'));
      expect(find.byType(FocusSurveyDialog), findsNothing);
    });

    testWidgets('the free survey asks what keeps them free; SKIP sends nothing', (tester) async {
      final sent = await pumpDialog(tester, SurveyKind.free);
      expect(find.text('WHAT KEEPS YOU ON THE FREE DESK?'), findsOneWidget);
      for (final reason in surveyFreeReasons) {
        expect(find.byKey(ValueKey('survey_reason_$reason')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('survey_skip')));
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
      expect(find.byType(FocusSurveyDialog), findsNothing);
    });

    testWidgets('fits a small phone', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpDialog(tester, SurveyKind.pro);
      expect(tester.takeException(), isNull);
    });
  });
}
