# Focus History & Telemetry Journal Slip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement an authentic in-place thermal receipt print roll (Slip Struk Telemetri) that smoothly feeds downward from beneath the 280px bottom spec plate to display today's focus session timeline, timestamps, completion statuses, and one-tap clipboard log export.

**Architecture:** A standalone `DeskTelemetrySlipWidget` connects to `appDatabaseProvider.watchTodayTimerSessions()` via Riverpod. It uses a pure procedural paper finish with a sawtooth `PerforatedEdgePainter`, dot-matrix monospace typography, animated feed/retract mechanics, and formatting via `TelemetryLogFormatter`. The bottom `DeskSpecPlateWidget` houses the trigger and mounts the slip within the 280px modular console column.

**Tech Stack:** Flutter / Dart, Riverpod, Drift (SQLite), Procedural CustomPainter, Flutter Services (Clipboard).

## Global Constraints

- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (authentic materials, high contrast, tactile feedback, "Weniger, aber besser").
- Target platform: Mobile Android handheld console (maxWidth 440px, modular 280px chassis).
- 0 analyzer issues (`/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`).
- 100% test pass rate across repository (`/home/tuneeca/RSQUARE/flutter/bin/flutter test`).
- Avoid external raster image assets; use mathematical procedural Flutter shaders/painters.
- Offline-first: zero external network dependencies.

---

### Task 1: TelemetryLogFormatter & PerforatedEdgePainter

**Files:**
- Create: `lib/features/desk/domain/telemetry_log_formatter.dart`
- Create: `test/features/desk/telemetry_log_formatter_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class TelemetryLogFormatter {
    static String formatSessionEntry(int index, TimerSession session);
    static String formatSummary(List<TimerSession> sessions);
    static String formatFullAuditLog({
      required String editionTitle,
      required String yearLabel,
      required DateTime date,
      required List<TimerSession> sessions,
    });
  }
  ```

- [ ] **Step 1: Write failing unit test for `TelemetryLogFormatter`**

```dart
// test/features/desk/telemetry_log_formatter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/desk/domain/telemetry_log_formatter.dart';

void main() {
  group('TelemetryLogFormatter', () {
    test('formats completed and interrupted sessions correctly', () {
      final startTime = DateTime(2026, 9, 10, 14, 0);
      final finishTime1 = DateTime(2026, 9, 10, 14, 25);
      final finishTime2 = DateTime(2026, 9, 10, 15, 15);

      final session1 = TimerSession(
        id: 1,
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: startTime,
        finishedAt: finishTime1,
      );

      final session2 = TimerSession(
        id: 2,
        targetMinutes: 25,
        elapsedSeconds: 900,
        isFinished: false,
        startedAt: startTime,
        finishedAt: finishTime2,
      );

      final entry1 = TelemetryLogFormatter.formatSessionEntry(1, session1);
      expect(entry1, contains('#01'));
      expect(entry1, contains('14:00 - 14:25'));
      expect(entry1, contains('[25 MIN]'));
      expect(entry1, contains('STATUS: COMPLETED'));

      final entry2 = TelemetryLogFormatter.formatSessionEntry(2, session2);
      expect(entry2, contains('#02'));
      expect(entry2, contains('[15/25 MIN]'));
      expect(entry2, contains('STATUS: INTERRUPTED'));
    });

    test('formats summary calculations accurately', () {
      final startTime = DateTime(2026, 9, 10, 14, 0);
      final sessions = [
        TimerSession(
          id: 1,
          targetMinutes: 25,
          elapsedSeconds: 1500,
          isFinished: true,
          startedAt: startTime,
          finishedAt: startTime,
        ),
        TimerSession(
          id: 2,
          targetMinutes: 25,
          elapsedSeconds: 1500,
          isFinished: false,
          startedAt: startTime,
          finishedAt: startTime,
        ),
      ];

      final summary = TelemetryLogFormatter.formatSummary(sessions);
      expect(summary, contains('SUMMARY : 1 CYCLES · 50 MIN'));
      expect(summary, contains('RATE    : 50% FOCUS EFFICIENCY'));
    });

    test('formats empty sessions list with graceful standby notice', () {
      final log = TelemetryLogFormatter.formatFullAuditLog(
        editionTitle: 'BRAUN CLASSIC',
        yearLabel: 'MOD. 01 · 1960',
        date: DateTime(2026, 9, 10),
        sessions: [],
      );

      expect(log, contains('TAKT DESK // SESSION TELEMETRY'));
      expect(log, contains('BRAUN CLASSIC · 1960'));
      expect(log, contains('NO SESSIONS RECORDED TODAY'));
      expect(log, contains('STANDBY // COMMENCE CHRONO DIAL'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/telemetry_log_formatter_test.dart`
Expected: FAIL ("Target of URI doesn't exist: telemetry_log_formatter.dart")

- [ ] **Step 3: Implement `TelemetryLogFormatter`**

