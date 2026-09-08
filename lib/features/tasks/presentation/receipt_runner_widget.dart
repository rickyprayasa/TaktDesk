import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'receipt_runner_controller.dart';
import 'receipt_runner_painter.dart';
import 'task_input_sheet.dart';
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TaktColors.slateBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('DISPENSER: 5 MAX', style: TaktTypography.controlLabel),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.add,
                  color: controller.canAddTask
                      ? TaktColors.warmBone
                      : TaktColors.warmBone.withValues(alpha: 0.3),
                  size: 18,
                ),
                onPressed: controller.canAddTask
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
            ],
          ),
          const SizedBox(height: 8),
          if (state.tasks.isEmpty)
            Container(
              height: 80,
              alignment: Alignment.center,
              child: Text(
                'NO TASKS IN QUEUE',
                style: TaktTypography.receiptBody.copyWith(color: Colors.white38),
              ),
            )
          else
            ...state.tasks.map((task) {
              return Dismissible(
                key: Key(task.id),
                direction: DismissDirection.horizontal,
                dismissThresholds: const {
                  DismissDirection.startToEnd: 0.75,
                  DismissDirection.endToStart: 0.75,
                },
                onUpdate: (details) => controller.updateTearProgress(details.progress),
                onDismissed: (_) => controller.tearTask(task.id),
                child: GestureDetector(
                  onDoubleTap: () => controller.stampDone(task.id),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: CustomPaint(
                      painter: ReceiptRunnerPainter(tearProgress: state.tearDragProgress),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TaktTypography.receiptBody.copyWith(
                                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (task.isDone)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: TaktColors.patinaOlive, width: 1.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  '[DONE]',
                                  style: TaktTypography.receiptHeader.copyWith(
                                    color: TaktColors.patinaOlive,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
