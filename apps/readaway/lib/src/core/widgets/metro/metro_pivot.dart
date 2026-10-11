import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'metro_pressable.dart';
import 'metro_typography.dart';

/// Controller for coordinating panoramic [MetroPivot] headers and swipeable body pages,
/// analogous to [TabController] for [TabBar] and [TabBarView].
class MetroPivotController extends ChangeNotifier {
  MetroPivotController({
    required this.length,
    int initialIndex = 0,
  }) : assert(length > 0),
       assert(initialIndex >= 0 && initialIndex < length),
       _index = initialIndex,
       _page = initialIndex.toDouble();

  /// Total number of pivot sections.
  final int length;

  int _index;
  int? _previousIndex;
  double _page;

  PageController? _attachedPageController;
  bool _isDisposed = false;

  bool _indexIsChanging = false;

  /// True while an animated programmatic transition (e.g. [animateTo]) is in progress.
  bool get indexIsChanging => _indexIsChanging;

  /// The currently active section index.
  int get index => _index;

  /// The previously active section index, or `null` if none.
  int? get previousIndex => _previousIndex;

  /// The continuous floating-point page offset (e.g. 1.5 halfway between page 1 and 2),
  /// updated on every frame during user drag gestures.
  double get page => _page;

  /// Attaches the internal [PageController] for 1:1 bi-directional sync.
  void attachPageController(PageController pageController) {
    if (_attachedPageController == pageController) return;
    _attachedPageController = pageController;
  }

  /// Detaches the currently attached [PageController].
  void detachPageController() {
    _attachedPageController = null;
  }

  /// Updates the continuous page fraction during body swipe gestures.
  void updatePage(double newPage) {
    if (_isDisposed) return;
    if (_page == newPage) return;
    _page = newPage.clamp(0.0, (length - 1).toDouble());

    if (!_indexIsChanging) {
      final roundedIndex = _page.round().clamp(0, length - 1);
      if (roundedIndex != _index) {
        _previousIndex = _index;
        _index = roundedIndex;
      }
    }
    notifyListeners();
  }

  /// Sets the active index programmatically with smooth Lumia-inspired deceleration.
  void animateTo(
    int targetIndex, {
    Duration duration = const Duration(milliseconds: 320),
    Curve? curve,
  }) {
    if (_isDisposed) return;
    assert(targetIndex >= 0 && targetIndex < length);
    if (targetIndex == _index) return;

    final effectiveCurve = curve ?? Curves.easeOutCubic;

    _previousIndex = _index;
    _index = targetIndex;
    _indexIsChanging = true;

    if (_attachedPageController != null &&
        _attachedPageController!.hasClients) {
      // Let _page update continuously frame-by-frame via PageController ticks
      // without premature frame 0 snapping or intermediate teleportation.
      notifyListeners();

      _attachedPageController!
          .animateToPage(
            targetIndex,
            duration: duration,
            curve: effectiveCurve,
          )
          .then((_) {
            if (!_isDisposed) {
              _indexIsChanging = false;
              _page = _index.toDouble();
              notifyListeners();
            }
          });
    } else {
      _page = targetIndex.toDouble();
      _indexIsChanging = false;
      notifyListeners();
    }
  }

  /// Instantly jumps to the target index without animation.
  void jumpTo(int targetIndex) {
    if (_isDisposed) return;
    assert(targetIndex >= 0 && targetIndex < length);
    if (targetIndex == _index) return;

    _previousIndex = _index;
    _index = targetIndex;
    _page = targetIndex.toDouble();
    _indexIsChanging = false;
    notifyListeners();

    if (_attachedPageController != null &&
        _attachedPageController!.hasClients) {
      _attachedPageController!.jumpToPage(targetIndex);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _attachedPageController = null;
    super.dispose();
  }
}

/// Represents a single panoramic section in a [MetroPivot].
class MetroPivotItem {
  const MetroPivotItem({
    required this.label,
    required this.content,
    this.count,
    this.icon,
  });

