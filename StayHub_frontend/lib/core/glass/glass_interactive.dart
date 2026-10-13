import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'glass_accessibility.dart';
import 'dart:async' show unawaited;

// ─────────────────────────────────────────────────────────────────────────────
// StayHub Glass Design System — Interactive Material
//
// Touch never enlarges an object. Touch *compresses* it. Dragging *stretches*
// it. Movement follows inertia, and motion follows spring physics.
//
// This wrapper owns that behaviour so no individual screen ever reimplements
// it. It does not paint glass — it drives the physical state that the glass
// engine renders. A component composes [GlassInteractive] around [OpticalGlass]
// and the two together are the material.
// ─────────────────────────────────────────────────────────────────────────────

/// The physical state of a piece of glass being touched.
@immutable
class GlassInteractionState {
  /// 0..1. How much the glass is compressed. Never produces a scale above 1.
  final double press;

  /// The horizontal stretch factor. 1.0 at rest, up to 1 + maxDragStretch.
  final double stretch;

  /// The vertical squash that conserves volume as the glass stretches.
  final double squash;

  /// -1, 0 or +1. The direction of travel, used to push the scale origin
  /// toward the trailing edge so the leading edge reaches further.
  final double direction;

  /// 0..1. How much the glass is still settling after release.
  final double settle;

  /// True while a finger is dragging the glass.
  final bool dragging;

  const GlassInteractionState({
    this.press = 0.0,
    this.stretch = 1.0,
    this.squash = 1.0,
    this.direction = 0.0,
    this.settle = 0.0,
    this.dragging = false,
  });

  static const GlassInteractionState rest = GlassInteractionState();

  /// The scale origin. Pushed toward the trailing edge while dragging, so the
  /// glass deforms like a droplet being pulled rather than a rigid rectangle
  /// being translated.
  Alignment get origin => Alignment(-direction * 0.35, 0.0);

  /// The transform that applies this state to a child.
  Widget apply(Widget child) {
    return Transform.translate(
      offset: Offset(0, press * 0.02),
      child: Transform.scale(
        scale: 1.0 - press * 0.05,
        child: Transform.scale(
          scaleX: stretch,
          scaleY: squash,
          alignment: origin,
          child: child,
        ),
      ),
    );
  }
}

/// Drives the physical interaction state of a piece of glass.
///
/// Wrap any glass surface in this to give it weight. It handles press
/// compression, drag inertia, the settle rebound and the haptics that
/// accompany them, and it hands the resulting state to a builder.
///
/// It deliberately does not know what it is wrapping. The same widget drives a
/// button, a card, a sheet handle and the navigation capsule.
class GlassInteractive extends StatefulWidget {
  /// Builds the glass, given the current physical state.
  final Widget Function(BuildContext context, GlassInteractionState state)
  builder;

  /// Called when a tap completes. Null makes the surface non-tappable.
  final VoidCallback? onTap;

  /// Called when a horizontal drag ends, with the release velocity in logical
  /// pixels per second. Null disables dragging entirely.
  final void Function(double velocity)? onDragEnd;

  /// Called continuously during a horizontal drag, with the delta in logical
  /// pixels. Null disables dragging entirely.
  final void Function(double delta)? onDragUpdate;

  /// Whether the surface responds to touch at all.
  final bool enabled;

  /// Whether the surface can be dragged horizontally.
  final bool draggable;

  /// Whether to emit haptics. Some surfaces, such as passive cards, should
  /// compress visually but stay silent.
  final bool haptics;

  const GlassInteractive({
    super.key,
    required this.builder,
    this.onTap,
    this.onDragEnd,
    this.onDragUpdate,
    this.enabled = true,
    this.draggable = false,
    this.haptics = true,
  });

  @override
  State<GlassInteractive> createState() => _GlassInteractiveState();
}

