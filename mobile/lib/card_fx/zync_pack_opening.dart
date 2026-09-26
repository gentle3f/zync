import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'card_fx_spec.dart';
import 'zync_fx_reveal.dart';

enum ZyncOpeningPrototype { tearUp, splitOpen, chargeBurst, sealSlide }

extension ZyncOpeningPrototypeUi on ZyncOpeningPrototype {
  String get code => switch (this) {
        ZyncOpeningPrototype.tearUp => 'A',
        ZyncOpeningPrototype.splitOpen => 'B',
        ZyncOpeningPrototype.chargeBurst => 'C',
        ZyncOpeningPrototype.sealSlide => 'D',
      };

  String get label => switch (this) {
        ZyncOpeningPrototype.tearUp => 'Tear Up',
        ZyncOpeningPrototype.splitOpen => 'Split Open',
        ZyncOpeningPrototype.chargeBurst => 'Charge Burst',
        ZyncOpeningPrototype.sealSlide => 'Seal Slide',
      };

  String get instruction => switch (this) {
        ZyncOpeningPrototype.tearUp =>
          'Hold the pack and drag upward to tear the top seal.',
        ZyncOpeningPrototype.splitOpen =>
          'Drag sideways to split the foil pack open from the middle.',
        ZyncOpeningPrototype.chargeBurst =>
          'Press and hold to charge. Release when the pack is powered up.',
        ZyncOpeningPrototype.sealSlide =>
          'Hold the seal tab and drag downward to unlock the pack.',
      };

  IconData get icon => switch (this) {
        ZyncOpeningPrototype.tearUp => Icons.swipe_up_alt_rounded,
        ZyncOpeningPrototype.splitOpen => Icons.open_in_full_rounded,
        ZyncOpeningPrototype.chargeBurst => Icons.bolt_rounded,
        ZyncOpeningPrototype.sealSlide => Icons.vertical_align_bottom_rounded,
      };
}

class ZyncPackOpeningStage extends StatefulWidget {
  const ZyncPackOpeningStage({
    super.key,
    required this.spec,
    required this.tuning,
    required this.prototype,
    required this.openToken,
    this.speed = 1.0,
    this.respectReduceMotion = true,
  });

  final ZyncFxCardSpec spec;
  final ZyncFxTuning tuning;
  final ZyncOpeningPrototype prototype;
  final int openToken;
  final double speed;
  final bool respectReduceMotion;

  @override
  State<ZyncPackOpeningStage> createState() => _ZyncPackOpeningStageState();
}

