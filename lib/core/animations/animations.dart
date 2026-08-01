import 'package:flutter/material.dart';

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

/// Animates a value from 0 to [end] with a counting effect.
///
/// NOT money-safe as written, and currently unused: [end] is a `double` and
/// [decimals] defaults to 2, so wiring it to an amount would re-introduce C4
/// (and show "1234.00" for a zero-decimal currency like JPY). To animate an
/// amount, drive it from minor units and format each frame through
/// `CurrencyUtils.formatAmount`.
class AnimatedCounter extends StatefulWidget {
  final double end;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.end,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 800),
    this.decimals = 2,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;
  double _prevEnd = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.end)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _prevEnd = oldWidget.end;
      _animation = Tween<double>(begin: _prevEnd, end: widget.end)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        final value = _animation.value.toStringAsFixed(widget.decimals);
        return Text(
          '${widget.prefix}$value${widget.suffix}',
          style: widget.style,
          overflow: TextOverflow.ellipsis,
        );
      },
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

/// Tap scale feedback — wraps a child in a scale-down-on-press effect.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.96,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Shimmer loading placeholder.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(1.0 + 2.0 * _ctrl.value, 0),
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHighest,
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
            ),
          ),
        );
      },
    );
  }
}
