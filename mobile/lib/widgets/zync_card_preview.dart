import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/card_visual_recipe.dart';
import '../core/cardverse_models.dart';

class ZyncCardPreview extends StatelessWidget {
  const ZyncCardPreview({
    super.key,
    required this.recipe,
    required this.title,
    this.subtitle = '',
    this.finish = CardFinishTier.normal,
    this.editionLabel = 'CORE',
    this.cardNumberLabel,
    this.animateFinish = false,
  });

  final CardVisualRecipe recipe;
  final String title;
  final String subtitle;
  final CardFinishTier finish;
  final String editionLabel;
  final String? cardNumberLabel;

  /// Grid/binder previews keep this false. Enable only for a focused card.
  final bool animateFinish;

  @override
  Widget build(BuildContext context) {
    final palette = _CardPalette.forRecipe(recipe);

    return AspectRatio(
      aspectRatio: 5 / 7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _CardScenePainter(
                  recipe: recipe,
                  palette: palette,
                ),
              ),
              _CardFinishOverlay(
                finish: finish,
                palette: palette,
                animate: animateFinish,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EditionSeal(
                          label: editionLabel,
                          foreground: palette.ink,
                          background: Colors.white.withValues(alpha: 0.78),
                        ),
                        const Spacer(),
                        if (cardNumberLabel != null)
                          Text(
                            cardNumberLabel!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: palette.ink.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: palette.ink,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                          ),
                          if (subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: palette.ink.withValues(alpha: 0.68),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      width: finish == CardFinishTier.legendary ? 4 : 2,
                      color: _borderColor(palette),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _borderColor(_CardPalette palette) => switch (finish) {
        CardFinishTier.normal => palette.ink.withValues(alpha: 0.24),
        CardFinishTier.foil => Colors.white.withValues(alpha: 0.72),
        CardFinishTier.holo => palette.accent.withValues(alpha: 0.82),
        CardFinishTier.prism => palette.secondary.withValues(alpha: 0.86),
        CardFinishTier.legendary => Colors.white.withValues(alpha: 0.92),
        CardFinishTier.secret => palette.ink.withValues(alpha: 0.82),
      };
}

class _CardFinishOverlay extends StatefulWidget {
  const _CardFinishOverlay({
    required this.finish,
    required this.palette,
    required this.animate,
  });

  final CardFinishTier finish;
  final _CardPalette palette;
  final bool animate;

  @override
  State<_CardFinishOverlay> createState() => _CardFinishOverlayState();
}

class _CardFinishOverlayState extends State<_CardFinishOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _supportsMotion =>
      widget.finish == CardFinishTier.holo ||
      widget.finish == CardFinishTier.prism ||
      widget.finish == CardFinishTier.legendary ||
      widget.finish == CardFinishTier.secret;

  bool get _motionEnabled {
    final media = MediaQuery.maybeOf(context);
    return widget.animate &&
        _supportsMotion &&
        !(media?.disableAnimations ?? false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant _CardFinishOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController();
  }

  void _syncController() {
    if (_motionEnabled) {
      final controller = _controller ??=
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 2400),
          );
      if (!controller.isAnimating) {
        controller.repeat();
      }
    } else {
      _controller?.stop();
      _controller?.value = 0.42;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.finish == CardFinishTier.normal) {
      return const SizedBox.shrink();
    }

    if (!_motionEnabled || _controller == null) {
      return IgnorePointer(
        key: const ValueKey('card-finish-static'),
        child: _StaticFinishLayer(
          finish: widget.finish,
          palette: widget.palette,
          progress: 0.42,
        ),
      );
    }

    return IgnorePointer(
      key: const ValueKey('card-finish-animated'),
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, _) => _StaticFinishLayer(
          finish: widget.finish,
          palette: widget.palette,
          progress: _controller!.value,
        ),
      ),
    );
  }
}

class _StaticFinishLayer extends StatelessWidget {
  const _StaticFinishLayer({
    required this.finish,
    required this.palette,
    required this.progress,
  });

