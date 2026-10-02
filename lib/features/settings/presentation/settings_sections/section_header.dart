part of '../takt_settings_sheet.dart';

// Shared section title used by every settings card.

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;

  const _SectionHeader({
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 10,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Container(
            height: 1.0,
            color: textColor.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}
