// ════════════════════════════════
//  Onboarding Painters & Helper Widgets
//  (split from onboarding_screen.dart to keep files manageable)
// ════════════════════════════════
part of 'onboarding_screen.dart';

// ════════════════════════════════
//  _SkyPainter — Realistic Day/Night cycle with Sun Arc, Dynamic
//  Clouds, Mountain Horizon & Atmospheric Lighting
// ════════════════════════════════

// ════════════════════════════════
//  _SkyPainter — Cinematic Day/Night cycle: Mountains rise up,
//  Sun/Moon arc transitions, God rays, Clouds
// ════════════════════════════════

class _SkyPainter extends CustomPainter {
  final List<_OnboardingPage> pages;
  final int from, to;
  final double t, pulseT, cloudT;
  final double exitT;

  const _SkyPainter({
    required this.pages,
    required this.from,
    required this.to,
    required this.t,
    required this.pulseT,
    required this.cloudT,
    this.exitT = 0.0,
  });

  // pageIndex -> sky config
  static const _skyConfigs = [
    // Page 0: Bình minh (Dawn 5:30am)
    _SkyConfig(
      skyColors: [
        Color(0xFF6488B8),
        Color(0xFF8FB1D8),
        Color(0xFFF9D1A0),
        Color(0xFFFFDFB0),
      ],
      colorStops: [0.0, 0.4, 0.75, 1.0],
      sunX: -0.70,
      sunY: -0.22,
      moonX: 0.70,
      moonY: 0.50,
      sunAlpha: 1.0,
      moonAlpha: 0.0,
      sunRadius: 52.0,
      glowRadius: 200.0,
      moonRadius: 28.0,
      sunCore: Color(0xFFFFEBAA),
      sunGlow: Color(0xFFFFC470),
      moonColor: Color(0xFFF0F4FF),
      glowAlpha: 0.45,
      godRays: 0.12,
      haze: 0.40,
      cloudAlpha: 0.55,
      cloudTint: Color(0xFFFFD0A0),
      cloudSpeed: 0.8,
    ),
    // Page 1: Sáng sớm (Morning 8am)
    _SkyConfig(
      skyColors: [
        Color(0xFF4A78A6),
        Color(0xFF75A3D1),
        Color(0xFFA6C8E8),
        Color(0xFFD9E8F5),
      ],
      colorStops: [0.0, 0.28, 0.68, 1.0],
      sunX: -0.35,
      sunY: -0.45,
      moonX: 0.80,
      moonY: 0.60,
      sunAlpha: 1.0,
      moonAlpha: 0.0,
      sunRadius: 38.0,
      glowRadius: 155.0,
      moonRadius: 28.0,
      sunCore: Color(0xFFFFEB3B),
      sunGlow: Color(0xFFFFF176),
      moonColor: Color(0xFFF0F4FF),
      glowAlpha: 0.70,
      godRays: 0.07,
      haze: 0.20,
      cloudAlpha: 0.50,
      cloudTint: Color(0xFFFFFFFF),
      cloudSpeed: 1.0,
    ),
    // Page 2: Trưa (High Noon 12pm)
    _SkyConfig(
      skyColors: [
        Color(0xFF3877C9),
        Color(0xFF5BA4E5),
        Color(0xFF91CDF2),
        Color(0xFFC5E8FA),
      ],
      colorStops: [0.0, 0.25, 0.65, 1.0],
      sunX: 0.0,
      sunY: -0.75,
      moonX: 0.90,
      moonY: 0.70,
      sunAlpha: 1.0,
      moonAlpha: 0.0,
      sunRadius: 32.0,
      glowRadius: 130.0,
      moonRadius: 28.0,
      sunCore: Color(0xFFFFFDE7),
      sunGlow: Color(0xFFFFF9C4),
      moonColor: Color(0xFFF0F4FF),
      glowAlpha: 0.60,
      godRays: 0.04,
      haze: 0.15,
      cloudAlpha: 0.35,
      cloudTint: Color(0xFFFFFFFF),
      cloudSpeed: 1.2,
    ),
    // Page 3: Hoàng hôn (Sunset 6pm)
    _SkyConfig(
      skyColors: [
        Color(0xFF7E30E1),
        Color(0xFFB52B9F),
        Color(0xFFFF5E3A),
        Color(0xFFFFB03A),
      ],
      colorStops: [0.0, 0.35, 0.70, 1.0],
      sunX: 0.65,
      sunY: -0.48,
      moonX: -0.65,
      moonY: -0.30,
      sunAlpha: 1.0,
      moonAlpha: 0.15,
      sunRadius: 62.0,
      glowRadius: 280.0,
      moonRadius: 28.0,
      sunCore: Color(0xFFFFE066),
      sunGlow: Color(0xFFFF7E5F),
      moonColor: Color(0xFFF0F4FF),
      glowAlpha: 0.90,
      godRays: 0.22,
      haze: 0.60,
      cloudAlpha: 0.70,
      cloudTint: Color(0xFFFF7043),
      cloudSpeed: 0.5,
    ),
    // Page 4: Tối (Night 8pm)
    _SkyConfig(
      skyColors: [
        Color(0xFF060B18),
        Color(0xFF0A1428),
        Color(0xFF0D1F3C),
        Color(0xFF1A2E55),
      ],
      colorStops: [0.0, 0.3, 0.7, 1.0],
      sunX: 0.85,
      sunY: 0.50,
      moonX: -0.05,
      moonY: -0.75,
      sunAlpha: 0.0,
      moonAlpha: 1.0,
      sunRadius: 40.0,
      glowRadius: 140.0,
      moonRadius: 28.0,
      sunCore: Color(0xFFF0F4FF),
      sunGlow: Color(0xFFB8C4DE),
      moonColor: Color(0xFFF0F4FF),
      glowAlpha: 0.70,
      godRays: 0.0,
      haze: 0.05,
      cloudAlpha: 0.60,
      cloudTint: Color(0xFF7A8B99),
      cloudSpeed: 0.4,
    ),
    // Page 5: Khuya (Late Night 11pm)
    _SkyConfig(
      skyColors: [
        Color(0xFF010408),
        Color(0xFF030912),
        Color(0xFF05101D),
        Color(0xFF071528),
      ],
      colorStops: [0.0, 0.3, 0.65, 1.0],
      sunX: 0.95,
      sunY: 0.80,
      moonX: 0.65,
      moonY: -0.40,
      sunAlpha: 0.0,
      moonAlpha: 1.0,
      sunRadius: 46.0,
      glowRadius: 160.0,
      moonRadius: 28.0,
      sunCore: Color(0xFFF8F8FF),
      sunGlow: Color(0xFFB8CCE0),
      moonColor: Color(0xFFF8F8FF),
      glowAlpha: 0.65,
      godRays: 0.0,
      haze: 0.02,
      cloudAlpha: 0.45,
      cloudTint: Color(0xFF4A5A69),
      cloudSpeed: 0.3,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cfgF = _skyConfigs[from.clamp(0, _skyConfigs.length - 1)];
    final cfgT = _skyConfigs[to.clamp(0, _skyConfigs.length - 1)];
    final rect = Offset.zero & size;

    // ─€ 1. Sky Gradient ─€
    _drawSky(canvas, size, rect, cfgF, cfgT, t);

    // ─€ 2. Stars (night pages only) ─€
    final nightBlend =
        (((from >= 4 ? 1.0 : 0.0) * (1 - t)) + ((to >= 4 ? 1.0 : 0.0) * t))
            .clamp(0.0, 1.0);
    if (nightBlend > 0.02) {
      _drawStars(canvas, size, nightBlend);
    }

    // ─€ 3. Sun and Moon objects ─€
    final sunXRaw = _lerp(cfgF.sunX, cfgT.sunX, t);
    final sunYRaw = _lerp(cfgF.sunY, cfgT.sunY, t);
    final moonXRaw = _lerp(cfgF.moonX, cfgT.moonX, t);
    final moonYRaw = _lerp(cfgF.moonY, cfgT.moonY, t) + exitT * 1.5;

    final sAlpha = _lerp(cfgF.sunAlpha, cfgT.sunAlpha, t);
    final mAlpha = _lerp(cfgF.moonAlpha, cfgT.moonAlpha, t) * (1.0 - exitT);

    final sunR = _lerp(cfgF.sunRadius, cfgT.sunRadius, t);
    final moonR = _lerp(cfgF.moonRadius, cfgT.moonRadius, t);
    final glowR = _lerp(cfgF.glowRadius, cfgT.glowRadius, t);
    final glowA = _lerp(cfgF.glowAlpha, cfgT.glowAlpha, t);
    final sunCore = Color.lerp(cfgF.sunCore, cfgT.sunCore, t)!;
    final sunGlow = Color.lerp(cfgF.sunGlow, cfgT.sunGlow, t)!;
    final moonCol = Color.lerp(cfgF.moonColor, cfgT.moonColor, t)!;

    // Draw Sun if visible
    if (sAlpha > 0.01) {
      final cx = size.width / 2 + sunXRaw * size.width / 2;
      final cy = size.height / 2 + sunYRaw * size.height / 2;
      final sc = Offset(cx, cy);

      final rayA = _lerp(cfgF.godRays, cfgT.godRays, t) * sAlpha;
      if (rayA > 0.003) _drawGodRays(canvas, size, sc, sunGlow, rayA);

      canvas.drawCircle(
        sc,
        glowR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sunGlow.withValues(alpha: glowA * sAlpha),
              sunGlow.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: sc, radius: glowR)),
      );

      canvas.drawCircle(
        sc,
        sunR * 1.8,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sunCore.withValues(alpha: glowA * 0.80 * sAlpha),
              sunCore.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: sc, radius: sunR * 1.8)),
      );

      _drawSunCore(canvas, sc, sunR, sunCore, sAlpha);
    }

    // Draw Moon if visible
    if (mAlpha > 0.01) {
      final cx = size.width / 2 + moonXRaw * size.width / 2;
      final cy = size.height / 2 + moonYRaw * size.height / 2;
      final sc = Offset(cx, cy);

      _drawMoon(canvas, sc, moonR, moonCol, mAlpha);
    }

    // ─€ 4. Atmospheric horizon haze ─€
    final haze = _lerp(cfgF.haze, cfgT.haze, t);
    if (haze > 0.01) {
      final hazeRect = Rect.fromLTWH(
        0,
        size.height * 0.55,
        size.width,
        size.height * 0.45,
      );
      canvas.drawRect(
        hazeRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              sunGlow.withValues(alpha: 0.0),
              sunGlow.withValues(alpha: haze * 0.4),
            ],
          ).createShader(hazeRect),
      );
    }

    // ─€ 5. Mountains (3 layers, drawn OVER sun for natural occlusion) ─€
    _drawMountains(canvas, size, sunXRaw, sunYRaw, cfgF, cfgT, t, exitT);

    // ─€ 6. Optional: Global tint if exiting
    if (exitT > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0A1228).withValues(alpha: exitT),
      );
    }

    // ─€ 6. Clouds ─€
    final cAlpha = _lerp(cfgF.cloudAlpha, cfgT.cloudAlpha, t);
    final cTint = Color.lerp(cfgF.cloudTint, cfgT.cloudTint, t)!;
    final cSpeed = _lerp(cfgF.cloudSpeed, cfgT.cloudSpeed, t);
    if (cAlpha > 0.02) {
      _drawClouds(canvas, size, cAlpha, cTint, cSpeed);
    }
  }

  void _drawSky(
    Canvas canvas,
    Size size,
    Rect rect,
    _SkyConfig f,
    _SkyConfig g,
    double blend,
  ) {
    final colors = List.generate(
      f.skyColors.length,
      (i) => Color.lerp(f.skyColors[i], g.skyColors[i], blend)!,
    );
    final stops = List.generate(
      f.colorStops.length,
      (i) => _lerp(f.colorStops[i], g.colorStops[i], blend),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
  }

  void _drawStars(Canvas canvas, Size size, double alpha) {
    final rng = math.Random(99);
    final sp = Paint();
    for (int i = 0; i < 45; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height * 0.70;
      final sr = rng.nextDouble() * 1.5 + 0.3;
      final blink =
          0.3 + 0.7 * math.sin(pulseT * math.pi * 2 + rng.nextDouble() * 12);
      sp.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: blink * 0.85 * alpha);
      canvas.drawCircle(Offset(sx, sy), sr, sp);
    }
  }

  void _drawGodRays(
    Canvas canvas,
    Size size,
    Offset sc,
    Color color,
    double alpha,
  ) {
    canvas.save();
    final rayRng = math.Random(42);
    for (int r = 0; r < 10; r++) {
      final baseAngle = (r / 10) * math.pi * 2 + cloudT * 0.20;
      final spread = 0.05 + rayRng.nextDouble() * 0.09;
      final rayAlpha = alpha * (0.4 + rayRng.nextDouble() * 0.6);
      final rayLen = size.width * (1.3 + rayRng.nextDouble() * 0.7);
      final rayPath = Path();
      rayPath.moveTo(sc.dx, sc.dy);
      rayPath.lineTo(
        sc.dx + math.cos(baseAngle - spread) * rayLen,
        sc.dy + math.sin(baseAngle - spread) * rayLen,
      );
      rayPath.lineTo(
        sc.dx + math.cos(baseAngle + spread) * rayLen,
        sc.dy + math.sin(baseAngle + spread) * rayLen,
      );
      rayPath.close();
      canvas.drawPath(
        rayPath,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: rayAlpha),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: sc, radius: rayLen))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
    canvas.restore();
  }

  void _drawSunCore(
    Canvas canvas,
    Offset sc,
    double r,
    Color color,
    double alpha,
  ) {
    if (alpha <= 0.0) return;
    // Draw a realistic, soft glowing sun core using a dense RadialGradient
    final Rect rect = Rect.fromCircle(center: sc, radius: r);
    canvas.drawCircle(
      sc,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(
              0xFFFFFFFF,
            ).withValues(alpha: alpha), // Blinding white center
            const Color(
              0xFFFFFFE0,
            ).withValues(alpha: alpha), // Warm glowing inner edge
            color.withValues(alpha: 0.9 * alpha), // Base sun color
            color.withValues(alpha: 0.0), // Soft fade out to nothing
          ],
          stops: const [0.0, 0.25, 0.6, 1.0],
        ).createShader(rect),
    );
  }

  void _drawMoon(
    Canvas canvas,
    Offset sc,
    double r,
    Color color,
    double alpha,
  ) {
    if (alpha <= 0.0) return;
    // Outer ambient glow (large, soft)
    canvas.drawCircle(
      sc,
      r * 3.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFB8D4FF).withValues(alpha: 0.15 * alpha),
            const Color(0xFFB8D4FF).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: sc, radius: r * 3.5)),
    );

    // Inner halo
    canvas.drawCircle(
      sc,
      r * 1.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.4 * alpha),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: sc, radius: r * 1.8)),
    );

    // Crescent using Path.combine to avoid hardcoded dark background sticker
    Path moonPath = Path()..addOval(Rect.fromCircle(center: sc, radius: r));
    // Push the shadow circle further left (-0.65) to make the crescent wider ("mở hơn")
    Path shadowPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(sc.dx - r * 0.65, sc.dy - r * 0.20),
          radius: r * 0.95,
        ),
      );
    Path crescent = Path.combine(
      PathOperation.difference,
      moonPath,
      shadowPath,
    );

    canvas.drawPath(crescent, Paint()..color = color.withValues(alpha: alpha));
  }

  // Helper functions for 1D procedural noise (fBm)
  double _hash(double n, int seed) {
    double x = math.sin(n * 12.9898 + seed * 78.233) * 43758.5453;
    return (x - x.floorToDouble()) * 2.0 - 1.0;
  }

  double _noise1D(double x, int seed) {
    double i = x.floorToDouble();
    double f = x - i;
    double u = f * f * (3.0 - 2.0 * f);
    return _hash(i, seed) * (1.0 - u) + _hash(i + 1.0, seed) * u;
  }

  // ignore: unused_element
  double _fbm(double x, int seed) {
    double v = 0.0;
    double a = 0.5;
    for (int i = 0; i < 5; i++) {
      v += a * _noise1D(x, seed + i * 137);
      x = x * 2.0;
      a *= 0.5;
    }
    return v;
  }

  void _drawMountains(
    Canvas canvas,
    Size size,
    double sunXRaw,
    double sunYRaw,
    _SkyConfig cfgF,
    _SkyConfig cfgT,
    double blend,
    double exitT,
  ) {
    final isNight =
        (from >= 4 && to >= 4) ||
        (from >= 3 && to >= 4 && blend > 0.5) ||
        (from >= 4 && to >= 3 && blend < 0.5);
    final isSunset =
        (from == 3 && to == 3) ||
        (from == 2 && to == 3 && blend > 0.5) ||
        (from == 3 && to == 2 && blend < 0.5);

    final farColor = isNight
        ? const Color(0xFF0D1626)
        : isSunset
        ? const Color(0xFF7A4F8A)
        : const Color(0xFF6B8AB8);
    final midColor = isNight
        ? const Color(0xFF070F1E)
        : isSunset
        ? const Color(0xFF5B3069)
        : const Color(0xFF3A5070);
    final nearColor = isNight
        ? const Color(0xFF030A14)
        : isSunset
        ? const Color(0xFF38164A)
        : const Color(0xFF1E2E48);

    final prevIsNight = (from >= 4);
    final prevIsSunset = from == 3;
    final prevFar = prevIsNight
        ? const Color(0xFF0D1626)
        : prevIsSunset
        ? const Color(0xFF7A4F8A)
        : const Color(0xFF6B8AB8);
    final prevMid = prevIsNight
        ? const Color(0xFF070F1E)
        : prevIsSunset
        ? const Color(0xFF5B3069)
        : const Color(0xFF3A5070);
    final prevNear = prevIsNight
        ? const Color(0xFF030A14)
        : prevIsSunset
        ? const Color(0xFF38164A)
        : const Color(0xFF1E2E48);

    final layers = [
      (height: 0.40, color: Color.lerp(prevFar, farColor, blend)!, seed: 11),
      (height: 0.28, color: Color.lerp(prevMid, midColor, blend)!, seed: 27),
      (height: 0.16, color: Color.lerp(prevNear, nearColor, blend)!, seed: 43),
    ];

    double getLightX(_SkyConfig cfg) =>
        cfg.sunAlpha > cfg.moonAlpha ? cfg.sunX : cfg.moonX;
    final lightX = _lerp(getLightX(cfgF), getLightX(cfgT), blend);

    for (final layer in layers) {
      final path = Path();
      final shadowPath = Path();

      final exitOffset = exitT * size.height * 0.8;

      final peakY = size.height * (0.65 - layer.height) + exitOffset;
      final baseY = size.height * 0.9 + exitOffset;

      final amplitude = (baseY - peakY) / 2.0;
      final midY = baseY - amplitude;

      final paint = Paint();

      if (layer.seed == 11 && !isNight) {
        final snowAlpha =
            (1 - (blend < 0.5 ? (from / 3.0) : (to / 3.0))).clamp(0.0, 1.0) *
            0.8;
        if (snowAlpha > 0.05) {
          paint.shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(layer.color, const Color(0xFFFFFFFF), snowAlpha)!,
              layer.color,
            ],
            stops: const [0.0, 0.45],
          ).createShader(Rect.fromLTWH(0, peakY, size.width, amplitude * 2.0));
        } else {
          paint.color = layer.color.withValues(alpha: 1.0);
        }
      } else {
        paint.color = layer.color.withValues(alpha: 1.0);
      }

      final baseFreq = layer.seed == 11
          ? 0.0025
          : (layer.seed == 27 ? 0.0035 : 0.0045);

      double getMountainY(double x) {
        double detail = 0.0;
        double amplitudeAcc = 1.0;
        double freq = baseFreq;
        double weight = 1.0;
        for (int i = 0; i < 4; i++) {
          double n = 1.0 - _noise1D(x * freq, layer.seed + i * 13).abs();
          n = n * n;
          n *= weight;
          weight = (n * 2.0).clamp(0.0, 1.0);
          detail += n * amplitudeAcc;
          amplitudeAcc *= 0.45;
          freq *= 2.2;
        }
        return midY - (amplitude * (detail / 1.5));
      }

      void addJaggedLine(
        Path p,
        double startX,
        double startY,
        double endY,
        int s,
      ) {
        double dist = (endY - startY).abs();
        int steps = (dist / 12.0).ceil();
        if (steps <= 1) {
          p.lineTo(startX, endY);
          return;
        }
        double stepY = (endY - startY) / steps;
        double y = startY;
        for (int i = 1; i < steps; i++) {
          y += stepY;
          double peakY = math.min(startY, endY);
          double distFromPeak = (y - peakY).abs();
          double dampen = (distFromPeak < 60.0) ? (distFromPeak / 60.0) : 1.0;

          double n1 = _noise1D(y * 0.02, s) - 0.5;
          double n2 = _noise1D(y * 0.05, s + 13) - 0.5;
          double dx = (n1 * 50.0 + n2 * 25.0) * dampen;
          p.lineTo(startX + dx, y);
        }
        p.lineTo(startX, endY);
      }

      double prevX = -10;
      double prevY = getMountainY(prevX);
      path.moveTo(prevX, size.height + 10);
      path.lineTo(prevX, prevY);

      bool inShadow = false;

      for (double x = -7; x <= size.width + 20; x += 3) {
        double y = getMountainY(x);
        path.lineTo(x, y);

        double dy = y - prevY;
        bool isShadow =
            (lightX * dy) < -0.15; // threshold to avoid flat area noise

        if (isShadow) {
          if (!inShadow) {
            shadowPath.moveTo(prevX, baseY);
            addJaggedLine(
              shadowPath,
              prevX,
              baseY,
              prevY,
              layer.seed + prevX.toInt(),
            );
            inShadow = true;
          }
          shadowPath.lineTo(x, y);
        } else {
          if (inShadow) {
            addJaggedLine(
              shadowPath,
              prevX,
              prevY,
              baseY,
              layer.seed + prevX.toInt(),
            );
            shadowPath.close();
            inShadow = false;
          }
        }

        prevX = x;
        prevY = y;
      }
      path.lineTo(size.width + 20, size.height + 10);
      path.close();

      if (inShadow) {
        addJaggedLine(
          shadowPath,
          prevX,
          prevY,
          baseY,
          layer.seed + prevX.toInt(),
        );
        shadowPath.close();
      }

      canvas.drawShadow(
        path,
        const Color(0xFF000000).withValues(alpha: 0.5),
        12.0,
        false,
      );
      canvas.drawPath(path, paint);

      final shadowColor = isNight
          ? const Color(0xFF00050D)
          : const Color(0xFF1D0E29);
      final shadowPaint = Paint()..color = shadowColor.withValues(alpha: 0.35);

      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(shadowPath, shadowPaint);
      canvas.restore();
    }
  }

  // ignore: unused_element
  void _drawSnow(
    Canvas canvas,
    Size size,
    double amplitude,
    double frequency,
    int seed,
    double baseY,
    double blend,
  ) {
    final snowAlpha =
        (1 - (blend < 0.5 ? (from / 3.0) : (to / 3.0))).clamp(0.0, 1.0) * 0.55;
    if (snowAlpha < 0.02) return;
    final snowPaint = Paint()
      ..color = const Color(0xFFE8F4FD).withValues(alpha: snowAlpha);
    final snowPath = Path();
    double? firstY;
    for (double x = -10; x <= size.width + 20; x += 3) {
      double y = baseY;
      y -= amplitude * (1.0 - math.sin(x * frequency + seed * 0.1).abs());
      y -=
          amplitude *
          0.38 *
          (1.0 - math.sin(x * frequency * 2.3 + seed * 0.18).abs());
      y -=
          amplitude *
          0.15 *
          (1.0 - math.sin(x * frequency * 5.1 + seed * 0.42).abs());
      if (firstY == null) {
        snowPath.moveTo(x, y + 4);
        firstY = y + 4;
      } else {
        snowPath.lineTo(x, y + 4);
      }
    }
    snowPath.lineTo(size.width + 20, baseY);
    snowPath.lineTo(-10, baseY);
    snowPath.close();
    canvas.drawPath(snowPath, snowPaint);
  }

  void _drawClouds(
    Canvas canvas,
    Size size,
    double alpha,
    Color tint,
    double speed,
  ) {
    final rng = math.Random(77);
    final cloudPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    for (int i = 0; i < 15; i++) {
      final baseX = rng.nextDouble() * size.width * 1.5;
      final baseY = size.height * (0.08 + rng.nextDouble() * 0.35);
      final w = 80.0 + rng.nextDouble() * 140;
      final h = 30.0 + rng.nextDouble() * 50;
      final dx = ((cloudT * speed + i * 0.18) % 1.5) * size.width * 1.5;
      final cx = (baseX + dx) % (size.width * 1.6) - 80;
      final cloudAlpha = alpha * (0.5 + rng.nextDouble() * 0.5);
      cloudPaint.color = tint.withValues(alpha: cloudAlpha);
      canvas.drawOval(Rect.fromLTWH(cx, baseY, w, h), cloudPaint);
      canvas.drawOval(
        Rect.fromLTWH(cx + w * 0.2, baseY - h * 0.4, w * 0.7, h * 0.9),
        cloudPaint,
      );
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _SkyPainter old) =>
      old.t != t ||
      old.pulseT != pulseT ||
      old.cloudT != cloudT ||
      old.from != from ||
      old.to != to ||
      old.exitT != exitT;
}

