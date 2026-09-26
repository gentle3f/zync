import 'package:flutter/material.dart';

enum ZyncFxRarity { common, uncommon, rare, epic, legendary }

enum ZyncAmbientFx { none, dust, steam, digitalPulse }

abstract final class ZyncFrameAssets {
  static const common =
      'assets/card_fx/frames/master/zync_frame_common_master_v1.png';
  static const uncommon =
      'assets/card_fx/frames/master/zync_frame_uncommon_master_v1.png';
  static const rare =
      'assets/card_fx/frames/master/zync_frame_rare_master_v1.png';
  static const epic =
      'assets/card_fx/frames/master/zync_frame_epic_master_v1.png';
  static const legendary =
      'assets/card_fx/frames/master/zync_frame_legendary_master_v1.png';

  static String forRarity(ZyncFxRarity rarity) => switch (rarity) {
        ZyncFxRarity.common => common,
        ZyncFxRarity.uncommon => uncommon,
        ZyncFxRarity.rare => rare,
        ZyncFxRarity.epic => epic,
        ZyncFxRarity.legendary => legendary,
      };
}

@immutable
class ZyncFrameGeometry {
  const ZyncFrameGeometry({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect artworkWindow(Size size) => Rect.fromLTRB(
        size.width * left,
        size.height * top,
        size.width * right,
        size.height * bottom,
      );

  static ZyncFrameGeometry forRarity(ZyncFxRarity rarity) => switch (rarity) {
        ZyncFxRarity.common => const ZyncFrameGeometry(
            left: 98 / 1024,
            top: 158 / 1536,
            right: 927 / 1024,
            bottom: 1127 / 1536,
          ),
        ZyncFxRarity.uncommon => const ZyncFrameGeometry(
            left: 104 / 1024,
            top: 157 / 1536,
            right: 922 / 1024,
            bottom: 1123 / 1536,
          ),
        ZyncFxRarity.rare => const ZyncFrameGeometry(
            left: 102 / 1024,
            top: 162 / 1536,
            right: 927 / 1024,
            bottom: 1122 / 1536,
          ),
        ZyncFxRarity.epic => const ZyncFrameGeometry(
            left: 101 / 1024,
            top: 161 / 1536,
            right: 922 / 1024,
            bottom: 1103 / 1536,
          ),
        ZyncFxRarity.legendary => const ZyncFrameGeometry(
            left: 101 / 1024,
            top: 158 / 1536,
            right: 923 / 1024,
            bottom: 1121 / 1536,
          ),
      };
}

@immutable
class ZyncCardFxProfile {
  const ZyncCardFxProfile({
    required this.rarity,
    required this.label,
    required this.frameColor,
    required this.accentColor,
    required this.secondaryColor,
    required this.maxTiltDegrees,
    required this.parallaxPixels,
    required this.foilOpacity,
    required this.edgeGlowOpacity,
    required this.particleCount,
    required this.revealImpact,
  });

  final ZyncFxRarity rarity;
  final String label;
  final Color frameColor;
  final Color accentColor;
  final Color secondaryColor;
  final double maxTiltDegrees;
  final double parallaxPixels;
  final double foilOpacity;
  final double edgeGlowOpacity;
  final int particleCount;
  final double revealImpact;

  static ZyncCardFxProfile forRarity(ZyncFxRarity rarity) {
    return switch (rarity) {
      ZyncFxRarity.common => const ZyncCardFxProfile(
          rarity: ZyncFxRarity.common,
          label: 'COMMON',
          frameColor: Color(0xFFD5DCE4),
          accentColor: Color(0xFF8DE5FF),
          secondaryColor: Color(0xFFF6FBFF),
          maxTiltDegrees: 4.0,
          parallaxPixels: 4.0,
          foilOpacity: 0.04,
          edgeGlowOpacity: 0.10,
          particleCount: 0,
          revealImpact: 0.20,
        ),
      ZyncFxRarity.uncommon => const ZyncCardFxProfile(
          rarity: ZyncFxRarity.uncommon,
          label: 'UNCOMMON',
          frameColor: Color(0xFFCED8D5),
          accentColor: Color(0xFF52C98A),
          secondaryColor: Color(0xFFA9F0C9),
          maxTiltDegrees: 4.8,
          parallaxPixels: 5.0,
          foilOpacity: 0.08,
          edgeGlowOpacity: 0.16,
          particleCount: 5,
          revealImpact: 0.32,
        ),
      ZyncFxRarity.rare => const ZyncCardFxProfile(
          rarity: ZyncFxRarity.rare,
          label: 'RARE',
          frameColor: Color(0xFFC8D1DC),
          accentColor: Color(0xFF49D7FF),
          secondaryColor: Color(0xFFB66BFF),
          maxTiltDegrees: 5.6,
          parallaxPixels: 6.0,
          foilOpacity: 0.18,
          edgeGlowOpacity: 0.28,
          particleCount: 9,
          revealImpact: 0.50,
        ),
      ZyncFxRarity.epic => const ZyncCardFxProfile(
          rarity: ZyncFxRarity.epic,
          label: 'EPIC',
          frameColor: Color(0xFF17253A),
          accentColor: Color(0xFF23D9FF),
          secondaryColor: Color(0xFF775CFF),
          maxTiltDegrees: 6.2,
          parallaxPixels: 7.0,
          foilOpacity: 0.24,
          edgeGlowOpacity: 0.38,
          particleCount: 14,
          revealImpact: 0.72,
        ),
      ZyncFxRarity.legendary => const ZyncCardFxProfile(
          rarity: ZyncFxRarity.legendary,
          label: 'LEGENDARY',
          frameColor: Color(0xFFDFC17E),
          accentColor: Color(0xFFFFD37C),
          secondaryColor: Color(0xFFFFF1C2),
          maxTiltDegrees: 6.8,
          parallaxPixels: 8.0,
          foilOpacity: 0.30,
          edgeGlowOpacity: 0.48,
          particleCount: 20,
          revealImpact: 1.0,
        ),
    };
  }
}

@immutable
class ZyncFxCardSpec {
  const ZyncFxCardSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.artworkAsset,
    required this.rarity,
    required this.ambientFx,
    this.frameAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final String artworkAsset;
  final ZyncFxRarity rarity;
  final ZyncAmbientFx ambientFx;

  /// Exact locked frame PNG. V1 can run with the procedural fallback while
  /// the immutable master binaries are being moved into the app asset bundle.
  final String? frameAsset;

  String get resolvedFrameAsset =>
      frameAsset ?? ZyncFrameAssets.forRarity(rarity);

  ZyncCardFxProfile get profile => ZyncCardFxProfile.forRarity(rarity);
}

const cardFxLabSamples = <ZyncFxCardSpec>[
  ZyncFxCardSpec(
    id: 'books.reading',
    title: 'Reading',
    subtitle: 'Quiet worlds · pages · discovery',
    artworkAsset: 'assets/card_fx/art/reading.jpg',
    rarity: ZyncFxRarity.common,
    ambientFx: ZyncAmbientFx.dust,
  ),
  ZyncFxCardSpec(
    id: 'technology.ai',
    title: 'Artificial Intelligence',
    subtitle: 'Curiosity · systems · possibility',
    artworkAsset: 'assets/card_fx/art/ai.jpg',
    rarity: ZyncFxRarity.rare,
    ambientFx: ZyncAmbientFx.digitalPulse,
  ),
  ZyncFxCardSpec(
    id: 'food.coffee',
    title: 'Coffee',
    subtitle: 'Ritual · warmth · conversation',
    artworkAsset: 'assets/card_fx/art/coffee.jpg',
    rarity: ZyncFxRarity.legendary,
    ambientFx: ZyncAmbientFx.steam,
  ),
];

@immutable
class ZyncFxTuning {
  const ZyncFxTuning({
    this.tilt = 1.0,
    this.parallax = 1.0,
    this.foil = 1.0,
    this.glow = 1.0,
    this.ambient = 1.0,
    this.particles = 1.0,
  });

  final double tilt;
  final double parallax;
  final double foil;
  final double glow;
  final double ambient;
  final double particles;

  ZyncFxTuning copyWith({
    double? tilt,
    double? parallax,
    double? foil,
    double? glow,
    double? ambient,
    double? particles,
  }) {
    return ZyncFxTuning(
      tilt: tilt ?? this.tilt,
      parallax: parallax ?? this.parallax,
      foil: foil ?? this.foil,
      glow: glow ?? this.glow,
      ambient: ambient ?? this.ambient,
      particles: particles ?? this.particles,
    );
  }
}
