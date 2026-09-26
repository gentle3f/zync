import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'card_fx_spec.dart';
import 'zync_fx_card.dart';

class ZyncFxRevealStage extends StatefulWidget {
  const ZyncFxRevealStage({
    super.key,
    required this.spec,
    required this.tuning,
    required this.revealToken,
    this.speed = 1.0,
    this.respectReduceMotion = true,
    this.startFromSettledBack = false,
  });

  final ZyncFxCardSpec spec;
  final ZyncFxTuning tuning;
  final int revealToken;
  final double speed;
  final bool respectReduceMotion;

  /// Used by pack-opening flow after the card back has already been physically
  /// extracted from the wrapper. Direct reveal keeps the original entrance.
  final bool startFromSettledBack;

  @override
  State<ZyncFxRevealStage> createState() => _ZyncFxRevealStageState();
}

class _ZyncFxRevealStageState extends State<ZyncFxRevealStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _flipHapticTimer;
  Timer? _legendaryHapticTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      animationBehavior: widget.respectReduceMotion
          ? AnimationBehavior.normal
          : AnimationBehavior.preserve,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Duration get _duration =>
      Duration(milliseconds: (2400 / widget.speed.clamp(0.55, 1.8)).round());

  @override
  void didUpdateWidget(covariant ZyncFxRevealStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _controller.duration = _duration;
    }
    if (oldWidget.revealToken != widget.revealToken ||
        oldWidget.spec.id != widget.spec.id) {
      unawaited(_play());
    }
  }

  Future<void> _play() async {
    final reduceMotion = widget.respectReduceMotion &&
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (reduceMotion) {
      _controller.value = 1;
      return;
    }

    _controller.stop();
    final start = widget.startFromSettledBack ? 0.22 : 0.0;
    _controller.value = start;
    unawaited(HapticFeedback.selectionClick());

    final totalMs = _duration.inMilliseconds;
    _flipHapticTimer?.cancel();
    _legendaryHapticTimer?.cancel();
    _flipHapticTimer = Timer(
      Duration(milliseconds: (totalMs * (0.48 - start)).round()),
      () {
        if (!mounted) return;
        if (widget.spec.rarity.index >= ZyncFxRarity.rare.index) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      },
    );
    _legendaryHapticTimer = Timer(
      Duration(milliseconds: (totalMs * (0.64 - start)).round()),
      () {
        if (!mounted || widget.spec.rarity != ZyncFxRarity.legendary) {
          return;
        }
        HapticFeedback.heavyImpact();
      },
    );
    await _controller.forward();
  }

  @override
  void dispose() {
    _flipHapticTimer?.cancel();
    _legendaryHapticTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p = _controller.value;
        final entrance = Curves.easeOutBack.transform(
          (p / 0.22).clamp(0.0, 1.0),
        );
        final flip = Curves.easeInOutCubic.transform(
          ((p - 0.22) / 0.40).clamp(0.0, 1.0),
        );
        final settle = Curves.easeOutBack.transform(
          ((p - 0.62) / 0.38).clamp(0.0, 1.0),
        );
        final angle = math.pi * (1 - flip);
        final showFront = angle <= math.pi / 2;
        final displayAngle = showFront ? angle : math.pi - angle;

        final flashT = ((p - 0.40) / 0.18).clamp(0.0, 1.0);
        final flash = math.sin(flashT * math.pi).clamp(0.0, 1.0) *
            widget.spec.profile.revealImpact;
        final hitT = ((p - 0.50) / 0.34).clamp(0.0, 1.0);
        final hit = math.sin(hitT * math.pi).clamp(0.0, 1.0) *
            widget.spec.profile.revealImpact;
        final legendaryFinaleT = ((p - 0.64) / 0.26).clamp(0.0, 1.0);
        final legendaryFinale = widget.spec.rarity == ZyncFxRarity.legendary
            ? math.sin(legendaryFinaleT * math.pi).clamp(0.0, 1.0) * 1.18
            : 0.0;
        final impact = math.max(hit, legendaryFinale);
        final finaleFlash = widget.spec.rarity == ZyncFxRarity.legendary
            ? math
                .sin(
                  ((p - 0.66) / 0.13).clamp(0.0, 1.0) * math.pi,
                )
                .clamp(0.0, 1.0)
            : 0.0;

        final scale =
            0.72 + entrance * 0.20 + settle * 0.08 + legendaryFinale * 0.032;
        final y = 96 * (1 - entrance) - 10 * hit - 5 * legendaryFinale;
        final z = (1 - entrance) * -0.085 + hit * 0.028;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0017)
          ..rotateY(displayAngle)
          ..rotateZ(z);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (flash > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.22 * flash),
                          widget.spec.profile.secondaryColor.withValues(
                            alpha: 0.18 * flash,
                          ),
                          widget.spec.profile.accentColor.withValues(
                            alpha: 0.10 * flash,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.28, 0.56, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            if (finaleFlash > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white.withValues(
                      alpha: 0.16 * finaleFlash,
                    ),
                  ),
                ),
              ),
            if (showFront && impact > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RarityRevealHaloPainter(
                      rarity: widget.spec.rarity,
                      impact: impact,
                      accent: widget.spec.profile.accentColor,
                      secondary: widget.spec.profile.secondaryColor,
                    ),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(0, y),
              child: Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: matrix,
                  child: showFront
                      ? ZyncFxCard(
                          spec: widget.spec,
                          tuning: widget.tuning,
                          enableDragTilt: p > 0.98,
                          revealImpact: impact,
                          respectReduceMotion: widget.respectReduceMotion,
                        )
                      : ZyncFxCardBack(accent: widget.spec.profile.accentColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RarityRevealHaloPainter extends CustomPainter {
  const _RarityRevealHaloPainter({
    required this.rarity,
    required this.impact,
    required this.accent,
    required this.secondary,
  });

  final ZyncFxRarity rarity;
  final double impact;
  final Color accent;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (impact <= 0.001) return;

    final center = Offset(size.width / 2, size.height / 2);
    final shortest = size.shortestSide;
    final level = rarity.index;
    final strength = (0.10 + level * 0.055) * impact;

    final haloRect = Rect.fromCenter(
      center: center,
      width: size.width * 1.28,
      height: size.height * 1.14,
    );
    final halo = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        colors: [
          secondary.withValues(alpha: strength),
          accent.withValues(alpha: strength * 0.62),
          Colors.transparent,
        ],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(haloRect);
    canvas.drawOval(haloRect, halo);

    if (rarity == ZyncFxRarity.common) return;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 + level * 0.35
      ..blendMode = BlendMode.screen;

    final ringCount = switch (rarity) {
      ZyncFxRarity.uncommon => 1,
      ZyncFxRarity.rare => 2,
      ZyncFxRarity.epic => 2,
      ZyncFxRarity.legendary => 5,
      ZyncFxRarity.common => 0,
    };

    for (var i = 0; i < ringCount; i++) {
      final radius = shortest * (0.34 + i * 0.11 + (1 - impact) * 0.10);
      ring.color = (i.isEven ? accent : secondary).withValues(
        alpha: impact * (0.18 + level * 0.045) / (i + 1),
      );
      canvas.drawCircle(center, radius, ring);
    }

    if (rarity == ZyncFxRarity.legendary) {
      for (var i = 0; i < 2; i++) {
        final radius = shortest *
            (0.58 + i * 0.20) *
            (0.78 + impact.clamp(0.0, 1.18) * 0.22);
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0 - i * 0.8
            ..blendMode = BlendMode.screen
            ..color = (i == 0 ? secondary : accent).withValues(
              alpha: (impact * (0.32 - i * 0.09)).clamp(0.0, 0.42),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }
    }

    if (rarity.index < ZyncFxRarity.epic.index) return;

    final isLegendary = rarity == ZyncFxRarity.legendary;
    final rayCount = isLegendary ? 28 : 10;
    final ray = Paint()
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.screen;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2 + 0.17;
      final inner = shortest * (isLegendary ? 0.32 : 0.43);
      final outerBase =
          isLegendary ? 0.82 + (i % 4) * 0.065 : 0.53 + (i % 3) * 0.045;
      final outer = shortest * outerBase * impact.clamp(0.0, 1.08);
      ray
        ..strokeWidth = isLegendary ? 1.4 + (i % 3) * 0.65 : 1.0 + (i % 2) * 0.7
        ..color = (i.isEven ? accent : secondary).withValues(
          alpha: (impact * (isLegendary ? 0.52 : 0.24)).clamp(0.0, 0.62),
        );
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RarityRevealHaloPainter oldDelegate) =>
      oldDelegate.rarity != rarity ||
      oldDelegate.impact != impact ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary;
}

class ZyncFxCardBack extends StatelessWidget {
  const ZyncFxCardBack({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF101722), Color(0xFF26324A), Color(0xFF11131C)],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.72), width: 2),
          boxShadow: [
            BoxShadow(blurRadius: 28, color: accent.withValues(alpha: 0.20)),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _BackPatternPainter(accent: accent)),
            Center(
              child: Container(
                width: 112,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.24),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.72),
                    width: 2,
                  ),
                ),
                child: const Text(
                  'Z',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackPatternPainter extends CustomPainter {
  const _BackPatternPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final gap = size.width / 7;
    for (var x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), line);
    }
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width * (0.11 + i * 0.08),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackPatternPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
