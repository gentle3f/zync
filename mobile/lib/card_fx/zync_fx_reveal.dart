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
  });

  final ZyncFxCardSpec spec;
  final ZyncFxTuning tuning;
  final int revealToken;
  final double speed;

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
    _controller = AnimationController(vsync: this, duration: _duration);
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Duration get _duration =>
      Duration(milliseconds: (1550 / widget.speed.clamp(0.55, 1.8)).round());

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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
      return;
    }

    _controller.stop();
    _controller.value = 0;
    unawaited(HapticFeedback.selectionClick());

    final totalMs = _duration.inMilliseconds;
    _flipHapticTimer?.cancel();
    _legendaryHapticTimer?.cancel();
    _flipHapticTimer = Timer(
      Duration(milliseconds: (totalMs * 0.48).round()),
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
      Duration(milliseconds: (totalMs * 0.64).round()),
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
        final lift = Curves.easeOutCubic.transform(
          ((p - 0.00) / 0.34).clamp(0.0, 1.0),
        );
        final flip = Curves.easeInOutCubic.transform(
          ((p - 0.16) / 0.48).clamp(0.0, 1.0),
        );
        final settle = Curves.easeOutBack.transform(
          ((p - 0.60) / 0.40).clamp(0.0, 1.0),
        );
        final angle = math.pi * (1 - flip);
        final showFront = angle <= math.pi / 2;
        final displayAngle = showFront ? angle : math.pi - angle;

        final hitT = ((p - 0.54) / 0.34).clamp(0.0, 1.0);
        final hit = math.sin(hitT * math.pi).clamp(0.0, 1.0) *
            widget.spec.profile.revealImpact;

        final scale = 0.82 + lift * 0.11 + settle * 0.07;
        final y = 72 * (1 - lift) - 8 * hit;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(displayAngle);

        return Transform.translate(
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
                      revealImpact: hit,
                    )
                  : _CardBack(accent: widget.spec.profile.accentColor),
            ),
          ),
        );
      },
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.accent});

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
