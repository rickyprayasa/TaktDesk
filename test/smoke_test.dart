// test/smoke_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scaffold baseline smoke test', () {
    const appName = 'Takt Desk';
    expect(appName, equals('Takt Desk'));
  });
}
