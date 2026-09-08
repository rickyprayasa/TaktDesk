import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'receipt_runner_controller.dart';
import 'task_input_sheet.dart';
import 'widgets/animated_receipt_strip.dart';
import 'widgets/dispenser_slot_header.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';

class ReceiptRunnerWidget extends ConsumerWidget {
  const ReceiptRunnerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiptRunnerProvider);
    final controller = ref.read(receiptRunnerProvider.notifier);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: TaktColors.basaltSlate,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TaktColors.slateBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Dispenser Header with Aperture Slit and Capacity Meter
          DispenserSlotHeader(
            taskCount: state.tasks.length,
            maxTasks: 5,
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
        ],
      ),
    );
  }
}
