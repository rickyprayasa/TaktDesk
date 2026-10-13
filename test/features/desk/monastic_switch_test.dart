import 'package:flutter/material.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/desk/presentation/widgets/monastic_switch_widget.dart';

class MockFocusLockService extends FocusLockService {
  bool dndGranted;
  int settingsOpened = 0;
  MockFocusLockService({this.dndGranted = true});

  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
  @override
  Future<bool> isNotificationPolicyAccessGranted() async => dndGranted;
  @override
  Future<bool> openNotificationPolicySettings() async {
    settingsOpened++;
    return true;
  }
}

Future<ProviderContainer> _pumpSwitch(WidgetTester tester, MockFocusLockService service) async {
  final container = ProviderContainer(
    overrides: [focusLockServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: MonasticSwitchWidget())),
    ),
  );
  return container;
}

void main() {
  testWidgets('MonasticSwitchWidget renders and toggles focus lock', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MonasticSwitchWidget(),
          ),
        ),
      ),
    );

    expect(find.text('MONASTIC'), findsOneWidget);
    expect(find.text('LOCKDOWN'), findsOneWidget);

    // Tap switch to engage
    await tester.tap(find.byType(MonasticSwitchWidget));
    await tester.pump();

    expect(container.read(focusLockProvider).isLocked, isTrue);
  });

  group('Do Not Disturb pre-flight', () {
    testWidgets('locks straight away when DND access is granted', (tester) async {
      final container = await _pumpSwitch(tester, MockFocusLockService());
      await tester.tap(find.byType(MonasticSwitchWidget));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('lockdown_silence_preflight')), findsNothing);
      expect(container.read(focusLockProvider).isLocked, isTrue);
    });

    testWidgets('without access, explains and can lock without silence', (tester) async {
      final service = MockFocusLockService(dndGranted: false);
      final container = await _pumpSwitch(tester, service);
      await tester.tap(find.byType(MonasticSwitchWidget));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('lockdown_silence_preflight')), findsOneWidget);
      expect(container.read(focusLockProvider).isLocked, isFalse);

      await tester.tap(find.byKey(const ValueKey('lockdown_without_silence')));
      await tester.pumpAndSettle();
      expect(container.read(focusLockProvider).isLocked, isTrue);
      expect(service.settingsOpened, 0);
    });

    testWidgets('grant access opens Android settings, then locks on return once granted', (tester) async {
      final service = MockFocusLockService(dndGranted: false);
      final container = await _pumpSwitch(tester, service);
      await tester.tap(find.byType(MonasticSwitchWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lockdown_grant_dnd')));
      await tester.pumpAndSettle();
      expect(service.settingsOpened, 1);
      expect(container.read(focusLockProvider).isLocked, isFalse);

      // The user grants access in Android settings and comes back.
      service.dndGranted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(container.read(focusLockProvider).isLocked, isTrue);
    });

    testWidgets('returning without granting does not lock', (tester) async {
      final service = MockFocusLockService(dndGranted: false);
      final container = await _pumpSwitch(tester, service);
      await tester.tap(find.byType(MonasticSwitchWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lockdown_grant_dnd')));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(container.read(focusLockProvider).isLocked, isFalse);
    });

    testWidgets('dismissing the dialog does not lock', (tester) async {
      final container = await _pumpSwitch(tester, MockFocusLockService(dndGranted: false));
      await tester.tap(find.byType(MonasticSwitchWidget));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5)); // barrier
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('lockdown_silence_preflight')), findsNothing);
      expect(container.read(focusLockProvider).isLocked, isFalse);
    });
  });

  testWidgets('MonasticSwitchWidget renders locked state and handles tap when locked', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MonasticSwitchWidget(),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Monastic Focus Inactive',
      ),
      findsOneWidget,
    );

    // Engage lock
    await container.read(focusLockProvider.notifier).engageLock();
    await tester.pumpAndSettle();

    expect(find.text('MONASTIC'), findsOneWidget);
    expect(find.text('ENGAGED'), findsOneWidget);
    expect(find.text('LOCKDOWN'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Monastic Focus Engaged',
      ),
      findsOneWidget,
    );

    // Tap while locked should not error or change state
    await tester.tap(find.byType(MonasticSwitchWidget));
    await tester.pumpAndSettle();
    expect(container.read(focusLockProvider).isLocked, isTrue);
  });

  testWidgets('MonasticSwitchWidget renders LED and text in themeState.filamentColor when locked', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
    await container.read(focusLockProvider.notifier).engageLock();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MonasticSwitchWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify outer container border and shadow use titaniumStealth.filamentColor
    final gestureFinder = find.byType(GestureDetector);
    final outerContainer = tester.widget<Container>(
      find.descendant(of: gestureFinder, matching: find.byType(Container)).first,
    );
    final outerDecoration = outerContainer.decoration as BoxDecoration;
    final border = outerDecoration.border as Border;
    expect(border.top.color, equals(const Color(0xFFFF9E00).withValues(alpha: 0.8)));
    expect(outerDecoration.boxShadow?.first.color, equals(const Color(0xFFFF9E00).withValues(alpha: 0.3)));

    // Verify LED indicator uses titaniumStealth.filamentColor
    final ledFinder = find.descendant(
      of: find.byType(MonasticSwitchWidget),
      matching: find.byType(AnimatedContainer),
    );
    expect(ledFinder, findsOneWidget);
    final animatedContainer = tester.widget<AnimatedContainer>(ledFinder);
    final ledBox = animatedContainer.decoration as BoxDecoration;
    expect(ledBox.color, equals(const Color(0xFFFF9E00)));
    expect(ledBox.boxShadow?.first.color, equals(const Color(0xFFFF9E00).withValues(alpha: 0.8)));

    // Verify ENGAGED text uses titaniumStealth.filamentColor
    final engagedText = tester.widget<Text>(find.text('ENGAGED'));
    expect(engagedText.style?.color, equals(const Color(0xFFFF9E00)));
  });

  testWidgets('MonasticSwitchWidget renders with themeState.moduleChassisColor, borderColor, and chassisTextColor in Light Mode', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    // Switch to Light Mode
    container.read(chassisThemeProvider.notifier).setDarkMode(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MonasticSwitchWidget(),
          ),
        ),
      ),
    );

    final themeState = container.read(chassisThemeProvider);
    expect(themeState.isDarkMode, isFalse);

    // Verify outer container matches moduleChassisColor and borderColor in light mode
    final gestureFinder = find.byType(GestureDetector);
    final outerContainer = tester.widget<Container>(
      find.descendant(of: gestureFinder, matching: find.byType(Container)).first,
    );
    final outerDecoration = outerContainer.decoration as BoxDecoration;
    expect(outerDecoration.color, equals(themeState.moduleChassisColor));
    final border = outerDecoration.border as Border;
    expect(border.top.color, equals(themeState.borderColor));

    // Verify MONASTIC text uses chassisTextColor
    final monasticText = tester.widget<Text>(find.text('MONASTIC'));
    expect(monasticText.style?.color, equals(themeState.chassisTextColor.withValues(alpha: 0.6)));

    // Verify LOCKDOWN text uses chassisTextColor (0.72: 0.4 read at about 2.3:1 in light mode)
    final lockdownText = tester.widget<Text>(find.text('LOCKDOWN'));
    expect(lockdownText.style?.color, equals(themeState.chassisTextColor.withValues(alpha: 0.72)));

    // Engage lock
    await container.read(focusLockProvider.notifier).engageLock();
    await tester.pumpAndSettle();

    final lockedMonasticText = tester.widget<Text>(find.text('MONASTIC'));
    expect(lockedMonasticText.style?.color, equals(themeState.chassisTextColor));

    final lockedEngagedText = tester.widget<Text>(find.text('ENGAGED'));
    expect(lockedEngagedText.style?.color, equals(TaktColors.readableAccent(themeState.filamentColor, onDark: themeState.hasDarkChassis)));

    final lockedContainer = tester.widget<Container>(
      find.descendant(of: gestureFinder, matching: find.byType(Container)).first,
    );
    final lockedDecoration = lockedContainer.decoration as BoxDecoration;
    final lockedBorder = lockedDecoration.border as Border;
    expect(lockedBorder.top.color, equals(themeState.filamentColor.withValues(alpha: 0.8)));
  });
}
