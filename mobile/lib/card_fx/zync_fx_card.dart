import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'card_fx_spec.dart';

class ZyncFxCard extends StatefulWidget {
  const ZyncFxCard({
    super.key,
    required this.spec,
    this.tuning = const ZyncFxTuning(),
    this.enableDragTilt = true,
    this.revealImpact = 0.0,
    this.respectReduceMotion = true,
  });

  final ZyncFxCardSpec spec;
  final ZyncFxTuning tuning;
  final bool enableDragTilt;

  /// 0 = calm inspect state, 1 = peak reveal hit.
  final double revealImpact;

  /// Keep true in production. The isolated FX Lab sets this false so system
  /// accessibility settings cannot silently disable the animation preview.
  final bool respectReduceMotion;

  @override
  State<ZyncFxCard> createState() => _ZyncFxCardState();
}

class _ZyncFxCardState extends State<ZyncFxCard> with TickerProviderStateMixin {
  late final AnimationController _surfaceController;
  late final AnimationController _settleController;
  Offset _tilt = Offset.zero;
  Offset _settleFrom = Offset.zero;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    final animationBehavior = widget.respectReduceMotion
        ? AnimationBehavior.normal
        : AnimationBehavior.preserve;
    _surfaceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
      animationBehavior: animationBehavior,
    )..addListener(_tick);
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      animationBehavior: animationBehavior,
    )..addListener(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = widget.respectReduceMotion &&
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (reduceMotion) {
      _surfaceController.stop();
      _surfaceController.value = 0.28;
    } else if (!_surfaceController.isAnimating) {
      _surfaceController.repeat();
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _surfaceController
      ..removeListener(_tick)
      ..dispose();
    _settleController
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  Offset get _displayTilt {
    if (_dragging) return _tilt;
    if (!_settleController.isAnimating && _settleController.value == 0) {
      return _tilt;
    }
    final t = Curves.easeOutCubic.transform(_settleController.value);
    return Offset.lerp(_settleFrom, Offset.zero, t) ?? Offset.zero;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enableDragTilt) return;
    _settleController.stop();
    _dragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableDragTilt) return;
    final next = Offset(
      (_tilt.dx + details.delta.dx / 92).clamp(-1.0, 1.0),
      (_tilt.dy + details.delta.dy / 92).clamp(-1.0, 1.0),
    );
    setState(() => _tilt = next);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableDragTilt) return;
    _dragging = false;
    _settleFrom = _tilt;
    _tilt = Offset.zero;
    _settleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final profile = spec.profile;
    final tilt = _displayTilt;
    final maxTilt = profile.maxTiltDegrees * widget.tuning.tilt;
    final rx = -tilt.dy * maxTilt * math.pi / 180;
    final ry = tilt.dx * maxTilt * math.pi / 180;
    final impact = widget.revealImpact.clamp(0.0, 1.0);

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0013)
      ..rotateX(rx)
      ..rotateY(ry);

    final glowStrength = (profile.edgeGlowOpacity * widget.tuning.glow +
            impact * profile.revealImpact * 0.28)
        .clamp(0.0, 0.88);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails(primaryVelocity: 0)),
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  blurRadius: 28 + impact * 22,
                  spreadRadius: 1 + impact * 5,
                  color: profile.accentColor.withValues(alpha: glowStrength),
                ),
                BoxShadow(
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                  color: Colors.black.withValues(alpha: 0.34),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFF0D1119)),
                      _artwork(size, tilt),
                      _ambient(size, tilt),
                      _foil(size, tilt),
                      _frame(size),
                      _labels(size),
                      _revealBurst(size, impact),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _artwork(Size size, Offset tilt) {
    final profile = widget.spec.profile;
    final geometry = ZyncFrameGeometry.forRarity(widget.spec.rarity);
    final window = geometry.artworkWindow(size);
    final depth = profile.parallaxPixels * widget.tuning.parallax;
    final dx = tilt.dx * depth;
    final dy = tilt.dy * depth;
    final parallaxScale = 1.10 + widget.tuning.parallax.clamp(0.0, 1.8) * 0.02;

    return Positioned.fromRect(
      rect: window,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size.width * 0.040),
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: parallaxScale,
            child: Image.asset(
              widget.spec.artworkAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }

  Widget _ambient(Size size, Offset tilt) {
    if (widget.spec.ambientFx == ZyncAmbientFx.none ||
        widget.tuning.ambient <= 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _AmbientFxPainter(
          fx: widget.spec.ambientFx,
          progress: _surfaceController.value,
          intensity: widget.tuning.ambient,
          tilt: tilt,
          accent: widget.spec.profile.accentColor,
        ),
      ),
    );
  }

  Widget _foil(Size size, Offset tilt) {
    final profile = widget.spec.profile;
    final opacity = (profile.foilOpacity * widget.tuning.foil).clamp(0.0, 0.55);
    if (opacity <= 0.002) return const SizedBox.shrink();

    final sweep = -1.65 +
        _surfaceController.value * 3.30 +
        tilt.dx * 0.48 -
        tilt.dy * 0.18;

    final geometry = ZyncFrameGeometry.forRarity(widget.spec.rarity);
    final window = geometry.artworkWindow(size);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fromRect(
            rect: window,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size.width * 0.040),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(sweep - 0.9, -0.9),
                    end: Alignment(sweep + 0.9, 0.9),
                    colors: [
                      Colors.transparent,
                      profile.secondaryColor.withValues(alpha: opacity * 0.44),
                      Colors.white.withValues(alpha: opacity),
                      profile.accentColor.withValues(alpha: opacity * 0.74),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.30, 0.48, 0.66, 1.0],
                  ),
                ),
              ),
            ),
          ),
          if (widget.spec.rarity.index >= ZyncFxRarity.rare.index)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + tilt.dx * 0.4, -0.85),
                  end: Alignment(1 + tilt.dx * 0.4, 0.85),
                  colors: [
                    Colors.transparent,
                    profile.accentColor.withValues(alpha: opacity * 0.18),
                    profile.secondaryColor.withValues(alpha: opacity * 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _frame(Size size) {
    return IgnorePointer(
      child: Image.asset(
        widget.spec.resolvedFrameAsset,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          painter: _FrameFallbackPainter(profile: widget.spec.profile),
        ),
      ),
    );
  }

  Widget _labels(Size size) {
    final profile = widget.spec.profile;
    // All locked masters use a light/silver information panel. Dark copy keeps
    // the title readable instead of letting white text disappear into it.
    const titleColor = Color(0xFF101722);
    final subColor = const Color(0xFF101722).withValues(alpha: 0.68);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: size.width * 0.115,
            right: size.width * 0.30,
            top: size.height * 0.775,
            child: Text(
              widget.spec.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: size.width * 0.068,
                height: 1.0,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Positioned(
            left: size.width * 0.115,
            right: size.width * 0.30,
            top: size.height * 0.835,
            child: Text(
              widget.spec.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subColor,
                fontSize: size.width * 0.029,
                height: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            left: size.width * 0.761,
            top: size.height * 0.773,
            width: size.width * 0.125,
            height: size.width * 0.125,
            child: Center(
              child: Icon(
                _ambientIcon(widget.spec.ambientFx),
                color: profile.rarity == ZyncFxRarity.epic
                    ? profile.secondaryColor
                    : const Color(0xFF202733),
                size: size.width * 0.058,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revealBurst(Size size, double impact) {
    if (impact <= 0.001 || widget.spec.profile.particleCount == 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _RevealBurstPainter(
          impact: impact,
          count: (widget.spec.profile.particleCount * widget.tuning.particles)
              .round(),
          accent: widget.spec.profile.accentColor,
          secondary: widget.spec.profile.secondaryColor,
        ),
      ),
    );
  }

  IconData _ambientIcon(ZyncAmbientFx fx) => switch (fx) {
        ZyncAmbientFx.steam => Icons.coffee_rounded,
        ZyncAmbientFx.digitalPulse => Icons.hub_rounded,
        ZyncAmbientFx.dust => Icons.auto_stories_rounded,
        ZyncAmbientFx.none => Icons.auto_awesome_rounded,
      };
}

class _FrameFallbackPainter extends CustomPainter {
  const _FrameFallbackPainter({required this.profile});

  final ZyncCardFxProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.058),
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.042
      ..color = profile.frameColor.withValues(alpha: 0.98);
    canvas.drawRRect(outer.deflate(size.width * 0.022), base);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.009
      ..color = profile.accentColor.withValues(alpha: 0.86);
    canvas.drawRRect(outer.deflate(size.width * 0.048), edge);

    final topLeft = Path()
      ..moveTo(size.width * 0.060, size.height * 0.034)
      ..lineTo(size.width * 0.455, size.height * 0.034)
      ..lineTo(size.width * 0.390, size.height * 0.112)
      ..lineTo(size.width * 0.060, size.height * 0.112)
      ..close();
    canvas.drawPath(
      topLeft,
      Paint()..color = const Color(0xFF121A25).withValues(alpha: 0.96),
    );
    _paintText(
      canvas,
      'Zync',
      Offset(size.width * 0.105, size.height * 0.052),
      size.width * 0.055,
      Colors.white,
      FontWeight.w800,
    );

    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.718,
        size.height * 0.040,
        size.width * 0.225,
        size.height * 0.066,
      ),
      Radius.circular(size.width * 0.030),
    );
    canvas.drawRRect(
      pill,
      Paint()..color = const Color(0xFF121A25).withValues(alpha: 0.96),
    );
    canvas.drawRRect(
      pill,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.006
        ..color = profile.accentColor.withValues(alpha: 0.92),
    );
    _paintText(
      canvas,
      profile.label,
      Offset(size.width * 0.741, size.height * 0.057),
      size.width * 0.030,
      profile.secondaryColor,
      FontWeight.w800,
    );

    final info = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.058,
        size.height * 0.748,
        size.width * 0.884,
        size.height * 0.193,
      ),
      Radius.circular(size.width * 0.040),
    );
    final infoColor = profile.rarity == ZyncFxRarity.epic
        ? const Color(0xFF172233)
        : const Color(0xFFE9EDF1);
    canvas.drawRRect(info, Paint()..color = infoColor.withValues(alpha: 0.98));
    canvas.drawRRect(
      info,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.006
        ..color = profile.accentColor.withValues(alpha: 0.66),
    );

    final separator = Paint()
      ..color = profile.accentColor.withValues(alpha: 0.48)
      ..strokeWidth = size.width * 0.004;
    canvas.drawLine(
      Offset(size.width * 0.090, size.height * 0.895),
      Offset(size.width * 0.725, size.height * 0.895),
      separator,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _FrameFallbackPainter oldDelegate) =>
      oldDelegate.profile.rarity != profile.rarity;
}

