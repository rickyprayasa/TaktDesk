import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/app/theme/takt_typography.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import '../../../../app/motion.dart';

enum _SilenceChoice { grantAccess, lockWithoutSilence }

class MonasticSwitchWidget extends ConsumerStatefulWidget {
  const MonasticSwitchWidget({super.key});

  @override
  ConsumerState<MonasticSwitchWidget> createState() => _MonasticSwitchWidgetState();
}

class _MonasticSwitchWidgetState extends ConsumerState<MonasticSwitchWidget> {
  late final AppLifecycleListener _lifecycle;

  /// The user went to Android settings to grant Do Not Disturb access from the
  /// pre-flight dialog. If access is granted when they come back, lock right
  /// away: that is what they asked for.
  bool _lockAfterGrant = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _onResume() async {
    if (!_lockAfterGrant) return;
    _lockAfterGrant = false;
    if (await ref.read(focusLockServiceProvider).isNotificationPolicyAccessGranted()) {
      await ref.read(focusLockProvider.notifier).engageLock();
    }
  }

  /// Lockdown silences calls and notifications only with Do Not Disturb
  /// access. Without it, ask before locking instead of failing silently.
  Future<void> _onTap() async {
    if (ref.read(focusLockProvider).isLocked || _checking) return;
    _checking = true;
    try {
      final service = ref.read(focusLockServiceProvider);
      if (await service.isNotificationPolicyAccessGranted()) {
        await ref.read(focusLockProvider.notifier).engageLock();
        return;
      }
      if (!mounted) return;
      final choice = await _showSilencePreflight(context, ref.read(chassisThemeProvider));
      if (choice == _SilenceChoice.lockWithoutSilence) {
        await ref.read(focusLockProvider.notifier).engageLock();
      } else if (choice == _SilenceChoice.grantAccess) {
        _lockAfterGrant = true;
        await service.openNotificationPolicySettings();
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusState = ref.watch(focusLockProvider);
    final themeState = ref.watch(chassisThemeProvider);
    final isLocked = focusState.isLocked;

    return Semantics(
      button: true,
      toggled: isLocked,
      enabled: !isLocked,
      label: isLocked ? 'Monastic Focus Engaged' : 'Monastic Focus Inactive',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: themeState.moduleChassisColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? themeState.filamentColor.withValues(alpha: 0.8)
                  : themeState.borderColor,
              width: 1.0,
            ),
            boxShadow: isLocked
                ? [
                    BoxShadow(
                      color: themeState.filamentColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sleek LED status indicator
              AnimatedContainer(
                duration: motion(context, const Duration(milliseconds: 250)),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked
                      ? themeState.filamentColor
                      : (themeState.isDarkMode ? const Color(0xFF4A4E55) : themeState.borderColor),
                  boxShadow: isLocked
                      ? [
                          BoxShadow(
                            color: themeState.filamentColor.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MONASTIC',
                style: TaktTypography.labelSmall.copyWith(
                  color: isLocked
                      ? themeState.chassisTextColor
                      : themeState.chassisTextColor.withValues(alpha: 0.6),
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isLocked ? 'ENGAGED' : 'LOCKDOWN',
                style: TaktTypography.labelSmall.copyWith(
                  color: isLocked
                      ? TaktColors.readableAccent(themeState.filamentColor, onDark: themeState.hasDarkChassis)
                      : themeState.chassisTextColor.withValues(alpha: 0.72),
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<_SilenceChoice?> _showSilencePreflight(BuildContext context, ChassisThemeState theme) {
  final isDark = theme.isDarkMode;
  TextStyle mono(double size, Color color, {FontWeight weight = FontWeight.w400}) => TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.4,
      );
  return showDialog<_SilenceChoice>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      key: const ValueKey('lockdown_silence_preflight'),
      backgroundColor: theme.moduleChassisColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Text(
        'SILENCE CALLS TOO?',
        style: mono(13, theme.chassisTextColor, weight: FontWeight.w700).copyWith(letterSpacing: 1.0),
      ),
      content: Text(
        'Monastic Lockdown pins ZYKL to the screen. To also silence phone calls and notifications, '
        'Android needs to give ZYKL Do Not Disturb access. Without it, calls still ring through.',
        style: mono(11, theme.chassisMutedTextColor),
      ),
      actions: [
        TextButton(
          key: const ValueKey('lockdown_without_silence'),
          onPressed: () => Navigator.of(dialogCtx).pop(_SilenceChoice.lockWithoutSilence),
          child: Text('LOCK WITHOUT SILENCE', style: mono(11, theme.chassisMutedTextColor, weight: FontWeight.w600)),
        ),
        ElevatedButton(
          key: const ValueKey('lockdown_grant_dnd'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TaktColors.amberText(isDark),
            foregroundColor: isDark ? TaktColors.chassisObsidian : TaktColors.warmBone,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(_SilenceChoice.grantAccess),
          child: const Text(
            'GRANT ACCESS',
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}