// ─€─€ Sky config ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€

class _SkyConfig {
  final List<Color> skyColors;
  final List<double> colorStops;
  final double sunX, sunY;
  final double moonX, moonY;
  final double sunAlpha, moonAlpha;
  final double sunRadius, glowRadius, moonRadius;
  final Color sunCore, sunGlow, moonColor;
  final double glowAlpha;
  final double godRays, haze;
  final double cloudAlpha, cloudSpeed;
  final Color cloudTint;

  const _SkyConfig({
    required this.skyColors,
    required this.colorStops,
    required this.sunX,
    required this.sunY,
    required this.moonX,
    required this.moonY,
    required this.sunAlpha,
    required this.moonAlpha,
    required this.sunRadius,
    required this.glowRadius,
    required this.moonRadius,
    required this.sunCore,
    required this.sunGlow,
    required this.moonColor,
    required this.glowAlpha,
    required this.godRays,
    required this.haze,
    required this.cloudAlpha,
    required this.cloudTint,
    required this.cloudSpeed,
  });
}

// _FlightPathPainter removed — flight path overlay disabled per request

// ════════════════════════════════
//  _SweepPainter  (radar sweep)
// ════════════════════════════════

// ignore: unused_element
class _SweepPainter extends CustomPainter {
  final Color color;
  _SweepPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.32),
          ],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawLine(
      c,
      Offset(c.dx, 0),
      Paint()
        ..color = CupertinoColors.white.withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}

