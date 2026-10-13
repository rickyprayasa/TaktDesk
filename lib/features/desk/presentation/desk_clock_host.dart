import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/display_service.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../timer/presentation/chrono_dial_controller.dart';

/// Desk clock mode (Settings → System). While it is on and a timer runs, the screen stays on so the desk works as a
/// clock on a stand or charger. After [idleDelay] without a touch the window dims (low brightness and a dark veil)
/// and the desk moves a few pixels every [shiftEvery] against OLED burn-in. The first touch on a dimmed screen only
/// wakes it, so it never presses a control by accident. Off, paused or finished: the screen times out as usual.
class DeskClockHost extends ConsumerStatefulWidget {
  const DeskClockHost({
    super.key,
    required this.child,
    this.idleDelay = const Duration(seconds: 60),
    this.shiftEvery = const Duration(seconds: 60),
  });

  final Widget child;
  final Duration idleDelay;
  final Duration shiftEvery;

  /// Burn-in shift positions (logical px), visited in a loop while dimmed.
  static const List<Offset> shifts = [
    Offset.zero,
    Offset(3, 0),
    Offset(3, 3),
    Offset(0, 3),
    Offset(-3, 3),
    Offset(-3, 0),
    Offset(-3, -3),
    Offset(0, -3),
    Offset(3, -3),
  ];

  /// Opacity of the black veil over the dimmed desk.
  static const double veilOpacity = 0.4;

  @override
  ConsumerState<DeskClockHost> createState() => _DeskClockHostState();
}

class _DeskClockHostState extends ConsumerState<DeskClockHost> {
  late final DisplayService _display;
  late final AppLifecycleListener _lifecycle;
  Timer? _idleTimer;
  Timer? _shiftTimer;
  bool _active = false;
  bool _dimmed = false;
  int _shiftStep = 0;

  @override
  void initState() {
    super.initState();
    _display = ref.read(displayServiceProvider);
    // Coming back to the app (or turning the screen on) always starts bright.
    _lifecycle = AppLifecycleListener(onResume: _wake);
    // Any touch in the app counts, also in Settings, the task sheet or a dialog (separate routes above the desk).
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onAnyPointer);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  void _onAnyPointer(PointerEvent event) {
    if (event is PointerDownEvent) _wake();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onAnyPointer);
    _lifecycle.dispose();
    _idleTimer?.cancel();
    _shiftTimer?.cancel();
    if (_active) {
      _display.setKeepScreenOn(false);
      if (_dimmed) _display.setDimmed(false);
    }
    super.dispose();
  }

  bool get _shouldBeActive =>
      ref.read(deskPreferencesControllerProvider).deskClockMode && ref.read(chronoDialControllerProvider).isRunning;

  void _sync() {
    final active = _shouldBeActive;
    if (active == _active || !mounted) return;
    setState(() => _active = active);
    _display.setKeepScreenOn(active);
    if (active) {
      _restartIdle();
    } else {
      _idleTimer?.cancel();
      _setDimmed(false);
    }
  }

  void _restartIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleDelay, () {
      // Someone is in a sheet or dialog over the desk (Settings, typing a slip): not idle, wait another round.
      if (mounted && ModalRoute.of(context)?.isCurrent == false) {
        _restartIdle();
        return;
      }
      _setDimmed(true);
    });
  }

  void _wake() {
    if (!_active) return;
    _setDimmed(false);
    _restartIdle();
  }

  void _setDimmed(bool dimmed) {
    if (dimmed == _dimmed || !mounted) return;
    _shiftTimer?.cancel();
    setState(() {
      _dimmed = dimmed;
      _shiftStep = 0;
    });
    _display.setDimmed(dimmed);
    if (dimmed) {
      _shiftTimer = Timer.periodic(widget.shiftEvery, (_) {
        if (mounted) setState(() => _shiftStep = (_shiftStep + 1) % DeskClockHost.shifts.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deskPreferencesControllerProvider.select((p) => p.deskClockMode), (_, __) => _sync());
    ref.listen(chronoDialControllerProvider.select((s) => s.isRunning), (_, __) => _sync());
    final fade =
        MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : const Duration(milliseconds: 600);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Transform.translate(
          offset: _dimmed ? DeskClockHost.shifts[_shiftStep] : Offset.zero,
          child: widget.child,
        ),
        if (_active)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_dimmed,
              // Swallows the waking touch so it does not reach the desk below.
              child: GestureDetector(
                key: const ValueKey('desk_clock_veil'),
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: AnimatedOpacity(
                  opacity: _dimmed ? 1 : 0,
                  duration: fade,
                  child: const ColoredBox(color: Color.fromRGBO(0, 0, 0, DeskClockHost.veilOpacity)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
