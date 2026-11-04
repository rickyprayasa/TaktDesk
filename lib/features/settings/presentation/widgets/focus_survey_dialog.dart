import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/widgets/rsquare_hardware_plaque.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/review/survey_prompter.dart';
import '../../../../core/services/url_service.dart';

/// What the owner focuses on; asked in both surveys.
const surveyUses = ['WORK & DEADLINES', 'STUDY', 'CREATIVE WORK', 'BUILDING A HABIT', 'SOMETHING ELSE'];

/// Why someone bought Studio PRO.
const surveyProReasons = [
  'THE HARDWARE EDITIONS',
  'THE SOUNDSCAPES',
  'PAY ONCE, NO SUBSCRIPTION',
  'SUPPORTING AN INDIE MAKER',
  'SOMETHING ELSE',
];

/// Why someone stays on the free desk.
const surveyFreeReasons = [
  'THE FREE DESK IS ENOUGH',
  'NOT SURE WHAT PRO ADDS',
  'THE PRICE',
  'STILL TRYING ZYKL',
  'SOMETHING ELSE',
];

/// The one-time survey (SurveyPrompter): two single-choice questions, then the answers go to support@zykl.app in a
/// pre-filled email the owner sends from their own mail app. SKIP closes it for good.
Future<void> showFocusSurveyDialog(
  BuildContext context, {
  required SurveyKind kind,
  bool isDark = true,
  Future<bool> Function({required String type, required String subject, required String body})? sendEmail,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => FocusSurveyDialog(kind: kind, isDark: isDark, sendEmail: sendEmail),
  );
}

class FocusSurveyDialog extends StatefulWidget {
  final SurveyKind kind;
  final bool isDark;
  final Future<bool> Function({required String type, required String subject, required String body})? sendEmail;

  const FocusSurveyDialog({super.key, required this.kind, this.isDark = true, this.sendEmail});

  @override
  State<FocusSurveyDialog> createState() => _FocusSurveyDialogState();
}

class _FocusSurveyDialogState extends State<FocusSurveyDialog> {
  String? _use;
  String? _reason;

  bool get _isPro => widget.kind == SurveyKind.pro;

  Future<void> _send() async {
    HapticService.selectionClick();
    final info = await UrlService.getDeviceInfo();
    final body = StringBuffer()
      ..writeln(_isPro ? '// STUDIO PRO SURVEY' : '// FREE DESK SURVEY')
      ..writeln('I focus on: $_use')
      ..writeln('${_isPro ? 'PRO was worth it for' : 'I stay on the free desk because'}: $_reason')
      ..writeln()
      ..writeln('Anything else (optional):')
      ..writeln()
      ..writeln()
      ..writeln('--------------------------------------------')
      ..writeln('Version: ${info['versionName'] ?? '?'} (Build ${info['versionCode'] ?? '?'})')
      ..writeln('Android: ${info['osVersion'] ?? '?'}');
    final send = widget.sendEmail ?? UrlService.sendFeedbackEmail;
    await send(
      type: 'SURVEY',
      subject: _isPro ? '[ZYKL Survey] Studio PRO' : '[ZYKL Survey] Free desk',
      body: body.toString(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryColor = isDark ? TaktColors.warmBone : const Color(0xFF141618);
    final secondaryColor = isDark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64);
    final bgColor = isDark ? TaktColors.basaltSlate : const Color(0xFFEDEAE2);
    final borderColor = isDark ? TaktColors.slateBorder : TaktColors.lightChassisBorder;
    final itemBgColor = isDark ? const Color(0xFF1E2126) : const Color(0xFFDFDBD0);
    final amber = TaktColors.amberText(isDark);

    Widget question(
        String label, List<String> options, String? selected, ValueChanged<String> onPick, String keyPrefix) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in options)
                InkWell(
                  key: ValueKey('${keyPrefix}_$option'),
                  onTap: () {
                    HapticService.selectionClick();
                    onPick(option);
                  },
                  borderRadius: BorderRadius.circular(4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected == option ? amber.withValues(alpha: 0.16) : itemBgColor,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: selected == option ? amber : borderColor.withValues(alpha: 0.8),
                        width: selected == option ? 1.2 : 0.8,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: selected == option ? amber : secondaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    final ready = _use != null && _reason != null;

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TWO QUICK QUESTIONS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ASKED ONCE · HELPS SHAPE ZYKL',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          RsquareHardwarePlaque(size: 22, isDark: isDark, showRivets: false),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              question(
                  'WHAT DO YOU FOCUS ON WITH ZYKL?', surveyUses, _use, (v) => setState(() => _use = v), 'survey_use'),
              const SizedBox(height: 16),
              question(
                _isPro ? 'WHAT MADE STUDIO PRO WORTH IT?' : 'WHAT KEEPS YOU ON THE FREE DESK?',
                _isPro ? surveyProReasons : surveyFreeReasons,
                _reason,
                (v) => setState(() => _reason = v),
                'survey_reason',
              ),
              const SizedBox(height: 14),
              Text(
                'SEND opens your email app with the answers filled in, addressed to support@zykl.app.',
                style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: secondaryColor, height: 1.3),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('survey_skip'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '[ SKIP ]',
            style:
                TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w700, color: secondaryColor),
          ),
        ),
        TextButton(
          key: const ValueKey('survey_send'),
          onPressed: ready ? _send : null,
          child: Text(
            '[ SEND ]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: ready ? amber : secondaryColor.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }
}
