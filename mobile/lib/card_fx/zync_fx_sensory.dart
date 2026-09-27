import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'card_fx_spec.dart';

enum ZyncFxSensoryEvent {
  packPick,
  revealEntrance,
  chargeArm,
  tearBreak,
  foilTension,
  splitTear,
  microAnticipation,
  splitBreak,
  chargeBurst,
  sealUnlock,
  hiddenOmen,
  cardExtract,
  cardFlip,
  rewardBloom,
  rarityHit,
  legendaryFinale,
}

abstract final class ZyncFxSensory {
  static final List<AudioPlayer> _players =
      List.generate(8, (_) => AudioPlayer());
  static int _nextPlayer = 0;

  static void play(
    ZyncFxSensoryEvent event, {
    required ZyncFxRarity rarity,
    bool sound = true,
    bool haptic = true,
  }) {
    if (haptic) unawaited(_playHaptic(event, rarity));
    if (sound) unawaited(_playSound(event, rarity));
  }

  static Future<void> _playSound(
    ZyncFxSensoryEvent event,
    ZyncFxRarity rarity,
  ) async {
    final spec = _soundSpec(event, rarity);
    if (spec == null) return;
    try {
      final player = _players[_nextPlayer++ % _players.length];
      await player.stop();
      await player.play(
        AssetSource(spec.asset),
        volume: spec.volume,
      );
    } catch (_) {
      // Sensory audio must never interrupt reveal flow or widget tests.
    }
  }

  static Future<void> _playHaptic(
    ZyncFxSensoryEvent event,
    ZyncFxRarity rarity,
  ) async {
    switch (event) {
      case ZyncFxSensoryEvent.packPick:
      case ZyncFxSensoryEvent.revealEntrance:
      case ZyncFxSensoryEvent.chargeArm:
      case ZyncFxSensoryEvent.foilTension:
      case ZyncFxSensoryEvent.microAnticipation:
      case ZyncFxSensoryEvent.rewardBloom:
      case ZyncFxSensoryEvent.hiddenOmen:
        await HapticFeedback.selectionClick();
      case ZyncFxSensoryEvent.tearBreak:
      case ZyncFxSensoryEvent.splitBreak:
        await HapticFeedback.mediumImpact();
      case ZyncFxSensoryEvent.splitTear:
        await HapticFeedback.lightImpact();
      case ZyncFxSensoryEvent.chargeBurst:
        await HapticFeedback.heavyImpact();
      case ZyncFxSensoryEvent.sealUnlock:
        await HapticFeedback.lightImpact();
      case ZyncFxSensoryEvent.cardExtract:
        if (rarity.index >= ZyncFxRarity.epic.index) {
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.lightImpact();
        }
      case ZyncFxSensoryEvent.cardFlip:
        if (rarity.index >= ZyncFxRarity.rare.index) {
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.lightImpact();
        }
      case ZyncFxSensoryEvent.rarityHit:
        switch (rarity) {
          case ZyncFxRarity.common:
            await HapticFeedback.selectionClick();
          case ZyncFxRarity.uncommon:
            await HapticFeedback.lightImpact();
          case ZyncFxRarity.rare:
            await HapticFeedback.mediumImpact();
          case ZyncFxRarity.epic:
          case ZyncFxRarity.legendary:
            await HapticFeedback.heavyImpact();
        }
      case ZyncFxSensoryEvent.legendaryFinale:
        await HapticFeedback.heavyImpact();
    }
  }

  static _SoundSpec? _soundSpec(
    ZyncFxSensoryEvent event,
    ZyncFxRarity rarity,
  ) {
    const root = 'card_fx/sfx/';
    return switch (event) {
      ZyncFxSensoryEvent.packPick => const _SoundSpec(
          '$root' 'pixabay_pack_pick_next_level_114480.mp3',
          0.42,
        ),
      ZyncFxSensoryEvent.revealEntrance => null,
      ZyncFxSensoryEvent.chargeArm => null,
      ZyncFxSensoryEvent.tearBreak =>
        const _SoundSpec('$root' 'tear_up.wav', 0.58),
      ZyncFxSensoryEvent.foilTension =>
        const _SoundSpec('$root' 'foil_tension.wav', 0.20),
      ZyncFxSensoryEvent.splitTear => const _SoundSpec(
          '$root' 'pixabay_split_tear_paper_132571.mp3',
          0.74,
        ),
      ZyncFxSensoryEvent.microAnticipation => const _SoundSpec(
          '$root' 'pixabay_anticipation_twinkle_244951.mp3',
          0.28,
        ),
      ZyncFxSensoryEvent.splitBreak => const _SoundSpec(
          '$root' 'pixabay_wrapper_opened_badge_pop_547866.mp3',
          0.68,
        ),
      ZyncFxSensoryEvent.chargeBurst =>
        const _SoundSpec('$root' 'charge_burst.wav', 0.70),
      ZyncFxSensoryEvent.sealUnlock =>
        const _SoundSpec('$root' 'seal_slide.wav', 0.55),
      ZyncFxSensoryEvent.hiddenOmen =>
        const _SoundSpec('$root' 'hidden_omen.wav', 0.36),
      ZyncFxSensoryEvent.cardExtract =>
        const _SoundSpec('$root' 'card_extract.wav', 0.82),
      ZyncFxSensoryEvent.cardFlip => const _SoundSpec(
          '$root' 'pixabay_card_flip_35956.mp3',
          0.78,
        ),
      ZyncFxSensoryEvent.rewardBloom => const _SoundSpec(
          '$root' 'pixabay_reward_bloom_surprise_145912.mp3',
          0.30,
        ),
      ZyncFxSensoryEvent.legendaryFinale => null,
      ZyncFxSensoryEvent.rarityHit => switch (rarity) {
          ZyncFxRarity.common => const _SoundSpec(
              '$root' 'pixabay_rarity_common_xp_gain_453274.mp3',
              0.56,
            ),
          ZyncFxRarity.uncommon => const _SoundSpec(
              '$root' 'pixabay_rarity_uncommon_great_success_384935.mp3',
              0.64,
            ),
          ZyncFxRarity.rare => const _SoundSpec(
              '$root' 'pixabay_rarity_rare_magic_stinger_552109.mp3',
              0.72,
            ),
          ZyncFxRarity.epic => const _SoundSpec(
              '$root' 'pixabay_rarity_epic_ice_448564.mp3',
              0.82,
            ),
          ZyncFxRarity.legendary => const _SoundSpec(
              '$root' 'pixabay_rarity_legendary_light_478379.mp3',
              0.92,
            ),
        },
    };
  }
}

class _SoundSpec {
  const _SoundSpec(this.asset, this.volume);

  final String asset;
  final double volume;
}
