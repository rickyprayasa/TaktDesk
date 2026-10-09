import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sensors/parallax_controller.dart';

class IsometricDeskLayout extends ConsumerWidget {
  final Widget child;

  const IsometricDeskLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tilt only: light changes must not rebuild the desk transform.
    final tilt = ref.watch(parallaxProvider.select((p) => (p.tiltX, p.tiltY)));

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateX(-tilt.$2 * 0.25)
        ..rotateY(tilt.$1 * 0.25),
      alignment: Alignment.center,
      child: child,
    );
  }
}