  /// Section label (e.g. "all books", "reading", "favorites").
  final String label;

  /// The child content rendered when this section is active.
  final Widget content;

  /// Optional counter badge (e.g. "12").
  final String? count;

  /// Optional icon.
  final IconData? icon;
}

/// Authentic Lumia Inspired Panoramic Pivot Navigation Hub.
///
/// Production Features:
/// - True bi-directional gesture synchronization via [MetroPivotController]
///   (analogous to Flutter's [TabController] + [TabBar] + [TabBarView]).
/// - Continuous real-time header glide and typographic interpolation during body swipe gestures.
/// - Fluid spring physics powered by `package:motor` (`Motion.snappySpring`, `Motion.smoothSpring`).
/// - Horizon-stretching bleed with unconstrained horizontal expansion.
/// - GPU keep-alive page caching to eliminate scroll hitching and re-render spikes.
class MetroPivot extends StatefulWidget {
  const MetroPivot({
    super.key,
    required this.title,
    required this.items,
    this.controller,
    this.currentIndex,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.trailing,
    this.headerPadding = const EdgeInsets.fromLTRB(20, 16, 20, 10),
  });

  /// The grand display title of the panorama (e.g. "library").
  final String title;

  /// List of pivot categories and their respective contents.
  final List<MetroPivotItem> items;

  /// Optional external [MetroPivotController] to programmatically control or listen
  /// to pivot changes, synchronizing gestures across body and other controls.
  final MetroPivotController? controller;

  /// Declarative active index for controlled usage. If provided, updates
  /// automatically when the parent state changes.
  final int? currentIndex;

  /// Starting active index when an external controller is not supplied.
  final int initialIndex;

  /// Callback invoked when the active pane changes.
  final ValueChanged<int>? onIndexChanged;

  /// Optional trailing widget in the top title row (e.g. search or settings).
  final Widget? trailing;

  /// Outer padding for the panoramic headers.
  final EdgeInsetsGeometry headerPadding;

  @override
  State<MetroPivot> createState() => _MetroPivotState();
}

class _MetroPivotState extends State<MetroPivot> {
  MetroPivotController? _internalController;
  MetroPivotController get _effectiveController =>
      widget.controller ?? _internalController!;

  late final PageController _pageController;

  // Track tab positions to ensure exact continuous parallax alignment during drags
  final List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _initTabKeys();

    final startIndex =
        widget.currentIndex ?? widget.controller?.index ?? widget.initialIndex;

    if (widget.controller == null) {
      _internalController = MetroPivotController(
        length: widget.items.length,
        initialIndex: startIndex,
      );
    }

    _pageController = PageController(initialPage: startIndex);

    _effectiveController.attachPageController(_pageController);
    _effectiveController.addListener(_handleControllerTick);
    _pageController.addListener(_handlePageScrollTick);
  }

