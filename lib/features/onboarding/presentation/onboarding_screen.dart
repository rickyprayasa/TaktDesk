import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/motion.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../../core/focus/focus_lock_service.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../desk/presentation/desk_canvas_screen.dart';
import '../../desk/presentation/desk_clock_host.dart';
import '../../timer/domain/pomodoro_profile.dart';
import '../../timer/presentation/chrono_dial_controller.dart';
import '../permission_service.dart';

enum OnboardingStep { welcome, rhythm, notifications, lockdown, ready }

/// First run only: pick a rhythm, then the two permissions ZYKL uses, each asked with its reason.
/// Every step can be skipped; nothing here is required to use the app.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Called instead of opening the desk (tests).
  final VoidCallback? onFinished;

  const OnboardingScreen({super.key, this.onFinished});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  OnboardingStep _step = OnboardingStep.welcome;
  NotificationPermission _notifications = NotificationPermission.denied;
  bool _notificationsAsked = false;
  bool _dndGranted = false;
  bool _finishing = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Back from Android's Settings (Do Not Disturb access, notification settings).
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final notifications = await ref.read(permissionServiceProvider).notificationStatus();
    final dnd = await ref.read(focusLockServiceProvider).isNotificationPolicyAccessGranted();
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _dndGranted = dnd;
    });
  }

  /// Steps for this phone: no notification step where Android grants it already (before 13, or allowed).
  List<OnboardingStep> get _steps => [
        OnboardingStep.welcome,
        OnboardingStep.rhythm,
        if (_notifications == NotificationPermission.denied || _notificationsAsked) OnboardingStep.notifications,
        OnboardingStep.lockdown,
        OnboardingStep.ready,
      ];

  void _next() {
    HapticService.selectionClick();
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i < 0 || i + 1 >= steps.length) {
      _finish();
      return;
    }
    setState(() => _step = steps[i + 1]);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    try {
      await ref.read(deskPreferencesControllerProvider.notifier).markOnboardingDone();
    } catch (_) {
      // Shown again next launch at worst.
    }
    if (!mounted) return;
    final done = widget.onFinished;
    if (done != null) {
      done();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: motion(context, const Duration(milliseconds: 600)),
        pageBuilder: (context, animation, secondaryAnimation) => const DeskClockHost(child: DeskCanvasScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic), child: child),
      ),
    );
  }

  Future<void> _askNotifications() async {
    HapticService.selectionClick();
    final granted = await ref.read(permissionServiceProvider).requestNotifications();
    if (!mounted) return;
    setState(() {
      _notificationsAsked = true;
      _notifications = granted ? NotificationPermission.granted : NotificationPermission.denied;
    });
    if (granted) _next();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(chassisThemeProvider);
    final isDark = theme.isDarkMode;
    final ink = theme.chassisTextColor;
    final muted = theme.chassisMutedTextColor;
    final steps = _steps;
    final index = steps.indexOf(_step).clamp(0, steps.length - 1);

    return Scaffold(
      backgroundColor: theme.canvasColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48, // same with or without SKIP, so the lamps don't jump on the last step
                    child: Row(
                      children: [
                        // One lamp per step, like the goal LEDs on the desk
                        for (var i = 0; i < steps.length; i++)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i <= index ? TaktColors.filamentAmber : muted.withValues(alpha: 0.3),
                            ),
                          ),
                        const Spacer(),
                        if (_step != OnboardingStep.ready)
                          TextButton(
                            key: const ValueKey('onboarding_skip'),
                            onPressed: _finish,
                            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                            child: Text('SKIP', style: _label(muted)),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: motion(context, const Duration(milliseconds: 280)),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 24),
                          child: _buildStep(isDark, ink, muted, index + 1, steps.length),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _label(Color c) =>
      TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: c);

  Widget _page({
    required String kicker,
    required String title,
    required String body,
    required Color ink,
    required Color muted,
    List<Widget> extra = const [],
    required List<Widget> actions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(kicker, style: _label(TaktColors.filamentAmber)),
        const SizedBox(height: 14),
        Text(title, style: TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 12),
        Text(body, style: TextStyle(fontSize: 15, height: 1.45, color: muted)),
        ...extra,
        const SizedBox(height: 28),
        ...actions,
      ],
    );
  }

  Widget _primary(String text, VoidCallback onPressed, {Key? key}) => FilledButton(
        key: key,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: TaktColors.filamentAmber,
          foregroundColor: const Color(0xFF141618),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(text,
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, letterSpacing: 1.0)),
      );

  Widget _secondary(String text, VoidCallback onPressed, Color muted, {Key? key}) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton(
          key: key,
          onPressed: onPressed,
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(text, style: _label(muted)),
        ),
      );

  Widget _buildStep(bool isDark, Color ink, Color muted, int n, int total) {
    final kicker = '[ SETUP // $n OF $total ]';
    switch (_step) {
      case OnboardingStep.welcome:
        return _page(
          kicker: kicker,
          title: 'Welcome to ZYKL.',
          body: 'A quiet instrument for focus. Pick a rhythm and allow two things, then the dial is yours. '
              'Everything stays on this phone.',
          ink: ink,
          muted: muted,
          actions: [_primary('BEGIN', _next, key: const ValueKey('onboarding_next'))],
        );
      case OnboardingStep.rhythm:
        final current = ref.watch(chronoDialProvider.select((s) => s.profile.type));
        return _page(
          kicker: kicker,
          title: 'Pick your rhythm.',
          body: 'Focus, then a short break; a long break every four cycles. You can change it any time in Settings.',
          ink: ink,
          muted: muted,
          extra: [
            const SizedBox(height: 20),
            for (final p in const [PomodoroProfile.classic, PomodoroProfile.monastic, PomodoroProfile.sprint])
              _RhythmCard(
                profile: p,
                selected: current == p.type,
                isDark: isDark,
                ink: ink,
                muted: muted,
                onTap: () {
                  HapticService.selectionClick();
                  ref.read(chronoDialProvider.notifier).setProfile(p);
                },
              ),
          ],
          actions: [_primary('CONTINUE', _next, key: const ValueKey('onboarding_next'))],
        );
      case OnboardingStep.notifications:
        final denied = _notificationsAsked && _notifications == NotificationPermission.denied;
        return _page(
          kicker: kicker,
          title: 'Let the timer speak up.',
          body: denied
              ? 'Notifications are off, so the timer won\'t show on the lock screen and a finished phase stays silent '
                  'while ZYKL is in the background. You can turn them on in Android settings any time.'
              : 'ZYKL shows the running timer on your lock screen and rings when a phase ends. '
                  'Nothing else. No reminders, no promotions.',
          ink: ink,
          muted: muted,
          actions: denied
              ? [
                  _primary('OPEN SETTINGS', () => ref.read(permissionServiceProvider).openNotificationSettings(),
                      key: const ValueKey('onboarding_open_notification_settings')),
                  _secondary('CONTINUE', _next, muted, key: const ValueKey('onboarding_next')),
                ]
              : [
                  _primary('ALLOW NOTIFICATIONS', _askNotifications,
                      key: const ValueKey('onboarding_allow_notifications')),
                  _secondary('NOT NOW', _next, muted, key: const ValueKey('onboarding_next')),
                ],
        );
      case OnboardingStep.lockdown:
        return _page(
          kicker: kicker,
          title: 'Silence the world, on purpose.',
          body: 'Monastic Lockdown pins ZYKL to the screen and can switch on Do Not Disturb while you focus, '
              'then switches it back. Android asks you to allow this once, in Settings. Optional.',
          ink: ink,
          muted: muted,
          extra: [
            if (_dndGranted) ...[
              const SizedBox(height: 16),
              Row(
                key: const ValueKey('onboarding_dnd_granted'),
                children: [
                  const Icon(Icons.check_circle, size: 18, color: TaktColors.filamentAmber),
                  const SizedBox(width: 8),
                  Flexible(child: Text('DO NOT DISTURB ACCESS ALLOWED', style: _label(ink))),
                ],
              ),
            ],
          ],
          actions: _dndGranted
              ? [_primary('CONTINUE', _next, key: const ValueKey('onboarding_next'))]
              : [
                  _primary('ALLOW IN SETTINGS', () {
                    HapticService.selectionClick();
                    ref.read(focusLockServiceProvider).openNotificationPolicySettings();
                  }, key: const ValueKey('onboarding_open_dnd_settings')),
                  _secondary('SKIP FOR NOW', _next, muted, key: const ValueKey('onboarding_next')),
                ],
        );
      case OnboardingStep.ready:
        return _page(
          kicker: kicker,
          title: 'You\'re set.',
          body: 'Turn the crown to choose the minutes, press it to start. Write what you\'re working on '
              'on a task slip, and tear it off when it\'s done.',
          ink: ink,
          muted: muted,
          actions: [_primary('OPEN THE DESK', _finish, key: const ValueKey('onboarding_finish'))],
        );
    }
  }
}

class _RhythmCard extends StatelessWidget {
  final PomodoroProfile profile;
  final bool selected;
  final bool isDark;
  final Color ink;
  final Color muted;
  final VoidCallback onTap;

  const _RhythmCard({
    required this.profile,
    required this.selected,
    required this.isDark,
    required this.ink,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          key: ValueKey('onboarding_rhythm_${profile.type.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: selected ? TaktColors.filamentAmber.withValues(alpha: isDark ? 0.12 : 0.16) : Colors.transparent,
              border: Border.all(
                color: selected ? TaktColors.filamentAmber : muted.withValues(alpha: 0.35),
                width: selected ? 1.4 : 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.label,
                          style: TextStyle(
                              fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(height: 4),
                      Text(profile.type.purpose, style: TextStyle(fontSize: 13, height: 1.35, color: muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20, color: selected ? TaktColors.filamentAmber : muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
