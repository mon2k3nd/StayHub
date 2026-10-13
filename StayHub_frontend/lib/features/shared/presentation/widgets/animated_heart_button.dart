import 'dart:async' show unawaited;
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── AnimatedHeartButton ─────────────────────────────────────────────────────
// Nút trái tim với hiệu ứng bounce + particle burst + glow + label animation
// ---------------------------------------------------------------------------

class AnimatedHeartButton extends StatefulWidget {
  final bool isWishlisted;
  final Future<void> Function() onTap;
  final double size;
  final bool showLabel;
  final int likesCount;

  const AnimatedHeartButton({
    super.key,
    required this.isWishlisted,
    required this.onTap,
    this.size = 28.0,
    this.showLabel = false,
    this.likesCount = 0,
  });

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with TickerProviderStateMixin {
  // Bounce controller: scale up → bounce down
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  // Glow controller: fade in glow ring on like
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  // Particle controller
  late AnimationController _particleController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.45,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.45,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_bounceController);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(AnimatedHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // isWishlisted changes are handled externally
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final isLiking = !widget.isWishlisted;

    if (isLiking) {
      unawaited(HapticFeedback.mediumImpact());
      unawaited(_bounceController.forward(from: 0.0));
      unawaited(
        _glowController.forward(from: 0.0).then((_) {
          unawaited(_glowController.reverse());
        }),
      );
      unawaited(_particleController.forward(from: 0.0));
    } else {
      unawaited(HapticFeedback.lightImpact());
      unawaited(_bounceController.forward(from: 0.0));
      _glowController.value = 0.0;
    }

    await widget.onTap();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bounceAnim,
          _glowAnim,
          _particleController,
        ]),
        builder: (context, child) {
          return SizedBox(
            width: widget.size + 28,
            height: widget.size + 28,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ── Glow ring ───────────────────────────────────────────
                if (widget.isWishlisted)
                  Opacity(
                    opacity: (_glowAnim.value * 0.6).clamp(0.0, 1.0),
                    child: Container(
                      width: widget.size * (1.0 + _glowAnim.value * 1.2),
                      height: widget.size * (1.0 + _glowAnim.value * 1.2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.6),
                            blurRadius: 20 * _glowAnim.value,
                            spreadRadius: 4 * _glowAnim.value,
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Particles burst ─────────────────────────────────────
                if (_particleController.isAnimating ||
                    _particleController.value > 0)
                  ..._buildParticles(),

                // ── Heart icon with bounce ───────────────────────────────
                Transform.scale(
                  scale: _bounceAnim.value,
                  child: Icon(
                    widget.isWishlisted
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: widget.isWishlisted
                        ? Colors.redAccent
                        : Colors.white,
                    size: widget.size,
                    shadows: const [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black45,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles() {
    final t = _particleController.value;
    if (t == 0) return [];
    final eased = Curves.easeOut.transform(t);
    final opacity = (1.0 - t).clamp(0.0, 1.0);

    const particleCount = 8;
    const colors = [
      Colors.redAccent,
      Colors.pinkAccent,
      Color(0xFFFF6B6B),
      Colors.orangeAccent,
      Color(0xFFFF4081),
      Colors.deepOrangeAccent,
    ];

    return List.generate(particleCount, (i) {
      final angle = (i / particleCount) * 2 * pi;
      final radius = eased * (widget.size * 1.6);
      final dx = cos(angle) * radius;
      final dy = sin(angle) * radius;
      final color = colors[i % colors.length];
      final pSize = widget.size * 0.18 * (1 - t * 0.5);

      return Positioned(
        left: (widget.size + 28) / 2 + dx - pSize / 2,
        top: (widget.size + 28) / 2 + dy - pSize / 2,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: pSize,
            height: pSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── HeartActionButton ──────────────────────────────────────────────────────
// Dùng cho sidebar của feed view với label "Đã thích" / "Thích" + burst anim
// ---------------------------------------------------------------------------

class HeartActionButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;
  final int likesCount;
  final bool isGuest;

  const HeartActionButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 32,
    this.likesCount = 0,
    this.isGuest = false,
  });

  @override
  State<HeartActionButton> createState() => _HeartActionButtonState();
}

class _HeartActionButtonState extends State<HeartActionButton>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  late AnimationController _particleController;

  late AnimationController _labelController;
  late Animation<double> _labelAnim;

  late int _localLikesCount;
  late bool _prevIsLiked;

  @override
  void initState() {
    super.initState();
    _localLikesCount = widget.likesCount;
    _prevIsLiked = widget.isLiked;

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.5,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.88,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeOut);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _labelAnim = CurvedAnimation(
      parent: _labelController,
      curve: Curves.elasticOut,
    );
    if (widget.isLiked) _labelController.value = 1.0;
  }

  @override
  void didUpdateWidget(HeartActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      if (widget.isLiked) {
        unawaited(_labelController.forward(from: 0.0));
        if (!_prevIsLiked) {
          setState(() {
            _localLikesCount++;
            _prevIsLiked = true;
          });
        }
      } else {
        unawaited(_labelController.reverse());
        if (_prevIsLiked) {
          setState(() {
            _localLikesCount--;
            if (_localLikesCount < 0) _localLikesCount = 0;
            _prevIsLiked = false;
          });
        }
      }
    } else if (oldWidget.likesCount != widget.likesCount) {
      setState(() {
        _localLikesCount = widget.likesCount;
      });
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Nếu chưa đăng nhập → gọi callback (sẽ show dialog login), KHÔNG đổi số
    if (widget.isGuest) {
      widget.onTap();
      return;
    }

    final isLiking = !widget.isLiked;
    setState(() {
      _prevIsLiked = isLiking;
      if (isLiking) {
        _localLikesCount++;
      } else {
        _localLikesCount--;
        if (_localLikesCount < 0) _localLikesCount = 0;
      }
    });

    if (isLiking) {
      unawaited(HapticFeedback.mediumImpact());
      unawaited(_bounceController.forward(from: 0.0));
      unawaited(
        _glowController
            .forward(from: 0.0)
            .then((_) => _glowController.reverse()),
      );
      unawaited(_particleController.forward(from: 0.0));
    } else {
      unawaited(HapticFeedback.lightImpact());
      unawaited(_bounceController.forward(from: 0.0));
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bounceAnim,
          _glowAnim,
          _particleController,
          _labelAnim,
        ]),
        builder: (context, _) {
          final t = _particleController.value;
          final glowVal = _glowAnim.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon area — compact size = widget.size, particles overflow via OverflowBox
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: OverflowBox(
                  maxWidth: widget.size + 40,
                  maxHeight: widget.size + 40,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Glow ring
                      if (widget.isLiked && glowVal > 0)
                        Container(
                          width: widget.size * (1.0 + glowVal * 1.4),
                          height: widget.size * (1.0 + glowVal * 1.4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(
                                  alpha: glowVal * 0.7,
                                ),
                                blurRadius: 24 * glowVal,
                                spreadRadius: 6 * glowVal,
                              ),
                            ],
                          ),
                        ),

                      // Particles
                      if (t > 0 && t < 1) ..._buildParticles(t),

                      // Heart icon
                      Transform.scale(
                        scale: _bounceAnim.value,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            widget.isLiked
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            key: ValueKey(widget.isLiked),
                            color: widget.isLiked
                                ? Colors.redAccent
                                : Colors.white,
                            size: widget.size,
                            shadows: const [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black45,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Label "Đã thích" / "Thích" with scale-in animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  );
                },
                child: Text(
                  '$_localLikesCount',
                  key: ValueKey('${widget.isLiked}_$_localLikesCount'),
                  style: TextStyle(
                    color: widget.isLiked ? Colors.redAccent : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black87),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles(double t) {
    final eased = Curves.easeOut.transform(t);
    final opacity = (1.0 - t * 1.4).clamp(0.0, 1.0);
    const particleCount = 10;
    const colors = [
      Colors.redAccent,
      Colors.pinkAccent,
      Color(0xFFFF6B6B),
      Colors.orangeAccent,
      Color(0xFFFF4081),
      Colors.deepOrangeAccent,
      Color(0xFFFF80AB),
    ];

    return List.generate(particleCount, (i) {
      final angle = (i / particleCount) * 2 * pi - pi / 2;
      final radius = eased * (widget.size * 1.7);
      final dx = cos(angle) * radius;
      final dy = sin(angle) * radius;
      final color = colors[i % colors.length];
      final pSize = widget.size * 0.2 * (1 - t * 0.6);
      final center = (widget.size + 40) / 2;

      return Positioned(
        left: center + dx - pSize / 2,
        top: center + dy - pSize / 2,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: pSize,
            height: pSize,
            decoration: BoxDecoration(
              color: color,
              shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: i.isEven ? null : BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.7),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
