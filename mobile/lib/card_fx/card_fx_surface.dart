import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/cardverse_models.dart';
import 'card_fx_profile.dart';

class ZyncCardFxSurface extends StatefulWidget {
  const ZyncCardFxSurface({
    super.key,
    required this.child,
    required this.finish,
    this.ambientFx = CardAmbientFx.none,
    this.interactive = true,
    this.effectIntensity = 1,
    this.tiltStrength = 1,
  });

  final Widget child;
  final CardFinishTier finish;
  final CardAmbientFx ambientFx;
  final bool interactive;
  final double effectIntensity;
  final double tiltStrength;

  @override
  State<ZyncCardFxSurface> createState() => _ZyncCardFxSurfaceState();
}

class _ZyncCardFxSurfaceState extends State<ZyncCardFxSurface>
    with TickerProviderStateMixin {
  late final AnimationController _motionController;
  late final AnimationController _settleController;

  Offset _tilt = Offset.zero;
  Offset _settleFrom = Offset.zero;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        final eased = Curves.easeOutCubic.transform(_settleController.value);
        setState(() => _tilt = Offset.lerp(_settleFrom, Offset.zero, eased)!);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _motionController.stop();
      _motionController.value = 0.42;
    } else if (!_motionController.isAnimating) {
      _motionController.repeat();
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  void _setTilt(Offset localPosition, Size size) {
    if (!widget.interactive || size.width <= 0 || size.height <= 0) return;
    _settleController.stop();
    final x = ((localPosition.dx / size.width) * 2 - 1)
        .clamp(-1.0, 1.0)
        .toDouble();
    final y = ((localPosition.dy / size.height) * 2 - 1)
        .clamp(-1.0, 1.0)
        .toDouble();
    setState(() => _tilt = Offset(x, y));
  }

  void _settle() {
    if (!widget.interactive) return;
    _settleFrom = _tilt;
    _settleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final profile = CardFxProfile.forFinish(widget.finish);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final intensity = widget.effectIntensity.clamp(0.0, 1.5).toDouble();
    final tiltStrength = widget.tiltStrength.clamp(0.0, 1.5).toDouble();
    final glowColor = profile.glowColors.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rx = -_tilt.dy * profile.maxTiltRadians * tiltStrength;
        final ry = _tilt.dx * profile.maxTiltRadians * tiltStrength;
        final parallax = Offset(
          _tilt.dx * profile.parallaxPixels * tiltStrength,
          _tilt.dy * profile.parallaxPixels * tiltStrength,
        );

        return GestureDetector(
          key: const ValueKey('card-fx-interactive-surface'),
          behavior: HitTestBehavior.opaque,
          onPanDown: widget.interactive
              ? (details) => _setTilt(details.localPosition, size)
              : null,
          onPanUpdate: widget.interactive
              ? (details) => _setTilt(details.localPosition, size)
              : null,
          onPanEnd: widget.interactive ? (_) => _settle() : null,
          onPanCancel: widget.interactive ? _settle : null,
          child: AnimatedBuilder(
            animation: _motionController,
            builder: (context, _) {
              final progress = reduceMotion ? 0.42 : _motionController.value;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(rx)
                  ..rotateY(ry),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: profile.edgeGlowOpacity * intensity,
                        ),
                        blurRadius: 18 + profile.edgeGlowOpacity * 28,
                        spreadRadius: profile.edgeGlowOpacity * 2,
                        offset: Offset(_tilt.dx * 4, _tilt.dy * 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Transform.translate(
                          offset: parallax,
                          child: Transform.scale(
                            scale: 1.018,
                            child: widget.child,
                          ),
                        ),
                        if (profile.hasFoil)
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _FoilPainter(
                                profile: profile,
                                progress: progress,
                                tilt: _tilt,
                                intensity: intensity,
                              ),
                            ),
                          ),
                        if (widget.ambientFx != CardAmbientFx.none)
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _AmbientPainter(
                                effect: widget.ambientFx,
                                progress: progress,
                                intensity: intensity,
                                color: profile.glowColors.last,
                              ),
                            ),
                          ),
                        if (profile.hasParticles)
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _ParticlePainter(
                                progress: progress,
                                count: profile.particleCount,
                                intensity: intensity,
                                colors: profile.glowColors,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ZyncCardReveal extends StatefulWidget {
  const ZyncCardReveal({
    super.key,
    required this.front,
    required this.finish,
    this.back,
    this.ambientFx = CardAmbientFx.none,
    this.effectIntensity = 1,
    this.tiltStrength = 1,
    this.enableHaptics = true,
  });

  final Widget front;
  final Widget? back;
  final CardFinishTier finish;
  final CardAmbientFx ambientFx;
  final double effectIntensity;
  final double tiltStrength;
  final bool enableHaptics;

  @override
  State<ZyncCardReveal> createState() => _ZyncCardRevealState();
}

class _ZyncCardRevealState extends State<ZyncCardReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _impactHapticFired = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final profile = CardFxProfile.forFinish(widget.finish);
    _controller = AnimationController(
      vsync: this,
      duration: profile.revealDuration,
    )..addListener(_handleRevealTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _handleRevealTick() {
    if (!_impactHapticFired && _controller.value >= 0.58) {
      _impactHapticFired = true;
      if (widget.enableHaptics) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleRevealTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = CardFxProfile.forFinish(widget.finish);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p = _controller.value;
        final lift = Curves.easeOutCubic.transform(
          (p / 0.34).clamp(0.0, 1.0).toDouble(),
        );
        final flip = Curves.easeInOutCubic.transform(
          (p / 0.62).clamp(0.0, 1.0).toDouble(),
        );
        final angle = math.pi * flip;
        final showFront = angle >= math.pi / 2;
        final faceAngle = showFront ? angle - math.pi : angle;
        final settle = Curves.easeOutBack.transform(
          ((p - 0.56) / 0.44).clamp(0.0, 1.0).toDouble(),
        );
        final impactWindow = ((p - 0.56) / 0.24)
            .clamp(0.0, 1.0)
            .toDouble();
        final impactPulse = math.sin(impactWindow * math.pi);
        final scale = 0.88 +
            lift * 0.12 +
            impactPulse * (profile.impactScale - 1);
        final translateY = (1 - lift) * 28 - settle * 3;

        final face = showFront
            ? ZyncCardFxSurface(
                finish: widget.finish,
                ambientFx: widget.ambientFx,
                effectIntensity: widget.effectIntensity,
                tiltStrength: widget.tiltStrength,
                interactive: p >= 0.98,
                child: widget.front,
              )
            : (widget.back ?? const _DefaultCardBack());

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (p >= 0.52 && profile.hasParticles)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RevealBurstPainter(
                      progress: ((p - 0.52) / 0.48)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      colors: profile.glowColors,
                      intensity: widget.effectIntensity,
                      count: profile.particleCount + 4,
                    ),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(faceAngle),
                  child: face,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DefaultCardBack extends StatelessWidget {
  const _DefaultCardBack();

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 5 / 7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF19172B),
                Color(0xFF423568),
                Color(0xFF173E4A),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _CardBackPatternPainter()),
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.42),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Z',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _FoilPainter extends CustomPainter {
  const _FoilPainter({
    required this.profile,
    required this.progress,
    required this.tilt,
    required this.intensity,
  });

  final CardFxProfile profile;
  final double progress;
  final Offset tilt;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sweep = ((progress * 2) - 1) + tilt.dx * 0.55;
    final colors = <Color>[
      Colors.transparent,
      for (final color in profile.glowColors)
        color.withValues(alpha: profile.foilOpacity * intensity),
      Colors.white.withValues(
        alpha: profile.foilOpacity * 0.85 * intensity,
      ),
      Colors.transparent,
    ];
    final stops = List<double>.generate(
      colors.length,
      (index) => index / (colors.length - 1),
    );

    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment(sweep - 1.0, -1 + tilt.dy * 0.35),
        end: Alignment(sweep + 1.0, 1 + tilt.dy * 0.35),
        colors: colors,
        stops: stops,
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final highlight = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        center: Alignment(
          (tilt.dx * 0.7).clamp(-1.0, 1.0).toDouble(),
          (tilt.dy * 0.7).clamp(-1.0, 1.0).toDouble(),
        ),
        radius: 0.72,
        colors: [
          Colors.white.withValues(
            alpha: profile.foilOpacity * 0.72 * intensity,
          ),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, highlight);
  }

  @override
  bool shouldRepaint(covariant _FoilPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.tilt != tilt ||
      oldDelegate.intensity != intensity ||
      oldDelegate.profile != profile;
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({
    required this.effect,
    required this.progress,
    required this.intensity,
    required this.color,
  });

  final CardAmbientFx effect;
  final double progress;
  final double intensity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    switch (effect) {
      case CardAmbientFx.none:
        return;
      case CardAmbientFx.dust:
        _paintDust(canvas, size);
        return;
      case CardAmbientFx.steam:
        _paintSteam(canvas, size);
        return;
      case CardAmbientFx.digitalPulse:
        _paintDigital(canvas, size);
        return;
      case CardAmbientFx.embers:
        _paintEmbers(canvas, size);
        return;
      case CardAmbientFx.waterCaustic:
        _paintWater(canvas, size);
        return;
    }
  }

  void _paintDust(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    for (var i = 0; i < 14; i++) {
      final phase = (progress + i * 0.071) % 1.0;
      final x = size.width * (0.08 + ((i * 31) % 83) / 100);
      final y = size.height * (0.78 - phase * 0.62);
      final opacity = math.sin(phase * math.pi).abs() * 0.24 * intensity;
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.55, paint);
    }
  }

  void _paintSteam(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..blendMode = BlendMode.screen
      ..color = Colors.white.withValues(alpha: 0.22 * intensity);

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i * 0.19) % 1.0;
      final baseX = size.width * (0.55 + i * 0.08);
      final baseY = size.height * (0.70 - phase * 0.04);
      final path = Path()
        ..moveTo(baseX, baseY)
        ..cubicTo(
          baseX - size.width * 0.08,
          baseY - size.height * 0.09,
          baseX + size.width * 0.09,
          baseY - size.height * 0.16,
          baseX - size.width * 0.01,
          baseY - size.height * 0.26,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _paintDigital(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.screen
      ..color = color.withValues(alpha: 0.26 * intensity);
    final nodes = <Offset>[];
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + progress * 0.45;
      final radius = size.width * (0.12 + (i % 3) * 0.035);
      nodes.add(
        Offset(
          size.width * 0.52 + math.cos(angle) * radius,
          size.height * 0.42 + math.sin(angle) * radius,
        ),
      );
    }
    for (var i = 0; i < nodes.length; i++) {
      canvas.drawLine(nodes[i], nodes[(i + 3) % nodes.length], paint);
      canvas.drawCircle(nodes[i], 3 + (i % 2), paint);
    }
  }

  void _paintEmbers(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    for (var i = 0; i < 12; i++) {
      final phase = (progress + i * 0.083) % 1.0;
      final x = size.width * (0.15 + ((i * 43) % 70) / 100);
      final y = size.height * (0.88 - phase * 0.70);
      paint.color = const Color(0xFFFFA640).withValues(
        alpha: math.sin(phase * math.pi).abs() * 0.45 * intensity,
      );
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.7, paint);
    }
  }

  void _paintWater(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..blendMode = BlendMode.screen
      ..color = const Color(0xFF9CEBFF).withValues(
        alpha: 0.20 * intensity,
      );
    for (var i = 0; i < 5; i++) {
      final phase = (progress + i * 0.13) % 1.0;
      final center = Offset(
        size.width * (0.18 + i * 0.17),
        size.height * (0.38 + math.sin(phase * math.pi * 2) * 0.05),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width * (0.18 + phase * 0.08),
          height: size.height * 0.05,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.effect != effect ||
      oldDelegate.color != color;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.progress,
    required this.count,
    required this.intensity,
    required this.colors,
  });

  final double progress;
  final int count;
  final double intensity;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    for (var i = 0; i < count; i++) {
      final phase = (progress + i * 0.097) % 1.0;
      final x = size.width * (0.08 + ((i * 37) % 84) / 100);
      final y = size.height * (0.12 + phase * 0.70);
      final opacity = math.sin(phase * math.pi).abs() * 0.34 * intensity;
      paint.color = colors[i % colors.length].withValues(alpha: opacity);
      final center = Offset(x, y);
      final r = 1.4 + (i % 4) * 0.65;
      canvas.drawCircle(center, r, paint);
      if (i % 3 == 0) {
        canvas.drawLine(
          Offset(center.dx - r * 2, center.dy),
          Offset(center.dx + r * 2, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - r * 2),
          Offset(center.dx, center.dy + r * 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.count != count ||
      oldDelegate.intensity != intensity ||
      oldDelegate.colors != colors;
}

class _RevealBurstPainter extends CustomPainter {
  const _RevealBurstPainter({
    required this.progress,
    required this.colors,
    required this.intensity,
    required this.count,
  });

  final double progress;
  final List<Color> colors;
  final double intensity;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = 1 - progress;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.screen;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + i * 0.21;
      final distance = size.shortestSide * (0.08 + eased * 0.55);
      final start = center +
          Offset(math.cos(angle), math.sin(angle)) * (distance * 0.58);
      final end = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      paint
        ..strokeWidth = 1.2 + (i % 3) * 0.7
        ..color = colors[i % colors.length].withValues(
          alpha: fade * 0.72 * intensity,
        );
      canvas.drawLine(start, end, paint);
      canvas.drawCircle(end, 1.8 + (i % 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RevealBurstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.count != count ||
      oldDelegate.colors != colors;
}

class _CardBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);
    final step = size.width / 8;
    for (var i = -4; i < 14; i++) {
      final dx = i * step;
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardBackPatternPainter oldDelegate) => false;
}
