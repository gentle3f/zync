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
  splitBreak,
  chargeBurst,
  sealUnlock,
  hiddenOmen,
  cardExtract,
  cardFlip,
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
      case ZyncFxSensoryEvent.hiddenOmen:
        await HapticFeedback.selectionClick();
      case ZyncFxSensoryEvent.tearBreak:
      case ZyncFxSensoryEvent.splitBreak:
        await HapticFeedback.mediumImpact();
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
      ZyncFxSensoryEvent.packPick =>
        const _SoundSpec('$root' 'pack_pick.wav', 0.26),
      ZyncFxSensoryEvent.revealEntrance => null,
      ZyncFxSensoryEvent.chargeArm => null,
      ZyncFxSensoryEvent.tearBreak =>
        const _SoundSpec('$root' 'tear_up.wav', 0.58),
      ZyncFxSensoryEvent.foilTension =>
        const _SoundSpec('$root' 'foil_tension.wav', 0.34),
      ZyncFxSensoryEvent.splitBreak =>
        const _SoundSpec('$root' 'split_open.wav', 0.84),
      ZyncFxSensoryEvent.chargeBurst =>
        const _SoundSpec('$root' 'charge_burst.wav', 0.70),
      ZyncFxSensoryEvent.sealUnlock =>
        const _SoundSpec('$root' 'seal_slide.wav', 0.55),
      ZyncFxSensoryEvent.hiddenOmen =>
        const _SoundSpec('$root' 'hidden_omen.wav', 0.36),
      ZyncFxSensoryEvent.cardExtract =>
        const _SoundSpec('$root' 'card_extract.wav', 0.82),
      ZyncFxSensoryEvent.cardFlip =>
        const _SoundSpec('$root' 'card_flip.wav', 0.74),
      ZyncFxSensoryEvent.legendaryFinale =>
        const _SoundSpec('$root' 'legendary_finale.wav', 0.96),
      ZyncFxSensoryEvent.rarityHit => switch (rarity) {
          ZyncFxRarity.common =>
            const _SoundSpec('$root' 'rarity_common.wav', 0.48),
          ZyncFxRarity.uncommon =>
            const _SoundSpec('$root' 'rarity_uncommon.wav', 0.56),
          ZyncFxRarity.rare =>
            const _SoundSpec('$root' 'rarity_rare.wav', 0.68),
          ZyncFxRarity.epic =>
            const _SoundSpec('$root' 'rarity_epic.wav', 0.82),
          ZyncFxRarity.legendary =>
            const _SoundSpec('$root' 'rarity_legendary.wav', 0.98),
        },
    };
  }
}

class _SoundSpec {
  const _SoundSpec(this.asset, this.volume);

  final String asset;
  final double volume;
}
