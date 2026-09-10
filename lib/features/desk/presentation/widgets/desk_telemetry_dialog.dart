import 'package:flutter/material.dart';
import 'desk_telemetry_slip_widget.dart';

/// Industrial modal dialog presenting the thermal dot-matrix session telemetry slip.
///
/// Anchored by a dimmed semi-transparent backdrop (`barrierDismissible: true`),
/// presenting a centered 280px thermal receipt paper roll with monospace audit log,
/// one-tap clipboard copy, and tactile dismiss button.
class DeskTelemetryDialog extends StatelessWidget {
  const DeskTelemetryDialog({super.key});

  /// Displays the modal dialog centered above the console without shifting canvas layout.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      barrierDismissible: true,
      builder: (dialogCtx) => const DeskTelemetryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: DeskTelemetrySlipWidget(
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