class _ZyncPackOpeningStageState extends State<ZyncPackOpeningStage>
    with TickerProviderStateMixin {
  int? _selectedPack;
  double _gestureProgress = 0;
  double _dragValue = 0;
  bool _opening = false;
  bool _revealing = false;

  Timer? _revealTimer;
  late final AnimationController _idleController;
  late final AnimationController _burstController;
  late final AnimationController _chargeController;

  AnimationBehavior get _behavior => widget.respectReduceMotion
      ? AnimationBehavior.normal
      : AnimationBehavior.preserve;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
      animationBehavior: _behavior,
    )..repeat();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      animationBehavior: _behavior,
    )..addListener(_tick);
    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
      animationBehavior: _behavior,
    )..addListener(() {
        if (!mounted || widget.prototype != ZyncOpeningPrototype.chargeBurst) {
          return;
        }
        setState(() => _gestureProgress = _chargeController.value);
      });
  }

  @override
  void didUpdateWidget(covariant ZyncPackOpeningStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openToken != widget.openToken ||
        oldWidget.spec.id != widget.spec.id ||
        oldWidget.spec.rarity != widget.spec.rarity ||
        oldWidget.prototype != widget.prototype) {
      _reset();
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _reset() {
    _revealTimer?.cancel();
    _selectedPack = null;
    _gestureProgress = 0;
    _dragValue = 0;
    _opening = false;
    _revealing = false;
    _burstController.reset();
    _chargeController.reset();
    if (mounted) setState(() {});
  }

  int get _seed {
    var value = widget.openToken * 31 +
        (_selectedPack ?? 0) * 17 +
        widget.prototype.index * 13 +
        widget.spec.rarity.index * 7;
    for (final unit in widget.spec.id.codeUnits) {
      value = (value * 33 + unit) & 0x7fffffff;
    }
    return value;
  }

  bool get _hasHiddenOmen {
    if (_selectedPack == null) return false;
    if (widget.spec.rarity == ZyncFxRarity.legendary) {
      return _seed % 7 == 0;
    }
    if (widget.spec.rarity == ZyncFxRarity.epic) {
      return _seed % 20 == 0;
    }
    return false;
  }

  double get _rarityEnergy => switch (widget.spec.rarity) {
        ZyncFxRarity.common => 0.34,
        ZyncFxRarity.uncommon => 0.48,
        ZyncFxRarity.rare => 0.66,
        ZyncFxRarity.epic => 0.84,
        ZyncFxRarity.legendary => 1.0,
      };

  void _selectPack(int index) {
    if (_opening || _revealing) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPack = index;
      _gestureProgress = 0;
      _dragValue = 0;
      _burstController.reset();
      _chargeController.reset();
    });
  }

  void _setProgress(double value) {
    if (_opening || _revealing) return;
    setState(() => _gestureProgress = value.clamp(0.0, 1.0));
  }

  void _cancelGesture() {
    if (_opening || _revealing) return;
    _chargeController.stop();
    _chargeController.animateBack(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    setState(() {
      _gestureProgress = 0;
      _dragValue = 0;
    });
  }

  void _finishDrag() {
    if (_gestureProgress >= 0.70) {
      _commitOpen();
    } else {
      _cancelGesture();
    }
  }

  void _chargeDown(TapDownDetails _) {
    if (_opening || _revealing) return;
    _chargeController.forward();
    HapticFeedback.selectionClick();
  }

  void _chargeUp([TapUpDetails? _]) {
    if (_opening || _revealing) return;
    _chargeController.stop();
    if (_chargeController.value >= 0.42) {
      _commitOpen();
    } else {
      _cancelGesture();
    }
  }

  void _commitOpen() {
    if (_selectedPack == null || _opening || _revealing) return;
    _chargeController.stop();
    _gestureProgress = math.max(_gestureProgress, 0.82);
    _opening = true;
    HapticFeedback.mediumImpact();
    _burstController.forward(from: 0);
    setState(() {});

    final normalDelay = switch (widget.spec.rarity) {
      ZyncFxRarity.common => 190,
      ZyncFxRarity.uncommon => 230,
      ZyncFxRarity.rare => 285,
      ZyncFxRarity.epic => 350,
      ZyncFxRarity.legendary => 430,
    };
    final revealDelay = _hasHiddenOmen ? 820 : normalDelay;
    _revealTimer = Timer(Duration(milliseconds: revealDelay), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _revealing = true);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _idleController.dispose();
    _burstController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_revealing) {
      return ZyncFxRevealStage(
        key: ValueKey(
          'pack-reveal-${widget.spec.id}-${widget.prototype.name}-${widget.openToken}',
        ),
        spec: widget.spec,
        tuning: widget.tuning,
        revealToken: widget.openToken,
        speed: widget.speed,
        respectReduceMotion: widget.respectReduceMotion,
      );
    }

    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, _) {
        final idle = _idleController.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedPack == null)
              _buildPackChoice(idle)
            else
              _buildInteraction(idle),
          ],
        );
      },
    );
  }

  Widget _buildPackChoice(double idle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'CHOOSE A PACK',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.1,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      math.sin((idle + i * 0.23) * math.pi * 2) * 4 +
                          (i == 1 ? -5 : 3),
                    ),
                    child: Transform.rotate(
                      angle: (i - 1) * 0.055,
                      child: GestureDetector(
                        key: ValueKey('pack-choice-$i'),
                        onTap: () => _selectPack(i),
                        child: SizedBox(
                          width: 96,
                          height: 154,
                          child: CustomPaint(
                            painter: _PackPainter(
                              profile: widget.spec.profile,
                              prototype: widget.prototype,
                              progress: 0,
                              energy: _rarityEnergy,
                              idle: idle + i * 0.19,
                              selected: false,
                              opening: false,
                              omen: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pick one. The result is already fixed; the choice is part of the ritual.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.46),
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildInteraction(double idle) {
    final burst = Curves.easeOutCubic.transform(_burstController.value);
    final chargePulse =
        1 + math.sin(idle * math.pi * 2) * 0.012 * _gestureProgress;
    final openingScale = _opening ? 1 + burst * 0.16 : chargePulse;
    final openingOpacity = _opening ? (1 - burst * 0.86).clamp(0.0, 1.0) : 1.0;

    Widget pack = SizedBox(
      width: 232,
      height: 350,
      child: CustomPaint(
        painter: _PackPainter(
          profile: widget.spec.profile,
          prototype: widget.prototype,
          progress: _gestureProgress,
          energy: _rarityEnergy,
          idle: idle,
          selected: true,
          opening: _opening,
          omen: _opening && _hasHiddenOmen,
          burst: burst,
        ),
      ),
    );

    pack = Transform.scale(
      scale: openingScale,
      child: Opacity(opacity: openingOpacity, child: pack),
    );

    pack = switch (widget.prototype) {
      ZyncOpeningPrototype.tearUp => GestureDetector(
          key: const ValueKey('opening-gesture-tear-up'),
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) => _dragValue = 0,
          onVerticalDragUpdate: (details) {
            _dragValue += -details.delta.dy;
            _setProgress(_dragValue / 132);
          },
          onVerticalDragEnd: (_) => _finishDrag(),
          onVerticalDragCancel: _cancelGesture,
          child: pack,
        ),
      ZyncOpeningPrototype.splitOpen => GestureDetector(
          key: const ValueKey('opening-gesture-split-open'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _dragValue = 0,
          onHorizontalDragUpdate: (details) {
            _dragValue += details.delta.dx;
            _setProgress(_dragValue.abs() / 142);
          },
          onHorizontalDragEnd: (_) => _finishDrag(),
          onHorizontalDragCancel: _cancelGesture,
          child: pack,
        ),
      ZyncOpeningPrototype.chargeBurst => GestureDetector(
          key: const ValueKey('opening-gesture-charge-burst'),
          behavior: HitTestBehavior.opaque,
          onTapDown: _chargeDown,
          onTapUp: _chargeUp,
          onTapCancel: _cancelGesture,
          child: pack,
        ),
      ZyncOpeningPrototype.sealSlide => GestureDetector(
          key: const ValueKey('opening-gesture-seal-slide'),
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) => _dragValue = 0,
          onVerticalDragUpdate: (details) {
            _dragValue += details.delta.dy;
            _setProgress(_dragValue / 138);
          },
          onVerticalDragEnd: (_) => _finishDrag(),
          onVerticalDragCancel: _cancelGesture,
          child: pack,
        ),
    };

    final progressLabel = widget.prototype == ZyncOpeningPrototype.chargeBurst
        ? (_gestureProgress < 0.42 ? 'HOLD TO CHARGE' : 'RELEASE')
        : (_gestureProgress < 0.70 ? 'KEEP GOING' : 'RELEASE');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.spec.profile.accentColor.withValues(alpha: 0.16),
                border: Border.all(
                  color:
                      widget.spec.profile.accentColor.withValues(alpha: 0.56),
                ),
              ),
              child: Text(
                widget.prototype.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.prototype.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 320,
          child: Text(
            widget.prototype.instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 14),
        pack,
        const SizedBox(height: 12),
        SizedBox(
          width: 232,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: _gestureProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: widget.spec.profile.accentColor,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _opening ? (_hasHiddenOmen ? '...' : 'OPENING') : progressLabel,
          style: TextStyle(
            color: (_opening && _hasHiddenOmen)
                ? widget.spec.profile.secondaryColor
                : Colors.white.withValues(alpha: 0.48),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.7,
          ),
        ),
        const SizedBox(height: 7),
        TextButton.icon(
          key: const ValueKey('choose-another-pack'),
          onPressed: _opening ? null : _reset,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Choose another pack'),
        ),
      ],
    );
  }
}

