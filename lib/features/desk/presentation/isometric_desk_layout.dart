import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sensors/parallax_controller.dart';

class IsometricDeskLayout extends ConsumerWidget {
  final Widget child;

  const IsometricDeskLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parallax = ref.watch(parallaxProvider);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateX(parallax.tiltY)
        ..rotateY(parallax.tiltX),
      alignment: Alignment.center,
      child: child,
    );
  }
}
