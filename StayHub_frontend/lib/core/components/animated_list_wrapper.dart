import 'package:flutter/cupertino.dart';
import '../theme/app_motion.dart';
import 'dart:async' show unawaited;

class AnimatedListWrapper extends StatefulWidget {
  final List<Widget> children;
  final int baseDelayMs;
  final int staggerDelayMs;

  const AnimatedListWrapper({
    super.key,
    required this.children,
    this.baseDelayMs = 100,
    this.staggerDelayMs = 50,
  });

  @override
  State<AnimatedListWrapper> createState() => _AnimatedListWrapperState();
}

class _AnimatedListWrapperState extends State<AnimatedListWrapper> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(widget.children.length, (index) {
        return AnimatedEntrance(
          delay: Duration(
            milliseconds: widget.baseDelayMs + (index * widget.staggerDelayMs),
          ),
          child: widget.children[index],
        );
      }),
    );
  }
}

class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedEntrance({super.key, required this.child, required this.delay});

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.appleEaseOut),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.appleEaseOut),
        );

    Future.delayed(widget.delay, () {
      if (mounted) unawaited(_controller.forward());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}
