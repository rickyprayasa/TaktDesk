import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/onboarding/permission_service.dart';
import 'package:takt_desk/features/onboarding/presentation/onboarding_screen.dart';
import 'package:takt_desk/features/timer/domain/pomodoro_profile.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

class _FakePermissions extends PermissionService {
  NotificationPermission status;
  bool grantOnRequest;
  int requests = 0;
  int settingsOpened = 0;
  _FakePermissions() : status = NotificationPermission.denied, grantOnRequest = true;

  @override
  Future<NotificationPermission> notificationStatus() async => status;

  @override
  Future<bool> requestNotifications() async {
    requests++;
    if (grantOnRequest) status = NotificationPermission.granted;
    return grantOnRequest;
  }

  @override
  Future<void> openNotificationSettings() async => settingsOpened++;
}

class _FakeFocusLock extends FocusLockService {
  bool dnd = false;
  int settingsOpened = 0;

  @override
  Future<bool> isNotificationPolicyAccessGranted() async => dnd;

  @override
  Future<bool> openNotificationPolicySettings() async {
    settingsOpened++;
    return true;
  }
}

void main() {
  late AppDatabase db;
  late _FakePermissions permissions;
  late _FakeFocusLock focusLock;
  late ProviderContainer container;
  late int finished;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    permissions = _FakePermissions();
    focusLock = _FakeFocusLock();
    finished = 0;
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      permissionServiceProvider.overrideWithValue(permissions),
      focusLockServiceProvider.overrideWithValue(focusLock),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: OnboardingScreen(onFinished: () => finished++)),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('walks through rhythm, notifications and lockdown, then remembers it is done', (tester) async {
    await open(tester);
    expect(find.text('Welcome to ZYKL.'), findsOneWidget);
    expect(find.text('[ SETUP // 1 OF 5 ]'), findsOneWidget);

    await tapKey(tester, 'onboarding_next');
    expect(find.text('Pick your rhythm.'), findsOneWidget);
    expect(find.text('DEEP WORK 50/10'), findsOneWidget);
    await tapKey(tester, 'onboarding_rhythm_monastic');
    expect(container.read(chronoDialProvider).profile.type, PomodoroProfileType.monastic);

    await tapKey(tester, 'onboarding_next');
    expect(find.text('Let the timer speak up.'), findsOneWidget);
    await tapKey(tester, 'onboarding_allow_notifications');
    expect(permissions.requests, 1);
    expect(find.text('Silence the world, on purpose.'), findsOneWidget, reason: 'allowed: straight on');

    await tapKey(tester, 'onboarding_open_dnd_settings');
    expect(focusLock.settingsOpened, 1);
    // Back from Settings with access granted
    focusLock.dnd = true;
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding_dnd_granted')), findsOneWidget);

    await tapKey(tester, 'onboarding_next');
    expect(find.text('You\'re set.'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_skip')), findsNothing);
    expect(await db.isOnboardingDone(), isFalse);
    await tapKey(tester, 'onboarding_finish');
    expect(finished, 1);
    expect(await db.isOnboardingDone(), isTrue);
    await done(tester);
  });

  testWidgets('a refused notification permission offers Android settings and lets the user go on', (tester) async {
    permissions.grantOnRequest = false;
    await open(tester);
    await tapKey(tester, 'onboarding_next');
    await tapKey(tester, 'onboarding_next');
    await tapKey(tester, 'onboarding_allow_notifications');
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    await tapKey(tester, 'onboarding_open_notification_settings');
    expect(permissions.settingsOpened, 1);
    await tapKey(tester, 'onboarding_next');
    expect(find.text('Silence the world, on purpose.'), findsOneWidget);
    await done(tester);
  });

  testWidgets('no notification step where Android already allows them', (tester) async {
    permissions.status = NotificationPermission.notRequired;
    await open(tester);
    expect(find.text('[ SETUP // 1 OF 4 ]'), findsOneWidget);
    await tapKey(tester, 'onboarding_next');
    await tapKey(tester, 'onboarding_next');
    expect(find.text('Silence the world, on purpose.'), findsOneWidget);
    await done(tester);
  });

  testWidgets('skip ends the walkthrough at once and it is not shown again', (tester) async {
    await open(tester);
    await tapKey(tester, 'onboarding_skip');
    expect(finished, 1);
    expect(await db.isOnboardingDone(), isTrue);
    expect(permissions.requests, 0, reason: 'skipping asks for nothing');
    await done(tester);
  });
}
