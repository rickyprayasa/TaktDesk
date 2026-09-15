import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/focus/focus_lock_controller.dart';
import '../../../tasks/presentation/receipt_runner_widget.dart';
import '../../../timer/presentation/chrono_dial_widget.dart';
import '../../../vinyl/presentation/vinyl_player_widget.dart';
import 'chassis_theme_switch.dart';
import 'desk_spec_plate_widget.dart';
import 'emergency_unlatch_widget.dart';
import 'settings_rivet_button.dart';

/// MasterConsoleLandscapeLayout renders an expansive dual-pane Braun Studio console
/// on tablets and landscape displays.
///
/// Left column: Chrono Dial with embedded Monastic focus toggle and emergency unlatch.
/// Right column: Simultaneous Receipt Runner task dispenser and minimalist Vinyl Player.
class MasterConsoleLandscapeLayout extends ConsumerWidget {
  const MasterConsoleLandscapeLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(chassisThemeProvider);
    final focusState = ref.watch(focusLockProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Master Header Bar
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: focusState.isLocked
                                ? TaktColors.filamentAmber
                                : TaktColors.patinaOlive,
                            boxShadow: [
                              BoxShadow(
                                color: (focusState.isLocked
                                        ? TaktColors.filamentAmber
                                        : TaktColors.patinaOlive)
                                    .withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'ZYKL',
                          style: TaktTypography.controlLabel.copyWith(
                            color: theme.hasDarkChassis
                                ? TaktColors.warmBone.withValues(alpha: 0.85)
                                : const Color(0xFF2C3038),
                            letterSpacing: 2.2,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MASTER CONSOLE',
                            style: TaktTypography.controlLabel.copyWith(
                              color: theme.chassisMutedTextColor,
                              fontSize: 8.5,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SettingsRivetButton(),
                        SizedBox(width: 8),
                        ChassisThemeSwitch(),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Dual-Pane Studio Rack
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Chrono Dial & Timing Controls
                    const Expanded(
                      flex: 5,
                      child: Center(
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ChronoDialWidget(),
                                SizedBox(height: 10),
                                EmergencyUnlatchWidget(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Chassis seam separator
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: theme.borderColor.withValues(alpha: 0.25),
                    ),

                    // Right Column: Simultaneous Receipt Runner & Vinyl Player
                    const Expanded(
                      flex: 6,
                      child: Center(
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ReceiptRunnerWidget(),
                                SizedBox(height: 20),
                                VinylPlayerWidget(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Desk Spec Plate Footer
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Center(
                  child: DeskSpecPlateWidget(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
