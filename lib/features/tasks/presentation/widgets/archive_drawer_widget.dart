import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/receipt_task.dart';
import '../receipt_runner_controller.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/sound_effect.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../app/motion.dart';

/// Industrial Slide-Out Modular Brass Archive Drawer attached to the bottom of the Thermal Task Runner.
class ArchiveDrawerWidget extends ConsumerStatefulWidget {
  const ArchiveDrawerWidget({super.key});

  @override
  ConsumerState<ArchiveDrawerWidget> createState() => _ArchiveDrawerWidgetState();
}

class _ArchiveDrawerWidgetState extends ConsumerState<ArchiveDrawerWidget> {
  final Set<int> _openDrawers = <int>{};

  @override
  void initState() {
    super.initState();
    if (ref.read(receiptRunnerProvider).isArchiveOpen) {
      _openDrawers.add(0);
    }
  }

  void _toggleDrawer(int drawerIndex) {
    HapticService.mechanicalPress();
    final bool nextOpen = !_openDrawers.contains(drawerIndex);
    setState(() {
      if (nextOpen) {
        _openDrawers.add(drawerIndex);
      } else {
        _openDrawers.remove(drawerIndex);
      }
    });
    if (drawerIndex == 0 && ref.read(receiptRunnerProvider).isArchiveOpen != nextOpen) {
      ref.read(receiptRunnerProvider.notifier).state =
          ref.read(receiptRunnerProvider).copyWith(isArchiveOpen: nextOpen);
    }
    ref.read(audioServiceProvider).playFoley(
      nextOpen ? SoundEffect.drawerSlide : SoundEffect.drawerLatch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptRunnerProvider);
    final controller = ref.read(receiptRunnerProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);

    ref.listen<bool>(
      receiptRunnerProvider.select((s) => s.isArchiveOpen),
      (prev, next) {
        if (prev != next) {
          setState(() {
            if (next) {
              _openDrawers.add(0);
            } else {
              _openDrawers.remove(0);
            }
          });
        }
      },
    );

    // Partition state.archivedTasks into chunks of 10 tasks
    final chunks = <List<ReceiptTask>>[];
    if (state.archivedTasks.isEmpty) {
      chunks.add(const []);
    } else {
      for (int i = 0; i < state.archivedTasks.length; i += 10) {
        chunks.add(
          state.archivedTasks.sublist(
            i,
            math.min(i + 10, state.archivedTasks.length),
          ),
        );
      }
    }

    final drawerWidgets = <Widget>[];
    for (int drawerIndex = 0; drawerIndex < chunks.length; drawerIndex++) {
      if (drawerIndex > 0) {
        drawerWidgets.add(const SizedBox(height: 6));
      }
      final bool isOpen = _openDrawers.contains(drawerIndex) && drawerIndex < chunks.length;
      drawerWidgets.add(
        _buildDrawerChassis(
          drawerIndex: drawerIndex,
          chunk: chunks[drawerIndex],
          isOpen: isOpen,
          controller: controller,
          themeState: themeState,
        ),
      );
    }

    return Column(
      key: const ValueKey('archive_drawer_multi_container'),
      mainAxisSize: MainAxisSize.min,
      children: drawerWidgets,
    );
  }