// ════════════════════════════════
//  _InteractiveElement — Tap bounce + elastic drag (3D tilt)
// ════════════════════════════════

class _InteractiveElement extends StatefulWidget {
  final Widget child;
  const _InteractiveElement({required this.child});

  @override
  State<_InteractiveElement> createState() => _InteractiveElementState();
}

class _InteractiveElementState extends State<_InteractiveElement> {
  Offset _drag = Offset.zero;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        unawaited(HapticFeedback.selectionClick());
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onPanUpdate: (d) => setState(() {
        _drag += d.delta / 3.5;
        _pressed = true;
      }),
      onPanEnd: (_) {
        unawaited(HapticFeedback.lightImpact());
        setState(() {
          _drag = Offset.zero;
          _pressed = false;
        });
      },
      child: AnimatedContainer(
        duration: _drag == Offset.zero
            ? const Duration(milliseconds: 650)
            : Duration.zero,
        curve: Curves.elasticOut,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_drag.dy * 0.013)
          ..rotateY(-_drag.dx * 0.013)
          ..scaleByDouble(
            _pressed ? 0.95 : 1.0,
            _pressed ? 0.95 : 1.0,
            _pressed ? 0.95 : 1.0,
            1.0,
          ),
        child: widget.child,
      ),
    );
  }
}

