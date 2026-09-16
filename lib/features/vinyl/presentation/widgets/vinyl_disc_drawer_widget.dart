import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/sound_effect.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../../../settings/presentation/widgets/studio_pro_dialog.dart';
import '../../domain/vinyl_track.dart';
import '../vinyl_controller.dart';

/// Industrial Slide-Out Dual Disc Drawer attached to the bottom of the BRAUN TP-1 Turntable.
///
/// Features two vertically stacked modular chassis bays:
/// - Drawer 01 (Nature presets, tracks 0..5)
/// - Drawer 02 (Harmonics presets, tracks 6..11)
///
/// Each drawer maintains independent expansion state, smooth animated transitions,
/// tactile foley feedback, and a dedicated 6-disc carousel.
class VinylDiscDrawerWidget extends ConsumerStatefulWidget {
  const VinylDiscDrawerWidget({super.key});

  @override
  ConsumerState<VinylDiscDrawerWidget> createState() => _VinylDiscDrawerWidgetState();
}

class _VinylDiscDrawerWidgetState extends ConsumerState<VinylDiscDrawerWidget> {
  late final PageController _pageController1;
  late final PageController _pageController2;
  int _currentPage1 = 0;
  int _currentPage2 = 0;
  bool _isDrawer1Open = false;
  bool _isDrawer2Open = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(vinylProvider).selectedTrackIndex;
    if (initialIndex < 6) {
      _currentPage1 = initialIndex;
      _currentPage2 = 0;
    } else {
      _currentPage1 = 0;
      _currentPage2 = (initialIndex - 6).clamp(0, 5);
    }