  Widget _buildDrawerChassis({
    required int drawerIndex,
    required List<ReceiptTask> chunk,
    required bool isOpen,
    required ReceiptRunnerController controller,
    required ChassisThemeState themeState,
  }) {
    final drawerNum = (drawerIndex + 1).toString().padLeft(2, '0');
    final taskCountText = '${chunk.length.toString().padLeft(2, '0')} TASKS';
    final arrow = isOpen ? '▲' : '▾';
    final handleText = '[ ARCHIVE // DRAWER $drawerNum · $taskCountText $arrow ]';

    return Container(
      key: drawerIndex == 0
          ? const ValueKey('archive_drawer_container')
          : ValueKey('archive_drawer_container_$drawerIndex'),
      margin: EdgeInsets.only(top: drawerIndex == 0 ? 8 : 0),
      decoration: BoxDecoration(
        color: themeState.isDarkMode ? const Color(0xFF1B1E22) : themeState.moduleChassisColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOpen ? themeState.filamentColor.withValues(alpha: 0.6) : themeState.borderColor,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Brushed Brass Handle Bar
          InkWell(
            key: ValueKey('archive_drawer_handle_$drawerIndex'),
            onTap: () => _toggleDrawer(drawerIndex),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              key: drawerIndex == 0
                  ? const ValueKey('archive_drawer_handle_bar')
                  : ValueKey('archive_drawer_handle_bar_$drawerIndex'),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  colors: themeState.plateGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  // Left brass rivet
                  _buildBrassRivet(
                    key: drawerIndex == 0
                        ? const ValueKey('archive_drawer_rivet_left')
                        : ValueKey('archive_drawer_${drawerIndex}_rivet_left'),
                    rivetColor: themeState.rivetColor,
                  ),
                  const SizedBox(width: 4),
                  // Center Brass Plate Handle
                  Expanded(
                    child: Center(
                      child: Container(
                        key: drawerIndex == 0
                            ? const ValueKey('archive_drawer_handle_plate')
                            : ValueKey('archive_drawer_${drawerIndex}_handle_plate'),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeState.isDarkMode
                              ? themeState.filamentColor.withValues(alpha: 0.15)
                              : themeState.canvasColor,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: themeState.isDarkMode
                                ? themeState.filamentColor.withValues(alpha: 0.7)
                                : themeState.borderColor,
                            width: 0.8,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            handleText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              color: themeState.isDarkMode
                                  ? themeState.filamentColor
                                  : themeState.chassisTextColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Right brass rivet
                  _buildBrassRivet(
                    key: drawerIndex == 0
                        ? const ValueKey('archive_drawer_rivet_right')
                        : ValueKey('archive_drawer_${drawerIndex}_rivet_right'),
                    rivetColor: themeState.rivetColor,
                  ),
                ],
              ),
            ),
          ),
          // 2. Sliding Drawer Contents
          AnimatedSize(
            duration: motion(context, const Duration(milliseconds: 280)),
            curve: Curves.easeOutCubic,
            child: isOpen
                ? Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(8),
                    child: chunk.isEmpty
                        ? Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Text(
                              'DRAWER EMPTY',
                              style: TaktTypography.receiptBody.copyWith(
                                color: themeState.chassisMutedTextColor,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: chunk.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final task = chunk[index];
                                    return _buildArchivedTaskItem(
                                      context,
                                      task,
                                      controller,
                                      themeState,
                                      ref.read(receiptRunnerProvider).focusMinutesOf(task.id),
                                    );
                                  },
                                ),
                              ),
                              if (chunk.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => controller.purgeTasks(chunk),
                                    child: Text(
                                      'PURGE THIS BATCH',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.0,
                                        fontWeight: FontWeight.w600,
                                        color: themeState.isDarkMode
                                            ? TaktColors.mutedOchre.withValues(alpha: 0.8)
                                            : const Color(0xFFB33A18),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrassRivet({Key? key, required Color rivetColor}) {
    return Container(
      key: key,
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rivetColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedTaskItem(
    BuildContext context,
    ReceiptTask task,
    ReceiptRunnerController controller,
    ChassisThemeState themeState,
    int focusMinutes,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: themeState.isDarkMode ? const Color(0xFF25282E) : themeState.canvasColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: themeState.borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          // Ochre checked dot
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFC85A32),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: TaktTypography.receiptBody.copyWith(
                fontSize: 10,
                color: themeState.chassisTextColor.withValues(alpha: 0.75),
                decoration: TextDecoration.lineThrough,
                decorationColor: themeState.chassisTextColor.withValues(alpha: 0.75),
                decorationThickness: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (focusMinutes > 0) ...[
            const SizedBox(width: 6),
            Text(
              '$focusMinutes MIN',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: themeState.chassisMutedTextColor,
              ),
            ),
          ],
          const SizedBox(width: 6),
          // Reprint button
          InkWell(
            onTap: () => controller.reprintTask(task),
            borderRadius: BorderRadius.circular(3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: themeState.isDarkMode ? const Color(0xFF333842) : themeState.moduleChassisColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'REPRINT',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: themeState.isDarkMode ? const Color(0xFFD99B59) : const Color(0xFF8B4513),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Delete button
          InkWell(
            onTap: () => controller.deleteArchivedTask(task.id),
            borderRadius: BorderRadius.circular(3),
            child: Padding(
              // Wider touch target (was ~18 x 16) without making the archive row taller.
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              child: Icon(
                Icons.close,
                size: 12,
                semanticLabel: 'Delete archived task',
                color: themeState.chassisMutedTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
