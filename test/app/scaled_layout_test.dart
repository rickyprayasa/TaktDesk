import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/scaled_layout.dart';

void main() {
  testWidgets('takes scale x the space, and taps land in the child\'s own coordinates', (tester) async {
    Offset? local;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: ScaledLayout(
          scale: 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => local = d.localPosition,
            child: const SizedBox(key: ValueKey('box'), width: 100, height: 50),
          ),
        ),
      ),
    ));
    expect(tester.getSize(find.byType(ScaledLayout)), const Size(200, 100));
    expect(tester.getSize(find.byKey(const ValueKey('box'))), const Size(100, 50), reason: 'laid out at design size');
    expect(tester.getRect(find.byKey(const ValueKey('box'))), const Rect.fromLTWH(0, 0, 200, 100),
        reason: 'painted at twice the size');
    await tester.tapAt(const Offset(160, 60));
    expect(local, const Offset(80, 30));
  });

  testWidgets('the child is laid out within the space divided by the scale', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 300,
          height: 120,
          child: ScaledLayout(scale: 1.5, child: SizedBox.expand(key: ValueKey('fill'))),
        ),
      ),
    ));
    expect(tester.getSize(find.byKey(const ValueKey('fill'))), const Size(200, 80));
  });

  test('instrumentScale: phones stay at 1, big screens grow up to the cap', () {
    const design = Size(340, 420);
    expect(instrumentScale(const Size(300, 600), design), 1);
    expect(instrumentScale(const Size(510, 630), design), 1.5);
    expect(instrumentScale(const Size(2000, 2000), design), 1.7);
    expect(instrumentScale(const Size(2000, 2000), design, maxScale: 1.8), 1.8);
    expect(instrumentScale(Size.zero, design), 1);
  });
}
