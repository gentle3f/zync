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
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: _EditionSeal(
                                label: editionLabel,
                                foreground: palette.ink,
                                background:
                                    Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ),
                        ),
                        if (cardNumberLabel != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              cardNumberLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color:
                                        palette.ink.withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
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
      case 'travel':
        _drawTravel(canvas, size, seed);
      case 'technology':
        _drawTechnology(canvas, size, seed);
      case 'nature':
        _drawNature(canvas, size, seed);
      case 'motorsport':
        _drawMotorsport(canvas, size, seed);
      case 'collecting':
        _drawCollecting(canvas, size, seed);
      default:
        _drawAbstract(canvas, size, seed);
    }

    _drawSceneGrammarAccent(canvas, size, seed);
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

  void _drawTravel(Canvas canvas, Size size, int seed) {
    final route = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.56)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.30,
        size.width * 0.52,
        size.height * 0.62,
        size.width * 0.76,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.20,
        size.width * 0.87,
        size.height * 0.24,
        size.width * 0.90,
        size.height * 0.17,
      );
    canvas.drawPath(path, route);

    final point = Paint()..color = palette.accent.withValues(alpha: 0.92);
    for (final offset in [
      Offset(size.width * 0.18, size.height * 0.55),
      Offset(size.width * 0.48, size.height * 0.46),
      Offset(size.width * 0.78, size.height * 0.27),
    ]) {
      canvas.drawCircle(offset, size.width * 0.045, point);
      canvas.drawCircle(
        offset,
        size.width * 0.018,
        Paint()..color = Colors.white.withValues(alpha: 0.90),
      );
    }

    final stamp = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015;
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.27),
      size.width * 0.13,
      stamp,
    );
  }

  void _drawTechnology(Canvas canvas, Size size, int seed) {
    final nodePaint = Paint()..color = Colors.white.withValues(alpha: 0.78);
    final linkPaint = Paint()
      ..color = palette.accent.withValues(alpha: 0.54)
      ..strokeWidth = size.width * 0.016;

    final nodes = <Offset>[
      Offset(size.width * 0.20, size.height * 0.28),
      Offset(size.width * 0.43, size.height * 0.20),
      Offset(size.width * 0.72, size.height * 0.30),
      Offset(size.width * 0.31, size.height * 0.50),
      Offset(size.width * 0.62, size.height * 0.53),
    ];
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], linkPaint);
    }
    canvas.drawLine(nodes[1], nodes[4], linkPaint);
    canvas.drawLine(nodes[0], nodes[3], linkPaint);

    for (var i = 0; i < nodes.length; i++) {
      canvas.drawCircle(
        nodes[i],
        size.width * (i == 1 ? 0.055 : 0.035),
        nodePaint,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.20,
          size.height * 0.60,
          size.width * 0.60,
          size.height * 0.08,
        ),
        Radius.circular(size.width * 0.035),
      ),
      Paint()..color = palette.ink.withValues(alpha: 0.18),
    );
  }

  void _drawNature(Canvas canvas, Size size, int seed) {
    final horizon = Paint()
      ..color = palette.ink.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.42,
        size.width * 0.46,
        size.height * 0.57,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.38,
        size.width,
        size.height * 0.55,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, horizon);

    final organic = Paint()
      ..color = Colors.white.withValues(alpha: 0.56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.24 + i * 0.16);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x, size.height * (0.34 + (i % 2) * 0.05)),
          width: size.width * 0.18,
          height: size.width * 0.12,
        ),
        math.pi * 0.12,
        math.pi * 0.82,
        false,
        organic,
      );
    }
  }

  void _drawMotorsport(Canvas canvas, Size size, int seed) {
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.52)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.20,
        size.width * 0.56,
        size.height * 0.62,
        size.width * 0.84,
        size.height * 0.30,
      );
    canvas.drawPath(path, track);

    final speed = Paint()
      ..color = palette.accent.withValues(alpha: 0.78)
      ..strokeWidth = size.width * 0.018;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.21 + i * 0.08);
      canvas.drawLine(
        Offset(size.width * 0.18, y),
        Offset(size.width * (0.40 + i * 0.08), y),
        speed,
      );
    }
  }

  void _drawCollecting(Canvas canvas, Size size, int seed) {
    final frame = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.014;

    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        final rect = Rect.fromLTWH(
          size.width * (0.16 + col * 0.23),
          size.height * (0.20 + row * 0.19),
          size.width * 0.17,
          size.height * 0.13,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(size.width * 0.025),
          ),
          frame,
        );
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.31,
          size.height * 0.23,
          size.width * 0.38,
          size.height * 0.30,
        ),
        Radius.circular(size.width * 0.05),
      ),
      Paint()..color = palette.accent.withValues(alpha: 0.38),
    );
  }

  void _drawSceneGrammarAccent(Canvas canvas, Size size, int seed) {
    switch (recipe.sceneGrammar) {
      case 'campfire_horizon':
        _drawCampfireAccent(canvas, size);
      case 'night_sky_orbit':
        _drawNightSkyAccent(canvas, size, seed);
      case 'wildlife_observation':
        _drawWildlifeAccent(canvas, size);
      case 'travel_destination_layers':
        _drawDestinationAccent(canvas, size);
      case 'travel_road_ribbon':
        _drawRoadtripAccent(canvas, size);
      case 'travel_food_stamp':
        _drawFoodStampAccent(canvas, size);
      case 'technology_code_grid':
        _drawCodeAccent(canvas, size);
      case 'technology_mechanical_nodes':
        _drawRoboticsAccent(canvas, size);
      case 'technology_hardware_grid':
        _drawKeyboardAccent(canvas, size);
      case 'wellness_energy_rings':
        _drawFitnessAccent(canvas, size);
      case 'arts_layered_canvas':
        _drawVisualArtAccent(canvas, size);
      case 'arts_ceramic_form':
        _drawCeramicsAccent(canvas, size);
      case 'food_plate_stamp':
        _drawCuisineAccent(canvas, size);
      case 'music_keys':
        _drawPianoAccent(canvas, size);
      case 'music_stage_lights':
        _drawLiveMusicAccent(canvas, size);
      case 'gaming_board_grid':
        _drawTabletopAccent(canvas, size);
      case 'gaming_strategy_nodes':
        _drawStrategyAccent(canvas, size);
      case 'learning_language_cards':
        _drawLanguageAccent(canvas, size);
      case 'learning_timeline':
        _drawTimelineAccent(canvas, size);
      case 'crafts_thread_weave':
        _drawTextileAccent(canvas, size);
    }
  }

  void _drawCampfireAccent(Canvas canvas, Size size) {
    final fire = Path()
      ..moveTo(size.width * 0.50, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.40,
        size.width * 0.50,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.37,
        size.width * 0.56,
        size.height * 0.29,
      )
      ..quadraticBezierTo(
        size.width * 0.53,
        size.height * 0.25,
        size.width * 0.50,
        size.height * 0.25,
      );
    canvas.drawPath(
      fire,
      Paint()..color = palette.accent.withValues(alpha: 0.82),
    );
  }

  void _drawNightSkyAccent(Canvas canvas, Size size, int seed) {
    final star = Paint()..color = Colors.white.withValues(alpha: 0.88);
    for (var i = 0; i < 11; i++) {
      final x = size.width * (0.12 + ((seed + i * 31) % 76) / 100);
      final y = size.height * (0.12 + ((seed + i * 47) % 34) / 100);
      canvas.drawCircle(
        Offset(x, y),
        size.width * (0.006 + (i % 3) * 0.004),
        star,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.25),
      size.width * 0.10,
      Paint()..color = palette.accent.withValues(alpha: 0.55),
    );
  }

  void _drawWildlifeAccent(Canvas canvas, Size size) {
    final scope = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018;
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.31),
      size.width * 0.13,
      scope,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.18),
      Offset(size.width * 0.55, size.height * 0.44),
      scope,
    );
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.31),
      Offset(size.width * 0.68, size.height * 0.31),
      scope,
    );
  }

  void _drawDestinationAccent(Canvas canvas, Size size) {
    final mountain = Path()
      ..moveTo(size.width * 0.28, size.height * 0.46)
      ..lineTo(size.width * 0.50, size.height * 0.20)
      ..lineTo(size.width * 0.72, size.height * 0.46)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.22),
      size.width * 0.055,
      Paint()..color = palette.accent.withValues(alpha: 0.82),
    );
  }

  void _drawRoadtripAccent(Canvas canvas, Size size) {
    final road = Paint()
      ..color = palette.ink.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.60),
      Offset(size.width * 0.74, size.height * 0.20),
      road,
    );
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.74)
      ..strokeWidth = size.width * 0.012;
    for (var i = 0; i < 4; i++) {
      final t = 0.16 + i * 0.20;
      final x = size.width * (0.24 + 0.50 * t);
      final y = size.height * (0.60 - 0.40 * t);
      canvas.drawCircle(Offset(x, y), size.width * 0.012, dash);
    }
  }

  void _drawFoodStampAccent(Canvas canvas, Size size) {
    final plate = Paint()
      ..color = Colors.white.withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025;
    canvas.drawCircle(
      Offset(size.width * 0.66, size.height * 0.36),
      size.width * 0.12,
      plate,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.25),
      Offset(size.width * 0.48, size.height * 0.50),
      plate,
    );
  }

  void _drawCodeAccent(Canvas canvas, Size size) {
    final code = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.23 + i * 0.07);
      final start = size.width * (0.22 + (i % 2) * 0.06);
      canvas.drawLine(
        Offset(start, y),
        Offset(size.width * (0.64 + (i % 3) * 0.06), y),
        code,
      );
    }
  }

  void _drawRoboticsAccent(Canvas canvas, Size size) {
    final gear = Paint()
      ..color = palette.accent.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035;
    canvas.drawCircle(
      Offset(size.width * 0.60, size.height * 0.34),
      size.width * 0.11,
      gear,
    );
    canvas.drawCircle(
      Offset(size.width * 0.40, size.height * 0.45),
      size.width * 0.075,
      gear,
    );
  }

  void _drawKeyboardAccent(Canvas canvas, Size size) {
    final keyPaint = Paint()..color = Colors.white.withValues(alpha: 0.58);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 5; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * (0.22 + col * 0.105),
              size.height * (0.24 + row * 0.075),
              size.width * 0.075,
              size.height * 0.050,
            ),
            Radius.circular(size.width * 0.012),
          ),
          keyPaint,
        );
      }
    }
  }

  void _drawFitnessAccent(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = palette.accent.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.030;
    final center = Offset(size.width * 0.50, size.height * 0.35);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        center,
        size.width * (0.09 + i * 0.07),
        ring,
      );
    }
  }

  void _drawVisualArtAccent(Canvas canvas, Size size) {
    final paint = Paint()..color = palette.accent.withValues(alpha: 0.58);
    canvas.drawCircle(
      Offset(size.width * 0.37, size.height * 0.31),
      size.width * 0.10,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.38),
      size.width * 0.13,
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
  }

  void _drawCeramicsAccent(Canvas canvas, Size size) {
    final pot = Path()
      ..moveTo(size.width * 0.38, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.44,
        size.width * 0.43,
        size.height * 0.53,
      )
      ..lineTo(size.width * 0.61, size.height * 0.53)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.44,
        size.width * 0.65,
        size.height * 0.24,
      )
      ..close();
    canvas.drawPath(
      pot,
      Paint()..color = Colors.white.withValues(alpha: 0.58),
    );
  }

  void _drawCuisineAccent(Canvas canvas, Size size) {
    final stamp = Paint()
      ..color = palette.ink.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018;
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.25),
      size.width * 0.10,
      stamp,
    );
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.25),
      size.width * 0.055,
      stamp,
    );
  }

  void _drawPianoAccent(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white.withValues(alpha: 0.82);
    final dark = Paint()..color = palette.ink.withValues(alpha: 0.58);
    final startX = size.width * 0.18;
    final keyW = size.width * 0.09;
    for (var i = 0; i < 7; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          startX + i * keyW,
          size.height * 0.27,
          keyW * 0.92,
          size.height * 0.23,
        ),
        white,
      );
    }
    for (final i in [0, 1, 3, 4, 5]) {
      canvas.drawRect(
        Rect.fromLTWH(
          startX + (i + 0.68) * keyW,
          size.height * 0.27,
          keyW * 0.42,
          size.height * 0.14,
        ),
        dark,
      );
    }
  }

  void _drawLiveMusicAccent(Canvas canvas, Size size) {
    final light = Paint()
      ..color = palette.accent.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.26 + i * 0.24);
      final cone = Path()
        ..moveTo(x, size.height * 0.16)
        ..lineTo(x - size.width * 0.12, size.height * 0.55)
        ..lineTo(x + size.width * 0.12, size.height * 0.55)
        ..close();
      canvas.drawPath(cone, light);
    }
  }

  void _drawTabletopAccent(Canvas canvas, Size size) {
    final tile = Paint()
      ..color = Colors.white.withValues(alpha: 0.54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * (0.25 + col * 0.14),
            size.height * (0.23 + row * 0.10),
            size.width * 0.11,
            size.width * 0.11,
          ),
          tile,
        );
      }
    }
  }

  void _drawStrategyAccent(Canvas canvas, Size size) {
    final link = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..strokeWidth = size.width * 0.014;
    final node = Paint()..color = palette.accent.withValues(alpha: 0.80);
    final points = [
      Offset(size.width * 0.30, size.height * 0.42),
      Offset(size.width * 0.48, size.height * 0.25),
      Offset(size.width * 0.68, size.height * 0.37),
      Offset(size.width * 0.54, size.height * 0.52),
    ];
    for (var i = 0; i < points.length; i++) {
      canvas.drawLine(points[i], points[(i + 1) % points.length], link);
      canvas.drawCircle(points[i], size.width * 0.035, node);
    }
  }

  void _drawLanguageAccent(Canvas canvas, Size size) {
    final card = Paint()..color = Colors.white.withValues(alpha: 0.56);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(size.width * (0.30 + i * 0.14), size.height * 0.34);
      canvas.rotate((i - 1) * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: size.width * 0.22,
            height: size.height * 0.20,
          ),
          Radius.circular(size.width * 0.03),
        ),
        card,
      );
      canvas.restore();
    }
  }

  void _drawTimelineAccent(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.66)
      ..strokeWidth = size.width * 0.018;
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.38),
      Offset(size.width * 0.78, size.height * 0.38),
      line,
    );
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.24 + i * 0.17);
      canvas.drawCircle(
        Offset(x, size.height * 0.38),
        size.width * 0.032,
        Paint()..color = palette.accent.withValues(alpha: 0.88),
      );
    }
  }

  void _drawTextileAccent(Canvas canvas, Size size) {
    final threadA = Paint()
      ..color = Colors.white.withValues(alpha: 0.60)
      ..strokeWidth = size.width * 0.015;
    final threadB = Paint()
      ..color = palette.accent.withValues(alpha: 0.58)
      ..strokeWidth = size.width * 0.015;
    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.20 + i * 0.09);
      canvas.drawLine(
        Offset(x, size.height * 0.22),
        Offset(x + size.width * 0.18, size.height * 0.52),
        i.isEven ? threadA : threadB,
      );
    }
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
    'travel': [
      _CardPalette(
        background: Color(0xFF2E6171),
        secondary: Color(0xFF6F9D8B),
        accent: Color(0xFFF3C66B),
        ink: Color(0xFF193640),
      ),
    ],
    'technology': [
      _CardPalette(
        background: Color(0xFF233C63),
        secondary: Color(0xFF466AA1),
        accent: Color(0xFF72E0CF),
        ink: Color(0xFF14243B),
      ),
    ],
    'nature': [
      _CardPalette(
        background: Color(0xFF2E594B),
        secondary: Color(0xFF678A6A),
        accent: Color(0xFFE9C779),
        ink: Color(0xFF1A332A),
      ),
    ],
    'motorsport': [
      _CardPalette(
        background: Color(0xFF3B3D49),
        secondary: Color(0xFF8A3946),
        accent: Color(0xFFF0C34C),
        ink: Color(0xFF1F2027),
      ),
    ],
    'collecting': [
      _CardPalette(
        background: Color(0xFF5A4267),
        secondary: Color(0xFF8D6A88),
        accent: Color(0xFFF2C879),
        ink: Color(0xFF302438),
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
