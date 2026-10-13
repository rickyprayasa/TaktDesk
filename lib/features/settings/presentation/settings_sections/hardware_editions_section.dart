part of '../takt_settings_sheet.dart';

// Hardware edition carousel, edition cards and their swatch/rivet details.

class _HardwareEditionsSection extends ConsumerStatefulWidget {
  final DeskPreferencesState prefs;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color panelBgColor;
  final Color borderColor;

  const _HardwareEditionsSection({
    required this.prefs,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.panelBgColor,
    required this.borderColor,
  });

  @override
  ConsumerState<_HardwareEditionsSection> createState() =>
      _HardwareEditionsSectionState();
}

class _HardwareEditionsSectionState
    extends ConsumerState<_HardwareEditionsSection> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    final initialIndex = HardwareEdition.all.indexWhere(
      (e) => e.type.name == widget.prefs.selectedEdition,
    );
    _currentPage = initialIndex >= 0 ? initialIndex : 0;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.82,
    );
  }

  @override
  void didUpdateWidget(covariant _HardwareEditionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prefs.selectedEdition != widget.prefs.selectedEdition) {
      final newIndex = HardwareEdition.all.indexWhere(
        (e) => e.type.name == widget.prefs.selectedEdition,
      );
      if (newIndex >= 0 &&
          newIndex != _currentPage &&
          _pageController.hasClients) {
        turnToPage(context, _pageController, newIndex,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrev() {
    if (!_pageController.hasClients || _currentPage <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticService.selectionClick();
  }

  void _goToNext() {
    if (!_pageController.hasClients || _currentPage >= HardwareEdition.all.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticService.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(chassisThemeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header with title, counter badge, and arrow buttons
        Row(
          children: [
            Flexible(
              flex: 4,
              child: Text(
                'HARDWARE EDITIONS // CHASSIS MATERIALITY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: widget.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Container(
                height: 1.0,
                color: widget.secondaryTextColor.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '[ ${(_currentPage + 1).toString().padLeft(2, '0')} / ${HardwareEdition.all.length.toString().padLeft(2, '0')} ]',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: widget.secondaryTextColor,
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              label: 'Previous hardware edition',
              button: true,
              enabled: _currentPage > 0,
              child: InkWell(
                key: const ValueKey('edition_prev_button'),
                borderRadius: BorderRadius.circular(3.0),
                onTap: _currentPage > 0 ? _goToPrev : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '◀',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: _currentPage > 0
                          ? widget.primaryTextColor
                          : widget.secondaryTextColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Semantics(
              label: 'Next hardware edition',
              button: true,
              enabled: _currentPage < HardwareEdition.all.length - 1,
              child: InkWell(
                key: const ValueKey('edition_next_button'),
                borderRadius: BorderRadius.circular(3.0),
                onTap: _currentPage < HardwareEdition.all.length - 1 ? _goToNext : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '▶',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: _currentPage < HardwareEdition.all.length - 1
                          ? widget.primaryTextColor
                          : widget.secondaryTextColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.panelBgColor,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: widget.borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Snapping Carousel of 4 HardwareEdition cards
              SizedBox(
                height: 152,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: HardwareEdition.all.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, i) {
                    final ed = HardwareEdition.all[i];
                    final isSel =
                        widget.prefs.selectedEdition == ed.type.name;
                    final isUnl =
                        !ed.isPremium || widget.prefs.isProSimulated;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: _EditionCard(
                        edition: ed,
                        isSelected: isSel,
                        isUnlocked: isUnl,
                        isDark: widget.isDark,
                        onTap: () {
                          if (!isUnl) {
                            _showStudioProDialog(
                              context,
                              ref,
                              ed,
                              isDark: widget.isDark,
                              primaryTextColor: widget.primaryTextColor,
                              secondaryTextColor: widget.secondaryTextColor,
                            );
                          } else if (!isSel) {
                            ref
                                .read(
                                    deskPreferencesControllerProvider.notifier)
                                .setHardwareEdition(ed.type);
                            HapticService.selectionClick();
                          } else {
                            HapticService.selectionClick();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < HardwareEdition.all.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Container(
                      key: ValueKey('edition_dot_$i'),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == i
                            ? themeState.filamentColor
                            : widget.borderColor.withValues(alpha: 0.5),
                        boxShadow: _currentPage == i
                            ? [
                                BoxShadow(
                                  color: themeState.filamentColor
                                      .withValues(alpha: 0.6),
                                  blurRadius: 3.0,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
              if (AppSecurityConfig.showDeveloperTools) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: widget.borderColor),
                const SizedBox(height: 12),
                // SIMULATE STUDIO PRO CLEARANCE switch row (Developer/Internal Test only)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SIMULATE STUDIO PRO CLEARANCE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: widget.primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Developer preview override for all hardware finishes',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.0,
                              color: widget.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      key: const ValueKey('simulate_pro_switch'),
                      value: widget.prefs.isProSimulated,
                      activeThumbColor: TaktColors.filamentAmber,
                      activeTrackColor:
                          TaktColors.filamentAmber.withValues(alpha: 0.5),
                      inactiveThumbColor: widget.isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                      inactiveTrackColor: widget.isDark
                          ? TaktColors.slateLight
                          : TaktColors.paperBorder,
                      onChanged: (val) {
                        ref
                            .read(deskPreferencesControllerProvider.notifier)
                            .setProSimulated(val);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


class _EditionCard extends StatelessWidget {
  final HardwareEdition edition;
  final bool isSelected;
  final bool isUnlocked;
  final bool isDark;
  final VoidCallback onTap;

  const _EditionCard({
    required this.edition,
    required this.isSelected,
    required this.isUnlocked,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rivetColor = isDark ? edition.rivetDark : edition.rivetLight;
    final borderColor = isSelected
        ? TaktColors.filamentAmber
        : (isDark ? edition.darkBorder : edition.lightBorder);
    final titleColor = isDark ? TaktColors.warmBone : const Color(0xFF141618);
    final subtitleColor =
        isDark ? const Color(0xFF9E9B93) : const Color(0xFF2D3139);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('edition_card_${edition.type.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.4 : 1.0,
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? edition.plateGradientDark
                  : edition.plateGradientLight,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // 4 Corner Rivets (4x4 circular containers)
              Positioned(
                top: 5,
                left: 5,
                child: _RivetDot(color: rivetColor),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: _RivetDot(color: rivetColor),
              ),
              Positioned(
                bottom: 5,
                left: 5,
                child: _RivetDot(color: rivetColor),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: _RivetDot(color: rivetColor),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Tier badge & Swatch chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge: FREE or STUDIO PRO
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: edition.isPremium
                                  ? TaktColors.filamentAmber
                                      .withValues(alpha: 0.2)
                                  : (isDark
                                      ? TaktColors.warmBone
                                          .withValues(alpha: 0.15)
                                      : const Color(0xFF141618)
                                          .withValues(alpha: 0.08)),
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: edition.isPremium
                                    ? TaktColors.filamentAmber
                                    : (isDark
                                        ? TaktColors.warmBone
                                        : const Color(0xFF2D3139)),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              edition.isPremium ? 'STUDIO PRO' : 'FREE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: edition.isPremium
                                    ? TaktColors.amberText(isDark)
                                    : (isDark
                                        ? TaktColors.warmBone
                                        : const Color(0xFF141618)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Swatch chips
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SwatchDot(
                              color: edition.needleColor,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                            _SwatchDot(
                              color: edition.filamentColor,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                            _SwatchDot(
                              color: edition.accentColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Middle: Title, Year & Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edition.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${edition.yearLabel} · ${edition.subtitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),

                    // Bottom: Action indicator / button
                    _buildActionButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (isSelected) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: TaktColors.filamentAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3.0),
          border: Border.all(
            color: TaktColors.filamentAmber,
            width: 0.8,
          ),
        ),
        child: Text(
          'EQUIPPED',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: TaktColors.amberText(isDark),
          ),
        ),
      );
    }

    if (isUnlocked) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(3.0),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black26,
            width: 0.8,
          ),
        ),
        child: Text(
          'EQUIP',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? TaktColors.warmBone : const Color(0xFF141618),
          ),
        ),
      );
    }

    // Locked
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(
          color: TaktColors.mutedOchre.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 9, color: TaktColors.mutedOchre),
          SizedBox(width: 4),
          Text(
            'LOCKED // PREVIEW 👁',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: TaktColors.mutedOchre,
            ),
          ),
        ],
      ),
    );
  }
}

class _RivetDot extends StatelessWidget {
  final Color color;

  const _RivetDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  final Color color;
  final bool isDark;

  const _SwatchDot({
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black26,
          width: 0.5,
        ),
      ),
    );
  }
}
