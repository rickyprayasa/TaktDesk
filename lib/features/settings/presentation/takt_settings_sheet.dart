import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../app/theme/widgets/rsquare_hardware_plaque.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/services/url_service.dart';
import '../../timer/domain/alarm_chime.dart';
import '../../timer/domain/pomodoro_profile.dart';
import '../../timer/presentation/chrono_dial_controller.dart';
import '../../analytics/presentation/widgets/focus_analytics_dialog.dart';
import 'settings_controller.dart';
import 'widgets/studio_pro_dialog.dart';

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
        isDark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64);

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
                          title: 'THE BRAUN CREED & LEGAL',
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
                        ? TaktColors.filamentAmber
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
              title: 'THE BRAUN CREED & LEGAL',
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 16,
                        color: TaktColors.filamentAmber,
                      ),
                      SizedBox(width: 8),
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
                              color: TaktColors.filamentAmber,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
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
            child: RsquareHardwarePlaque(
              size: 38,
              isDark: isDark,
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
          InkWell(
            key: const ValueKey('zykl_portal_button'),
            onTap: () {
              HapticService.selectionClick();
              UrlService.openUrl('https://zykl.app');
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2125) : const Color(0xFFDDD9CE),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: TaktColors.filamentAmber.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
              child: const Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language, size: 14, color: TaktColors.filamentAmber),
                      SizedBox(width: 8),
                      Text(
                        'ZYKL.APP // PORTAL & PRIVACY',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: TaktColors.filamentAmber,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_outward, size: 12, color: TaktColors.filamentAmber),
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

class _AlarmAcousticsSection extends ConsumerWidget {
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color panelBgColor;
  final Color borderColor;

  const _AlarmAcousticsSection({
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.panelBgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(deskPreferencesControllerProvider);
    final audioService = ref.watch(audioServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'ALARM ACOUSTICS & CHIMES',
          textColor: secondaryTextColor,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: panelBgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            children: AlarmChimes.all.map((chime) {
              final isSelected = prefs.alarmChimeId == chime.id;
              final isProLocked = chime.isPro && !prefs.isProSimulated;

              return InkWell(
                key: ValueKey('alarm_chime_tile_${chime.id}'),
                onTap: () {
                  HapticService.selectionClick();
                  if (isProLocked) {
                    showStudioProDialog(
                      context,
                      ref,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    );
                  } else {
                    ref
                        .read(deskPreferencesControllerProvider.notifier)
                        .setAlarmChime(chime.id);
                    audioService.playAlarmChime(chime.id);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        key: ValueKey('preview_chime_${chime.id}'),
                        icon: const Icon(Icons.volume_up, size: 16),
                        color: isSelected
                            ? TaktColors.filamentAmber
                            : (isDark
                                ? const Color(0xFF9E9B93)
                                : const Color(0xFF5A5D64)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () {
                          HapticService.lightClick();
                          audioService.playAlarmChime(chime.id);
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    chime.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      letterSpacing: 0.8,
                                      color: isSelected
                                          ? TaktColors.filamentAmber
                                          : primaryTextColor,
                                    ),
                                  ),
                                ),
                                if (chime.isPro) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isProLocked
                                          ? Colors.transparent
                                          : TaktColors.filamentAmber
                                              .withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: TaktColors.filamentAmber,
                                        width: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.0,
                                        fontWeight: FontWeight.w700,
                                        color: TaktColors.filamentAmber,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chime.description,
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
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? TaktColors.filamentAmber
                                : (isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF)),
                            width: isSelected ? 4 : 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
              const SizedBox(height: 10),

              // Quick preset selector cassette keys
              Row(
                children: [
                  _buildPresetButton(
                    label: '25/5 CLS',
                    type: PomodoroProfileType.classic,
                    isSelected: activeProfile.type == PomodoroProfileType.classic,
                    isRunning: isRunning,
                    onTap: () => controller.setProfile(PomodoroProfile.classic),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: '50/10 MON',
                    type: PomodoroProfileType.monastic,
                    isSelected: activeProfile.type == PomodoroProfileType.monastic,
                    isRunning: isRunning,
                    onTap: () => controller.setProfile(PomodoroProfile.monastic),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: '15/3 SPR',
                    type: PomodoroProfileType.sprint,
                    isSelected: activeProfile.type == PomodoroProfileType.sprint,
                    isRunning: isRunning,
                    onTap: () => controller.setProfile(PomodoroProfile.sprint),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 6),
                  _buildPresetButton(
                    label: 'CUSTOM',
                    type: PomodoroProfileType.custom,
                    isSelected: activeProfile.type == PomodoroProfileType.custom,
                    isRunning: isRunning,
                    onTap: () => controller.setProfile(customProfile),
                    primaryTextColor: primaryTextColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: borderColor.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: 12),

              // Stepper 1: Focus Duration
              _buildStepperRow(
                title: 'FOCUS DURATION',
                subtitle: 'Work interval (1 – 90 min)',
                value: '${activeProfile.focusMinutes} MIN',
                valueKey: const ValueKey('custom_focus_value'),
                minusKey: const ValueKey('custom_focus_minus'),
                plusKey: const ValueKey('custom_focus_plus'),
                canDecrement: !isRunning && activeProfile.focusMinutes > 1,
                canIncrement: !isRunning && activeProfile.focusMinutes < 90,
                onDecrement: () => controller.updateCustomDurations(
                  focusMinutes: activeProfile.focusMinutes - 1,
                  activate: true,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  focusMinutes: activeProfile.focusMinutes + 1,
                  activate: true,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Stepper 2: Short Break
              _buildStepperRow(
                title: 'SHORT BREAK',
                subtitle: 'Cycle rest interval (1 – 30 min)',
                value: '${activeProfile.shortBreakMinutes} MIN',
                valueKey: const ValueKey('custom_short_break_value'),
                minusKey: const ValueKey('custom_short_break_minus'),
                plusKey: const ValueKey('custom_short_break_plus'),
                canDecrement: !isRunning && activeProfile.shortBreakMinutes > 1,
                canIncrement: !isRunning && activeProfile.shortBreakMinutes < 30,
                onDecrement: () => controller.updateCustomDurations(
                  shortBreakMinutes: activeProfile.shortBreakMinutes - 1,
                  activate: true,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  shortBreakMinutes: activeProfile.shortBreakMinutes + 1,
                  activate: true,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Stepper 3: Long Break
              _buildStepperRow(
                title: 'LONG BREAK',
                subtitle: 'Extended recovery (1 – 45 min)',
                value: '${activeProfile.longBreakMinutes} MIN',
                valueKey: const ValueKey('custom_long_break_value'),
                minusKey: const ValueKey('custom_long_break_minus'),
                plusKey: const ValueKey('custom_long_break_plus'),
                canDecrement: !isRunning && activeProfile.longBreakMinutes > 1,
                canIncrement: !isRunning && activeProfile.longBreakMinutes < 45,
                onDecrement: () => controller.updateCustomDurations(
                  longBreakMinutes: activeProfile.longBreakMinutes - 1,
                  activate: true,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  longBreakMinutes: activeProfile.longBreakMinutes + 1,
                  activate: true,
                ),
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),

              // Stepper 4: Cycle Count
              _buildStepperRow(
                title: 'CYCLE COUNT',
                subtitle: 'Cycles to long recovery (2 – 8)',
                value: '${activeProfile.longBreakInterval} CYCLES',
                valueKey: const ValueKey('custom_cycle_count_value'),
                minusKey: const ValueKey('custom_cycle_count_minus'),
                plusKey: const ValueKey('custom_cycle_count_plus'),
                canDecrement: !isRunning && activeProfile.longBreakInterval > 2,
                canIncrement: !isRunning && activeProfile.longBreakInterval < 8,
                onDecrement: () => controller.updateCustomDurations(
                  longBreakInterval: activeProfile.longBreakInterval - 1,
                  activate: true,
                ),
                onIncrement: () => controller.updateCustomDurations(
                  longBreakInterval: activeProfile.longBreakInterval + 1,
                  activate: true,
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

  Widget _buildPresetButton({
    required String label,
    required PomodoroProfileType type,
    required bool isSelected,
    required bool isRunning,
    required VoidCallback onTap,
    required Color primaryTextColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRunning ? null : onTap,
          borderRadius: BorderRadius.circular(4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? TaktColors.filamentAmber.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: isSelected
                    ? TaktColors.filamentAmber
                    : borderColor.withValues(alpha: 0.5),
                width: isSelected ? 1.2 : 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4.0,
                  height: 4.0,
                  margin: const EdgeInsets.only(bottom: 3.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? TaktColors.filamentAmber
                        : borderColor.withValues(alpha: 0.4),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: TaktColors.filamentAmber.withValues(alpha: 0.6),
                              blurRadius: 3.0,
                            ),
                          ]
                        : null,
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isSelected
                        ? TaktColors.filamentAmber
                        : (isRunning
                            ? primaryTextColor.withValues(alpha: 0.35)
                            : primaryTextColor.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8.5,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              key: minusKey,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              icon: Icon(
                Icons.remove_circle_outline,
                color: canDecrement ? primaryTextColor : borderColor,
                size: 18,
              ),
              onPressed: canDecrement ? onDecrement : null,
            ),
            Container(
              width: 70,
              alignment: Alignment.center,
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
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
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
          flex: 10,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
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