  void _initTabKeys() {
    _tabKeys.clear();
    for (int i = 0; i < widget.items.length; i++) {
      _tabKeys.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(MetroPivot oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length) {
      _initTabKeys();
      _tabWidths.clear();
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detachPageController();
      oldWidget.controller?.removeListener(_handleControllerTick);

      if (widget.controller == null) {
        _internalController = MetroPivotController(
          length: widget.items.length,
          initialIndex: _pageController.hasClients
              ? (_pageController.page?.round() ?? 0)
              : widget.initialIndex,
        );
      } else {
        _internalController?.dispose();
        _internalController = null;
      }

      _effectiveController.attachPageController(_pageController);
      _effectiveController.addListener(_handleControllerTick);
    }

    // Handle controlled index change from parent
    if (widget.currentIndex != null &&
        widget.currentIndex != oldWidget.currentIndex &&
        widget.currentIndex != _effectiveController.index) {
      _effectiveController.animateTo(widget.currentIndex!);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScrollTick);
    _effectiveController.removeListener(_handleControllerTick);
    _effectiveController.detachPageController();

    _internalController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  static const double _kTabGap = 28.0;
  static const double _kLeadingPadding = 20.0;
  static const TextStyle _kTabTextStyle = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
  );

  final Map<int, double> _tabWidths = {};

  double _getTabWidth(int index, BuildContext context) {
    if (_tabWidths.containsKey(index)) {
      return _tabWidths[index]!;
    }
    final item = widget.items[index];
    final textPainter = TextPainter(
      text: TextSpan(
        text: item.label.toLowerCase(),
        style: _kTabTextStyle,
      ),
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    )..layout();

    double width = textPainter.width;
    if (item.count != null) {
      final countPainter = TextPainter(
        text: TextSpan(
          text: item.count!,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      )..layout();
      width += 8.0 + 12.0 + countPainter.width;
    }
    _tabWidths[index] = width;
    return width;
  }

  void _handlePageScrollTick() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;

    _effectiveController.updatePage(page);
  }

  void _handleControllerTick() {
    if (!mounted) return;
    setState(() {});
    widget.onIndexChanged?.call(_effectiveController.index);
  }

  void _onTabTapped(int index) {
    _effectiveController.animateTo(index);
  }

  double _accumulatedHorizontalDelta = 0.0;
  DateTime _lastScrollEventTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const double _kHorizontalScrollThreshold = 30.0;

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Only register interest when horizontal delta dominates vertical motion
      if (event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()) {
        GestureBinding.instance.pointerSignalResolver.register(event, (event) {
          if (event is! PointerScrollEvent) return;

          final now = DateTime.now();
          // Reset accumulated delta if idle for > 300ms
          if (now.difference(_lastScrollEventTime).inMilliseconds > 300) {
            _accumulatedHorizontalDelta = 0.0;
          }
          _lastScrollEventTime = now;

          if (_effectiveController.indexIsChanging) return;

          _accumulatedHorizontalDelta += event.scrollDelta.dx;

          if (_accumulatedHorizontalDelta >= _kHorizontalScrollThreshold) {
            _accumulatedHorizontalDelta = 0.0;
            if (_effectiveController.index < widget.items.length - 1) {
              _effectiveController.animateTo(_effectiveController.index + 1);
            }
          } else if (_accumulatedHorizontalDelta <=
              -_kHorizontalScrollThreshold) {
            _accumulatedHorizontalDelta = 0.0;
            if (_effectiveController.index > 0) {
              _effectiveController.animateTo(_effectiveController.index - 1);
            }
          }
        });
      } else {
        // Vertical scroll dominates; clear accumulated horizontal delta
        _accumulatedHorizontalDelta = 0.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final controller = _effectiveController;
    final currentPage = controller.page;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Panoramic Horizon Title Row
        Padding(
          padding: widget.headerPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: MetroText.pivotTitle(
                  widget.title.toLowerCase(),
                  color: appColors.readerForeground,
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),

        // 2. Horizon-Bleeding Tab Bar with Continuous Metro Carousel Physics
        _buildCarouselTabs(context, appColors, currentPage),

        const SizedBox(height: 12),

        // 3. 1:1 Swipeable Content Pages with AutomaticKeepAlive & Desktop Gesture Support
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
                PointerDeviceKind.invertedStylus,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                if (controller.index != index) {
                  controller.updatePage(index.toDouble());
                }
              },
              itemBuilder: (context, index) {
                return _KeepAlivePage(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerSignal: _handlePointerSignal,
                    child: widget.items[index].content,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselTabs(
    BuildContext context,
    AppColors appColors,
    double currentPage,
  ) {
    final itemCount = widget.items.length;
    if (itemCount == 0) return const SizedBox(height: 56);
    if (itemCount == 1) {
      return SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kLeadingPadding),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildTabItem(
              context,
              widget.items[0],
              0,
              1.0,
              1.0,
              appColors,
            ),
          ),
        ),
      );
    }

    final baseIndex = currentPage.floor().clamp(0, itemCount - 1);
    final fraction = (currentPage - baseIndex).clamp(0.0, 1.0);

    // Compute cyclic display order starting from baseIndex:
    // e.g. for 3 items with base 1: [1, 2, 0]
    final displayIndices = <int>[];
    for (int i = 0; i < itemCount; i++) {
      displayIndices.add((baseIndex + i) % itemCount);
    }

    final bool isAnimating = fraction > 0.0001 && fraction < 0.9999;
    if (isAnimating) {
      // Add trailing wrap-around clone of baseIndex at the end of the carousel
      displayIndices.add(baseIndex);
    }

    final leadingWidth = _getTabWidth(baseIndex, context);
    final shift = fraction * (leadingWidth + _kTabGap);

    return SizedBox(
      height: 56,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0.0;
          if (velocity < -200) {
            if (_effectiveController.index < widget.items.length - 1) {
              _effectiveController.animateTo(_effectiveController.index + 1);
            }
          } else if (velocity > 200) {
            if (_effectiveController.index > 0) {
              _effectiveController.animateTo(_effectiveController.index - 1);
            }
          }
        },
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0.0,
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(_kLeadingPadding - shift, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (int i = 0; i < displayIndices.length; i++) ...[
                    if (i > 0) const SizedBox(width: _kTabGap),
                    _buildCarouselItemSlot(
                      context,
                      displayIndices[i],
                      i,
                      displayIndices.length,
                      fraction,
                      isAnimating,
                      appColors,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselItemSlot(
    BuildContext context,
    int originalIndex,
    int slotIndex,
    int totalSlots,
    double fraction,
    bool isAnimating,
    AppColors appColors,
  ) {
    final item = widget.items[originalIndex];

    double t;
    double opacity = 1.0;

    if (!isAnimating) {
      // At rest: slot 0 is the leading active item (t = 1.0), all other slots are inactive (t = 0.0)
      t = slotIndex == 0 ? 1.0 : 0.0;
      opacity = 1.0;
    } else {
      if (slotIndex == 0) {
        // Exiting item being pushed out to the left
        t = (1.0 - fraction).clamp(0.0, 1.0);
        opacity = (1.0 - fraction * 1.5).clamp(0.0, 1.0);
      } else if (slotIndex == 1) {
        // Entering item sliding into the leading position
        t = fraction.clamp(0.0, 1.0);
        opacity = 1.0;
      } else if (slotIndex == totalSlots - 1) {
        // Trailing wrap-around clone of the exiting item entering from the right
        t = 0.0;
        opacity = fraction.clamp(0.0, 1.0);
      } else {
        // Other items in between
        t = 0.0;
        opacity = 1.0;
      }
    }

    // Attach GlobalKey to the primary instance only (never to trailing clone)
    final Key? key =
        (slotIndex < widget.items.length && originalIndex < _tabKeys.length)
        ? _tabKeys[originalIndex]
        : null;

    return Opacity(
      opacity: opacity,
      child: _buildTabItem(
        context,
        item,
        originalIndex,
        t,
        opacity,
        appColors,
        key: key,
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    MetroPivotItem item,
    int originalIndex,
    double t,
    double opacity,
    AppColors appColors, {
    Key? key,
  }) {
    final activeColor = appColors.buttonBackground;
    final inactiveColor = appColors.readerForeground.withValues(alpha: 0.40);

    final style = _kTabTextStyle.copyWith(
      color: Color.lerp(inactiveColor, activeColor, t),
    );

    final badgeBg = Color.lerp(
      appColors.readerForeground.withValues(alpha: 0.15),
      appColors.buttonBackground,
      t,
    );
    final badgeFg = Color.lerp(
      appColors.readerForeground.withValues(alpha: 0.60),
      appColors.buttonForeground,
      t,
    );

    return MetroPressable(
      key: key,
      onTap: () => _onTabTapped(originalIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label.toLowerCase(),
              style: style,
            ),
            if (item.count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                color: badgeBg,
                child: Text(
                  item.count!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Keeps pivot page contents alive in GPU memory to eliminate re-layout and image loading jank.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
