import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/haptics/haptic_service.dart';
import 'settings_controller.dart';

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
                  const SizedBox(height: 20),

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

                  // Section 2: System Clearance & Lockdown
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
                        Text(
                          'Takt Desk v1.0.0 (Build 2026.09) · Pure Handheld Mobile Edition',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.0,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
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
                              applicationName: 'Takt Desk',
                              applicationVersion: 'v1.0.0 (Build 2026.09)',
                              applicationLegalese:
                                  'Weniger, aber besser — Dieter Rams',
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

class _HardwareEditionsSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'HARDWARE EDITIONS // CHASSIS MATERIALITY',
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
              // Horizontal scrollable row of 4 _EditionCard widgets
              SizedBox(
                height: 148,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < HardwareEdition.all.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        _EditionCard(
                          edition: HardwareEdition.all[i],
                          isSelected: prefs.selectedEdition ==
                              HardwareEdition.all[i].type.name,
                          isUnlocked: !HardwareEdition.all[i].isPremium ||
                              prefs.isProSimulated,
                          isDark: isDark,
                          onTap: () {
                            final ed = HardwareEdition.all[i];
                            final isSel =
                                prefs.selectedEdition == ed.type.name;
                            final isUnl =
                                !ed.isPremium || prefs.isProSimulated;
                            if (!isUnl) {
                              _showStudioProDialog(
                                context,
                                ref,
                                ed,
                                isDark: isDark,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                              );
                            } else if (!isSel) {
                              ref
                                  .read(
                                      deskPreferencesControllerProvider
                                          .notifier)
                                  .setHardwareEdition(ed.type);
                              HapticService.selectionClick();
                            } else {
                              HapticService.selectionClick();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: borderColor),
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
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Developer preview override for all hardware finishes',
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
                    key: const ValueKey('simulate_pro_switch'),
                    value: prefs.isProSimulated,
                    activeThumbColor: TaktColors.filamentAmber,
                    activeTrackColor:
                        TaktColors.filamentAmber.withValues(alpha: 0.5),
                    inactiveThumbColor: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    inactiveTrackColor: isDark
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
          Icon(
            Icons.lock,
            size: 9,
            color: TaktColors.mutedOchre,
          ),
          SizedBox(width: 4),
          Text(
            'LOCKED // PRO',
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
  final dark = isDark ?? ref.read(chassisThemeProvider).isDarkMode;
  final primary = primaryTextColor ??
      (dark ? TaktColors.warmBone : const Color(0xFF141618));
  final secondary = secondaryTextColor ??
      (dark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64));

  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor:
          dark ? TaktColors.basaltSlate : const Color(0xFFEDEAE2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: dark ? TaktColors.slateBorder : TaktColors.lightChassisBorder,
        ),
      ),
      title: Text(
        'TAKT DESK STUDIO PRO',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: primary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UNLOCK ${edition.title} & ALL HARDWARE FINISHES',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: TaktColors.filamentAmber,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lifetime clearance gives you access to aerospace titanium, Bauhaus primary palettes, burnished marine brass, and all future hardware materials.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: secondary,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text(
            'CANCEL',
            style: TextStyle(
              fontFamily: 'monospace',
              color: secondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        ElevatedButton(
          key: const ValueKey('pro_dialog_unlock_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TaktColors.filamentAmber,
            foregroundColor: TaktColors.chassisObsidian,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          onPressed: () async {
            await ref
                .read(deskPreferencesControllerProvider.notifier)
                .setProSimulated(true);
            await ref
                .read(deskPreferencesControllerProvider.notifier)
                .setHardwareEdition(edition.type);
            HapticService.selectionClick();
            if (dialogCtx.mounted) {
              Navigator.of(dialogCtx).pop();
            }
          },
          child: const Text(
            'UNLOCK NOW (SIMULATED)',
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