  final CardFinishTier finish;
  final _CardPalette palette;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final opacity = switch (finish) {
      CardFinishTier.foil => 0.14,
      CardFinishTier.holo => 0.22,
      CardFinishTier.prism => 0.30,
      CardFinishTier.legendary => 0.36,
      CardFinishTier.secret => 0.42,
      CardFinishTier.normal => 0.0,
    };
    final sweep = -1.6 + progress * 3.2;
    final secondarySweep = 1.2 - progress * 2.4;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(sweep - 1.0, -0.9),
              end: Alignment(sweep + 1.0, 0.9),
              colors: [
                Colors.white.withValues(alpha: 0),
                palette.accent.withValues(alpha: opacity * 0.82),
                Colors.white.withValues(alpha: opacity),
                palette.secondary.withValues(alpha: opacity * 0.88),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.24, 0.48, 0.72, 1.0],
            ),
          ),
        ),
        if (finish == CardFinishTier.prism ||
            finish == CardFinishTier.legendary ||
            finish == CardFinishTier.secret)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(secondarySweep, -0.25),
                radius: 0.78,
                colors: [
                  Colors.white.withValues(alpha: opacity * 0.74),
                  palette.accent.withValues(alpha: opacity * 0.28),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
        if (finish == CardFinishTier.legendary ||
            finish == CardFinishTier.secret)
          CustomPaint(
            painter: _FinishSparkPainter(
              progress: progress,
              color: Colors.white.withValues(alpha: opacity * 1.5),
            ),
          ),
      ],
    );
  }
}

