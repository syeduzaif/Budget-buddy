import 'package:flutter/material.dart';

// Shared animation widgets. Both of the two that remain have live callers:
// [FadeSlideItem] staggers the dashboard, categories and analytics blocks;
// [AnimatedProgressBar] draws every budget bar.
//
// Three were deleted 2026-08-05 (D-016) and must not come back by copy-paste —
// each taught a pattern this app has since decided against:
//   * `ShimmerBox`      — a loading placeholder, against D-015's ruling that
//                         this app shows no screen-level loading state.
//   * `TapScale`        — a second tap-feedback vocabulary, competing with the
//                         ripple the theme already gives every tappable.
//   * `AnimatedCounter` — money-unsafe by its own doc: a `double` end with
//                         `decimals: 2` renders "1234.00" for a zero-decimal
//                         currency such as JPY, i.e. it re-introduces C4 the
//                         moment anyone wires it to an amount.
//
// The rule that separates this from D-024's kept "No data" branch: delete dead
// code that teaches a wrong pattern; keep dead code that is a correct
// defensive branch behind a live caller.

/// Staggered fade + slide-up animation for list items.
/// Wrap each list child in this widget with an incrementing [index].
class FadeSlideItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FadeSlideItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 400),
    this.offsetY = 24,
  });

  @override
  State<FadeSlideItem> createState() => _FadeSlideItemState();
}

class _FadeSlideItemState extends State<FadeSlideItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(curve);

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: _offset.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// Animated linear progress bar that fills from 0 to [value].
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color? backgroundColor;
  final double height;
  final Duration duration;
  final BorderRadius? borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 6,
    this.duration = const Duration(milliseconds: 600),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(100);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (_, val, __) => LinearProgressIndicator(
            value: val,
            backgroundColor: backgroundColor ?? color.withValues(alpha: 0.15),
            color: color,
            minHeight: height,
          ),
        ),
      ),
    );
  }
}
