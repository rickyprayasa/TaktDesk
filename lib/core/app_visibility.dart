import 'package:flutter/widgets.dart';

/// False only when the app is known to be in the background (hidden or paused). Foley and haptics are for someone
/// looking at the desk: from the background (a minute tick, a needle lifted from the notification) they only startle.
bool get appIsVisible {
  try {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
  } catch (_) {
    return true;
  }
}
