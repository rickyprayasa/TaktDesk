import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'receipt_runner_controller.dart';
import 'task_input_sheet.dart';
import 'widgets/animated_receipt_strip.dart';
import 'widgets/archive_drawer_widget.dart';
import 'widgets/dispenser_slot_header.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../app/theme/theme_controller.dart';

class ReceiptRunnerWidget extends ConsumerWidget {
  const ReceiptRunnerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiptRunnerProvider);
    final controller = ref.read(receiptRunnerProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);

    return Container(
      key: const ValueKey('receipt_dispenser_chassis'),
      width: 280,
      decoration: BoxDecoration(
        color: themeState.moduleChassisColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeState.borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 4 Corner Mechanical Rivets
          Positioned(
            top: 6,
            left: 6,
            child: _buildCornerRivet(0, themeState.rivetColor),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _buildCornerRivet(1, themeState.rivetColor),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: _buildCornerRivet(2, themeState.rivetColor),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: _buildCornerRivet(3, themeState.rivetColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Dispenser Header with Aperture Slit and Capacity Meter
                DispenserSlotHeader(
                  taskCount: state.tasks.length,
                  maxTasks: 5,
                  borderColor: themeState.borderColor,
                  onAddTap: controller.canAddTask
                ? () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TaskInputSheet(
                        onSubmitted: (val) => controller.addTask(val),
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: 6),
          // 2. Receipt Paper Queue or Empty State
          if (state.tasks.isEmpty)
            Container(
              height: 72,
              alignment: Alignment.center,
              child: Text(
                'NO TASKS IN QUEUE',
                style: TaktTypography.receiptBody.copyWith(
                  color: Colors.white30,
                  letterSpacing: 1.0,
                ),
              ),
            )
          else
            ...state.tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return AnimatedReceiptStrip(
                task: task,
                index: index,
                currentTearProgress: state.tearDragProgress,
                onTearUpdate: (p) => controller.updateTearProgress(p),
                onTorn: () => controller.tearTask(task.id),
                onStampToggle: () => controller.stampDone(task.id),
              );
            }),
                // 3. Slide-Out Brass Archive Drawer
                const ArchiveDrawerWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerRivet(int index, Color color) {
    return Container(
      key: ValueKey('dispenser_rivet_$index'),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            offset: Offset(0, 0.5),
            blurRadius: 0.5,
          ),
        ],
      ),
    );
  }
}
