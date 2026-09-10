import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../../../settings/presentation/widgets/studio_pro_dialog.dart';
import '../../domain/vinyl_track.dart';
import '../vinyl_controller.dart';

/// Tactile Vinyl Record Crate Bottom Sheet Modal (`VinylRecordCrateSheet`).
///
/// Allows users to browse through the 8 curated vinyl record jackets in a tactile,
/// industrial Braun/Rams inspired crate with peeking miniature vinyl discs,
/// catalog badges, and Studio Pro gating.
class VinylRecordCrateSheet extends ConsumerStatefulWidget {
  const VinylRecordCrateSheet({super.key});

  /// Opens the crate sheet via [showModalBottomSheet].
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VinylRecordCrateSheet(),
    );
  }

  @override
  ConsumerState<VinylRecordCrateSheet> createState() =>
      _VinylRecordCrateSheetState();
}

class _VinylRecordCrateSheetState extends ConsumerState<VinylRecordCrateSheet> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final activeIndex =
        ref.read(vinylProvider).selectedTrackIndex.clamp(0, 7);
    _currentPage = activeIndex;
    _pageController = PageController(
      initialPage: activeIndex,
      viewportFraction: 0.82,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(chassisThemeProvider);
    final vinylState = ref.watch(vinylProvider);
    final isPro =
        ref.watch(deskPreferencesControllerProvider).isProSimulated;

    return Container(
      height: 460,
      decoration: BoxDecoration(
        color: themeState.moduleChassisColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: themeState.borderColor, width: 1.0),
          left: BorderSide(color: themeState.borderColor, width: 1.0),
          right: BorderSide(color: themeState.borderColor, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: themeState.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ANALOG RECORD CRATE // 33 RPM',
                      style: TaktTypography.controlLabel.copyWith(
                        color: themeState.chassisTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '[ ${(_currentPage + 1).toString().padLeft(2, '0')} / ${VinylTrack.presets.length.toString().padLeft(2, '0')} ]',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: themeState.chassisMutedTextColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    key: const ValueKey('crate_close_button'),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: themeState.chassisTextColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Snapping Carousel of 8 Album Sleeves
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: VinylTrack.presets.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentPage = idx;
                  });
                },
                itemBuilder: (context, index) {
                  final track = VinylTrack.presets[index];
                  final isActive = vinylState.selectedTrackIndex == track.index;
                  final isLocked = track.isPremium && !isPro;

                  return _RecordSleeveCard(
                    track: track,
                    isActive: isActive,
                    isLocked: isLocked,
                    isDark: themeState.isDarkMode,
                    borderColor: themeState.borderColor,
                    chassisTextColor: themeState.chassisTextColor,
                    chassisMutedTextColor: themeState.chassisMutedTextColor,
                    onLoadTrack: () {
                      ref
                          .read(vinylProvider.notifier)
                          .selectTrack(track.index, isPro: isPro);
                      HapticService.selectionClick();
                      Navigator.of(context).pop();
                    },
                    onOpenProDialog: () {
                      showStudioProDialog(
                        context,
                        ref,
                        vinylTrack: track,
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(VinylTrack.presets.length, (i) {
                final isSelected = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 16 : 6,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (themeState.isDarkMode
                            ? TaktColors.filamentAmber
                            : themeState.chassisTextColor)
                        : themeState.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// A tactile album sleeve jacket card with peeking miniature vinyl disc.
class _RecordSleeveCard extends StatelessWidget {
  final VinylTrack track;
  final bool isActive;
  final bool isLocked;
  final bool isDark;
  final Color borderColor;
  final Color chassisTextColor;
  final Color chassisMutedTextColor;
  final VoidCallback onLoadTrack;
  final VoidCallback onOpenProDialog;

  const _RecordSleeveCard({
    required this.track,
    required this.isActive,
    required this.isLocked,
    required this.isDark,
    required this.borderColor,
    required this.chassisTextColor,
    required this.chassisMutedTextColor,
    required this.onLoadTrack,
    required this.onOpenProDialog,
  });

  void _handleTap() {
    if (isActive) {
      return;
    }
    if (isLocked) {
      onOpenProDialog();
    } else {
      onLoadTrack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('record_sleeve_${track.index}'),
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isActive ? TaktColors.filamentAmber : borderColor,
            width: isActive ? 1.5 : 1.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              track.labelColor.withValues(alpha: isDark ? 0.16 : 0.08),
              isDark ? const Color(0xFF191B1F) : const Color(0xFFE4E1DA),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: Catalog ID badge & Tier indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Text(
                    track.catalogId,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: chassisTextColor,
                    ),
                  ),
                ),
                if (track.isPremium)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TaktColors.filamentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: TaktColors.filamentAmber,
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 10,
                          color: TaktColors.filamentAmber,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'STUDIO PRO',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: TaktColors.filamentAmber,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    '33 RPM // HI-FI',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: chassisMutedTextColor,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Peeking Miniature Vinyl Disc Display
            Center(
              child: SizedBox(
                width: 82,
                height: 82,
                child: CustomPaint(
                  painter: _MiniVinylDiscPainter(
                    labelColor: track.labelColor,
                    isActive: isActive,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Track metadata
            Text(
              track.name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: chassisTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              track.subtitle,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: chassisMutedTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                track.description,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  height: 1.35,
                  color: chassisMutedTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 6),

            // Status Action Button
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (isActive) {
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: TaktColors.filamentAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: TaktColors.filamentAmber,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          '[ ON PLATTER ]',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: TaktColors.filamentAmber,
          ),
        ),
      );
    }

    if (isLocked) {
      return InkWell(
        key: ValueKey('locked_track_button_${track.index}'),
        onTap: onOpenProDialog,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF262320)
                : const Color(0xFFEBE3D8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: TaktColors.filamentAmber.withValues(alpha: 0.8),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            '[ LOCKED // STUDIO PRO 🔒 ]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: TaktColors.filamentAmber,
            ),
          ),
        ),
      );
    }

    return InkWell(
      key: ValueKey('load_track_button_${track.index}'),
      onTap: onLoadTrack,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2B2E34)
              : const Color(0xFFD6D3CB),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '[ LOAD ON PLATTER ]',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: chassisTextColor,
          ),
        ),
      ),
    );
  }
}

