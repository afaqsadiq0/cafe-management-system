import 'package:flutter/material.dart';

class TiltCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TiltCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  double x = 0;
  double y = 0;
  double z = 0;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(PointerEvent details) {
    if (MediaQuery.of(context).disableAnimations) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.globalToLocal(details.position);
    
    // Calculate rotation based on touch position relative to center
    setState(() {
      x = (position.dy - renderBox.size.height / 2) / renderBox.size.height;
      y = -(position.dx - renderBox.size.width / 2) / renderBox.size.width;
    });
    _controller.forward();
  }

  void _onPanEnd(PointerEvent details) {
    if (MediaQuery.of(context).disableAnimations) return;

    setState(() {
      x = 0;
      y = 0;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPanUpdate,
      onPointerMove: _onPanUpdate,
      onPointerUp: (details) {
        _onPanEnd(details);
        if (widget.onTap != null) widget.onTap!();
      },
      onPointerCancel: _onPanEnd,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(x * _animation.value * 0.5)
            ..rotateY(y * _animation.value * 0.5);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
