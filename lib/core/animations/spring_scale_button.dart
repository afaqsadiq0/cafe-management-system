import 'package:flutter/material.dart';

class SpringScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scaleFactor;

  const SpringScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleFactor = 0.95,
  });

  @override
  State<SpringScaleButton> createState() => _SpringScaleButtonState();
}

class _SpringScaleButtonState extends State<SpringScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (MediaQuery.of(context).disableAnimations) {
      widget.onPressed();
      return;
    }
    _controller.reverse().then((value) {
      widget.onPressed();
    });
  }

  void _onTapCancel() {
    if (!MediaQuery.of(context).disableAnimations) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