class _FinishSparkPainter extends CustomPainter {
  const _FinishSparkPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, size.width * 0.008).toDouble();

    for (var i = 0; i < 9; i++) {
      final phase = (progress + i * 0.137) % 1.0;
      final x = size.width * (0.10 + ((i * 37) % 79) / 100);
      final y = size.height * (0.10 + phase * 0.54);
      final radius = size.width * (0.010 + (i % 3) * 0.004);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FinishSparkPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _EditionSeal extends StatelessWidget {
  const _EditionSeal({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
        ),
      );
}

class _CardScenePainter extends CustomPainter {
  const _CardScenePainter({
    required this.recipe,
    required this.palette,
  });

  final CardVisualRecipe recipe;
  final _CardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.background,
          palette.secondary,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final seed = int.tryParse(recipe.visualSeed, radix: 16) ?? 1;
    _drawPattern(canvas, size, seed);

    switch (recipe.categoryKit) {
      case 'sports':
        _drawSports(canvas, size, seed);
      case 'outdoors':
        _drawOutdoors(canvas, size, seed);
      case 'food':
        _drawFood(canvas, size, seed);
      case 'entertainment':
        _drawCinema(canvas, size, seed);
      case 'music':
        _drawMusic(canvas, size, seed);
      case 'gaming':
        _drawGaming(canvas, size, seed);
      case 'learning':
        _drawLearning(canvas, size, seed);
      case 'arts':
        _drawArts(canvas, size, seed);
      case 'crafts':
        _drawCrafts(canvas, size, seed);
      case 'wellness':
        _drawWellness(canvas, size, seed);
      default:
        _drawAbstract(canvas, size, seed);
    }
  }

  void _drawPattern(Canvas canvas, Size size, int seed) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final gap = size.width / (7 + seed % 3);
    for (var x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  void _drawSports(Canvas canvas, Size size, int seed) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.width * 0.012).toDouble();

    final court = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.18,
        size.width * 0.76,
        size.height * 0.50,
      ),
      Radius.circular(size.width * 0.05),
    );
    canvas.drawRRect(court, line);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.18),
      Offset(size.width * 0.5, size.height * 0.68),
      line,
    );

    final arcPaint = Paint()
      ..color = palette.accent.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.055;
    final arc = Rect.fromCircle(
      center: Offset(size.width * 0.54, size.height * 0.38),
      radius: size.width * 0.31,
    );
    canvas.drawArc(arc, math.pi * 1.08, math.pi * 0.78, false, arcPaint);

    final ball = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(
      Offset(size.width * (0.35 + (seed % 20) / 100), size.height * 0.34),
      size.width * 0.08,
      ball,
    );
  }

  void _drawOutdoors(Canvas canvas, Size size, int seed) {
    final layers = [
      palette.accent.withValues(alpha: 0.66),
      palette.ink.withValues(alpha: 0.34),
      Colors.white.withValues(alpha: 0.20),
    ];

    for (var i = 0; i < layers.length; i++) {
      final baseY = size.height * (0.62 - i * 0.08);
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(0, baseY)
        ..lineTo(size.width * 0.20, baseY - size.height * 0.12)
        ..lineTo(size.width * 0.40, baseY + size.height * 0.01)
        ..lineTo(size.width * 0.63, baseY - size.height * 0.18)
        ..lineTo(size.width * 0.86, baseY - size.height * 0.04)
        ..lineTo(size.width, baseY - size.height * 0.10)
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = layers[i]);
    }

    final route = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.69)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.58,
        size.width * 0.52,
        size.height * 0.53,
        size.width * 0.72,
        size.height * 0.28,
      );
    canvas.drawPath(path, route);
  }

  void _drawFood(Canvas canvas, Size size, int seed) {
    final plate = Paint()..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawCircle(
      Offset(size.width * 0.54, size.height * 0.40),
      size.width * 0.27,
      plate,
    );
    canvas.drawCircle(
      Offset(size.width * 0.54, size.height * 0.40),
      size.width * 0.18,
      Paint()..color = palette.accent.withValues(alpha: 0.74),
    );

    final steam = Paint()
      ..color = Colors.white.withValues(alpha: 0.74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.43 + i * 0.11);
      final path = Path()
        ..moveTo(x, size.height * 0.22)
        ..cubicTo(
          x - size.width * 0.06,
          size.height * 0.16,
          x + size.width * 0.07,
          size.height * 0.12,
          x,
          size.height * 0.07,
        );
      canvas.drawPath(path, steam);
    }
  }

  void _drawCinema(Canvas canvas, Size size, int seed) {
    final frame = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;
    final rect = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.18,
      size.width * 0.72,
      size.height * 0.42,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.04)),
      frame,
    );

    final light = Path()
      ..moveTo(size.width * 0.23, size.height * 0.22)
      ..lineTo(size.width * 0.72, size.height * 0.60)
      ..lineTo(size.width * 0.88, size.height * 0.60)
      ..lineTo(size.width * 0.39, size.height * 0.22)
      ..close();
    canvas.drawPath(
      light,
      Paint()..color = palette.accent.withValues(alpha: 0.34),
    );

    final perforation = Paint()..color = Colors.white.withValues(alpha: 0.52);
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.19 + i * 0.115);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.14, size.width * 0.05, size.height * 0.025),
          Radius.circular(size.width * 0.01),
        ),
        perforation,
      );
    }
  }

  void _drawMusic(Canvas canvas, Size size, int seed) {
    final waveform = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = size.width * 0.024
      ..strokeCap = StrokeCap.round;

    final centerY = size.height * 0.40;
    for (var i = 0; i < 13; i++) {
      final x = size.width * (0.14 + i * 0.06);
      final wave = 0.04 + ((seed + i * 17) % 16) / 100;
      canvas.drawLine(
        Offset(x, centerY - size.height * wave),
        Offset(x, centerY + size.height * wave),
        waveform,
      );
    }

    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.26),
      size.width * 0.13,
      Paint()..color = palette.accent.withValues(alpha: 0.54),
    );
  }

  void _drawGaming(Canvas canvas, Size size, int seed) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gap = size.width * 0.10;
    for (var x = size.width * 0.1; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height * 0.16),
        Offset(x, size.height * 0.64),
        grid,
      );
    }
    for (var y = size.height * 0.16; y < size.height * 0.64; y += gap) {
      canvas.drawLine(
        Offset(size.width * 0.1, y),
        Offset(size.width * 0.9, y),
        grid,
      );
    }

    final node = Paint()..color = palette.accent.withValues(alpha: 0.85);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.2 + ((seed >> (i * 2)) % 60) / 100);
      final y = size.height * (0.22 + ((seed >> (i * 3)) % 30) / 100);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y),
            width: size.width * 0.10,
            height: size.width * 0.10,
          ),
          Radius.circular(size.width * 0.025),
        ),
        node,
      );
    }
  }

  void _drawLearning(Canvas canvas, Size size, int seed) {
    final page = Paint()..color = Colors.white.withValues(alpha: 0.78);
    final left = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.19,
        size.width * 0.31,
        size.height * 0.42,
      ),
      Radius.circular(size.width * 0.03),
    );
    final right = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.51,
        size.height * 0.19,
        size.width * 0.31,
        size.height * 0.42,
      ),
      Radius.circular(size.width * 0.03),
    );
    canvas.drawRRect(left, page);
    canvas.drawRRect(right, page);

    final ink = Paint()
      ..color = palette.ink.withValues(alpha: 0.22)
      ..strokeWidth = size.width * 0.012;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.28 + i * 0.055);
      canvas.drawLine(
        Offset(size.width * 0.23, y),
        Offset(size.width * 0.44, y),
        ink,
      );
      canvas.drawLine(
        Offset(size.width * 0.56, y),
        Offset(size.width * 0.77, y),
        ink,
      );
    }
  }

  void _drawArts(Canvas canvas, Size size, int seed) {
    final frame = Paint()
      ..color = Colors.white.withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.20,
          size.width * 0.68,
          size.height * 0.39,
        ),
        Radius.circular(size.width * 0.06),
      ),
      frame,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.395),
      size.width * 0.14,
      Paint()..color = palette.accent.withValues(alpha: 0.78),
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.395),
      size.width * 0.07,
      Paint()..color = Colors.white.withValues(alpha: 0.74),
    );
  }

  void _drawCrafts(Canvas canvas, Size size, int seed) {
    final shapes = [
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.20,
        size.width * 0.33,
        size.height * 0.19,
      ),
      Rect.fromLTWH(
        size.width * 0.46,
        size.height * 0.31,
        size.width * 0.35,
        size.height * 0.22,
      ),
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.46,
        size.width * 0.30,
        size.height * 0.14,
      ),
    ];
    final colors = [
      Colors.white.withValues(alpha: 0.66),
      palette.accent.withValues(alpha: 0.74),
      palette.ink.withValues(alpha: 0.26),
    ];

    for (var i = 0; i < shapes.length; i++) {
      canvas.save();
      canvas.translate(shapes[i].center.dx, shapes[i].center.dy);
      canvas.rotate((i - 1) * 0.14);
      canvas.translate(-shapes[i].center.dx, -shapes[i].center.dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          shapes[i],
          Radius.circular(size.width * 0.04),
        ),
        Paint()..color = colors[i],
      );
      canvas.restore();
    }
  }

  void _drawWellness(Canvas canvas, Size size, int seed) {
    final center = Offset(size.width * 0.5, size.height * 0.38);
    for (var i = 4; i >= 1; i--) {
      canvas.drawCircle(
        center,
        size.width * (0.09 + i * 0.055),
        Paint()
          ..color = (i.isEven ? palette.accent : Colors.white)
              .withValues(alpha: 0.16 + i * 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.025,
      );
    }

    final breath = Paint()
      ..color = Colors.white.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018;
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.62,
        height: size.width * 0.62,
      ),
      -math.pi * 0.25,
      math.pi * 0.5,
      false,
      breath,
    );
  }

  void _drawAbstract(Canvas canvas, Size size, int seed) {
    final paint = Paint()..color = palette.accent.withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.36),
      size.width * 0.26,
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.20,
          size.width * 0.34,
          size.height * 0.34,
        ),
        Radius.circular(size.width * 0.08),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.30),
    );
  }

  @override
  bool shouldRepaint(covariant _CardScenePainter oldDelegate) =>
      oldDelegate.recipe.interestId != recipe.interestId ||
      oldDelegate.recipe.visualSeed != recipe.visualSeed ||
      oldDelegate.palette != palette;
}