// ════════════════════════════════
//  _WaveClipper & _WaveBorderPainter (Morphing Bottom Card)
// ════════════════════════════════

double _getWaveY(
  int index,
  double x,
  double w,
  double time,
  double dragOffset,
) {
  double nx = x / w; // 0.0 to 1.0
  double base = 75.0; // Kéo đường cơ sở của sóng lên 1 chút xíu

  // Stretch amplitude when dragged to create a jelly spring effect
  double stretch = 1.0 + (dragOffset / 20.0) * 0.4;

  // Rich multi-layer wave — lush, smooth undulating shape
  double f1 = 1.0 + (index % 3) * 0.2;
  double f2 = 2.0 + (index % 2) * 0.3;
  double f3 = 3.5 + (index % 4) * 0.2;
  double a1 = (12.0 + (index % 2) * 2.0) * stretch; // primary
  double a2 = (6.0 + (index % 3) * 2.0) * stretch; // secondary
  double a3 = (3.0 + (index % 2) * 1.0) * stretch; // ripple
  double speed1 = 2.0 + (index * 0.08);
  double speed2 = 1.2 + (index * 0.15);
  double speed3 = 2.5 + (index * 0.05);

  return base +
      math.sin(nx * math.pi * f1 + time * speed1) * a1 +
      math.cos(nx * math.pi * f2 - time * speed2) * a2 +
      math.sin(nx * math.pi * f3 + time * speed3 + 1.2) * a3;
}

