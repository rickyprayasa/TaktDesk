import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/app_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppWidgetService service;
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    service = const AppWidgetService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      AppWidgetService.channel,
      (MethodCall call) async {
        methodCalls.add(call);
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppWidgetService.channel, null);
  });

  test('channel name matches com.takt.desk/app_widget', () {
    expect(AppWidgetService.channel.name, equals('com.takt.desk/app_widget'));
  });

  test('updateWidgetData invokes method with expected payload', () async {
    final result = await service.updateWidgetData(
      cyclesCompleted: 2,
      cyclesTarget: 4,
      minutesFocused: 50,
      status: 'STANDBY',
    );

    expect(result, isTrue);
    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, equals('updateWidgetData'));
    expect(methodCalls.first.arguments, equals({
      'cyclesCompleted': 2,
      'cyclesTarget': 4,
      'minutesFocused': 50,
      'status': 'STANDBY',
    }));
  });

  test('updateWidgetData handles channel errors gracefully without throwing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      AppWidgetService.channel,
      (MethodCall call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'Not supported');
      },
    );

    final result = await service.updateWidgetData(
      cyclesCompleted: 1,
      cyclesTarget: 4,
      minutesFocused: 25,
      status: 'FOCUS',
    );

    expect(result, isFalse);
  });

  test('updateAllWidgetData invokes method with expected full payload', () async {
    final tasksPayload = [
      {'id': 1, 'title': 'Design Dial', 'is_completed': false},
      {'id': 2, 'title': 'Review PR', 'is_completed': true},
    ];

    final result = await service.updateAllWidgetData(
      cyclesCompleted: 3,
      cyclesTarget: 4,
      minutesFocused: 75,
      status: 'FOCUS',
      remainingSeconds: 1200,
      targetMinutes: 25,
      tasks: tasksPayload,
    );

    expect(result, isTrue);
    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, equals('updateAllWidgetData'));
    expect(methodCalls.first.arguments, equals({
      'cyclesCompleted': 3,
      'cyclesTarget': 4,
      'minutesFocused': 75,
      'status': 'FOCUS',
      'remainingSeconds': 1200,
      'targetMinutes': 25,
      'tasks': tasksPayload,
    }));
  });

  test('updateAllWidgetData handles channel errors gracefully and returns false', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      AppWidgetService.channel,
      (MethodCall call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'Not supported');
      },
    );

    final result = await service.updateAllWidgetData(
      cyclesCompleted: 1,
      cyclesTarget: 4,
      minutesFocused: 25,
      status: 'FOCUS',
      remainingSeconds: 1500,
      targetMinutes: 25,
      tasks: [],
    );

    expect(result, isFalse);
  });

  test('appWidgetServiceProvider provides AppWidgetService instance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final instance = container.read(appWidgetServiceProvider);
    expect(instance, isA<AppWidgetService>());
  });
}

