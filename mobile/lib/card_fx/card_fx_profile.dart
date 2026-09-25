import 'package:flutter/material.dart';

import '../core/cardverse_models.dart';

enum CardAmbientFx {
  none,
  dust,
  steam,
  digitalPulse,
  embers,
  waterCaustic,
}

@immutable
class CardFxProfile {
  const CardFxProfile({
    required this.finish,
    required this.maxTiltRadians,
    required this.parallaxPixels,
    required this.foilOpacity,
    required this.edgeGlowOpacity,
    required this.particleCount,
    required this.revealDuration,
    required this.impactScale,
    required this.glowColors,
  });

  final CardFinishTier finish;
  final double maxTiltRadians;
  final double parallaxPixels;
  final double foilOpacity;
  final double edgeGlowOpacity;
  final int particleCount;
  final Duration revealDuration;
  final double impactScale;
  final List<Color> glowColors;

  bool get hasFoil => foilOpacity > 0;
  bool get hasParticles => particleCount > 0;

  static CardFxProfile forFinish(CardFinishTier finish) => switch (finish) {
        CardFinishTier.normal => const CardFxProfile(
            finish: CardFinishTier.normal,
            maxTiltRadians: 0.075,
            parallaxPixels: 3,
            foilOpacity: 0,
            edgeGlowOpacity: 0.08,
            particleCount: 0,
            revealDuration: Duration(milliseconds: 680),
            impactScale: 1.01,
            glowColors: [Color(0xFFCDD5E1), Color(0xFFFFFFFF)],
          ),
        CardFinishTier.foil => const CardFxProfile(
            finish: CardFinishTier.foil,
            maxTiltRadians: 0.085,
            parallaxPixels: 4,
            foilOpacity: 0.16,
            edgeGlowOpacity: 0.14,
            particleCount: 2,
            revealDuration: Duration(milliseconds: 760),
            impactScale: 1.015,
            glowColors: [Color(0xFFE8FFF7), Color(0xFFA7F3D0)],
          ),
        CardFinishTier.holo => const CardFxProfile(
            finish: CardFinishTier.holo,
            maxTiltRadians: 0.095,
            parallaxPixels: 5,
            foilOpacity: 0.24,
            edgeGlowOpacity: 0.22,
            particleCount: 5,
            revealDuration: Duration(milliseconds: 860),
            impactScale: 1.025,
            glowColors: [Color(0xFF67E8F9), Color(0xFFC084FC)],
          ),
        CardFinishTier.prism => const CardFxProfile(
            finish: CardFinishTier.prism,
            maxTiltRadians: 0.105,
            parallaxPixels: 6,
            foilOpacity: 0.32,
            edgeGlowOpacity: 0.30,
            particleCount: 8,
            revealDuration: Duration(milliseconds: 980),
            impactScale: 1.035,
            glowColors: [
              Color(0xFF22D3EE),
              Color(0xFF818CF8),
              Color(0xFFE879F9),
            ],
          ),
        CardFinishTier.legendary => const CardFxProfile(
            finish: CardFinishTier.legendary,
            maxTiltRadians: 0.115,
            parallaxPixels: 7,
            foilOpacity: 0.38,
            edgeGlowOpacity: 0.40,
            particleCount: 12,
            revealDuration: Duration(milliseconds: 1180),
            impactScale: 1.05,
            glowColors: [
              Color(0xFFFFD88A),
              Color(0xFFFFF2C7),
              Color(0xFFFFA94D),
            ],
          ),
        CardFinishTier.secret => const CardFxProfile(
            finish: CardFinishTier.secret,
            maxTiltRadians: 0.12,
            parallaxPixels: 8,
            foilOpacity: 0.46,
            edgeGlowOpacity: 0.48,
            particleCount: 15,
            revealDuration: Duration(milliseconds: 1320),
            impactScale: 1.06,
            glowColors: [
              Color(0xFFF8FAFC),
              Color(0xFF67E8F9),
              Color(0xFFE879F9),
              Color(0xFFFFD88A),
            ],
          ),
      };
}

extension CardAmbientFxLabel on CardAmbientFx {
  String get label => switch (this) {
        CardAmbientFx.none => 'None',
        CardAmbientFx.dust => 'Dust',
        CardAmbientFx.steam => 'Steam',
        CardAmbientFx.digitalPulse => 'Digital pulse',
        CardAmbientFx.embers => 'Embers',
        CardAmbientFx.waterCaustic => 'Water caustic',
      };
}
