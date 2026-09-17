import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';
import '../../../core/haptics/haptic_service.dart';
import 'receipt_runner_painter.dart';

class TaskInputSheet extends StatefulWidget {
  final ValueChanged<String> onSubmitted;

  const TaskInputSheet({super.key, required this.onSubmitted});

  @override
  State<TaskInputSheet> createState() => _TaskInputSheetState();
}

class _TaskInputSheetState extends State<TaskInputSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      HapticService.mechanicalPress();
      widget.onSubmitted(text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D22),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(
          color: const Color(0xFF343842),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tactile Chassis Drag Pill
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Industrial Control Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TaktColors.filamentAmber,
                      boxShadow: [
                        BoxShadow(
                          color: TaktColors.filamentAmber.withValues(alpha: 0.60),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PRINT TASK RECEIPT',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      color: TaktColors.warmBone,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'ESC ✕',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: TaktColors.warmBone.withValues(alpha: 0.45),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Simulated Dispenser Ejection Aperture Slot
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E10),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF2E3238), width: 0.8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 4. Emerging Thermal Paper Receipt Ticket (Direct Surface Input)
          Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: CustomPaint(
              painter: ReceiptRunnerPainter(tearProgress: 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thermal Ticket Metadata Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#NEW // ZYKL DISPENSER',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: TaktColors.thermalCarbon.withValues(alpha: 0.55),
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'THERMAL SLIP',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.0,
                            fontWeight: FontWeight.w700,
                            color: TaktColors.thermalCarbon.withValues(alpha: 0.40),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Micro Dotted Divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: TaktColors.thermalCarbon.withValues(alpha: 0.15),
                            width: 1.0,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Typewriter Monospace Text Field directly on paper
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: 48,
                      style: TaktTypography.receiptBody.copyWith(
                        color: TaktColors.thermalCarbon,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      cursorColor: TaktColors.filamentAmber,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        hintText: 'Enter mission objective...',
                        hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          color: TaktColors.thermalCarbon.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        counterStyle: TextStyle(
                          fontFamily: 'monospace',
                          color: TaktColors.thermalCarbon.withValues(alpha: 0.50),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Tactile Mechanical Action Button: [ ⏎ FEED PAPER (PRINT) ]
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TaktColors.mutedOchre,
              foregroundColor: TaktColors.warmBone,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Color(0xFF8E3B10), width: 1.0),
              ),
            ),
            onPressed: _submit,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_return_rounded, size: 15, color: TaktColors.warmBone),
                SizedBox(width: 8),
                Text(
                  'FEED PAPER (PRINT)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 11.5,
                    color: TaktColors.warmBone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
