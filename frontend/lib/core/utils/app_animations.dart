import 'package:flutter/material.dart';

class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset beginOffset;

  FadeSlidePageRoute({required this.page, this.beginOffset = const Offset(0, 0.04)})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved), child: child),
            );
          },
        );
}

class PressAnimated extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final Duration duration;
  final BorderRadius? borderRadius;

  const PressAnimated({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.95, this.duration = const Duration(milliseconds: 120), this.borderRadius});

  @override
  State<PressAnimated> createState() => _PressAnimatedState();
}

class _PressAnimatedState extends State<PressAnimated> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration, reverseDuration: const Duration(milliseconds: 180));
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.borderRadius != null ? ClipRRect(borderRadius: widget.borderRadius!, child: widget.child) : widget.child,
      ),
    );
  }
}

class PulseAnimated extends StatefulWidget {
  final Widget child;
  final Duration period;
  final double minOpacity;
  final double maxOpacity;

  const PulseAnimated({super.key, required this.child, this.period = const Duration(milliseconds: 1200), this.minOpacity = 0.5, this.maxOpacity = 1.0});

  @override
  State<PulseAnimated> createState() => _PulseAnimatedState();
}

class _PulseAnimatedState extends State<PulseAnimated> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)..repeat(reverse: true);
    _opacity = Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center)],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({super.key, required this.width, required this.height, this.borderRadius = const BorderRadius.all(Radius.circular(8))});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.4, end: 0.8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFE5E7EB), const Color(0xFFF3F4F6), _shimmer.value),
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}
