import 'package:flutter/material.dart';
import '../../../app/theme/takt_colors.dart';
import '../../../app/theme/takt_typography.dart';

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
      widget.onSubmitted(text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      color: TaktColors.basaltSlate,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('PRINT TASK RECEIPT', style: TaktTypography.controlLabel),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 48,
            style: TaktTypography.receiptBody.copyWith(color: TaktColors.warmBone),
            decoration: const InputDecoration(
              hintText: 'Enter mission objective...',
              hintStyle: TextStyle(color: Colors.white38),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: TaktColors.mutedOchre),
              ),
              counterStyle: TextStyle(color: Colors.white38, fontSize: 10),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TaktColors.mutedOchre,
              foregroundColor: TaktColors.warmBone,
            ),
            onPressed: _submit,
            child: const Text('FEED PAPER (PRINT)'),
          ),
        ],
      ),
    );
  }
}