Path _buildMorphingPath(
  Size size,
  double page,
  double time,
  double dragOffset,
) {
  int p1 = page.floor();
  int p2 = p1 + 1;
  double t = page - p1;

  // Ensure we don't go out of bounds
  if (p1 < 0) p1 = 0;
  if (p2 > 5) p2 = 5;

  Path path = Path();
  path.moveTo(0, size.height);

  for (double x = 0; x <= size.width; x += 3) {
    double y1 = _getWaveY(p1, x, size.width, time, dragOffset);
    double y2 = _getWaveY(p2, x, size.width, time, dragOffset);
    double y = y1 + (y2 - y1) * t;

    if (x == 0) {
      path.lineTo(0, y);
    } else {
      path.lineTo(x, y);
    }
  }

  // Connect to end
  double y1End = _getWaveY(p1, size.width, size.width, time, dragOffset);
  double y2End = _getWaveY(p2, size.width, size.width, time, dragOffset);
  double yEnd = y1End + (y2End - y1End) * t;
  path.lineTo(size.width, yEnd);

  path.lineTo(size.width, size.height);
  path.close();
  return path;
}

class _WaveClipper extends CustomClipper<Path> {
  final double page;
  final double time;
  final double dragOffset;
  _WaveClipper(this.page, this.time, this.dragOffset);

  @override
  Path getClip(Size size) => _buildMorphingPath(size, page, time, dragOffset);

  @override
  bool shouldReclip(covariant _WaveClipper old) =>
      old.page != page || old.time != time || old.dragOffset != dragOffset;
}

class _WaveBorderPainter extends CustomPainter {
  final double page;
  final double time;
  final Color borderColor;
  final double dragOffset;
  _WaveBorderPainter(this.page, this.time, this.borderColor, this.dragOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildMorphingPath(size, page, time, dragOffset);
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveBorderPainter old) =>
      old.page != page ||
      old.time != time ||
      old.borderColor != borderColor ||
      old.dragOffset != dragOffset;
}

