import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../timer/presentation/chrono_dial_controller.dart';
import 'settings_controller.dart';
import 'widgets/studio_pro_dialog.dart';

/// The Industrial Service Hatch Modal Sheet (Settings, About & Legal).
///
/// Embodies Dieter Rams / Braun design language with tactile sliders,
/// telemetry readouts, system clearance badges, and legal attributions.
class TaktSettingsSheet extends ConsumerWidget {
  const TaktSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;
    final prefs = ref.watch(deskPreferencesControllerProvider);
    final lifetimeStatsAsync = ref.watch(lifetimeFocusStatsProvider);
    final lifetimeStats =
        lifetimeStatsAsync.valueOrNull ?? const LifetimeFocusStats();

    final bgColor =
        isDark ? TaktColors.chassisObsidian : const Color(0xFFE3E0D8);
    final panelBgColor =
        isDark ? TaktColors.basaltSlate : const Color(0xFFEDEAE2);
    final borderColor =
        isDark ? TaktColors.slateBorder : TaktColors.lightChassisBorder;
    final primaryTextColor =
        isDark ? TaktColors.warmBone : const Color(0xFF141618);
    final secondaryTextColor =
        isDark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16.0)),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                offset: const Offset(0, -4),
                blurRadius: 16.0,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grip Handle
                  Center(
                    child: Container(
                      key: const ValueKey('service_hatch_grip_handle'),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? TaktColors.slateBorder
                            : const Color(0xFFB5B0A4),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Title
                  Text(
                    'SERVICE HATCH // CALIBRATION & TELEMETRY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'DEVELOPED BY RSQUARE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: TaktColors.filamentAmber,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section: Hardware Editions // Chassis Materiality
                  _HardwareEditionsSection(
                    prefs: prefs,
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    panelBgColor: panelBgColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Hardware Acoustics & Tactility
                  _SectionHeader(
                    title: 'HARDWARE ACOUSTICS & TACTILITY',
                    textColor: secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: panelBgColor,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Master Volume
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'MASTER VOLUME',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(prefs.soundVolume * 100).round()}%',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: TaktColors.filamentAmber,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: TaktColors.filamentAmber,
                            inactiveTrackColor: isDark
                                ? TaktColors.slateLight
                                : TaktColors.paperBorder,
                            thumbColor: TaktColors.filamentAmber,
                            overlayColor:
                                TaktColors.filamentAmber.withValues(alpha: 0.2),
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6.0,
                            ),
                          ),
                          child: Slider(
                            key: const ValueKey('master_volume_slider'),
                            value: prefs.soundVolume.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              ref
                                  .read(deskPreferencesControllerProvider
                                      .notifier)
                                  .setVolume(val);
                            },
                            onChangeEnd: (val) {
                              ref
                                  .read(deskPreferencesControllerProvider
                                      .notifier)
                                  .setVolume(val);
                            },
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Foley Clicks Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FOLEY CLICKS',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.0,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mechanical click & tear feedback',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9.0,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              key: const ValueKey('foley_clicks_switch'),
                              value: prefs.foleyEnabled,
                              activeThumbColor: TaktColors.filamentAmber,
                              activeTrackColor: TaktColors.filamentAmber
                                  .withValues(alpha: 0.5),
                              inactiveThumbColor: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                              inactiveTrackColor: isDark
                                  ? TaktColors.slateLight
                                  : TaktColors.paperBorder,
                              onChanged: (val) {
                                ref
                                    .read(deskPreferencesControllerProvider
                                        .notifier)
                                    .setFoleyEnabled(val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Tactile Haptics Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TACTILE HAPTICS',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.0,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Physical impulse on dial & switches',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9.0,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              key: const ValueKey('tactile_haptics_switch'),
                              value: prefs.hapticsEnabled,
                              activeThumbColor: TaktColors.filamentAmber,
                              activeTrackColor: TaktColors.filamentAmber
                                  .withValues(alpha: 0.5),
                              inactiveThumbColor: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                              inactiveTrackColor: isDark
                                  ? TaktColors.slateLight
                                  : TaktColors.paperBorder,
                              onChanged: (val) {
                                ref
                                    .read(deskPreferencesControllerProvider
                                        .notifier)
                                    .setHapticsEnabled(val);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Pomodoro Interval Engine
                  _PomodoroIntervalEngineSection(
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    panelBgColor: panelBgColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 20),

                  // Section 3: System Clearance & Lockdown
                  _SectionHeader(
                    title: 'SYSTEM CLEARANCE & LOCKDOWN',
                    textColor: secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: panelBgColor,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Row(
                          key: const ValueKey('clearance_status_badge'),
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: TaktColors.patinaOlive,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x664D5D4B),
                                    blurRadius: 4.0,
                                    spreadRadius: 1.0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'STATUS: VERIFIED (ANDROID DND / APP PINNING)',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'In Monastic Lockdown, press and hold the bottom unlatch lever for 5 continuous seconds to release the system.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            color: secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Telemetry & Logs
                  _SectionHeader(
                    title: 'TELEMETRY & LOGS',
                    textColor: secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: panelBgColor,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COMPLETED SESSIONS',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${lifetimeStats.totalSessions}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HOURS FOCUSED',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${lifetimeStats.totalHours.toStringAsFixed(1)}h',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TaktColors.mutedOchre,
                            side: const BorderSide(
                              color: TaktColors.mutedOchre,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _confirmPurge(
                            context,
                            ref,
                            isDark,
                            primaryTextColor,
                            secondaryTextColor,
                          ),
                          child: const Text(
                            'PURGE SESSION LOGS',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 4: The Braun Creed & Legal
                  _SectionHeader(
                    title: 'THE BRAUN CREED & LEGAL',
                    textColor: secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: panelBgColor,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '“Weniger, aber besser — Less, but better.”',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.0,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '— Dieter Rams',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFEFECE6) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: TaktColors.filamentAmber.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                offset: Offset(0, 1.5),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4.5),
                          child: Image.asset(
                            'assets/images/rsquare_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          'Takt Desk v1.0.0 (Build 2026.09) · Developed by RSQUARE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.0,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'DEVELOPED BY RSQUARE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: TaktColors.filamentAmber,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '100% Offline. Zero analytics. Zero telemetry. All session data remains exclusively on this device.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            color: secondaryTextColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryTextColor,
                            side: BorderSide(color: borderColor, width: 1.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                          ),
                          onPressed: () {
                            showLicensePage(
                              context: context,
                              applicationName: 'Takt Desk by RSQUARE',
                              applicationVersion: 'v1.0.0 (Build 2026.09)',
                              applicationLegalese:
                                  'Weniger, aber besser — Dieter Rams · Developed by RSQUARE',
                            );
                          },
                          child: const Text(
                            'OPEN SOURCE LICENSES',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmPurge(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor:
            isDark ? TaktColors.basaltSlate : const Color(0xFFEDEAE2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: isDark ? TaktColors.slateBorder : TaktColors.lightChassisBorder,
          ),
        ),
        title: Text(
          'CONFIRM PURGE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: primaryTextColor,
          ),
        ),
        content: Text(
          'All lifetime focus session records and telemetry logs will be permanently erased. This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: secondaryTextColor,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'monospace',
                color: secondaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('confirm_purge_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TaktColors.mutedOchre,
              foregroundColor: TaktColors.warmBone,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            onPressed: () {
              ref
                  .read(deskPreferencesControllerProvider.notifier)
                  .clearAllSessions();
              Navigator.of(dialogCtx).pop(true);
            },
            child: const Text(
              'PURGE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PomodoroIntervalEngineSection extends ConsumerWidget {
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color panelBgColor;
  final Color borderColor;

  const _PomodoroIntervalEngineSection({
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.panelBgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(chronoDialProvider);
    final controller = ref.read(chronoDialProvider.notifier);
    final activeProfile = timerState.profile;
    final customProfile = timerState.customProfile;
    final isRunning = timerState.isRunning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'POMODORO INTERVAL ENGINE',
          textColor: secondaryTextColor,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: panelBgColor,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active profile indicator
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'ACTIVE PROFILE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    activeProfile.type.label,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TaktColors.filamentAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: borderColor.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: 12),

              // Stepper 1: Focus Duration
              _buildStepperRow(
                title: 'FOCUS DURATION',
                subtitle: 'Custom work interval (1 – 90 min)',
                value: '${customProfile.focusMinutes} MIN',
                valueKey: const ValueKey('custom_focus_value'),
                minusKey: const ValueKey('custom_focus_minus'),
                plusKey: const ValueKey('custom_focus_plus'),
                canDecrement: !isRunning && customProfile.focusMinutes > 1,
                canIncrement: !isRunning && customProfile.focusMinutes < 90,
                onDecrement: () => controller.updateCustomDurations(
                  focusMinutes: customProfile.focusMinutes - 1,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  focusMinutes: customProfile.focusMinutes + 1,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Stepper 2: Short Break
              _buildStepperRow(
                title: 'SHORT BREAK',
                subtitle: 'Custom cycle rest (1 – 30 min)',
                value: '${customProfile.shortBreakMinutes} MIN',
                valueKey: const ValueKey('custom_short_break_value'),
                minusKey: const ValueKey('custom_short_break_minus'),
                plusKey: const ValueKey('custom_short_break_plus'),
                canDecrement: !isRunning && customProfile.shortBreakMinutes > 1,
                canIncrement: !isRunning && customProfile.shortBreakMinutes < 30,
                onDecrement: () => controller.updateCustomDurations(
                  shortBreakMinutes: customProfile.shortBreakMinutes - 1,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  shortBreakMinutes: customProfile.shortBreakMinutes + 1,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Stepper 3: Long Break
              _buildStepperRow(
                title: 'LONG BREAK',
                subtitle: 'Custom 4th cycle recovery (1 – 45 min)',
                value: '${customProfile.longBreakMinutes} MIN',
                valueKey: const ValueKey('custom_long_break_value'),
                minusKey: const ValueKey('custom_long_break_minus'),
                plusKey: const ValueKey('custom_long_break_plus'),
                canDecrement: !isRunning && customProfile.longBreakMinutes > 1,
                canIncrement: !isRunning && customProfile.longBreakMinutes < 45,
                onDecrement: () => controller.updateCustomDurations(
                  longBreakMinutes: customProfile.longBreakMinutes - 1,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  longBreakMinutes: customProfile.longBreakMinutes + 1,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperRow({
    required String title,
    required String subtitle,
    required String value,
    required Key valueKey,
    required Key minusKey,
    required Key plusKey,
    required bool canDecrement,
    required bool canIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.0,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: minusKey,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                Icons.remove_circle_outline,
                color: canDecrement ? primaryTextColor : borderColor,
                size: 18,
              ),
              onPressed: canDecrement ? onDecrement : null,
            ),
            SizedBox(
              width: 54,
              child: Text(
                value,
                key: valueKey,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: TaktColors.filamentAmber,
                ),
              ),
            ),
            IconButton(
              key: plusKey,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                Icons.add_circle_outline,
                color: canIncrement ? primaryTextColor : borderColor,
                size: 18,
              ),
              onPressed: canIncrement ? onIncrement : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;

  const _SectionHeader({
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1.0,
            color: textColor.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

class _HardwareEditionsSection extends ConsumerStatefulWidget {
  final DeskPreferencesState prefs;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color panelBgColor;
  final Color borderColor;

  const _HardwareEditionsSection({
    required this.prefs,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.panelBgColor,
    required this.borderColor,
  });

  @override
  ConsumerState<_HardwareEditionsSection> createState() =>
      _HardwareEditionsSectionState();
}

class _HardwareEditionsSectionState
    extends ConsumerState<_HardwareEditionsSection> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    final initialIndex = HardwareEdition.all.indexWhere(
      (e) => e.type.name == widget.prefs.selectedEdition,
    );
    _currentPage = initialIndex >= 0 ? initialIndex : 0;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.82,
    );
  }

  @override
  void didUpdateWidget(covariant _HardwareEditionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prefs.selectedEdition != widget.prefs.selectedEdition) {
      final newIndex = HardwareEdition.all.indexWhere(
        (e) => e.type.name == widget.prefs.selectedEdition,
      );
      if (newIndex >= 0 &&
          newIndex != _currentPage &&
          _pageController.hasClients) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrev() {
    if (!_pageController.hasClients || _currentPage <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticService.selectionClick();
  }

  void _goToNext() {
    if (!_pageController.hasClients || _currentPage >= HardwareEdition.all.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticService.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(chassisThemeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header with title, counter badge, and arrow buttons
        Row(
          children: [
            Flexible(
              flex: 4,
              child: Text(
                'HARDWARE EDITIONS // CHASSIS MATERIALITY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: widget.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Container(
                height: 1.0,
                color: widget.secondaryTextColor.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '[ ${(_currentPage + 1).toString().padLeft(2, '0')} / ${HardwareEdition.all.length.toString().padLeft(2, '0')} ]',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: widget.secondaryTextColor,
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              label: 'Previous hardware edition',
              button: true,
              enabled: _currentPage > 0,
              child: InkWell(
                key: const ValueKey('edition_prev_button'),
                borderRadius: BorderRadius.circular(3.0),
                onTap: _currentPage > 0 ? _goToPrev : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '◀',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: _currentPage > 0
                          ? widget.primaryTextColor
                          : widget.secondaryTextColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Semantics(
              label: 'Next hardware edition',
              button: true,
              enabled: _currentPage < HardwareEdition.all.length - 1,
              child: InkWell(
                key: const ValueKey('edition_next_button'),
                borderRadius: BorderRadius.circular(3.0),
                onTap: _currentPage < HardwareEdition.all.length - 1 ? _goToNext : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '▶',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: _currentPage < HardwareEdition.all.length - 1
                          ? widget.primaryTextColor
                          : widget.secondaryTextColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.panelBgColor,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: widget.borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Snapping Carousel of 4 HardwareEdition cards
              SizedBox(
                height: 152,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: HardwareEdition.all.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, i) {
                    final ed = HardwareEdition.all[i];
                    final isSel =
                        widget.prefs.selectedEdition == ed.type.name;
                    final isUnl =
                        !ed.isPremium || widget.prefs.isProSimulated;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: _EditionCard(
                        edition: ed,
                        isSelected: isSel,
                        isUnlocked: isUnl,
                        isDark: widget.isDark,
                        onTap: () {
                          if (!isUnl) {
                            _showStudioProDialog(
                              context,
                              ref,
                              ed,
                              isDark: widget.isDark,
                              primaryTextColor: widget.primaryTextColor,
                              secondaryTextColor: widget.secondaryTextColor,
                            );
                          } else if (!isSel) {
                            ref
                                .read(
                                    deskPreferencesControllerProvider.notifier)
                                .setHardwareEdition(ed.type);
                            HapticService.selectionClick();
                          } else {
                            HapticService.selectionClick();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < HardwareEdition.all.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Container(
                      key: ValueKey('edition_dot_$i'),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == i
                            ? themeState.filamentColor
                            : widget.borderColor.withValues(alpha: 0.5),
                        boxShadow: _currentPage == i
                            ? [
                                BoxShadow(
                                  color: themeState.filamentColor
                                      .withValues(alpha: 0.6),
                                  blurRadius: 3.0,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: widget.borderColor),
              const SizedBox(height: 12),
              // SIMULATE STUDIO PRO CLEARANCE switch row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIMULATE STUDIO PRO CLEARANCE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: widget.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Developer preview override for all hardware finishes',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.0,
                            color: widget.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    key: const ValueKey('simulate_pro_switch'),
                    value: widget.prefs.isProSimulated,
                    activeThumbColor: TaktColors.filamentAmber,
                    activeTrackColor:
                        TaktColors.filamentAmber.withValues(alpha: 0.5),
                    inactiveThumbColor: widget.isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    inactiveTrackColor: widget.isDark
                        ? TaktColors.slateLight
                        : TaktColors.paperBorder,
                    onChanged: (val) {
                      ref
                          .read(deskPreferencesControllerProvider.notifier)
                          .setProSimulated(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _EditionCard extends StatelessWidget {
  final HardwareEdition edition;
  final bool isSelected;
  final bool isUnlocked;
  final bool isDark;
  final VoidCallback onTap;

  const _EditionCard({
    required this.edition,
    required this.isSelected,
    required this.isUnlocked,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rivetColor = isDark ? edition.rivetDark : edition.rivetLight;
    final borderColor = isSelected
        ? TaktColors.filamentAmber
        : (isDark ? edition.darkBorder : edition.lightBorder);
    final titleColor = isDark ? TaktColors.warmBone : const Color(0xFF141618);
    final subtitleColor =
        isDark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('edition_card_${edition.type.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.4 : 1.0,
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? edition.plateGradientDark
                  : edition.plateGradientLight,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // 4 Corner Rivets (4x4 circular containers)
              Positioned(
                top: 5,
                left: 5,
                child: _RivetDot(color: rivetColor),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: _RivetDot(color: rivetColor),
              ),
              Positioned(
                bottom: 5,
                left: 5,
                child: _RivetDot(color: rivetColor),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: _RivetDot(color: rivetColor),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Tier badge & Swatch chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge: FREE or STUDIO PRO
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: edition.isPremium
                                  ? TaktColors.filamentAmber
                                      .withValues(alpha: 0.2)
                                  : (isDark
                                      ? TaktColors.warmBone
                                          .withValues(alpha: 0.15)
                                      : const Color(0xFF141618)
                                          .withValues(alpha: 0.08)),
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: edition.isPremium
                                    ? TaktColors.filamentAmber
                                    : (isDark
                                        ? TaktColors.warmBone
                                        : const Color(0xFF5A5D64)),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              edition.isPremium ? 'STUDIO PRO' : 'FREE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: edition.isPremium
                                    ? TaktColors.filamentAmber
                                    : (isDark
                                        ? TaktColors.warmBone
                                        : const Color(0xFF141618)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Swatch chips
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SwatchDot(
                              color: edition.needleColor,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                            _SwatchDot(
                              color: edition.filamentColor,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                            _SwatchDot(
                              color: edition.accentColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Middle: Title, Year & Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edition.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${edition.yearLabel} · ${edition.subtitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),

                    // Bottom: Action indicator / button
                    _buildActionButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (isSelected) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: TaktColors.filamentAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3.0),
          border: Border.all(
            color: TaktColors.filamentAmber,
            width: 0.8,
          ),
        ),
        child: const Text(
          'EQUIPPED',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: TaktColors.filamentAmber,
          ),
        ),
      );
    }

    if (isUnlocked) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(3.0),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black26,
            width: 0.8,
          ),
        ),
        child: Text(
          'EQUIP',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? TaktColors.warmBone : const Color(0xFF141618),
          ),
        ),
      );
    }

    // Locked
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(
          color: TaktColors.mutedOchre.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 9, color: TaktColors.mutedOchre),
          SizedBox(width: 4),
          Text(
            'LOCKED // PREVIEW 👁',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: TaktColors.mutedOchre,
            ),
          ),
        ],
      ),
    );
  }
}

class _RivetDot extends StatelessWidget {
  final Color color;

  const _RivetDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  final Color color;
  final bool isDark;

  const _SwatchDot({
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black26,
          width: 0.5,
        ),
      ),
    );
  }
}

void _showStudioProDialog(
  BuildContext context,
  WidgetRef ref,
  HardwareEdition edition, {
  bool? isDark,
  Color? primaryTextColor,
  Color? secondaryTextColor,
}) {
  showStudioProDialog(
    context,
    ref,
    edition: edition,
    isDark: isDark,
    primaryTextColor: primaryTextColor,
    secondaryTextColor: secondaryTextColor,
  );
}