```dart
// lib/features/desk/domain/telemetry_log_formatter.dart
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';

class TelemetryLogFormatter {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static String formatSessionEntry(int index, TimerSession session) {
    final numStr = index.toString().padLeft(2, '0');
    final startStr = _timeFormat.format(session.startedAt);
    final finishStr = _timeFormat.format(session.finishedAt);
    final elapsedMin = (session.elapsedSeconds / 60).round();

    final durationStr = session.isFinished
        ? '[$elapsedMin MIN]'
        : '[$elapsedMin/${session.targetMinutes} MIN]';
    final statusStr = session.isFinished
        ? 'STATUS: COMPLETED ●'
        : 'STATUS: INTERRUPTED ○';

    return '#$numStr  $startStr - $finishStr  $durationStr\n     $statusStr';
  }

  static String formatSummary(List<TimerSession> sessions) {
    final completedCount = sessions.where((s) => s.isFinished).length;
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.elapsedSeconds);
    final totalMinutes = (totalSeconds / 60).round();
    final rate = sessions.isEmpty
        ? 0
        : ((completedCount / sessions.length) * 100).round();

    return 'SUMMARY : $completedCount CYCLES · $totalMinutes MIN\nRATE    : $rate% FOCUS EFFICIENCY';
  }

  static String formatFullAuditLog({
    required String editionTitle,
    required String yearLabel,
    required DateTime date,
    required List<TimerSession> sessions,
  }) {
    final dateStr = _dateFormat.format(date);
    final cleanYear = yearLabel.replaceAll('MOD. ', '').replaceAll('· ', '');

    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('TAKT DESK // SESSION TELEMETRY');
    buffer.writeln('EDITION : $editionTitle · $cleanYear');
    buffer.writeln('DATE    : $dateStr');
    buffer.writeln('================================');
    buffer.writeln(formatSummary(sessions));
    buffer.writeln('--------------------------------');
    buffer.writeln('LOG ENTRIES:');

    if (sessions.isEmpty) {
      buffer.writeln('[ NO SESSIONS RECORDED TODAY ]');
      buffer.writeln('STANDBY // COMMENCE CHRONO DIAL');
    } else {
      for (int i = 0; i < sessions.length; i++) {
        buffer.writeln(formatSessionEntry(i + 1, sessions[i]));
        if (i < sessions.length - 1) {
          buffer.writeln('--------------------------------');
        }
      }
    }
    buffer.writeln('================================');
    return buffer.toString();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/telemetry_log_formatter_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/desk/domain/telemetry_log_formatter.dart test/features/desk/telemetry_log_formatter_test.dart
git commit -m "feat(desk): add TelemetryLogFormatter for focus history audit formatting"
```

---

### Task 2: DeskTelemetrySlipWidget with Animated Feed and Dot-Matrix Telemetry

**Files:**
- Create: `lib/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart`
- Create: `test/features/desk/desk_telemetry_slip_widget_test.dart`

**Interfaces:**
- Consumes:
  - `appDatabaseProvider.watchTodayTimerSessions()`
  - `TelemetryLogFormatter`
  - `chassisThemeProvider`
  - `HapticService`
  - `AudioService`
- Produces:
  ```dart
  class DeskTelemetrySlipWidget extends ConsumerStatefulWidget {
    final bool isExpanded;
    final VoidCallback onRetract;
    const DeskTelemetrySlipWidget({
      super.key,
      required this.isExpanded,
      required this.onRetract,
    });
  }
  ```

- [ ] **Step 1: Write failing widget test for `DeskTelemetrySlipWidget`**

```dart
// test/features/desk/desk_telemetry_slip_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart';

void main() {
  testWidgets('DeskTelemetrySlipWidget animates expansion and renders session log entries', (tester) async {
    final now = DateTime(2026, 9, 10, 14, 0);
    final mockSessions = [
      TimerSession(
        id: 1,
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: now,
        finishedAt: now.add(const Duration(minutes: 25)),
      ),
    ];

    bool retracted = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(mockSessions)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: true,
              onRetract: () => retracted = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('TAKT DESK // SESSION TELEMETRY'), findsOneWidget);
    expect(find.textContaining('1 CYCLES · 25 MIN'), findsOneWidget);
    expect(find.textContaining('STATUS: COMPLETED ●'), findsOneWidget);
    expect(find.text('[ COPY TEXT LOG ]'), findsOneWidget);
    expect(find.text('[ RETRACT ▲ ]'), findsOneWidget);

    // Tap retract
    await tester.tap(find.text('[ RETRACT ▲ ]'));
    await tester.pumpAndSettle();
    expect(retracted, isTrue);
  });

  testWidgets('DeskTelemetrySlipWidget copies formatted telemetry text to clipboard', (tester) async {
    final now = DateTime(2026, 9, 10, 14, 0);
    final mockSessions = [
      TimerSession(
        id: 1,
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: now,
        finishedAt: now.add(const Duration(minutes: 25)),
      ),
    ];

    String? clipboardData;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardData = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value(mockSessions)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DeskTelemetrySlipWidget(
              isExpanded: true,
              onRetract: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('[ COPY TEXT LOG ]'));
    await tester.pump();

    expect(clipboardData, isNotNull);
    expect(clipboardData, contains('TAKT DESK // SESSION TELEMETRY'));
    expect(clipboardData, contains('STATUS: COMPLETED ●'));
    expect(find.text('[ COPIED! ]'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_telemetry_slip_widget_test.dart`