class _CardPalette {
  const _CardPalette({
    required this.background,
    required this.secondary,
    required this.accent,
    required this.ink,
  });

  final Color background;
  final Color secondary;
  final Color accent;
  final Color ink;

  static _CardPalette forRecipe(CardVisualRecipe recipe) {
    final palettes = _paletteBank[recipe.categoryKit] ??
        _paletteBank['default']!;
    return palettes[recipe.paletteSlot % palettes.length];
  }

  static const _paletteBank = <String, List<_CardPalette>>{
    'sports': [
      _CardPalette(
        background: Color(0xFF174F65),
        secondary: Color(0xFF1B846F),
        accent: Color(0xFFF7C95C),
        ink: Color(0xFF102A37),
      ),
      _CardPalette(
        background: Color(0xFF5A386D),
        secondary: Color(0xFFB25362),
        accent: Color(0xFFF5C87A),
        ink: Color(0xFF2A1833),
      ),
    ],
    'outdoors': [
      _CardPalette(
        background: Color(0xFF315B45),
        secondary: Color(0xFF728A59),
        accent: Color(0xFFE2B56E),
        ink: Color(0xFF1E3024),
      ),
    ],
    'food': [
      _CardPalette(
        background: Color(0xFF8D4B3E),
        secondary: Color(0xFFD88B5A),
        accent: Color(0xFFF8D7A4),
        ink: Color(0xFF44241E),
      ),
    ],
    'entertainment': [
      _CardPalette(
        background: Color(0xFF272647),
        secondary: Color(0xFF594E84),
        accent: Color(0xFFE8B85D),
        ink: Color(0xFF17172B),
      ),
    ],
    'music': [
      _CardPalette(
        background: Color(0xFF4D2F66),
        secondary: Color(0xFFB34F7B),
        accent: Color(0xFF74D7D0),
        ink: Color(0xFF281A35),
      ),
    ],
    'gaming': [
      _CardPalette(
        background: Color(0xFF1E3D55),
        secondary: Color(0xFF3B548A),
        accent: Color(0xFF70E5C0),
        ink: Color(0xFF102532),
      ),
    ],
    'learning': [
      _CardPalette(
        background: Color(0xFF6A5148),
        secondary: Color(0xFFB98F72),
        accent: Color(0xFFF0DDA8),
        ink: Color(0xFF372B27),
      ),
    ],
    'arts': [
      _CardPalette(
        background: Color(0xFF315E6D),
        secondary: Color(0xFF8A6683),
        accent: Color(0xFFF1C475),
        ink: Color(0xFF1D3037),
      ),
    ],
    'crafts': [
      _CardPalette(
        background: Color(0xFF71566A),
        secondary: Color(0xFFC47B6B),
        accent: Color(0xFFF1D17E),
        ink: Color(0xFF392B36),
      ),
    ],
    'wellness': [
      _CardPalette(
        background: Color(0xFF456B69),
        secondary: Color(0xFF8EB7A1),
        accent: Color(0xFFF2D7A2),
        ink: Color(0xFF243937),
      ),
    ],
    'default': [
      _CardPalette(
        background: Color(0xFF3D4F69),
        secondary: Color(0xFF7484A1),
        accent: Color(0xFFF2C66F),
        ink: Color(0xFF222D3D),
      ),
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is _CardPalette &&
      other.background == background &&
      other.secondary == secondary &&
      other.accent == accent &&
      other.ink == ink;

  @override
  int get hashCode => Object.hash(background, secondary, accent, ink);
}
