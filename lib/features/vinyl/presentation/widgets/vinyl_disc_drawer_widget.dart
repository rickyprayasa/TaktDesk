import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../../../settings/presentation/widgets/studio_pro_dialog.dart';
import '../../domain/vinyl_track.dart';
import '../vinyl_controller.dart';

/// Industrial Slide-Out Disc Drawer attached to the bottom of the BRAUN TP-1 Turntable.
class VinylDiscDrawerWidget extends ConsumerStatefulWidget {
  const VinylDiscDrawerWidget({super.key});

  @override
  ConsumerState<VinylDiscDrawerWidget> createState() => _VinylDiscDrawerWidgetState();
}

class _VinylDiscDrawerWidgetState extends ConsumerState<VinylDiscDrawerWidget> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(vinylProvider).selectedTrackIndex;
    _currentPage = initialIndex;
    _pageController = PageController(
      initialPage: initialIndex,
      viewportFraction: 0.86,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= VinylTrack.presets.length) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vinylState = ref.watch(vinylProvider);
    final vinylController = ref.read(vinylProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);
    final isOpen = vinylState.isDrawerOpen;
    final totalTracks = VinylTrack.presets.length;

    return Container(
      key: const ValueKey('vinyl_disc_drawer_container'),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: themeState.isDarkMode
            ? const Color(0xFF1B1E22)
            : themeState.moduleChassisColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOpen
              ? themeState.filamentColor.withValues(alpha: 0.6)
              : themeState.borderColor,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Brushed Metal Handle Bar
          Semantics(
            button: true,
            label: 'Toggle record crate drawer',
            child: InkWell(
              onTap: vinylController.toggleDrawer,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                key: const ValueKey('vinyl_drawer_handle_bar'),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    colors: themeState.plateGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    _buildRivet(
                      key: const ValueKey('vinyl_drawer_rivet_left'),
                      rivetColor: themeState.rivetColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Center(
                        child: Container(
                          key: const ValueKey('vinyl_drawer_handle_plate'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: themeState.isDarkMode
                                ? themeState.filamentColor.withValues(alpha: 0.15)
                                : themeState.canvasColor,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: themeState.isDarkMode
                                  ? themeState.filamentColor.withValues(alpha: 0.7)
                                  : themeState.borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '[ RECORD DRAWER // ${totalTracks.toString().padLeft(2, '0')} DISCS ${isOpen ? '▲' : '▾'} ]',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: themeState.isDarkMode
                                    ? themeState.filamentColor
                                    : themeState.chassisTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildRivet(
                      key: const ValueKey('vinyl_drawer_rivet_right'),
                      rivetColor: themeState.rivetColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Expandable Sliding Interior Bay
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: isOpen
                ? Container(
                    key: const ValueKey('vinyl_drawer_interior_bay'),
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: themeState.borderColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        right: BorderSide(
                          color: themeState.borderColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Micro navigation strip with counter and arrow buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'ARCHIVE',
                                style: TaktTypography.controlLabel.copyWith(
                                  fontSize: 8.0,
                                  color: themeState.chassisMutedTextColor,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '[ ${(_currentPage + 1).toString().padLeft(2, '0')} / ${totalTracks.toString().padLeft(2, '0')} ]',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: themeState.chassisMutedTextColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                key: const ValueKey('drawer_prev_disc'),
                                onTap: _currentPage > 0
                                    ? () => _goToPage(_currentPage - 1)
                                    : null,
                                borderRadius: BorderRadius.circular(3),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: 16,
                                    color: _currentPage > 0
                                        ? themeState.chassisTextColor
                                        : themeState.chassisMutedTextColor
                                            .withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              InkWell(
                                key: const ValueKey('drawer_next_disc'),
                                onTap: _currentPage < totalTracks - 1
                                    ? () => _goToPage(_currentPage + 1)
                                    : null,
                                borderRadius: BorderRadius.circular(3),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: _currentPage < totalTracks - 1
                                        ? themeState.chassisTextColor
                                        : themeState.chassisMutedTextColor
                                            .withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Horizontal Album Sleeves Carousel
                        SizedBox(
                          height: 140,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: totalTracks,
                            onPageChanged: (idx) {
                              setState(() {
                                _currentPage = idx;
                              });
                            },
                            itemBuilder: (context, index) {
                              final track = VinylTrack.presets[index];
                              final isSelected =
                                  vinylState.selectedTrackIndex == index;
                              final isProSimulated = ref
                                  .watch(deskPreferencesControllerProvider)
                                  .isProSimulated;
                              final isUnlocked =
                                  !track.isPremium || isProSimulated;

                              return _CompactRecordSleeveCard(
                                key: ValueKey('record_sleeve_$index'),
                                track: track,
                                isSelected: isSelected,
                                isUnlocked: isUnlocked,
                                isDark: themeState.isDarkMode,
                                chassisColor: themeState.moduleChassisColor,
                                borderColor: themeState.borderColor,
                                chassisTextColor: themeState.chassisTextColor,
                                chassisMutedTextColor:
                                    themeState.chassisMutedTextColor,
                                onSelect: () {
                                  vinylController.selectTrack(
                                    track.index,
                                    isPro: isProSimulated,
                                  );
                                },
                                onUnlockTap: () {
                                  showStudioProDialog(
                                    context,
                                    ref,
                                    track: track,
                                    isDark: themeState.isDarkMode,
                                    primaryTextColor:
                                        themeState.chassisTextColor,
                                    secondaryTextColor:
                                        themeState.chassisMutedTextColor,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildRivet({required Key key, required Color rivetColor}) {
    return Container(
      key: key,
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: rivetColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _CompactRecordSleeveCard extends StatelessWidget {
  final VinylTrack track;
  final bool isSelected;
  final bool isUnlocked;
  final bool isDark;
  final Color chassisColor;
  final Color borderColor;
  final Color chassisTextColor;
  final Color chassisMutedTextColor;
  final VoidCallback onSelect;
  final VoidCallback onUnlockTap;

  const _CompactRecordSleeveCard({
    super.key,
    required this.track,
    required this.isSelected,
    required this.isUnlocked,
    required this.isDark,
    required this.chassisColor,
    required this.borderColor,
    required this.chassisTextColor,
    required this.chassisMutedTextColor,
    required this.onSelect,
    required this.onUnlockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(
                track.labelColor.withValues(alpha: 0.08),
                const Color(0xFF141619),
              )
            : Color.alphaBlend(
                track.labelColor.withValues(alpha: 0.06),
                const Color(0xFFF3F1ED),
              ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? TaktColors.filamentAmber.withValues(alpha: 0.8)
              : borderColor,
          width: isSelected ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Catalog ID & Tier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  track.catalogId,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: chassisTextColor,
                  ),
                ),
              ),
              Text(
                track.isPremium ? 'STUDIO PRO 🔒' : '33 RPM // HI-FI',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: track.isPremium
                      ? TaktColors.filamentAmber
                      : chassisMutedTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Center Row: Peeking Vinyl + Track Title & Subtitle
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _MiniDiscPainter(
                      labelColor: track.labelColor,
                      isActive: isSelected,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        track.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? TaktColors.filamentAmber
                              : chassisTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.subtitle,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: chassisMutedTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Bottom Action Button
          SizedBox(
            height: 26,
            child: _buildActionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (isSelected) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TaktColors.filamentAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: TaktColors.filamentAmber,
            width: 1.0,
          ),
        ),
        child: const Text(
          '[ ON PLATTER ]',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: TaktColors.filamentAmber,
          ),
        ),
      );
    }

    if (!isUnlocked) {
      return InkWell(
        key: ValueKey('locked_track_button_${track.index}'),
        onTap: onUnlockTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TaktColors.filamentAmber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: TaktColors.filamentAmber.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: const Text(
            '[ STUDIO PRO 🔒 ]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: TaktColors.filamentAmber,
            ),
          ),
        ),
      );
    }

    return InkWell(
      key: ValueKey('load_track_button_${track.index}'),
      onTap: onSelect,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: borderColor,
            width: 0.8,
          ),
        ),
        child: Text(
          '[ LOAD TO PLATTER ]',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: chassisTextColor,
          ),
        ),
      ),
    );
  }
}

class _MiniDiscPainter extends CustomPainter {
  final Color labelColor;
  final bool isActive;

  const _MiniDiscPainter({
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
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius - 0.5, rimPaint);

    // Concentric micro-grooves
    final groovePaint = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final grooveRadii = [
      radius * 0.86,
      radius * 0.76,
      radius * 0.66,
      radius * 0.56,
      radius * 0.46,
    ];
    for (final r in grooveRadii) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Specular sheen reflection
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
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, labelRadius, labelBorderPaint);

    // Active illuminated halo
    if (isActive) {
      final activeHalo = Paint()
        ..color = const Color(0xFFE89A3C).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(center, labelRadius + 0.6, activeHalo);
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
      ..strokeWidth = 0.6;
    canvas.drawCircle(center, spindleRadius, spindleRing);
  }

  @override
  bool shouldRepaint(covariant _MiniDiscPainter oldDelegate) {
    return oldDelegate.labelColor != labelColor ||
        oldDelegate.isActive != isActive;
  }
}