    _pageController1 = PageController(
      initialPage: _currentPage1,
      viewportFraction: 0.86,
    );
    _pageController2 = PageController(
      initialPage: _currentPage2,
      viewportFraction: 0.86,
    );
  }

  @override
  void dispose() {
    _pageController1.dispose();
    _pageController2.dispose();
    super.dispose();
  }

  void _goToPage1(int page) {
    if (page < 0 || page >= VinylTrack.drawer1Presets.length) return;
    _pageController1.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPage2(int page) {
    if (page < 0 || page >= VinylTrack.drawer2Presets.length) return;
    _pageController2.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleDrawer(int drawerNumber) {
    HapticService.selectionClick();
    final bool nextOpen;
    if (drawerNumber == 1) {
      nextOpen = !_isDrawer1Open;
      setState(() {
        _isDrawer1Open = nextOpen;
      });
    } else {
      nextOpen = !_isDrawer2Open;
      setState(() {
        _isDrawer2Open = nextOpen;
      });
    }

    ref.read(audioServiceProvider).playFoley(
      nextOpen ? SoundEffect.drawerSlide : SoundEffect.drawerLatch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vinylState = ref.watch(vinylProvider);
    final vinylController = ref.read(vinylProvider.notifier);
    final themeState = ref.watch(chassisThemeProvider);
    final isProSimulated =
        ref.watch(deskPreferencesControllerProvider).isProSimulated;

    return Column(
      key: const ValueKey('vinyl_disc_drawer_container'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drawer 01: Nature soundscapes (Tracks 0..5)
        _buildDrawerChassis(
          drawerNumber: 1,
          title: '01',
          category: 'NATURE',
          isOpen: _isDrawer1Open,
          tracks: VinylTrack.drawer1Presets,
          pageController: _pageController1,
          currentPage: _currentPage1,
          onPrev:
              _currentPage1 > 0 ? () => _goToPage1(_currentPage1 - 1) : null,
          onNext: _currentPage1 < VinylTrack.drawer1Presets.length - 1
              ? () => _goToPage1(_currentPage1 + 1)
              : null,
          onPageChanged: (idx) {
            setState(() {
              _currentPage1 = idx;
            });
          },
          themeState: themeState,
          vinylState: vinylState,
          vinylController: vinylController,
          isProSimulated: isProSimulated,
        ),
        const SizedBox(height: 6),
        // Drawer 02: Harmonics soundscapes (Tracks 6..11)
        _buildDrawerChassis(
          drawerNumber: 2,
          title: '02',
          category: 'HARMONICS',
          isOpen: _isDrawer2Open,
          tracks: VinylTrack.drawer2Presets,
          pageController: _pageController2,
          currentPage: _currentPage2,
          onPrev:
              _currentPage2 > 0 ? () => _goToPage2(_currentPage2 - 1) : null,
          onNext: _currentPage2 < VinylTrack.drawer2Presets.length - 1
              ? () => _goToPage2(_currentPage2 + 1)
              : null,
          onPageChanged: (idx) {
            setState(() {
              _currentPage2 = idx;
            });
          },
          themeState: themeState,
          vinylState: vinylState,
          vinylController: vinylController,
          isProSimulated: isProSimulated,
        ),
      ],
    );
  }

  Widget _buildDrawerChassis({
    required int drawerNumber,
    required String title,
    required String category,
    required bool isOpen,
    required List<VinylTrack> tracks,
    required PageController pageController,
    required int currentPage,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
    required ValueChanged<int> onPageChanged,
    required dynamic themeState,
    required dynamic vinylState,
    required VinylController vinylController,
    required bool isProSimulated,
  }) {
    final totalTracks = tracks.length;

    return Container(
      margin: EdgeInsets.only(top: drawerNumber == 1 ? 8 : 0),
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
            label: 'Toggle record crate drawer $drawerNumber',
            child: InkWell(
              key: ValueKey('vinyl_drawer_${drawerNumber}_handle'),
              onTap: () => _toggleDrawer(drawerNumber),
              borderRadius: BorderRadius.circular(6),
              child: Container(
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
                      key: ValueKey('vinyl_drawer_${drawerNumber}_rivet_left'),
                      rivetColor: themeState.rivetColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: themeState.isDarkMode
                                ? themeState.filamentColor
                                    .withValues(alpha: 0.15)
                                : themeState.canvasColor,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: themeState.isDarkMode
                                  ? themeState.filamentColor
                                      .withValues(alpha: 0.7)
                                  : themeState.borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '[ RECORD DRAWER $title // ${totalTracks.toString().padLeft(2, '0')} DISCS · $category ${isOpen ? '▲' : '▾'} ]',
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
                      key: ValueKey('vinyl_drawer_${drawerNumber}_rivet_right'),
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
                    key: ValueKey('vinyl_drawer_${drawerNumber}_interior_bay'),
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
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'ARCHIVE $title',
                                style: TaktTypography.controlLabel.copyWith(
                                  fontSize: 7.5,
                                  color: themeState.chassisMutedTextColor,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '[ ${(currentPage + 1).toString().padLeft(2, '0')} / 06 ]',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: themeState.chassisMutedTextColor,
                                ),
                              ),
                              const SizedBox(width: 2),
                              InkWell(
                                key: ValueKey(
                                    'drawer_${drawerNumber}_prev_disc'),
                                onTap: onPrev,
                                borderRadius: BorderRadius.circular(3),
                                child: Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: 15,
                                    color: onPrev != null
                                        ? themeState.chassisTextColor
                                        : themeState.chassisMutedTextColor
                                            .withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              InkWell(
                                key: ValueKey(
                                    'drawer_${drawerNumber}_next_disc'),
                                onTap: onNext,
                                borderRadius: BorderRadius.circular(3),
                                child: Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 15,
                                    color: onNext != null
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
                            controller: pageController,
                            itemCount: totalTracks,
                            onPageChanged: onPageChanged,
                            itemBuilder: (context, index) {
                              final track = tracks[index];
                              final isSelected =
                                  vinylState.selectedTrackIndex == track.index;
                              final isUnlocked =
                                  !track.isPremium || isProSimulated;

                              return _CompactRecordSleeveCard(
                                key: ValueKey('record_sleeve_${track.index}'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
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