Expected: FAIL ("Target of URI doesn't exist")

- [ ] **Step 3: Implement `DeskTelemetrySlipWidget` and `todayTimerSessionsStreamProvider`**

In `lib/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart`:
- Define Riverpod provider `todayTimerSessionsStreamProvider = StreamProvider<List<TimerSession>>((ref) => ref.watch(appDatabaseProvider).watchTodayTimerSessions());`
- Build procedural thermal receipt roll with width 280, subtle drop shadow, background `#F5F3EB` (light) / `#202328` (dark), border `#DDD9D0` / `#2D323B`.
- Add `_PerforatedSawtoothPainter` for bottom edge serration.
- Add `SizeTransition` driven by `AnimationController` (400ms, `Curves.easeInOutCubic`).
- Add clipboard copying and ephemeral `[ COPIED! ]` feedback.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_telemetry_slip_widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/desk/presentation/widgets/desk_telemetry_slip_widget.dart test/features/desk/desk_telemetry_slip_widget_test.dart
git commit -m "feat(desk): build DeskTelemetrySlipWidget with animated thermal receipt roll and clipboard export"
```

---

### Task 3: Bottom Spec Plate Housing Integration & Verification

**Files:**
- Modify: `lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart`
- Modify: `test/features/desk/desk_spec_plate_widget_test.dart`

**Interfaces:**
- Consumes:
  - `DeskTelemetrySlipWidget`
  - `SoundEffect.dialClick`
  - `HapticService.selectionClick`
- Produces:
  - Spec plate with toggle cue `[ TELEMETRY LOG ▼ ]` / `[ TELEMETRY LOG ▲ ]` and attached `DeskTelemetrySlipWidget` mounted beneath the 280px plate.

- [ ] **Step 1: Write failing widget test asserting spec plate toggles telemetry slip**

In `test/features/desk/desk_spec_plate_widget_test.dart`:
- Add test:
  ```dart
  testWidgets('DeskSpecPlateWidget toggles DeskTelemetrySlipWidget on plate tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayFocusStatsProvider.overrideWith(
            (ref) => Stream.value(const TodayFocusStats(completedCount: 1, totalMinutes: 25)),
          ),
          todayTimerSessionsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeskSpecPlateWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially slip is not visible/collapsed
    expect(find.byType(DeskTelemetrySlipWidget), findsOneWidget);
    final initialSlip = tester.widget<DeskTelemetrySlipWidget>(find.byType(DeskTelemetrySlipWidget));
    expect(initialSlip.isExpanded, isFalse);

    // Tap plate
    await tester.tap(find.byKey(const ValueKey('desk_spec_plate_surface')));
    await tester.pumpAndSettle();

    final expandedSlip = tester.widget<DeskTelemetrySlipWidget>(find.byType(DeskTelemetrySlipWidget));
    expect(expandedSlip.isExpanded, isTrue);
  });
  ```

- [ ] **Step 2: Run test to verify failure**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_spec_plate_widget_test.dart`
Expected: FAIL

- [ ] **Step 3: Modify `DeskSpecPlateWidget` to manage expansion state and mount `DeskTelemetrySlipWidget`**

In `lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart`:
- Convert `DeskSpecPlateWidget` from `ConsumerWidget` to `ConsumerStatefulWidget`.
- Maintain `bool _isTelemetryExpanded = false;`.
- On plate tap: toggle `setState(() => _isTelemetryExpanded = !_isTelemetryExpanded);`.
- In build: return a `Column(mainAxisSize: MainAxisSize.min, children: [plateContainer, DeskTelemetrySlipWidget(isExpanded: _isTelemetryExpanded, onRetract: () => setState(() => _isTelemetryExpanded = false))])`.
- Add `ValueKey('desk_spec_plate_surface')` to the `InkWell`.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_spec_plate_widget_test.dart`
Expected: PASS

- [ ] **Step 5: Run full verification suite**

Run:
1. `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze` (0 issues)
2. `/home/tuneeca/RSQUARE/flutter/bin/flutter test` (100% pass)

- [ ] **Step 6: Commit and push**

```bash
git add lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart test/features/desk/desk_spec_plate_widget_test.dart
git commit -m "feat(desk): mount tactile DeskTelemetrySlipWidget beneath DeskSpecPlateWidget with mechanical toggle"
git push origin main
```
