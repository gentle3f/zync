import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'card_fx_spec.dart';
import 'zync_fx_reveal.dart';
import 'zync_fx_sensory.dart';

enum ZyncOpeningPrototype { tearUp, splitOpen, chargeBurst, sealSlide }

double _splitSeparationFor(double effectiveProgress) {
  final normalized =
      ((effectiveProgress - 0.12) / 0.88).clamp(0.0, 1.0).toDouble();
  return Curves.easeOutCubic.transform(normalized);
}

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
  int _splitTensionCueIndex = -1;
  bool _opening = false;
  bool _extracting = false;
  bool _revealing = false;

  Timer? _revealTimer;
  Timer? _omenTimer;
  late final AnimationController _idleController;
  late final AnimationController _burstController;
  late final AnimationController _extractController;
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
    _extractController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (560 / widget.speed.clamp(0.55, 1.8)).round(),
      ),
      animationBehavior: _behavior,
    )
      ..addListener(_tick)
      ..addStatusListener((status) {
        if (!mounted || !_extracting || status != AnimationStatus.completed) {
          return;
        }
        setState(() => _revealing = true);
      });
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
    if (oldWidget.speed != widget.speed) {
      _extractController.duration = Duration(
        milliseconds: (560 / widget.speed.clamp(0.55, 1.8)).round(),
      );
    }
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
    _omenTimer?.cancel();
    _selectedPack = null;
    _gestureProgress = 0;
    _dragValue = 0;
    _splitTensionCueIndex = -1;
    _opening = false;
    _extracting = false;
    _revealing = false;
    _burstController.reset();
    _extractController.reset();
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
    ZyncFxSensory.play(
      ZyncFxSensoryEvent.packPick,
      rarity: widget.spec.rarity,
    );
    setState(() {
      _selectedPack = index;
      _gestureProgress = 0;
      _dragValue = 0;
      _splitTensionCueIndex = -1;
      _burstController.reset();
      _extractController.reset();
      _chargeController.reset();
    });
  }

  void _setProgress(double value) {
    if (_opening || _revealing) return;
    setState(() => _gestureProgress = value.clamp(0.0, 1.0));
  }

  void _maybePlaySplitTension(double value) {
    if (widget.prototype != ZyncOpeningPrototype.splitOpen ||
        _opening ||
        value < 0.12) {
      return;
    }
    final cueIndex = math.min(
      5,
      math.max(0, ((value - 0.12) / 0.15).floor()),
    );
    if (cueIndex <= _splitTensionCueIndex) return;
    _splitTensionCueIndex = cueIndex;
    ZyncFxSensory.play(
      ZyncFxSensoryEvent.foilTension,
      rarity: widget.spec.rarity,
      haptic: false,
    );
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
      _splitTensionCueIndex = -1;
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
    ZyncFxSensory.play(
      ZyncFxSensoryEvent.chargeArm,
      rarity: widget.spec.rarity,
      sound: false,
    );
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
    ZyncFxSensory.play(
      switch (widget.prototype) {
        ZyncOpeningPrototype.tearUp => ZyncFxSensoryEvent.tearBreak,
        ZyncOpeningPrototype.splitOpen => ZyncFxSensoryEvent.splitBreak,
        ZyncOpeningPrototype.chargeBurst => ZyncFxSensoryEvent.chargeBurst,
        ZyncOpeningPrototype.sealSlide => ZyncFxSensoryEvent.sealUnlock,
      },
      rarity: widget.spec.rarity,
    );
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
    if (_hasHiddenOmen) {
      _omenTimer = Timer(const Duration(milliseconds: 290), () {
        if (!mounted || !_opening) return;
        ZyncFxSensory.play(
          ZyncFxSensoryEvent.hiddenOmen,
          rarity: widget.spec.rarity,
        );
      });
    }
    _revealTimer = Timer(Duration(milliseconds: revealDelay), () {
      if (!mounted) return;
      ZyncFxSensory.play(
        ZyncFxSensoryEvent.cardExtract,
        rarity: widget.spec.rarity,
      );
      setState(() => _extracting = true);
      _extractController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _omenTimer?.cancel();
    _idleController.dispose();
    _burstController.dispose();
    _extractController.dispose();
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
        startFromSettledBack: true,
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
                          width: 108,
                          height: 166,
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
    final extraction = Curves.easeOutCubic.transform(_extractController.value);
    final cardOpacity = Curves.easeIn.transform(
      (extraction / 0.28).clamp(0.0, 1.0),
    );
    final chargePulse =
        1 + math.sin(idle * math.pi * 2) * 0.012 * _gestureProgress;
    final openingScale = 1.06 * (_opening ? 1 + burst * 0.16 : chargePulse);
    final wrapperExit = Curves.easeIn.transform(
      ((extraction - 0.58) / 0.42).clamp(0.0, 1.0),
    );
    final wrapperOpacity = _opening
        ? (1 - burst * 0.12 - wrapperExit * 0.80).clamp(0.08, 1.0)
        : 1.0;
    final splitEffectiveProgress =
        widget.prototype == ZyncOpeningPrototype.splitOpen
            ? (_opening
                ? (_gestureProgress + (1 - _gestureProgress) * burst)
                    .clamp(0.0, 1.0)
                    .toDouble()
                : _gestureProgress)
            : 0.0;
    final splitSeparation = _splitSeparationFor(splitEffectiveProgress);
    final splitInteriorFraction = splitSeparation <= 0
        ? 0.0
        : (0.018 + splitSeparation * 0.46).clamp(0.0, 0.48).toDouble();
    final splitCardReveal = Curves.easeOutCubic.transform(
      ((splitEffectiveProgress - 0.30) / 0.58).clamp(0.0, 1.0).toDouble(),
    );
    final splitCardFraction = splitInteriorFraction *
        math.pow(splitCardReveal, 0.72).toDouble() *
        0.92;

    Widget wrapper = SizedBox(
      width: 390,
      height: 620,
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

    wrapper = Transform.translate(
      offset: Offset(0, extraction * 240),
      child: Transform.scale(
        scale: openingScale,
        child: Opacity(opacity: wrapperOpacity, child: wrapper),
      ),
    );

    Widget? cardBackLayer;
    if (_extracting || widget.prototype == ZyncOpeningPrototype.splitOpen) {
      Widget physicalBack = SizedBox(
        width: 390,
        height: 620,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, 128 * (1 - extraction)),
            child: Transform.scale(
              scale: 0.82 + extraction * 0.10,
              child: SizedBox(
                width: 390,
                height: 585,
                child: ZyncFxCardBack(
                  accent: widget.spec.profile.accentColor,
                ),
              ),
            ),
          ),
        ),
      );

      if (widget.prototype == ZyncOpeningPrototype.splitOpen && !_extracting) {
        physicalBack = ClipRect(
          key: const ValueKey('opening-split-card-window'),
          clipper: _CenterGapClipper(
            widthFraction: splitCardFraction,
            topFraction: 0.15,
            bottomFraction: 0.86,
          ),
          child: physicalBack,
        );
        cardBackLayer = KeyedSubtree(
          key: const ValueKey('opening-split-preextract-back'),
          child: physicalBack,
        );
      } else {
        cardBackLayer = KeyedSubtree(
          key: const ValueKey('opening-card-extraction-back'),
          child: widget.prototype == ZyncOpeningPrototype.splitOpen
              ? physicalBack
              : Opacity(opacity: cardOpacity, child: physicalBack),
        );
      }
    }

    Widget pack = SizedBox(
      width: 390,
      height: 620,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.prototype == ZyncOpeningPrototype.splitOpen &&
              splitInteriorFraction > 0)
            SizedBox(
              width: 390 * splitInteriorFraction,
              height: 620 * 0.70,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF020304),
                      Color(0xFF111A24),
                      Color(0xFF05070A),
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          if (cardBackLayer != null) cardBackLayer,
          wrapper,
        ],
      ),
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
            final next = (_dragValue.abs() / 142).clamp(0.0, 1.0).toDouble();
            _setProgress(next);
            _maybePlaySplitTension(next);
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
          width: 300,
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
          _opening
              ? (_extracting
                  ? 'DRAWING CARD'
                  : (_hasHiddenOmen ? '...' : 'OPENING'))
              : progressLabel,
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

