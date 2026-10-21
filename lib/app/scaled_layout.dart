import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [child] out [scale] times smaller and paints it [scale] times bigger, so it takes [scale] times the space.
///
/// Unlike [Transform.scale], the enlarged size is real layout: centring, scrolling, hit testing and local gesture
/// positions (the dial's rotary pan) all see the scaled instrument. ZYKL draws its instruments as vectors, so a
/// tablet gets a bigger instrument rather than a phone-sized one floating in empty space.
class ScaledLayout extends SingleChildRenderObjectWidget {
  final double scale;

  const ScaledLayout({super.key, required this.scale, super.child}) : assert(scale > 0);

  @override
  RenderObject createRenderObject(BuildContext context) => RenderScaledLayout(scale);

  @override
  void updateRenderObject(BuildContext context, RenderScaledLayout renderObject) {
    renderObject.scale = scale;
  }
}

class RenderScaledLayout extends RenderProxyBox {
  RenderScaledLayout(this._scale);

  double _scale;
  double get scale => _scale;
  set scale(double value) {
    if (value == _scale) return;
    _scale = value;
    markNeedsLayout();
  }

  static double _div(double v, double s) => v.isFinite ? v / s : v;

  BoxConstraints _inner(BoxConstraints c) => BoxConstraints(
        minWidth: _div(c.minWidth, _scale),
        maxWidth: _div(c.maxWidth, _scale),
        minHeight: _div(c.minHeight, _scale),
        maxHeight: _div(c.maxHeight, _scale),
      );

  Matrix4 get _transform => Matrix4.diagonal3Values(_scale, _scale, 1);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    return constraints.constrain(c.getDryLayout(_inner(constraints)) * _scale);
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(c.size * _scale);
  }

  @override
  double computeMinIntrinsicWidth(double height) => (child?.getMinIntrinsicWidth(_div(height, _scale)) ?? 0) * _scale;

  @override
  double computeMaxIntrinsicWidth(double height) => (child?.getMaxIntrinsicWidth(_div(height, _scale)) ?? 0) * _scale;

  @override
  double computeMinIntrinsicHeight(double width) => (child?.getMinIntrinsicHeight(_div(width, _scale)) ?? 0) * _scale;

  @override
  double computeMaxIntrinsicHeight(double width) => (child?.getMaxIntrinsicHeight(_div(width, _scale)) ?? 0) * _scale;

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    if (_scale == 1) {
      context.paintChild(c, offset);
      return;
    }
    layer = context.pushTransform(needsCompositing, offset, _transform, (ctx, o) => ctx.paintChild(c, o),
        oldLayer: layer is TransformLayer ? layer as TransformLayer : null);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, transformed) => c.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }
}

/// How much bigger the desk instruments are drawn on a large screen: the most that fits [available] for a design of
/// [design] logical pixels, never below 1 (phones keep their layout) and at most [maxScale].
double instrumentScale(Size available, Size design, {double maxScale = 1.7}) {
  if (available.width <= 0 || available.height <= 0) return 1;
  final fit = math.min(available.width / design.width, available.height / design.height);
  return fit.clamp(1.0, maxScale).toDouble();
}

/// [ScaledLayout] that also shrinks to keep its child within [availableHeight]: at [scale] while the child fits, then
/// smaller as it grows (an opened record drawer or archive), down to [minScale]; past that the caller scrolls.
/// The child's own expand animations make the change smooth.
class FitScaledLayout extends SingleChildRenderObjectWidget {
  final double scale;
  final double minScale;
  final double availableHeight;

  const FitScaledLayout({
    super.key,
    required this.scale,
    required this.availableHeight,
    this.minScale = 0.8,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderFitScaledLayout(scale: scale, minScale: minScale, availableHeight: availableHeight);

  @override
  void updateRenderObject(BuildContext context, RenderFitScaledLayout renderObject) {
    renderObject
      ..maxScale = scale
      ..minScale = minScale
      ..availableHeight = availableHeight;
  }
}

class RenderFitScaledLayout extends RenderScaledLayout {
  RenderFitScaledLayout({required double scale, required double minScale, required double availableHeight})
      : _maxScale = scale,
        _minScale = minScale,
        _availableHeight = availableHeight,
        super(scale);

  double _maxScale;
  set maxScale(double v) {
    if (v == _maxScale) return;
    _maxScale = v;
    markNeedsLayout();
  }

  double _minScale;
  set minScale(double v) {
    if (v == _minScale) return;
    _minScale = v;
    markNeedsLayout();
  }

  double _availableHeight;
  set availableHeight(double v) {
    if (v == _availableHeight) return;
    _availableHeight = v;
    markNeedsLayout();
  }

  double _fit(Size natural) {
    final floor = math.min(_minScale, _maxScale);
    if (natural.height <= 0 || !_availableHeight.isFinite || _availableHeight <= 0) return _maxScale;
    return (_availableHeight / natural.height).clamp(floor, _maxScale).toDouble();
  }

  BoxConstraints _at(BoxConstraints c, double s) => BoxConstraints(
        minWidth: RenderScaledLayout._div(c.minWidth, s),
        maxWidth: RenderScaledLayout._div(c.maxWidth, s),
        minHeight: RenderScaledLayout._div(c.minHeight, s),
        maxHeight: RenderScaledLayout._div(c.maxHeight, s),
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    final s = _fit(c.getDryLayout(_at(constraints, _maxScale)));
    return constraints.constrain(c.getDryLayout(_at(constraints, s)) * s);
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(_at(constraints, _maxScale), parentUsesSize: true);
    final s = _fit(c.size);
    if (s != _maxScale) c.layout(_at(constraints, s), parentUsesSize: true);
    // Set the field directly: the setter would ask for another layout.
    _scale = s;
    size = constraints.constrain(c.size * s);
  }
}
