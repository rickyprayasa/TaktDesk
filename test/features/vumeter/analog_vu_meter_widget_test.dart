import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/vumeter/presentation/analog_vu_meter_widget.dart';
import 'package:takt_desk/features/vumeter/presentation/vu_meter_painter.dart';

void main() {
  testWidgets('AnalogVuMeterWidget renders dual meter apertures and ballistics toggle', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnalogVuMeterWidget(),
            ),
          ),
        ),
      ),
    );

    // Verify header label
    expect(find.text('STEREO VU METER'), findsOneWidget);

    // Verify CustomPaint with VuMeterPainter
    final painterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is VuMeterPainter,
    );
    expect(painterFinder, findsOneWidget);

    // Verify ballistics toggle button
    expect(find.text('BALLISTICS: SLOW'), findsOneWidget);

    // Tap toggle button
    await tester.tap(find.text('BALLISTICS: SLOW'));
    await tester.pump();

    // Verify toggled to FAST
    expect(find.text('BALLISTICS: FAST'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
