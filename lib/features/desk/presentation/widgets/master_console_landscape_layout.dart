import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/focus/focus_lock_controller.dart';
import '../../../../core/haptics/haptic_service.dart';
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
/// Right column: Segmented tab menu separating Dispenser and Vinyl Player to prevent
/// vertical stretching and clipping.
class MasterConsoleLandscapeLayout extends ConsumerStatefulWidget {
  const MasterConsoleLandscapeLayout({super.key});

  @override
  ConsumerState<MasterConsoleLandscapeLayout> createState() =>
      _MasterConsoleLandscapeLayoutState();
}

class _MasterConsoleLandscapeLayoutState
    extends ConsumerState<MasterConsoleLandscapeLayout> {
  int _selectedModuleIndex = 0; // 0: Dispenser, 1: Vinyl

  Widget _buildRightModuleSelector(ChassisThemeState theme) {
    const labels = ['DISPENSER', 'VINYL'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? TaktColors.basaltSlate : const Color(0xFFD2D6DC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.isDarkMode ? TaktColors.slateBorder : const Color(0xFFB0B5BC),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final isSelected = _selectedModuleIndex == index;
          return InkWell(
            onTap: () {
              if (_selectedModuleIndex != index) {
                HapticService.selectionClick();
                setState(() {
                  _selectedModuleIndex = index;
                });
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (theme.isDarkMode ? TaktColors.chassisObsidian : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                labels[index],
                style: TaktTypography.controlLabel.copyWith(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (theme.isDarkMode ? TaktColors.filamentAmber : const Color(0xFF141517))
                      : (theme.isDarkMode ? Colors.white54 : Colors.black45),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

                    // Right Column: Tab Menu Separating Dispenser & Vinyl
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildRightModuleSelector(theme),
                                const SizedBox(height: 16),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _selectedModuleIndex == 0
                                      ? const Center(
                                          key: ValueKey('landscape_dispenser_module'),
                                          child: ReceiptRunnerWidget(),
                                        )
                                      : const Center(
                                          key: ValueKey('landscape_vinyl_module'),
                                          child: VinylPlayerWidget(),
                                        ),
                                ),
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