class _AmbientFxPainter extends CustomPainter {
  const _AmbientFxPainter({
    required this.fx,
    required this.progress,
    required this.intensity,
    required this.tilt,
    required this.accent,
  });

  final ZyncAmbientFx fx;
  final double progress;
  final double intensity;
  final Offset tilt;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    switch (fx) {
      case ZyncAmbientFx.dust:
        _dust(canvas, size);
      case ZyncAmbientFx.steam:
        _steam(canvas, size);
      case ZyncAmbientFx.digitalPulse:
        _digital(canvas, size);
      case ZyncAmbientFx.none:
        break;
    }
  }

  void _dust(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24 * intensity);
    for (var i = 0; i < 18; i++) {
      final phase = (progress + i * 0.083) % 1.0;
      final x = size.width * (0.11 + ((i * 37) % 77) / 100) + tilt.dx * 4;
      final y = size.height * (0.66 - phase * 0.46);
      final r = size.width * (0.0028 + (i % 4) * 0.0014);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _steam(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i * 0.27) % 1.0;
      final fade =
          math.pow(math.sin(phase * math.pi).clamp(0.0, 1.0), 1.5).toDouble();
      if (fade < 0.02) continue;

      final drift = math.sin(progress * math.pi * 2 + i * 1.9);
      final baseX = size.width * (0.555 + i * 0.030) +
          drift * size.width * 0.010 +
          tilt.dx * 2.0;
      final baseY = size.height * (0.355 - phase * 0.035);
      final rise = size.height * (0.105 + phase * 0.055);
      final sway = size.width * (0.014 + (i % 2) * 0.006);
      final topY = baseY - rise;

      final path = Path()
        ..moveTo(baseX, baseY)
        ..cubicTo(
          baseX - sway,
          baseY - rise * 0.30,
          baseX + sway * 1.2,
          baseY - rise * 0.68,
          baseX + drift * size.width * 0.012,
          topY,
        );

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.11 * intensity * fade)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = size.width * 0.010
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.006);
      canvas.drawPath(path, paint);
    }
  }

  void _digital(Canvas canvas, Size size) {
    final nodes = <Offset>[
      Offset(size.width * 0.26, size.height * 0.29),
      Offset(size.width * 0.42, size.height * 0.21),
      Offset(size.width * 0.56, size.height * 0.34),
      Offset(size.width * 0.70, size.height * 0.24),
      Offset(size.width * 0.77, size.height * 0.43),
      Offset(size.width * 0.49, size.height * 0.51),
      Offset(size.width * 0.30, size.height * 0.47),
    ];
    final pulse = 0.45 + 0.55 * math.sin(progress * math.pi * 2).abs();
    final line = Paint()
      ..color = accent.withValues(alpha: 0.18 * intensity * pulse)
      ..strokeWidth = size.width * 0.004;
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], line);
    }
    canvas.drawLine(nodes.last, nodes.first, line);
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.42 * intensity * pulse);
    for (final node in nodes) {
      canvas.drawCircle(node, size.width * 0.009, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientFxPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.tilt != tilt ||
      oldDelegate.fx != fx;
}

class _RevealBurstPainter extends CustomPainter {
  const _RevealBurstPainter({
    required this.impact,
    required this.count,
    required this.accent,
    required this.secondary,
  });

  final double impact;
  final int count;
  final Color accent;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.48);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.010
      ..color = accent.withValues(alpha: 0.34 * impact);
    canvas.drawCircle(center, size.width * (0.22 + (1 - impact) * 0.34), ring);

    for (var i = 0; i < count; i++) {
      final angle = (i / math.max(1, count)) * math.pi * 2 + i * 0.31;
      final travel = size.width * (0.16 + (i % 7) * 0.025) * impact;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * travel;
      final paint = Paint()
        ..color = (i.isEven ? accent : secondary).withValues(
          alpha: 0.70 * impact,
        );
      canvas.drawCircle(point, size.width * (0.004 + (i % 3) * 0.002), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RevealBurstPainter oldDelegate) =>
      oldDelegate.impact != impact ||
      oldDelegate.count != count ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary;
}
