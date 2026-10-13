import 'package:flutter/widgets.dart';

/// [duration], or zero when the system asks for no animations (Settings → Accessibility → Remove animations).
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : duration;

/// Turns a page, animated unless animations are off (animateToPage refuses a zero duration).
Future<void> turnToPage(BuildContext context, PageController controller, int page,
    {Duration duration = const Duration(milliseconds: 280), Curve curve = Curves.easeOutCubic}) {
  if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
    controller.jumpToPage(page);
    return Future<void>.value();
  }
  return controller.animateToPage(page, duration: duration, curve: curve);
}
