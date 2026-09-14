import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../soundscape_mixer_controller.dart';

/// Dieter Rams / Braun 3-Channel Analog Soundscape Mixing Console Strip.
///
/// Features:
/// - REC (Primary Vinyl Audio)
/// - DUST (Surface & Needle Crackle)
/// - FLOW (10 Hz Alpha Binaural Drone at 432 Hz)
class TurntableMixerStrip extends ConsumerWidget {
  const TurntableMixerStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixerState = ref.watch(soundscapeMixerProvider);
    final mixerNotifier = ref.read(soundscapeMixerProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;

    return Container(
      width: 256,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131518) : const Color(0xFFE2DDD1),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isDark ? const Color(0xFF262930) : const Color(0xFFC7C2B4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x66000000) : const Color(0x1A000000),
            offset: const Offset(0, 1.5),
            blurRadius: 3.0,
            spreadRadius: -0.5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Plaque
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'SOUNDSCAPE MIXER // 3-CH',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? const Color(0xFF8A909A) : const Color(0xFF656A72),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1E22) : const Color(0xFFDDD8CD),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: isDark ? const Color(0xFF33373E) : const Color(0xFFB5B0A4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '432Hz · 10Hz α',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: themeState.filamentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 3-Channel Fader Strips Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFaderChannel(
                label: 'REC',
                subLabel: 'PRIMARY',
                value: mixerState.primaryVolume,
                isMuted: mixerState.isPrimaryMuted,
                faderKey: 'fader_rec_track',
                muteKey: 'mute_rec_button',
                onChanged: mixerNotifier.setPrimaryVolume,
                onMuteToggle: mixerNotifier.togglePrimaryMute,
                themeState: themeState,
                isDark: isDark,
              ),
              Container(
                width: 1.0,
                height: 82,
                color: themeState.borderColor.withValues(alpha: 0.4),
              ),
              _buildFaderChannel(
                label: 'DUST',
                subLabel: 'CRACKLE',
                value: mixerState.crackleVolume,
                isMuted: mixerState.isCrackleMuted,
                faderKey: 'fader_dust_track',
                muteKey: 'mute_dust_button',
                onChanged: mixerNotifier.setCrackleVolume,
                onMuteToggle: mixerNotifier.toggleCrackleMute,
                themeState: themeState,
                isDark: isDark,
              ),
              Container(
                width: 1.0,
                height: 82,
                color: themeState.borderColor.withValues(alpha: 0.4),
              ),
              _buildFaderChannel(
                label: 'FLOW',
                subLabel: 'BINAURAL',
                value: mixerState.binauralVolume,
                isMuted: mixerState.isBinauralMuted,
                faderKey: 'fader_flow_track',
                muteKey: 'mute_flow_button',
                onChanged: mixerNotifier.setBinauralVolume,
                onMuteToggle: mixerNotifier.toggleBinauralMute,
                themeState: themeState,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaderChannel({
    required String label,
    required String subLabel,
    required double value,
    required bool isMuted,
    required String faderKey,
    required String muteKey,
    required ValueChanged<double> onChanged,
    required VoidCallback onMuteToggle,
    required dynamic themeState,
    required bool isDark,
  }) {
    const faderHeight = 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Channel Label
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isMuted
                ? (isDark ? const Color(0xFF555A64) : const Color(0xFFA09B8E))
                : themeState.chassisTextColor,
          ),
        ),
        Text(
          subLabel,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 6.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: isDark ? const Color(0xFF7A808A) : const Color(0xFF8E897E),
          ),
        ),
        const SizedBox(height: 4),
        // Fader Track + dB Markings
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // dB scale markings on the left
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0dB', style: TextStyle(fontFamily: 'monospace', fontSize: 6.5, color: isDark ? const Color(0xFF6A707A) : const Color(0xFF8E897E))),
                const SizedBox(height: 20),
                Text('-∞', style: TextStyle(fontFamily: 'monospace', fontSize: 6.5, color: isDark ? const Color(0xFF6A707A) : const Color(0xFF8E897E))),
              ],
            ),
            const SizedBox(width: 3),
            // Physical Machined Fader Track
            GestureDetector(
              key: ValueKey(faderKey),
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                // Dragging up increases volume, dragging down decreases
                final delta = -details.primaryDelta! / faderHeight;
                final newVal = (value + delta).clamp(0.0, 1.0);
                if ((value < 0.75 && newVal >= 0.75) || (value > 0.75 && newVal <= 0.75)) {
                  HapticService.dialTick();
                }
                onChanged(newVal);
              },
              child: Container(
                width: 22,
                height: faderHeight,
                alignment: Alignment.bottomCenter,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Recessed Center Track Groove
                    Center(
                      child: Container(
                        width: 4.0,
                        height: faderHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C0E10),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isDark ? const Color(0xFF262930) : const Color(0xFFC7C2B4),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // Aluminum Machined Slider Thumb
                    Positioned(
                      bottom: (value * (faderHeight - 14)).clamp(0.0, faderHeight - 14),
                      child: Container(
                        width: 18,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFD4D0C5) : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(2.5),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4A4E58) : const Color(0xFFB5B0A4),
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              offset: Offset(0, 1),
                              blurRadius: 2.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 2.0,
                            decoration: BoxDecoration(
                              color: isMuted ? const Color(0xFF888888) : TaktColors.filamentAmber,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Mute Micro-LED Toggle
        InkWell(
          key: ValueKey(muteKey),
          onTap: () {
            HapticService.selectionClick();
            onMuteToggle();
          },
          borderRadius: BorderRadius.circular(3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isMuted
                  ? (isDark ? const Color(0xFF1E2126) : const Color(0xFFD5D0C3))
                  : (isDark ? const Color(0xFF141619) : const Color(0xFFECE7DB)),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isMuted
                    ? const Color(0xFFC85A32).withValues(alpha: 0.6)
                    : (isDark ? const Color(0xFF2C3038) : const Color(0xFFBBB5A7)),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMuted
                        ? const Color(0xFFC85A32)
                        : (isDark ? const Color(0xFF333842) : const Color(0xFFA09B8E)),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  isMuted ? 'MUTED' : 'MUTE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7.0,
                    fontWeight: FontWeight.w700,
                    color: isMuted
                        ? const Color(0xFFC85A32)
                        : (isDark ? const Color(0xFF7A808A) : const Color(0xFF7E796E)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