// ════════════════════════════════
//  Cityscape Painters
// ════════════════════════════════

// ignore: unused_element
class _MountainPainter extends CustomPainter {
  final double cloudT;
  final Color hazeColor;
  final Color mountainColor1;
  final Color mountainColor2;

  _MountainPainter({
    required this.cloudT,
    required this.hazeColor,
    required this.mountainColor1,
    required this.mountainColor2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shift = cloudT * w * 0.08; // slow parallax shift

    // Mountain range 1 (far, lighter)
    final path1 = Path();
    path1.moveTo(0, h);
    const peaks1 = [0.0, 0.18, 0.35, 0.52, 0.70, 0.85, 1.0];
    const heights1 = [0.72, 0.38, 0.55, 0.32, 0.48, 0.40, 0.72];
    for (int i = 0; i < peaks1.length - 1; i++) {
      final x1 = (peaks1[i] * w - shift) % w;
      final x2 = (peaks1[i + 1] * w - shift) % w;
      final y1 = h * heights1[i];
      final y2 = h * heights1[i + 1];
      final cx = (x1 + x2) / 2;
      path1.quadraticBezierTo(x1, y1, cx, (y1 + y2) / 2);
    }
    path1.lineTo(w, h);
    path1.close();
    canvas.drawPath(
      path1,
      Paint()
        ..color = mountainColor1
        ..style = PaintingStyle.fill,
    );

    // Mountain range 2 (closer, slightly darker)
    final path2 = Path();
    path2.moveTo(0, h);
    const peaks2 = [0.0, 0.12, 0.28, 0.45, 0.62, 0.78, 0.92, 1.0];
    const heights2 = [0.80, 0.52, 0.68, 0.44, 0.60, 0.50, 0.64, 0.80];
    final shift2 = cloudT * w * 0.14;
    for (int i = 0; i < peaks2.length - 1; i++) {
      final x1 = (peaks2[i] * w - shift2) % w;
      final x2 = (peaks2[i + 1] * w - shift2) % w;
      final y1 = h * heights2[i];
      final y2 = h * heights2[i + 1];
      final cx = (x1 + x2) / 2;
      path2.quadraticBezierTo(x1, y1, cx, (y1 + y2) / 2);
    }
    path2.lineTo(w, h);
    path2.close();
    canvas.drawPath(
      path2,
      Paint()
        ..color = mountainColor2
        ..style = PaintingStyle.fill,
    );

    // Atmospheric haze gradient overlay at the base of mountains
    final hazeRect = Rect.fromLTWH(0, h * 0.6, w, h * 0.4);
    final hazePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [hazeColor.withValues(alpha: 0.0), hazeColor],
      ).createShader(hazeRect);
    canvas.drawRect(hazeRect, hazePaint);
  }

  @override
  bool shouldRepaint(covariant _MountainPainter old) => old.cloudT != cloudT;
}

// ignore: unused_element
class _BuildingsPainter extends CustomPainter {
  final int row;
  final double cloudT;
  final double float;
  final Color accent;
  final Color windowColor;
  _BuildingsPainter({
    required this.row,
    required this.cloudT,
    required this.float,
    required this.accent,
    required this.windowColor,
  });
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant _BuildingsPainter old) => false;
}

// ════════════════════════════════
//  Skyline Painter — Full Scene
// ════════════════════════════════

// ignore: unused_element
class _SkylinePainter extends CustomPainter {
  final double cloudT; // 0..1 repeating
  final double float; // -8..8 vertical float

  _SkylinePainter({required this.cloudT, required this.float});

  // Each building: [xFrac, widthPx, heightFrac, seed]
  // xFrac = left edge as fraction of width
  // widthPx = fixed pixel width for that building
  // heightFrac = height as fraction of canvas height (0..1)
  // seed = for window pattern variety
  static const _backBuildings = [
    // xFrac,  w,    h,    seed
    [0.00, 28.0, 0.75, 1],
    [0.04, 22.0, 0.55, 2],
    [0.09, 32.0, 0.90, 3],
    [0.15, 20.0, 0.65, 4],
    [0.19, 26.0, 0.80, 5],
    [0.24, 18.0, 0.58, 6],
    [0.28, 30.0, 0.95, 7],
    [0.34, 22.0, 0.70, 8],
    [0.38, 24.0, 0.82, 9],
    [0.44, 20.0, 0.60, 10],
    [0.48, 28.0, 0.88, 11],
    [0.53, 18.0, 0.52, 12],
    [0.57, 32.0, 0.93, 13],
    [0.63, 22.0, 0.68, 14],
    [0.67, 26.0, 0.78, 15],
    [0.73, 20.0, 0.62, 16],
    [0.77, 30.0, 0.87, 17],
    [0.82, 24.0, 0.72, 18],
    [0.87, 22.0, 0.84, 19],
    [0.92, 28.0, 0.58, 20],
    [0.96, 18.0, 0.70, 21],
  ];
  static const _frontBuildings = [
    [0.00, 36.0, 0.60, 31],
    [0.05, 28.0, 0.45, 32],
    [0.11, 40.0, 0.72, 33],
    [0.18, 32.0, 0.50, 34],
    [0.24, 36.0, 0.65, 35],
    [0.31, 28.0, 0.40, 36],
    [0.36, 44.0, 0.78, 37],
    [0.44, 32.0, 0.55, 38],
    [0.50, 38.0, 0.68, 39],
    [0.57, 28.0, 0.42, 40],
    [0.62, 42.0, 0.76, 41],
    [0.69, 30.0, 0.58, 42],
    [0.74, 36.0, 0.70, 43],
    [0.81, 28.0, 0.48, 44],
    [0.86, 40.0, 0.63, 45],
    [0.92, 30.0, 0.52, 46],
    [0.97, 24.0, 0.67, 47],
  ];

  void _drawBuildings(
    Canvas canvas,
    Size size,
    List<List<Object>> buildings,
    Color bodyColor,
    Color winColor,
    double yOffset,
  ) {
    final w = size.width;
    final h = size.height;
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final winPaint = Paint()
      ..color = winColor
      ..style = PaintingStyle.fill;
    final roofPaint = Paint()
      ..color = bodyColor.withValues(alpha: 1.0)
      ..style = PaintingStyle.fill;

    for (final b in buildings) {
      final bx = (b[0] as double) * w;
      final bw = b[1] as double;
      final bh = (b[2] as double) * h;
      final seed = b[3] as int;
      final by = h - bh + yOffset;

      // Body
      canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), bodyPaint);

