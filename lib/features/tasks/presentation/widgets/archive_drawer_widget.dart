import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/receipt_task.dart';
import '../receipt_runner_controller.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';
import '../../../../app/theme/theme_controller.dart';

/// Industrial Slide-Out Brass Archive Drawer attached to the bottom of the Thermal Task Runner.
class ArchiveDrawerWidget extends ConsumerWidget {
  const ArchiveDrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiptRunnerProvider);
    final controller = ref.read(receiptRunnerProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);
    final isOpen = state.isArchiveOpen;
    final count = state.archivedTasks.length;

    return Container(
      key: const ValueKey('archive_drawer_container'),
      margin: const EdgeInsets.only(top: 8),
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
            onTap: controller.toggleArchiveDrawer,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              key: const ValueKey('archive_drawer_handle_bar'),
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
                    key: const ValueKey('archive_drawer_rivet_left'),
                    rivetColor: themeState.rivetColor,
                  ),
                  const Spacer(),
                  // Center Brass Plate Handle
                  Container(
                    key: const ValueKey('archive_drawer_handle_plate'),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 14,
                          color: themeState.isDarkMode
                              ? themeState.filamentColor
                              : themeState.chassisTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ARCHIVE // $count',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.0,
                            fontWeight: FontWeight.w700,
                            color: themeState.isDarkMode
                                ? themeState.filamentColor
                                : themeState.chassisTextColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Right brass rivet
                  _buildBrassRivet(
                    key: const ValueKey('archive_drawer_rivet_right'),
                    rivetColor: themeState.rivetColor,
                  ),
                ],
              ),
            ),
          ),
          // 2. Sliding Drawer Contents
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: isOpen
                ? Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(8),
                    child: state.archivedTasks.isEmpty
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
                                  itemCount: state.archivedTasks.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final task = state.archivedTasks[index];
                                    return _buildArchivedTaskItem(context, task, controller, themeState);
                                  },
                                ),
                              ),
                              if (state.archivedTasks.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: controller.clearArchive,
                                    child: Text(
                                      'PURGE ARCHIVE',
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
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: Icon(Icons.close, size: 12, color: themeState.chassisMutedTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
