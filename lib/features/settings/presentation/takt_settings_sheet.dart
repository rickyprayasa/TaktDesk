import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../app/theme/widgets/zykl_hardware_plaque.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/backup/history_backup.dart';
import '../../../core/config/app_security_config.dart';
import '../../../core/focus/focus_lock_service.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/services/url_service.dart';
import '../../tasks/presentation/receipt_runner_controller.dart';
import '../../timer/domain/alarm_chime.dart';
import '../../timer/domain/pomodoro_profile.dart';
import '../../timer/presentation/chrono_dial_controller.dart';
import '../../analytics/presentation/widgets/focus_analytics_dialog.dart';
import 'settings_controller.dart';
import 'widgets/feedback_dialog.dart';
import 'widgets/studio_pro_dialog.dart';

part 'settings_sections/alarm_acoustics_section.dart';
part 'settings_sections/hardware_editions_section.dart';
part 'settings_sections/history_files_section.dart';
part 'settings_sections/pomodoro_interval_section.dart';
part 'settings_sections/quick_sheets.dart';
part 'settings_sections/section_header.dart';

/// The Industrial Service Hatch Modal Sheet (Settings, About & Legal).
///
/// Embodies Dieter Rams / Braun design language with tactile sliders,
/// telemetry readouts, system clearance badges, and legal attributions.
class TaktSettingsSheet extends ConsumerStatefulWidget {
  final bool? isLandscape;
  const TaktSettingsSheet({super.key, this.isLandscape});

  @override
  ConsumerState<TaktSettingsSheet> createState() => _TaktSettingsSheetState();
}

class _TaktSettingsSheetState extends ConsumerState<TaktSettingsSheet> {
  int _selectedTabIndex = 0;
  static const List<String> _tabs = [
    'EDITIONS',
    'ACOUSTICS',
    'INTERVALS',
    'TELEMETRY',
  ];