class _GlassInteractiveState extends State<GlassInteractive>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  GlassInteractionState _state = GlassInteractionState.rest;

  /// The glass has mass. When a finger first grabs it, the body lags behind the
  /// contact point for a moment before it starts to move — the leading edge
  /// deforms first and the bulk follows. This tracks that lag, 0..1.
  double _inertia = 0.0;

  /// How much the glass is still settling after release. Drives a single small
  /// overshoot so the material rebounds once before coming to rest, the way a
  /// viscous body does, instead of stopping dead.
  double _settle = 0.0;

  /// Accumulates drag distance so continuous haptics fire at a steady cadence
  /// rather than on every frame.
  double _hapticAccum = 0.0;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
    )..addListener(_onPressTick);
  }

  @override
  void dispose() {
    _pressCtrl
      ..removeListener(_onPressTick)
      ..dispose();
    super.dispose();
  }

  void _onPressTick() {
    setState(() {
      _state = GlassInteractionState(
        press: _pressCtrl.value,
        stretch: _state.stretch,
        squash: _state.squash,
        direction: _state.direction,
        settle: _state.settle,
        dragging: _state.dragging,
      );
    });
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    if (widget.haptics) unawaited(HapticFeedback.lightImpact());
    unawaited(_pressCtrl.forward());
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    unawaited(_pressCtrl.reverse());
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    unawaited(_pressCtrl.reverse());
  }

  void _onTap() {
    if (!widget.enabled) return;
    if (widget.haptics) unawaited(HapticFeedback.selectionClick());
    widget.onTap?.call();
  }

  void _onDragStart(DragStartDetails _) {
    if (!widget.enabled || !widget.draggable) return;
    if (widget.haptics) unawaited(HapticFeedback.lightImpact());
    setState(() {
      _inertia = 1.0;
      _settle = 0.0;
      _hapticAccum = 0.0;
      _state = GlassInteractionState(press: _state.press, dragging: true);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !widget.draggable) return;

    final dx = details.delta.dx;

    // Continuous haptic feedback while the material is being dragged, throttled
    // by distance so it reads as texture rather than as a rattle.
    if (widget.haptics) {
      _hapticAccum += dx.abs();
      if (_hapticAccum > 14) {
        _hapticAccum = 0.0;
        unawaited(HapticFeedback.selectionClick());
      }
    }

    setState(() {
      // The body has not started moving yet. The leading edge deforms first and
      // the bulk follows over the next few frames.
      _inertia = (_inertia - 0.16).clamp(0.0, 1.0);

      // The glass stretches toward its direction of travel. The brief caps the
      // deformation at 6%, so the speed term is scaled to stay inside it.
      final speed = (dx.abs() / 260).clamp(0.0, 1.0);
      final stretch = 1.0 + speed * 0.02 + _inertia * (0.02 * 0.5);

      _state = GlassInteractionState(
        press: _state.press,
        stretch: stretch,
        // Volume is conserved: as the glass stretches it thins vertically.
        squash: (2.0 - stretch).clamp(0.94, 1.0),
        direction: dx.abs() > 0.5 ? dx.sign : _state.direction,
        settle: 0.0,
        dragging: true,
      );
    });

    widget.onDragUpdate?.call(dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled || !widget.draggable) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    if (widget.haptics) unawaited(HapticFeedback.selectionClick());

    setState(() {
      _inertia = 0.0;
      // The glass has momentum. It overshoots its seat very slightly and then
      // settles back — one rebound, not a bounce.
      _settle = (velocity.abs() / 2400).clamp(0.0, 1.0);
      _state = GlassInteractionState(
        press: _state.press,
        stretch: 1.0 + _settle * 0.05,
        squash: (2.0 - (1.0 + _settle * 0.05)).clamp(0.94, 1.0),
        direction: _state.direction,
        settle: _settle,
        dragging: false,
      );
    });

    widget.onDragEnd?.call(velocity);

    // Decay the settle rebound over the spring duration, then come to unawaited(rest.)
    unawaited(_decaySettle());
  }

  Future<void> _decaySettle() async {
    const steps = 12;
    const stepMs = 22;
    for (var i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: stepMs));
      if (!mounted) return;
      setState(() {
        _settle = (_settle * 0.90).clamp(0.0, 1.0);
        if (_settle < 0.01) _settle = 0.0;
        final stretch = 1.0 + _settle * 0.05;
        _state = GlassInteractionState(
          press: _state.press,
          stretch: stretch,
          squash: (2.0 - stretch).clamp(0.94, 1.0),
          direction: _state.direction,
          settle: _settle,
          dragging: false,
        );
      });
      if (_settle == 0.0) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a11y = GlassAccessibility.of(context);

    // Under reduced motion the material still responds to touch, but it does so
    // instantly. The compression is applied directly rather than animated.
    if (a11y.reduceMotion) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(
          context,
          GlassInteractionState(press: _pressCtrl.value),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap == null ? null : _onTap,
      onHorizontalDragStart: widget.draggable ? _onDragStart : null,
      onHorizontalDragUpdate: widget.draggable ? _onDragUpdate : null,
      onHorizontalDragEnd: widget.draggable ? _onDragEnd : null,
      child: widget.builder(context, _state),
    );
  }
}