class _CenterGapClipper extends CustomClipper<Rect> {
  const _CenterGapClipper({
    required this.widthFraction,
    required this.topFraction,
    required this.bottomFraction,
  });

  final double widthFraction;
  final double topFraction;
  final double bottomFraction;

  @override
  Rect getClip(Size size) {
    final width = size.width * widthFraction.clamp(0.0, 1.0);
    return Rect.fromLTRB(
      (size.width - width) / 2,
      size.height * topFraction,
      (size.width + width) / 2,
      size.height * bottomFraction,
    );
  }

  @override
  bool shouldReclip(covariant _CenterGapClipper oldClipper) =>
      oldClipper.widthFraction != widthFraction ||
      oldClipper.topFraction != topFraction ||
      oldClipper.bottomFraction != bottomFraction;
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
    if (prototype == ZyncOpeningPrototype.chargeBurst && selected && opening) {
      _paintChargeBurstWrapper(canvas, size);
    } else if (prototype == ZyncOpeningPrototype.splitOpen && selected) {
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
    final pulse = 0.5 + 0.5 * math.sin(idle * math.pi * 2);
    final reveal = selected ? progress : 0.0;
    final body = Path()
      ..moveTo(size.width * 0.025, size.height * 0.02)
      ..quadraticBezierTo(
        size.width * 0.008,
        size.height * 0.15,
        size.width * 0.020,
        size.height * 0.29,
      )
      ..quadraticBezierTo(
        size.width * 0.008,
        size.height * 0.52,
        size.width * 0.025,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.008,
        size.height * 0.86,
        size.width * 0.030,
        size.height * 0.98,
      )
      ..lineTo(size.width * 0.97, size.height * 0.98)
      ..quadraticBezierTo(
        size.width * 0.992,
        size.height * 0.86,
        size.width * 0.975,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.992,
        size.height * 0.52,
        size.width * 0.980,
        size.height * 0.29,
      )
      ..quadraticBezierTo(
        size.width * 0.992,
        size.height * 0.15,
        size.width * 0.975,
        size.height * 0.02,
      )
      ..close();

    final foilBounds = Rect.fromLTWH(
      size.width * 0.015,
      size.height * 0.015,
      size.width * 0.97,
      size.height * 0.97,
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF060B12),
            Color(0xFF71849A),
            Color(0xFF101925),
            Color(0xFF34475D),
            Color(0xFF9BAABC),
            Color(0xFF0A111A),
          ],
          stops: [0.0, 0.14, 0.31, 0.50, 0.67, 1.0],
        ).createShader(foilBounds),
    );

    canvas.save();
    canvas.clipPath(body);

    final sheen = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment(-1.5 + idle * 2.4, -1),
        end: Alignment(0.4 + idle * 2.4, 1),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.05 + pulse * 0.055),
          profile.accentColor.withValues(
            alpha: 0.035 + reveal * 0.12 * energy,
          ),
          Colors.white.withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [0.0, 0.36, 0.49, 0.58, 1.0],
      ).createShader(foilBounds);
    canvas.drawRect(foilBounds, sheen);

    final specSweep = (idle * 1.65) % 1.0;
    final directionalSpecular = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment(-1.85 + specSweep * 3.5, -1.0),
        end: Alignment(-0.35 + specSweep * 3.5, 1.0),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: selected ? 0.055 : 0.035),
          Colors.white.withValues(
            alpha: (selected ? 0.24 : 0.15) + reveal * 0.08 * energy,
          ),
          profile.secondaryColor.withValues(
            alpha: 0.065 + reveal * 0.055 * energy,
          ),
          Colors.transparent,
        ],
        stops: const [0.0, 0.43, 0.495, 0.55, 1.0],
      ).createShader(foilBounds);
    canvas.drawRect(foilBounds, directionalSpecular);

    final label = Path()
      ..moveTo(size.width * 0.10, size.height * 0.30)
      ..lineTo(size.width * 0.90, size.height * 0.235)
      ..lineTo(size.width * 0.90, size.height * 0.665)
      ..lineTo(size.width * 0.10, size.height * 0.72)
      ..close();
    canvas.drawPath(
      label,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF07111D).withValues(alpha: 0.84),
            const Color(0xFF111D2C).withValues(alpha: 0.82),
            profile.accentColor.withValues(alpha: 0.16 + reveal * 0.12),
          ],
        ).createShader(foilBounds),
    );
    canvas.drawPath(
      label,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = profile.accentColor.withValues(
          alpha: 0.34 + reveal * 0.28 * energy,
        ),
    );
    canvas.save();
    canvas.clipPath(label);
    canvas.drawRect(
      foilBounds,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment(-1.2 + specSweep * 2.4, -0.8),
          end: Alignment(0.2 + specSweep * 2.4, 0.9),
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.10),
            profile.accentColor.withValues(alpha: 0.045),
            Colors.transparent,
          ],
          stops: const [0.0, 0.46, 0.54, 1.0],
        ).createShader(foilBounds),
    );
    canvas.restore();

    final topCrimp = Rect.fromLTWH(
      size.width * 0.020,
      size.height * 0.020,
      size.width * 0.96,
      size.height * 0.105,
    );
    final bottomCrimp = Rect.fromLTWH(
      size.width * 0.025,
      size.height * 0.875,
      size.width * 0.95,
      size.height * 0.105,
    );
    final crimpPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF77879A),
          Color(0xFF202C3A),
          Color(0xFF68798D),
        ],
      ).createShader(foilBounds);
    canvas.drawRect(topCrimp, crimpPaint);
    canvas.drawRect(bottomCrimp, crimpPaint);

    final crimpShadow = Paint()
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: 0.38);
    final crimpHighlight = Paint()
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.42);
    for (var i = 0; i < 18; i++) {
      final x = size.width * (0.055 + i * 0.0525);
      final topStart = Offset(x, size.height * 0.029);
      final topEnd = Offset(x - size.width * 0.020, size.height * 0.113);
      final bottomStart = Offset(x, size.height * 0.887);
      final bottomEnd = Offset(x + size.width * 0.020, size.height * 0.971);
      canvas.drawLine(
        topStart + const Offset(1.4, 1.2),
        topEnd + const Offset(1.4, 1.2),
        crimpShadow,
      );
      canvas.drawLine(topStart, topEnd, crimpHighlight);
      canvas.drawLine(
        bottomStart + const Offset(1.4, 1.2),
        bottomEnd + const Offset(1.4, 1.2),
        crimpShadow,
      );
      canvas.drawLine(bottomStart, bottomEnd, crimpHighlight);
    }
    final crimpBoundaryShadow = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.black.withValues(alpha: 0.34);
    final crimpBoundaryLight = Paint()
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawLine(
      Offset(size.width * 0.03, size.height * 0.124),
      Offset(size.width * 0.97, size.height * 0.124),
      crimpBoundaryShadow,
    );
    canvas.drawLine(
      Offset(size.width * 0.03, size.height * 0.121),
      Offset(size.width * 0.97, size.height * 0.121),
      crimpBoundaryLight,
    );
    canvas.drawLine(
      Offset(size.width * 0.03, size.height * 0.876),
      Offset(size.width * 0.97, size.height * 0.876),
      crimpBoundaryShadow,
    );
    canvas.drawLine(
      Offset(size.width * 0.03, size.height * 0.873),
      Offset(size.width * 0.97, size.height * 0.873),
      crimpBoundaryLight,
    );

    final sideSeam = Paint()
      ..strokeWidth = size.width * 0.018
      ..color = const Color(0xFF02060B).withValues(alpha: 0.56);
    canvas.drawLine(
      Offset(size.width * 0.035, size.height * 0.135),
      Offset(size.width * 0.040, size.height * 0.865),
      sideSeam,
    );
    canvas.drawLine(
      Offset(size.width * 0.965, size.height * 0.135),
      Offset(size.width * 0.960, size.height * 0.865),
      sideSeam,
    );
    final seamLight = Paint()
      ..strokeWidth = 1.35
      ..color = Colors.white.withValues(alpha: 0.34);
    canvas.drawLine(
      Offset(size.width * 0.052, size.height * 0.14),
      Offset(size.width * 0.055, size.height * 0.86),
      seamLight,
    );
    canvas.drawLine(
      Offset(size.width * 0.948, size.height * 0.14),
      Offset(size.width * 0.945, size.height * 0.86),
      seamLight,
    );

    final wrinkle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.10);
    final wrinkleDark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: 0.18);
    final wrinkles = <Path>[
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.20)
        ..quadraticBezierTo(
          size.width * 0.19,
          size.height * 0.24,
          size.width * 0.28,
          size.height * 0.31,
        ),
      Path()
        ..moveTo(size.width * 0.92, size.height * 0.19)
        ..quadraticBezierTo(
          size.width * 0.80,
          size.height * 0.25,
          size.width * 0.70,
          size.height * 0.34,
        ),
      Path()
        ..moveTo(size.width * 0.07, size.height * 0.76)
        ..quadraticBezierTo(
          size.width * 0.19,
          size.height * 0.72,
          size.width * 0.30,
          size.height * 0.67,
        ),
      Path()
        ..moveTo(size.width * 0.93, size.height * 0.77)
        ..quadraticBezierTo(
          size.width * 0.82,
          size.height * 0.72,
          size.width * 0.70,
          size.height * 0.68,
        ),
      Path()
        ..moveTo(size.width * 0.16, size.height * 0.17)
        ..quadraticBezierTo(
          size.width * 0.42,
          size.height * 0.19,
          size.width * 0.55,
          size.height * 0.16,
        ),
      Path()
        ..moveTo(size.width * 0.44, size.height * 0.82)
        ..quadraticBezierTo(
          size.width * 0.58,
          size.height * 0.78,
          size.width * 0.84,
          size.height * 0.81,
        ),
    ];
    if (selected && prototype == ZyncOpeningPrototype.splitOpen) {
      wrinkles.addAll([
        Path()
          ..moveTo(size.width * 0.50, size.height * 0.23)
          ..quadraticBezierTo(
            size.width * 0.43,
            size.height * 0.34,
            size.width * 0.36,
            size.height * 0.43,
          ),
        Path()
          ..moveTo(size.width * 0.50, size.height * 0.25)
          ..quadraticBezierTo(
            size.width * 0.57,
            size.height * 0.35,
            size.width * 0.65,
            size.height * 0.44,
          ),
        Path()
          ..moveTo(size.width * 0.50, size.height * 0.77)
          ..quadraticBezierTo(
            size.width * 0.43,
            size.height * 0.68,
            size.width * 0.35,
            size.height * 0.61,
          ),
        Path()
          ..moveTo(size.width * 0.50, size.height * 0.75)
          ..quadraticBezierTo(
            size.width * 0.58,
            size.height * 0.67,
            size.width * 0.66,
            size.height * 0.60,
          ),
      ]);
    }
    for (final wrinklePath in wrinkles) {
      canvas.save();
      canvas.translate(0.9, 1.1);
      canvas.drawPath(wrinklePath, wrinkleDark);
      canvas.restore();
      canvas.drawPath(wrinklePath, wrinkle);
    }

    _paintText(
      canvas,
      'ZYNC',
      Offset(size.width * 0.17, size.height * 0.365),
      size.width * 0.235,
      Colors.white,
      FontWeight.w900,
      letterSpacing: 2.2,
    );
    _paintText(
      canvas,
      'ACTIVITY BOOSTER',
      Offset(size.width * 0.175, size.height * 0.525),
      size.width * 0.057,
      Colors.white.withValues(alpha: 0.70),
      FontWeight.w800,
      letterSpacing: 1.35,
    );

    final accentY = size.height * 0.625;
    canvas.drawLine(
      Offset(size.width * 0.18, accentY),
      Offset(size.width * 0.82, accentY),
      Paint()
        ..strokeWidth = 2
        ..color = profile.accentColor.withValues(
          alpha: 0.44 + reveal * 0.32 * energy,
        ),
    );
    _paintText(
      canvas,
      'OPEN / DISCOVER / DO',
      Offset(size.width * 0.19, size.height * 0.665),
      size.width * 0.038,
      Colors.white.withValues(alpha: 0.47),
      FontWeight.w700,
      letterSpacing: 0.65,
    );

    canvas.save();
    canvas.clipPath(label);
    canvas.drawRect(
      label.getBounds(),
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment(-1.4 + specSweep * 2.8, -1),
          end: Alignment(0.3 + specSweep * 2.8, 1),
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.085),
            profile.secondaryColor.withValues(alpha: 0.035),
            Colors.transparent,
          ],
          stops: const [0.0, 0.47, 0.54, 1.0],
        ).createShader(label.getBounds()),
    );
    canvas.restore();

    canvas.restore();

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.8 : 1.25
        ..color = Color.lerp(
          const Color(0xFF94A4B9),
          profile.accentColor,
          selected ? 0.30 + reveal * 0.42 : 0.08,
        )!
            .withValues(alpha: selected ? 0.88 : 0.62),
    );
  }

  void _paintTear(Canvas canvas, Size size) {
    final tearY = size.height * 0.145;
    final tearProgress = opening
        ? (progress + (1 - progress) * burst).clamp(0.0, 1.0)
        : progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, tearY, size.width, size.height - tearY));
    _paintFace(canvas, size);
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, tearY + 3));
    canvas.translate(
      tearProgress * size.width * 0.045,
      -tearProgress * size.height * 0.23,
    );
    canvas.rotate(-tearProgress * 0.075);
    _paintFace(canvas, size);
    canvas.restore();

    if (tearProgress > 0.18) {
      final rip = Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.32);
      for (var i = 0; i < 12; i++) {
        final x1 = size.width * (0.055 + i * 0.075);
        final dy = (i.isEven ? 1 : -1) * size.height * 0.008;
        canvas.drawLine(
          Offset(x1, tearY + dy),
          Offset(x1 + size.width * 0.045, tearY - dy),
          rip,
        );
      }
    }
  }

  void _paintSplit(Canvas canvas, Size size) {
    final effectiveProgress = opening
        ? (progress + (1 - progress) * burst).clamp(0.0, 1.0).toDouble()
        : progress;
    final separation = _splitSeparationFor(effectiveProgress);
    final shift = separation * size.width * 0.24;

    canvas.save();
    canvas.translate(-shift, 0);
    canvas.rotate(-separation * 0.018);
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
    _paintFace(canvas, size);
    canvas.restore();

    canvas.save();
    canvas.translate(shift, 0);
    canvas.rotate(separation * 0.018);
    canvas.clipRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
    );
    _paintFace(canvas, size);
    canvas.restore();

    if (separation > 0.015) {
      final leftEdge = Path();
      final rightEdge = Path();
      for (var i = 0; i <= 14; i++) {
        final t = i / 14;
        final y = size.height * (0.15 + t * 0.71);
        final jitter =
            math.sin(i * 2.17 + separation * 4.2) * size.width * 0.0045;
        final lx = size.width * 0.5 - shift + jitter;
        final rx = size.width * 0.5 + shift - jitter;
        if (i == 0) {
          leftEdge.moveTo(lx, y);
          rightEdge.moveTo(rx, y);
        } else {
          leftEdge.lineTo(lx, y);
          rightEdge.lineTo(rx, y);
        }
      }
      final edgeShadow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.38);
      final edgeHighlight = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.48);
      canvas.drawPath(leftEdge, edgeShadow);
      canvas.drawPath(rightEdge, edgeShadow);
      canvas.drawPath(leftEdge, edgeHighlight);
      canvas.drawPath(rightEdge, edgeHighlight);
    }
  }

  void _paintChargeBurstWrapper(Canvas canvas, Size size) {
    final spread = Curves.easeOutCubic.transform(burst);
    final shift = size.width * (0.06 + spread * 0.42);

    canvas.save();
    canvas.translate(-shift, -spread * size.height * 0.035);
    canvas.rotate(-spread * 0.11);
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
    _paintFace(canvas, size);
    canvas.restore();

    canvas.save();
    canvas.translate(shift, -spread * size.height * 0.02);
    canvas.rotate(spread * 0.11);
    canvas.clipRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
    );
    _paintFace(canvas, size);
    canvas.restore();

    final shardPaint = Paint()
      ..color = Colors.white.withValues(alpha: (1 - spread) * 0.34);
    for (var i = 0; i < 8; i++) {
      final dir = i.isEven ? -1.0 : 1.0;
      final x =
          size.width * 0.5 + dir * size.width * (0.06 + i * 0.018) * spread;
      final y = size.height * (0.24 + (i % 4) * 0.15) -
          spread * size.height * (0.03 + (i % 3) * 0.02);
      final shard = Path()
        ..moveTo(x, y)
        ..lineTo(x + dir * size.width * 0.05, y - size.height * 0.018)
        ..lineTo(x + dir * size.width * 0.025, y + size.height * 0.025)
        ..close();
      canvas.drawPath(shard, shardPaint);
    }
  }

  void _paintTearGuide(Canvas canvas, Size size) {
    final y = size.height * 0.145;
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
    final effectiveProgress = opening
        ? (progress + (1 - progress) * burst).clamp(0.0, 1.0).toDouble()
        : progress;
    final separation = _splitSeparationFor(effectiveProgress);
    final guideFade = (1 - separation * 0.96).clamp(0.0, 1.0);
    final alpha = (0.16 + progress * 0.68 * energy) * guideFade;
    final seam = Paint()
      ..strokeWidth = 2.1
      ..color = profile.accentColor.withValues(alpha: alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.01);
    final splitPath = Path()
      ..moveTo(centerX, size.height * 0.16)
      ..lineTo(centerX - size.width * 0.018, size.height * 0.30)
      ..lineTo(centerX + size.width * 0.016, size.height * 0.43)
      ..lineTo(centerX - size.width * 0.012, size.height * 0.58)
      ..lineTo(centerX + size.width * 0.018, size.height * 0.72)
      ..lineTo(centerX, size.height * 0.84);
    canvas.drawPath(splitPath, seam);

    final arrow = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.38 * guideFade);
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
    final startY = size.height * 0.60;
    final travel = size.height * 0.22;
    final y = startY + travel * progress;
    final bandHeight = size.height * 0.078;
    final bandRect = Rect.fromLTWH(
      size.width * 0.035,
      y - bandHeight / 2,
      size.width * 0.93,
      bandHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bandRect,
        Radius.circular(size.width * 0.022),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF75869A).withValues(alpha: 0.90),
            const Color(0xFF121B27).withValues(alpha: 0.96),
            profile.accentColor.withValues(alpha: 0.34 + progress * 0.28),
          ],
        ).createShader(bandRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bandRect,
        Radius.circular(size.width * 0.022),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = profile.accentColor.withValues(alpha: 0.62),
    );

    for (var i = 0; i < 7; i++) {
      final cx = size.width * (0.16 + i * 0.11);
      canvas.drawLine(
        Offset(cx, y - bandHeight * 0.19),
        Offset(cx + size.width * 0.028, y),
        Paint()
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.26),
      );
      canvas.drawLine(
        Offset(cx + size.width * 0.028, y),
        Offset(cx, y + bandHeight * 0.19),
        Paint()
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.26),
      );
    }

    final tabCenter = Offset(size.width * 0.91, y);
    final tabRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: tabCenter,
        width: size.width * 0.19,
        height: bandHeight * 1.22,
      ),
      Radius.circular(size.width * 0.025),
    );
    canvas.drawRRect(
      tabRect,
      Paint()..color = const Color(0xFF08101A),
    );
    canvas.drawRRect(
      tabRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = profile.accentColor.withValues(alpha: 0.80),
    );

    final unlockTrack = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = profile.accentColor.withValues(alpha: 0.28 + progress * 0.34);
    canvas.drawLine(
      Offset(size.width * 0.91, startY - bandHeight),
      Offset(size.width * 0.91, y - bandHeight * 0.72),
      unlockTrack,
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