/// Custom painter that renders a miniature 12-inch vinyl disc with concentric
/// micro-grooves, specular sheen reflection, and center label disc.
class _MiniVinylDiscPainter extends CustomPainter {
  final Color labelColor;
  final bool isActive;

  const _MiniVinylDiscPainter({
    required this.labelColor,
    this.isActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer vinyl body
    final vinylPaint = Paint()
      ..color = const Color(0xFF141517)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, vinylPaint);

    // Rim highlight
    final rimPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 0.5, rimPaint);

    // Concentric micro-grooves
    final groovePaint = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    final grooveRadii = [
      radius * 0.88,
      radius * 0.80,
      radius * 0.72,
      radius * 0.64,
      radius * 0.56,
      radius * 0.48,
    ];
    for (final r in grooveRadii) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Specular sheen / reflection
    final sheenPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center - Offset(radius * 0.28, radius * 0.28),
          radius: radius,
        ),
      );
    canvas.drawCircle(center, radius, sheenPaint);

    // Center record label
    final labelRadius = radius * 0.38;
    final labelPaint = Paint()
      ..color = labelColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, labelRadius, labelPaint);

    // Center label outer border
    final labelBorderPaint = Paint()
      ..color = const Color(0x44000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, labelRadius, labelBorderPaint);

    // Active track subtle illuminated label halo
    if (isActive) {
      final activeHalo = Paint()
        ..color = const Color(0xFFE89A3C).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, labelRadius + 0.75, activeHalo);
    }

    // Center spindle hole
    final spindleRadius = radius * 0.09;
    final spindlePaint = Paint()
      ..color = const Color(0xFF141517)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, spindleRadius, spindlePaint);

    // Spindle ring
    final spindleRing = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, spindleRadius, spindleRing);
  }

  @override
  bool shouldRepaint(covariant _MiniVinylDiscPainter oldDelegate) {
    return oldDelegate.labelColor != labelColor ||
        oldDelegate.isActive != isActive;
  }
}