      // Roof line (1px brighter)
      canvas.drawRect(Rect.fromLTWH(bx, by, bw, 2), roofPaint);

      // Antenna on tall buildings
      if ((b[2] as double) > 0.75) {
        final ax = bx + bw / 2;
        canvas.drawLine(
          Offset(ax, by),
          Offset(ax, by - 10),
          Paint()
            ..color = bodyColor
            ..strokeWidth = 2,
        );
        canvas.drawCircle(Offset(ax, by - 11), 2, roofPaint);
      }

      // Windows: 3 cols, evenly spaced rows
      const cols = 2;
      const winW = 5.0;
      const winH = 5.0;
      const gapX = 6.0;
      const gapY = 9.0;
      const startY = 10.0;
      final startX = (bw - cols * winW - (cols - 1) * gapX) / 2;
      int rowIdx = 0;
      double wy = by + startY;
      while (wy + winH < by + bh - 4) {
        for (int col = 0; col < cols; col++) {
          final wx = bx + startX + col * (winW + gapX);
          final isLit = ((rowIdx * 5 + col * 3 + seed) % 5) != 0;
          if (isLit) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, winW, winH), winPaint);
          }
        }
        wy += winH + gapY;
        rowIdx++;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ─€─€ Horizon haze (bottom 30%) ─€─€
    final hazeRect = Rect.fromLTWH(0, h * 0.55, w, h * 0.45);
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFC7E2FF).withValues(alpha: 0.0),
            const Color(0xFF9CCBFF).withValues(alpha: 0.25),
          ],
        ).createShader(hazeRect),
    );

    // ─€─€ Mountain silhouette ─€─€
    final shift = cloudT * w * 0.12;
    final mPath = Path();
    mPath.moveTo(-shift, h);
    const mPoints = [0.0, 0.12, 0.22, 0.35, 0.47, 0.60, 0.72, 0.84, 0.95, 1.1];
    const mHeights = [
      0.85,
      0.52,
      0.68,
      0.40,
      0.60,
      0.48,
      0.58,
      0.44,
      0.62,
      0.85,
    ];
    for (int i = 0; i < mPoints.length - 1; i++) {
      final x1 = mPoints[i] * w - shift;
      final x2 = mPoints[i + 1] * w - shift;
      final y1 = mHeights[i] * h;
      final y2 = mHeights[i + 1] * h;
      mPath.quadraticBezierTo(x1, y1, (x1 + x2) / 2, (y1 + y2) / 2);
    }
    mPath.lineTo(w - shift + w * 0.15, h);
    mPath.close();
    canvas.drawPath(
      mPath,
      Paint()..color = const Color(0xFF1A6FD4).withValues(alpha: 0.30),
    );

    // ─€─€ Back buildings ─€─€
    _drawBuildings(
      canvas,
      size,
      _backBuildings,
      const Color(0xFF2F6FB8).withValues(alpha: 0.60),
      const Color(0xFFC7E2FF).withValues(alpha: 0.70),
      float * 0.3,
    );

    // ─€─€ Front buildings ─€─€
    _drawBuildings(
      canvas,
      size,
      _frontBuildings,
      const Color(0xFF1A6FD4),
      const Color(0xFFFEF9C3).withValues(alpha: 0.90),
      float * 0.7,
    );

    // ─€─€ Ground strip ─€─€
    canvas.drawRect(
      Rect.fromLTWH(0, h - 4, w, 4),
      Paint()..color = const Color(0xFF1A6FD4).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _SkylinePainter old) =>
      old.cloudT != cloudT || old.float != float;
}

// ignore: unused_element
class _PremiumRadarPainter extends CustomPainter {
  final Color color;
  final double sweepAngle;
  final Offset center;
  final double maxR;

  _PremiumRadarPainter(this.color, this.sweepAngle, this.center, this.maxR);

  @override
  void paint(Canvas canvas, Size size) {
    final c = center;
    final r = maxR;

    // ─€─€ Thin concentric circles ─€─€
    for (int i = 1; i <= 3; i++) {
      final ringR = r * (i / 3.0);
      canvas.drawCircle(
        c,
        ringR,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // ─€─€ Radar sweep trail (gentle scan) ─€─€
    final sweepRect = Rect.fromCircle(center: c, radius: r);
    const trailAngle = -math.pi / 2;
    canvas.drawArc(
      sweepRect,
      sweepAngle + trailAngle,
      math.pi / 2,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: sweepAngle + trailAngle,
          endAngle: sweepAngle + trailAngle + math.pi / 2,
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.02),
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.4, 0.9, 1.0],
        ).createShader(sweepRect),
    );

    // ─€─€ Leading edge ─€─€
    final sweepTip = Offset(
      c.dx + math.cos(sweepAngle) * r,
      c.dy + math.sin(sweepAngle) * r,
    );
    canvas.drawLine(
      c,
      sweepTip,
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumRadarPainter old) =>
      old.sweepAngle != sweepAngle || old.center != center;
}

// ignore: unused_element
class _RadarLinesPainter extends CustomPainter {
  final Color color;
  final List<Map<String, dynamic>> pois;
  final Offset center;
  final double maxR;
  final double floatVal;

  _RadarLinesPainter(
    this.color,
    this.pois,
    this.center,
    this.maxR,
    this.floatVal,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final c = center;
    final r = maxR;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < pois.length; i++) {
      final poi = pois[i];
      // BUGFIX (data): coerce an toàn — tránh `as double` ném TypeError khi
      // angle/radius là int/String.
      final rawAngle = poi['angle'];
      final rawRad = poi['radius'];
      final angle = rawAngle is num ? rawAngle.toDouble() : 0.0;
      final rad = rawRad is num ? rawRad.toDouble() : 0.0;

      final nodeFloatY = math.sin(floatVal * 2 * math.pi + angle) * 6;
      final dx = r * rad * math.cos(angle);
      final dy = r * rad * math.sin(angle) + nodeFloatY;

      final dest = Offset(c.dx + dx, c.dy + dy);

      // Simple straight connection line for premium minimal look
      canvas.drawLine(c, dest, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarLinesPainter old) =>
      old.floatVal != floatVal;
}

// ignore: unused_element
class _NetworkLinesPainter extends CustomPainter {
  final Color color;
  final List<({IconData icon, Color color, double angle, double r})> nodes;
  final double cx, cy, floatVal;

