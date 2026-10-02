part of '../takt_settings_sheet.dart';

// Alarm chime gallery: audition (instant preview) and equip.

class _AlarmAcousticsSection extends ConsumerWidget {
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color panelBgColor;
  final Color borderColor;

  const _AlarmAcousticsSection({
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.panelBgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(deskPreferencesControllerProvider);
    final audioService = ref.watch(audioServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'ALARM ACOUSTICS & CHIMES',
          textColor: secondaryTextColor,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: panelBgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            children: AlarmChimes.all.map((chime) {
              final isSelected = prefs.alarmChimeId == chime.id;
              final isProLocked = chime.isPro && !prefs.isProSimulated;

              return InkWell(
                key: ValueKey('alarm_chime_tile_${chime.id}'),
                onTap: () {
                  HapticService.selectionClick();
                  if (isProLocked) {
                    showStudioProDialog(
                      context,
                      ref,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    );
                  } else {
                    ref
                        .read(deskPreferencesControllerProvider.notifier)
                        .setAlarmChime(chime.id);
                    audioService.previewAlarmChime(chime.id);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        key: ValueKey('preview_chime_${chime.id}'),
                        icon: const Icon(Icons.volume_up, size: 16),
                        color: isSelected
                            ? TaktColors.filamentAmber
                            : (isDark
                                ? const Color(0xFF9E9B93)
                                : const Color(0xFF2D3139)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () {
                          HapticService.lightClick();
                          audioService.previewAlarmChime(chime.id);
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    chime.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      letterSpacing: 0.8,
                                      color: isSelected
                                          ? TaktColors.amberText(isDark)
                                          : primaryTextColor,
                                    ),
                                  ),
                                ),
                                if (chime.isPro) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isProLocked
                                          ? Colors.transparent
                                          : TaktColors.filamentAmber
                                              .withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: TaktColors.filamentAmber,
                                        width: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.0,
                                        fontWeight: FontWeight.w700,
                                        color: TaktColors.amberText(isDark),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chime.description,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.0,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? TaktColors.filamentAmber
                                : (isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF)),
                            width: isSelected ? 4 : 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
