import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/theme_controller.dart';

class AmbientLightingLayer extends ConsumerWidget {
  final Widget child;
  final DateTime? currentTime;

  const AmbientLightingLayer({
    super.key,
    required this.child,
    this.currentTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(chassisThemeProvider);
    final now = currentTime ?? DateTime.now();
    final hour = now.hour;

    // Morning (6-11), Afternoon (11-17), Night (17-6)
    Color lightTint;
    Alignment lightOrigin;

    if (hour >= 6 && hour < 11) {
      lightTint = themeState.edition.accentColor.withValues(alpha: 0.06); // Cool morning daylight tinted with accent
      lightOrigin = Alignment.topLeft;
    } else if (hour >= 11 && hour < 17) {
      lightTint = const Color(0x15FFD6A5); // Warm afternoon sunlight
      lightOrigin = Alignment.topCenter;
    } else {
      lightTint = themeState.filamentColor.withValues(alpha: 0.08); // Filament night lamp
      lightOrigin = Alignment.topRight;
    }

    return Stack(
      children: [
        child,
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: lightOrigin,
                radius: 1.5,
                colors: [lightTint, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