  _NetworkLinesPainter(this.color, this.nodes, this.cx, this.cy, this.floatVal);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final n in nodes) {
      final nodeFloatY = math.sin(floatVal * 2 * math.pi + n.angle) * 8;
      final destX = cx + math.cos(n.angle) * (size.width * n.r);
      final destY = cy + math.sin(n.angle) * (size.width * n.r) + nodeFloatY;

      final path = Path();
      path.moveTo(cx, cy); // Static center point

      // Create a smooth curved connection line instead of straight line
      final ctrlX =
          cx +
          math.cos(n.angle) * (size.width * n.r * 0.5) -
          math.sin(n.angle) * 30;
      final ctrlY =
          cy +
          math.sin(n.angle) * (size.width * n.r * 0.5) +
          math.cos(n.angle) * 30;
      path.quadraticBezierTo(ctrlX, ctrlY, destX, destY);

      _drawDashedLine(canvas, path, paint);

      // Draw a glowing data packet moving along the path
      // floatVal goes from -1 to 1, let's make a 0..1 progression
      double progress = (floatVal + 1.0) / 2.0;
      // Offset it based on angle so they don't all move in sync
      progress = (progress + (n.angle + math.pi) / (2 * math.pi)) % 1.0;

      final metrics = path.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final packetPos = metric
            .getTangentForOffset(metric.length * progress)
            ?.position;
        if (packetPos != null) {
          canvas.drawCircle(
            packetPos,
            4,
            Paint()
              ..color = n.color
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
          canvas.drawCircle(
            packetPos,
            2,
            Paint()..color = CupertinoColors.white,
          );
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0.0;
      bool draw = true;
      while (dist < metric.length) {
        final len = draw ? 6.0 : 6.0;
        if (draw) canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkLinesPainter oldDelegate) => true;
}

// ignore: unused_element
class _TechRingsPainter extends CustomPainter {
  final Color color;
  final double pulse;
  final double cx, cy, s;

  _TechRingsPainter(this.color, this.pulse, this.cx, this.cy, this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1 + pulse * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(cx, cy), s * 0.25, paint);
    canvas.drawCircle(Offset(cx, cy), s * 0.35, paint..strokeWidth = 0.5);
    canvas.drawCircle(
      Offset(cx, cy),
      s * 0.45,
      paint..color = color.withValues(alpha: 0.05),
    );

    final chPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(cx, cy - s * 0.5),
      Offset(cx, cy + s * 0.5),
      chPaint,
    );
    canvas.drawLine(
      Offset(cx - s * 0.5, cy),
      Offset(cx + s * 0.5, cy),
      chPaint,
    );
  }

  @override
  bool shouldRepaint(_TechRingsPainter oldDelegate) =>
      pulse != oldDelegate.pulse;
}

class _CTAButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final double pulseScale;

  const _CTAButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.pulseScale = 1.0,
  });

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        unawaited(HapticFeedback.lightImpact());
        unawaited(_ctrl.forward());
      },
      onTapUp: (_) {
        unawaited(HapticFeedback.selectionClick());
        unawaited(_ctrl.reverse());
        widget.onTap();
      },
      onTapCancel: () {
        unawaited(_ctrl.reverse());
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value * widget.pulseScale,
            child: child,
          );
        },
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(widget.color, CupertinoColors.white, 0.12)!,
                widget.color,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: CupertinoColors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                widget.icon,
                color: widget.textColor,
                size: 16,
                shadows: [
                  Shadow(
                    color: CupertinoColors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterAvoidanceClipper extends CustomClipper<Rect> {
  final double bottomOffset;
  _FooterAvoidanceClipper(this.bottomOffset);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      0,
      0,
      size.width,
      math.max(0, size.height - bottomOffset),
    );
  }

  @override
  bool shouldReclip(_FooterAvoidanceClipper oldClipper) =>
      oldClipper.bottomOffset != bottomOffset;
}

class _MiniQRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CupertinoColors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final double block = size.width / 5;

    // Draw 3 corner blocks
    _drawCornerBlock(canvas, paint, 0, 0, block * 1.5);
    _drawCornerBlock(canvas, paint, size.width - block * 1.5, 0, block * 1.5);
    _drawCornerBlock(canvas, paint, 0, size.height - block * 1.5, block * 1.5);

    // Draw random smaller blocks in center
    canvas.drawRect(Rect.fromLTWH(block * 2, block * 2, block, block), paint);
    canvas.drawRect(
      Rect.fromLTWH(block * 3.5, block * 2, block * 0.8, block * 0.8),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(block * 2.5, block * 3.5, block, block),
      paint,
    );
    canvas.drawRect(Rect.fromLTWH(block * 4, block * 4, block, block), paint);
  }

  void _drawCornerBlock(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double size,
  ) {
    canvas.drawRect(Rect.fromLTWH(x, y, size, size), paint);
    final innerPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x + size * 0.25, y + size * 0.25, size * 0.5, size * 0.5),
      innerPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + size * 0.4, y + size * 0.4, size * 0.2, size * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ignore: unused_element
class _RoomGridPainter extends CustomPainter {
  final Color color;
  _RoomGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    final step = size.width / 8;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ignore: unused_element
class _SpeedLinesPainter extends CustomPainter {
  final double t; // 0 to 1
  final Color color;
  final bool isScanning;

  _SpeedLinesPainter(this.t, this.color, this.isScanning);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isScanning) return; // Don't draw hyperdrive lines when matched

    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..strokeWidth = 2.0;

    // Draw 24 lines radiating outwards
    for (int i = 0; i < 24; i++) {
      double angle = (i * math.pi * 2) / 24;

      // Calculate radial position based on time t.
      // Each line has a different phase offset based on its index.
      double phase = (i * 0.137 + t * 2.0) % 1.0;

      // r1 is start of line, r2 is end of line
      double r1 = phase * size.width * 0.8;
      double r2 =
          r1 + 20 + phase * 80; // lines stretch longer as they go outwards

      // Opacity fades in at center and fades out at edges
      double opacity = math.sin(phase * math.pi);
      paint.color = color.withValues(alpha: opacity * 0.4);

      canvas.drawLine(
        Offset(cx + math.cos(angle) * r1, cy + math.sin(angle) * r1),
        Offset(cx + math.cos(angle) * r2, cy + math.sin(angle) * r2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedLinesPainter old) =>
      old.t != t || old.isScanning != isScanning;
}