class _PackPainter extends CustomPainter {
  const _PackPainter({
    required this.profile,
    required this.prototype,
    required this.progress,
    required this.energy,
    required this.idle,
    required this.selected,
    required this.opening,
    required this.omen,
    this.burst = 0,
  });

  final ZyncCardFxProfile profile;
  final ZyncOpeningPrototype prototype;
  final double progress;
  final double energy;
  final double idle;
  final bool selected;
  final bool opening;
  final bool omen;
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    if (prototype == ZyncOpeningPrototype.splitOpen && selected) {
      _paintSplit(canvas, size);
    } else if (prototype == ZyncOpeningPrototype.tearUp && selected) {
      _paintTear(canvas, size);
    } else {
      _paintFace(canvas, size);
    }

    if (selected) {
      switch (prototype) {
        case ZyncOpeningPrototype.tearUp:
          _paintTearGuide(canvas, size);
        case ZyncOpeningPrototype.splitOpen:
          _paintSplitGuide(canvas, size);
        case ZyncOpeningPrototype.chargeBurst:
          _paintCharge(canvas, size);
        case ZyncOpeningPrototype.sealSlide:
          _paintSealSlide(canvas, size);
      }
    }

    if (omen) _paintOmen(canvas, size);
    if (opening && burst > 0) _paintOpeningBurst(canvas, size);
  }

  void _paintFace(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.075),
    );
    final pulse = 0.5 + 0.5 * math.sin(idle * math.pi * 2);
    final reveal = selected ? progress : 0.0;

    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF111824),
          Color(0xFF28364A),
          Color(0xFF0D1118),
          Color(0xFF1E2938),
        ],
        stops: [0.0, 0.34, 0.68, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rect, base);

    final sheen = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment(-1 + idle * 2, -1),
        end: Alignment(1 + idle * 2, 1),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.06 + pulse * 0.04),
          profile.accentColor.withValues(
            alpha: 0.025 + reveal * 0.13 * energy,
          ),
          Colors.transparent,
        ],
        stops: const [0.0, 0.43, 0.58, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rect, sheen);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.2 : 1.3
      ..color = Color.lerp(
        const Color(0xFF9EAABD),
        profile.accentColor,
        selected ? 0.35 + reveal * 0.45 : 0.08,
      )!
          .withValues(alpha: selected ? 0.90 : 0.64);
    canvas.drawRRect(rect.deflate(1), border);

    final topSealY = size.height * 0.105;
    final seal = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.08, topSealY),
      Offset(size.width * 0.92, topSealY),
      seal,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.89),
      Offset(size.width * 0.92, size.height * 0.89),
      seal,
    );

    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.10 + i * 0.115);
      canvas.drawLine(
        Offset(x, size.height * 0.035),
        Offset(x + size.width * 0.05, size.height * 0.075),
        Paint()
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.045),
      );
    }

    _paintText(
      canvas,
      'ZYNC',
      Offset(size.width * 0.14, size.height * 0.19),
      size.width * 0.18,
      Colors.white,
      FontWeight.w900,
      letterSpacing: 1.6,
    );
    _paintText(
      canvas,
      'ACTIVITY CARD',
      Offset(size.width * 0.145, size.height * 0.31),
      size.width * 0.055,
      Colors.white.withValues(alpha: 0.54),
      FontWeight.w700,
      letterSpacing: 1.5,
    );

    final emblemCenter = Offset(size.width * 0.50, size.height * 0.58);
    final emblem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..color = profile.accentColor.withValues(
        alpha: 0.18 + reveal * 0.46 * energy,
      );
    canvas.drawCircle(emblemCenter, size.width * 0.20, emblem);
    canvas.drawCircle(
      emblemCenter,
      size.width * 0.125,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.006
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    _paintText(
      canvas,
      'Z',
      Offset(size.width * 0.425, size.height * 0.505),
      size.width * 0.20,
      Colors.white.withValues(alpha: 0.92),
      FontWeight.w900,
      fontStyle: FontStyle.italic,
    );

    _paintText(
      canvas,
      'HOLD · OPEN · DISCOVER',
      Offset(size.width * 0.145, size.height * 0.81),
      size.width * 0.043,
      Colors.white.withValues(alpha: 0.45),
      FontWeight.w700,
      letterSpacing: 0.8,
    );
  }

  void _paintTear(Canvas canvas, Size size) {
    final tearY = size.height * 0.072;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, tearY, size.width, size.height - tearY));
    _paintFace(canvas, size);
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, tearY + 2));
    canvas.translate(0, -progress * size.height * 0.20);
    canvas.rotate(-progress * 0.035);
    _paintFace(canvas, size);
    canvas.restore();
  }

  void _paintSplit(Canvas canvas, Size size) {
    final shift = progress * size.width * 0.19;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
    canvas.translate(-shift, 0);
    _paintFace(canvas, size);
    canvas.restore();

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
    );
    canvas.translate(shift, 0);
    _paintFace(canvas, size);
    canvas.restore();
  }

  void _paintTearGuide(Canvas canvas, Size size) {
    final y = size.height * 0.072;
    final glow = Paint()
      ..strokeWidth = 2.0
      ..color = profile.accentColor.withValues(
        alpha: 0.18 + progress * 0.62 * energy,
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.012);
    canvas.drawLine(
      Offset(size.width * 0.08, y),
      Offset(size.width * 0.92, y),
      glow,
    );
    final arrowY = y - size.height * (0.02 + progress * 0.05);
    canvas.drawLine(
      Offset(size.width * 0.50, arrowY + size.height * 0.055),
      Offset(size.width * 0.50, arrowY),
      Paint()
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.42),
    );
  }

  void _paintSplitGuide(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final alpha = 0.16 + progress * 0.68 * energy;
    final seam = Paint()
      ..strokeWidth = 2.1
      ..color = profile.accentColor.withValues(alpha: alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.01);
    canvas.drawLine(
      Offset(centerX, size.height * 0.10),
      Offset(centerX, size.height * 0.90),
      seam,
    );

    final arrow = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.38);
    final y = size.height * 0.54;
    canvas.drawLine(
      Offset(centerX - size.width * 0.05, y),
      Offset(centerX - size.width * 0.16, y),
      arrow,
    );
    canvas.drawLine(
      Offset(centerX + size.width * 0.05, y),
      Offset(centerX + size.width * 0.16, y),
      arrow,
    );
  }

  void _paintCharge(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.56);
    final pulse = 0.5 + 0.5 * math.sin(idle * math.pi * 4);
    final glowStrength = (0.08 + progress * 0.42) * energy;

    for (var i = 0; i < 3; i++) {
      final radius =
          size.width * (0.24 + i * 0.09 + progress * 0.07 + pulse * 0.015);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3 + progress * 1.8
          ..color = profile.accentColor.withValues(
            alpha: glowStrength / (i + 1),
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            size.width * (0.006 + progress * 0.010),
          ),
      );
    }

    final rayCount = 8 + (progress * 10).round();
    for (var i = 0; i < rayCount; i++) {
      final angle = (i / math.max(1, rayCount)) * math.pi * 2 + idle * math.pi;
      final inner = size.width * (0.28 + progress * 0.02);
      final outer = size.width * (0.31 + progress * (0.09 + (i % 3) * 0.02));
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.0 + progress
          ..color = (i.isEven ? profile.accentColor : profile.secondaryColor)
              .withValues(alpha: progress * 0.42 * energy),
      );
    }
  }

  void _paintSealSlide(Canvas canvas, Size size) {
    final x = size.width * 0.80;
    final top = size.height * 0.16;
    final bottom = size.height * 0.80;
    final y = top + (bottom - top) * progress;

    final track = Paint()
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawLine(Offset(x, top), Offset(x, bottom), track);

    final unlocked = Paint()
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round
      ..color = profile.accentColor.withValues(
        alpha: 0.20 + progress * 0.65 * energy,
      );
    canvas.drawLine(Offset(x, top), Offset(x, y), unlocked);

    final tabRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: size.width * 0.15,
        height: size.height * 0.055,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(
      tabRect,
      Paint()
        ..color = const Color(0xFF101722)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      tabRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = profile.accentColor.withValues(alpha: 0.70),
    );
  }

  void _paintOmen(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.51);
    final phase = (burst * 1.7).clamp(0.0, 1.0);
    final alpha = math.sin(phase * math.pi).abs();

    final haloRect = Rect.fromCenter(
      center: center,
      width: size.width * (1.1 + phase * 0.25),
      height: size.height * (0.82 + phase * 0.16),
    );
    canvas.drawOval(
      haloRect,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF5CC).withValues(alpha: 0.28 * alpha),
            const Color(0xFFFFC84E).withValues(alpha: 0.16 * alpha),
            Colors.transparent,
          ],
        ).createShader(haloRect),
    );

    final crack = Path()
      ..moveTo(size.width * 0.47, size.height * 0.18)
      ..lineTo(size.width * 0.52, size.height * 0.30)
      ..lineTo(size.width * 0.49, size.height * 0.41)
      ..lineTo(size.width * 0.55, size.height * 0.55);
    canvas.drawPath(
      crack,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFE8A3).withValues(alpha: 0.70 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }

  void _paintOpeningBurst(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rarityBoost = profile.rarity == ZyncFxRarity.legendary ? 1.45 : 1.0;
    final alpha = (1 - burst) * energy * rarityBoost;

    for (var i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2 + i * 0.23;
      final travel = size.width * (0.22 + burst * (0.36 + (i % 3) * 0.03));
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * size.width * 0.16;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * travel;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.3 + (i % 3) * 0.7
          ..color = (i.isEven ? profile.accentColor : profile.secondaryColor)
              .withValues(alpha: alpha.clamp(0.0, 0.88)),
      );
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = profile.accentColor.withValues(
        alpha: ((1 - burst) * 0.58 * energy).clamp(0.0, 0.72),
      );
    canvas.drawCircle(
      center,
      size.width * (0.24 + burst * 0.50),
      ring,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Color color,
    FontWeight fontWeight, {
    double letterSpacing = 0,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PackPainter oldDelegate) =>
      oldDelegate.profile.rarity != profile.rarity ||
      oldDelegate.prototype != prototype ||
      oldDelegate.progress != progress ||
      oldDelegate.idle != idle ||
      oldDelegate.selected != selected ||
      oldDelegate.opening != opening ||
      oldDelegate.omen != omen ||
      oldDelegate.burst != burst;
}