  @override
  Widget build(BuildContext context) {
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
        isDark ? const Color(0xFF9E9B93) : const Color(0xFF2D3139);

    final orientation = MediaQuery.of(context).orientation;
    final size = MediaQuery.of(context).size;
    final isLandscape = widget.isLandscape ??
        (orientation == Orientation.landscape && size.height < 550);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 760 : 440,
          maxHeight: isLandscape
              ? (size.height * 0.90).clamp(340.0, 640.0)
              : double.infinity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: isLandscape
                ? BorderRadius.circular(16.0)
                : const BorderRadius.vertical(top: Radius.circular(16.0)),
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
            child: isLandscape
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                            const SizedBox(height: 12),

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
                            Text(
                              'DEVELOPED BY RSQUARE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: TaktColors.amberText(isDark),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Dieter Rams Tab Bar
                            _buildTabBar(
                              isDark: isDark,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              panelBgColor: panelBgColor,
                              borderColor: borderColor,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          physics: const BouncingScrollPhysics(),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: KeyedSubtree(
                              key: ValueKey(_selectedTabIndex),
                              child: _buildActiveTabContent(
                                prefs: prefs,
                                lifetimeStats: lifetimeStats,
                                isDark: isDark,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                panelBgColor: panelBgColor,
                                borderColor: borderColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        Text(
                          'DEVELOPED BY RSQUARE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: TaktColors.amberText(isDark),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section: Hardware Editions
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
                        _buildHardwareAcousticsCard(
                          prefs: prefs,
                          isDark: isDark,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          panelBgColor: panelBgColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 20),

                        // Section 1.5: Alarm Acoustics & Chimes
                        _AlarmAcousticsSection(
                          isDark: isDark,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          panelBgColor: panelBgColor,
                          borderColor: borderColor,
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
                        _buildSystemClearanceCard(
                          prefs: prefs,
                          isDark: isDark,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          panelBgColor: panelBgColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 20),

                        // Section 4: Telemetry & Logs
                        _SectionHeader(
                          title: 'TELEMETRY & LOGS',
                          textColor: secondaryTextColor,
                        ),
                        const SizedBox(height: 8),
                        _buildTelemetryCard(
                          context: context,
                          lifetimeStats: lifetimeStats,
                          isDark: isDark,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          panelBgColor: panelBgColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 20),

                        // Section 5: The Braun Creed & Legal
                        _SectionHeader(
                          title: 'THE DESIGN CREED & LEGAL',
                          textColor: secondaryTextColor,
                        ),
                        const SizedBox(height: 8),
                        _buildBraunCreedCard(
                          context: context,
                          isDark: isDark,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          panelBgColor: panelBgColor,
                          borderColor: borderColor,
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

  Widget _buildTabBar({
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color panelBgColor,
    required Color borderColor,
  }) {
    return Container(
      key: const ValueKey('settings_landscape_tab_bar'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: panelBgColor,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: InkWell(
              key: ValueKey('settings_tab_${_tabs[index]}'),
              borderRadius: BorderRadius.circular(2.0),
              onTap: () {
                HapticService.selectionClick();
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? TaktColors.chassisObsidian : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2.0),
                  border: isSelected
                      ? Border.all(color: borderColor, width: 0.8)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 1.0,
                    color: isSelected
                        ? TaktColors.amberText(isDark)
                        : secondaryTextColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent({
    required dynamic prefs,
    required dynamic lifetimeStats,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color panelBgColor,
    required Color borderColor,
  }) {
    switch (_selectedTabIndex) {
      case 0:
        return _HardwareEditionsSection(
          prefs: prefs,
          isDark: isDark,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
          panelBgColor: panelBgColor,
          borderColor: borderColor,
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: 'HARDWARE ACOUSTICS & TACTILITY',
              textColor: secondaryTextColor,
            ),
            const SizedBox(height: 8),
            _buildHardwareAcousticsCard(
              prefs: prefs,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              panelBgColor: panelBgColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 16),
            _AlarmAcousticsSection(
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              panelBgColor: panelBgColor,
              borderColor: borderColor,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PomodoroIntervalEngineSection(
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              panelBgColor: panelBgColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'SYSTEM CLEARANCE & LOCKDOWN',
              textColor: secondaryTextColor,
            ),
            const SizedBox(height: 8),
            _buildSystemClearanceCard(
              prefs: prefs,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              panelBgColor: panelBgColor,
              borderColor: borderColor,
            ),
          ],
        );
      case 3:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: 'TELEMETRY & LOGS',
              textColor: secondaryTextColor,
            ),
            const SizedBox(height: 8),
            _buildTelemetryCard(
              context: context,
              lifetimeStats: lifetimeStats,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              panelBgColor: panelBgColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'THE DESIGN CREED & LEGAL',
              textColor: secondaryTextColor,
            ),
            const SizedBox(height: 8),
            _buildBraunCreedCard(
              context: context,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              panelBgColor: panelBgColor,
              borderColor: borderColor,
            ),
          ],
        );
    }
  }

  Widget _buildHardwareAcousticsCard({
    required dynamic prefs,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color panelBgColor,
    required Color borderColor,
  }) {
    return Container(
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
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: TaktColors.amberText(isDark),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: TaktColors.filamentAmber,
              inactiveTrackColor:
                  isDark ? TaktColors.slateLight : TaktColors.paperBorder,
              thumbColor: TaktColors.filamentAmber,
              overlayColor: TaktColors.filamentAmber.withValues(alpha: 0.2),
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
                    .read(deskPreferencesControllerProvider.notifier)
                    .setVolume(val);
              },
              onChangeEnd: (val) {
                ref
                    .read(deskPreferencesControllerProvider.notifier)
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
                activeTrackColor:
                    TaktColors.filamentAmber.withValues(alpha: 0.5),
                inactiveThumbColor:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                inactiveTrackColor:
                    isDark ? TaktColors.slateLight : TaktColors.paperBorder,
                onChanged: (val) {
                  ref
                      .read(deskPreferencesControllerProvider.notifier)
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
                activeTrackColor:
                    TaktColors.filamentAmber.withValues(alpha: 0.5),
                inactiveThumbColor:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                inactiveTrackColor:
                    isDark ? TaktColors.slateLight : TaktColors.paperBorder,
                onChanged: (val) {
                  ref
                      .read(deskPreferencesControllerProvider.notifier)
                      .setHapticsEnabled(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemClearanceCard({
    required dynamic prefs,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color panelBgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelBgColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge: the real Do Not Disturb access, rechecked on resume
          _DndAccess(
            builder: (context, granted) => Row(
              key: const ValueKey('clearance_status_badge'),
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: granted == false ? TaktColors.mutedOchre : TaktColors.patinaOlive,
                    boxShadow: const [
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
                    switch (granted) {
                      true => 'STATUS: DND ACCESS GRANTED · APP PINNING READY',
                      false => 'STATUS: DND ACCESS NEEDED · CALLS WILL STILL RING',
                      null => 'STATUS: CHECKING ANDROID DND ACCESS',
                    },
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
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1, thickness: 0.6),
          const SizedBox(height: 12),

          // Auto-release toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUTO-RELEASE MONASTIC ON FINISH',
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
                      'Automatically unpin app when timer reaches 00:00. Keep OFF to guarantee screen stays awake with alarm chime until manually released.',
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
                key: const ValueKey('auto_release_monastic_switch'),
                value: prefs.autoUnlockMonastic,
                activeThumbColor: TaktColors.filamentAmber,
                activeTrackColor:
                    TaktColors.filamentAmber.withValues(alpha: 0.5),
                inactiveThumbColor:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                inactiveTrackColor:
                    isDark ? TaktColors.slateLight : TaktColors.paperBorder,
                onChanged: (val) {
                  ref
                      .read(deskPreferencesControllerProvider.notifier)
                      .setAutoUnlockMonastic(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Desk clock toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESK CLOCK WHILE RUNNING',
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
                      'Keeps the screen on while the timer runs. After a minute untouched it dims and shifts a few pixels against burn-in. Best on a stand or charger.',
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
                key: const ValueKey('desk_clock_mode_switch'),
                value: prefs.deskClockMode,
                activeThumbColor: TaktColors.filamentAmber,
                activeTrackColor:
                    TaktColors.filamentAmber.withValues(alpha: 0.5),
                inactiveThumbColor:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                inactiveTrackColor:
                    isDark ? TaktColors.slateLight : TaktColors.paperBorder,
                onChanged: (val) {
                  ref
                      .read(deskPreferencesControllerProvider.notifier)
                      .setDeskClockMode(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Configure DND button
          InkWell(
            key: const ValueKey('dnd_settings_button'),
            onTap: () async {
              await ref
                  .read(focusLockServiceProvider)
                  .openNotificationPolicySettings();
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2126)
                    : const Color(0xFFE8E4D9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.do_not_disturb_on_outlined,
                    size: 13,
                    color: primaryTextColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CONFIGURE ANDROID DND ACCESS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DndAccessStatus(isDark: isDark, mutedColor: secondaryTextColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard({
    required BuildContext context,
    required dynamic lifetimeStats,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color panelBgColor,
    required Color borderColor,
  }) {
    return Container(
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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: TaktColors.filamentAmber.withValues(alpha: 0.6),
                width: 1.2,
              ),
              color: TaktColors.filamentAmber.withValues(alpha: 0.08),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('open_focus_analytics_btn'),
                borderRadius: BorderRadius.circular(4.0),
                onTap: () {
                  ref.read(audioServiceProvider).play(SoundEffect.dialClick);
                  HapticService.selectionClick();
                  FocusAnalyticsDialog.show(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bar_chart,
                        size: 16,
                        color: TaktColors.filamentAmber,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'FOCUS ANALYTICS & CHARTS',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: TaktColors.amberText(isDark),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: TaktColors.filamentAmber,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _HistoryFilesControls(
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildBraunCreedCard({
    required BuildContext context,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color panelBgColor,
    required Color borderColor,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ZyklHardwarePlaque(
              size: 46,
              isDark: isDark,
            ),
          ),
          Text(
            switch (ref.watch(appVersionLabelProvider).valueOrNull) {
              final String version => 'ZYKL: POMODORO FOCUS TIMER // $version',
              _ => 'ZYKL: POMODORO FOCUS TIMER',
            },
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CRAFTED BY RSQUARE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: TaktColors.amberText(isDark),
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
          const SizedBox(height: 6),
          Text(
            'Design inspired by the principles of Dieter Rams. ZYKL is an independent product by RSQUARE, '
            'not affiliated with or endorsed by Dieter Rams or Braun.',
            key: const ValueKey('zykl_design_disclaimer'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.0,
              color: secondaryTextColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          // Rate on Google Play Store Button
          InkWell(
            key: const ValueKey('zykl_rate_playstore_button'),
            onTap: () {
              HapticService.selectionClick();
              UrlService.openPlayStore();
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2125) : const Color(0xFFDDD9CE),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: TaktColors.filamentAmber.withValues(alpha: 0.7),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rate_rounded, size: 16, color: TaktColors.filamentAmber),
                      const SizedBox(width: 8),
                      Text(
                        'RATE ZYKL ON GOOGLE PLAY',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: TaktColors.amberText(isDark),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_outward, size: 12, color: TaktColors.filamentAmber),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Dispatch Feedback Dialog Button (Gmail direct with diagnostics)
          InkWell(
            key: const ValueKey('zykl_feedback_button'),
            onTap: () {
              HapticService.selectionClick();
              showFeedbackDispatchDialog(context, isDark: isDark);
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191B1F) : const Color(0xFFE5E1D6),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.8),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_unread_outlined, size: 14, color: primaryTextColor),
                      const SizedBox(width: 8),
                      Text(
                        'DISPATCH FEEDBACK & BUG REPORT',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 12, color: secondaryTextColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Web Portal & Privacy
          InkWell(
            key: const ValueKey('zykl_portal_button'),
            onTap: () {
              HapticService.selectionClick();
              UrlService.openUrl('https://zykl.app');
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191B1F) : const Color(0xFFE5E1D6),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language, size: 13, color: secondaryTextColor),
                      const SizedBox(width: 8),
                      Text(
                        'ZYKL.APP // PORTAL & PRIVACY',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_outward, size: 11, color: secondaryTextColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                applicationName: 'ZYKL: Pomodoro Focus Timer',
                applicationVersion: ref.read(appVersionLabelProvider).valueOrNull,
                applicationIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: ZyklHardwarePlaque(size: 48),
                ),
                applicationLegalese:
                    'Weniger, aber besser — Dieter Rams · Crafted with precision by RSQUARE',
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

/// Android Do Not Disturb access, checked on build and again whenever the user
/// comes back from Android settings, so the sheet never shows a stale answer.
/// `granted` is null until the first check returns.
class _DndAccess extends ConsumerStatefulWidget {
  final Widget Function(BuildContext context, bool? granted) builder;

  const _DndAccess({required this.builder});

  @override
  ConsumerState<_DndAccess> createState() => _DndAccessState();
}

class _DndAccessState extends ConsumerState<_DndAccess> {
  late final AppLifecycleListener _lifecycle;
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final granted = await ref.read(focusLockServiceProvider).isNotificationPolicyAccessGranted();
    if (mounted) setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _granted);
}

/// GRANTED / NOT GRANTED next to the DND button.
class _DndAccessStatus extends StatelessWidget {
  final bool isDark;
  final Color mutedColor;

  const _DndAccessStatus({required this.isDark, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return _DndAccess(
      builder: (context, granted) => granted == null
          ? const SizedBox.shrink()
          : Text(
              granted ? 'GRANTED' : 'NOT GRANTED',
              key: const ValueKey('dnd_access_status'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: granted ? TaktColors.amberText(isDark) : mutedColor,
              ),
            ),
    );
  }
}
