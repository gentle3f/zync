import 'dart:async';

import 'package:flutter/material.dart';

import '../card_fx/card_fx_spec.dart';
import '../card_fx/zync_fx_reveal.dart';
import '../card_fx/zync_fx_sensory.dart';
import '../core/card_visual_recipe.dart';
import '../core/cardverse_models.dart';
import '../core/cardverse_pack_reveal.dart';
import '../core/interest_catalog.dart';
import '../ui/zync_design.dart';
import 'zync_card_preview.dart';

Future<void> showCardverseSingleDrawReveal({
  required BuildContext context,
  required CardverseSingleDrawReceipt receipt,
  required String locale,
}) async {
  final item = receipt.item;
  final recipe = CardVisualRecipeResolver.resolve(item.variant.interestId);
  final interest = InterestCatalog.byId(item.variant.interestId);
  final title = interest?.labelFor(locale) ?? item.variant.interestId;
  final finish = _finish(item.variant.finishId);
  final rarity = _fxRarity(finish);
  final isZh = locale.toLowerCase().startsWith('zh');
  Timer? rarityTimer;
  var revealed = false;
  var revealing = false;

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> reveal() async {
            if (revealed || revealing) return;
            setSheetState(() => revealing = true);

            final reduceMotion =
                MediaQuery.maybeOf(sheetContext)?.disableAnimations ?? false;
            final delay = CardverseRevealTiming.suspenseFor(
              finish,
              reduceMotion: reduceMotion,
            );
            if (delay > Duration.zero) {
              await Future<void>.delayed(delay);
            }
            if (!sheetContext.mounted) return;

            if (!reduceMotion) {
              ZyncFxSensory.play(
                ZyncFxSensoryEvent.cardFlip,
                rarity: rarity,
              );
            }

            setSheetState(() {
              revealed = true;
              revealing = false;
            });

            if (!reduceMotion) {
              ZyncFxSensory.play(
                ZyncFxSensoryEvent.rewardBloom,
                rarity: rarity,
                haptic: false,
              );
              rarityTimer?.cancel();
              rarityTimer = Timer(const Duration(milliseconds: 120), () {
                if (!sheetContext.mounted) return;
                ZyncFxSensory.play(
                  ZyncFxSensoryEvent.rarityHit,
                  rarity: rarity,
                  haptic: false,
                );
              });
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFDFCFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7D2DE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      revealed
                          ? (isZh ? '你抽到一張新卡' : 'You drew a card')
                          : (isZh ? '有一張卡等你揭曉' : 'One card is ready'),
                      style: Theme.of(sheetContext).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isZh
                          ? '結果已由 Cardverse server 決定；揭曉動畫唔會改卡。'
                          : 'The Cardverse server already decided the result. The reveal cannot change the card.',
                      textAlign: TextAlign.center,
                      style: Theme.of(sheetContext)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: ZyncPalette.inkSoft),
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: revealed
                          ? KeyedSubtree(
                              key: const ValueKey('single-draw-card-front'),
                              child: recipe != null
                                  ? ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 330),
                                      child: AspectRatio(
                                        aspectRatio: 5 / 7,
                                        child: ZyncCardPreview(
                                          recipe: recipe,
                                          title: title,
                                          subtitle: _finishLabel(finish),
                                          finish: finish,
                                          editionLabel:
                                              _edition(item.variant.editionId),
                                          cardNumberLabel: 'NEW',
                                          animateFinish: true,
                                        ),
                                      ),
                                    )
                                  : ZyncSurface(
                                      shadow: false,
                                      child: ListTile(
                                        leading:
                                            const Icon(Icons.style_outlined),
                                        title: Text(title),
                                        subtitle: Text(_finishLabel(finish)),
                                      ),
                                    ),
                            )
                          : SizedBox(
                              key: const ValueKey('single-draw-card-back'),
                              width: 276,
                              child: ZyncFxCardBack(
                                accent: ZyncCardFxProfile.forRarity(rarity)
                                    .accentColor,
                              ),
                            ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: ValueKey(
                          revealed
                              ? 'single-draw-close'
                              : 'single-draw-reveal-button',
                        ),
                        onPressed: revealing
                            ? null
                            : revealed
                                ? () => Navigator.of(sheetContext).pop()
                                : reveal,
                        icon: revealing
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                revealed
                                    ? Icons.collections_bookmark_outlined
                                    : Icons.auto_awesome_rounded,
                              ),
                        label: Text(
                          revealing
                              ? (isZh ? '揭曉中…' : 'Revealing…')
                              : revealed
                                  ? (isZh ? '加入收藏' : 'Add to collection')
                                  : (isZh ? '揭曉' : 'Reveal card'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  } finally {
    rarityTimer?.cancel();
  }
}

CardFinishTier _finish(String raw) => switch (raw) {
      'foil' => CardFinishTier.foil,
      'holo' => CardFinishTier.holo,
      'prism' => CardFinishTier.prism,
      'legendary' => CardFinishTier.legendary,
      'secret' => CardFinishTier.secret,
      _ => CardFinishTier.normal,
    };

ZyncFxRarity _fxRarity(CardFinishTier finish) => switch (finish) {
      CardFinishTier.normal => ZyncFxRarity.common,
      CardFinishTier.foil => ZyncFxRarity.uncommon,
      CardFinishTier.holo => ZyncFxRarity.rare,
      CardFinishTier.prism => ZyncFxRarity.epic,
      CardFinishTier.legendary ||
      CardFinishTier.secret =>
        ZyncFxRarity.legendary,
    };

String _finishLabel(CardFinishTier finish) => switch (finish) {
      CardFinishTier.normal => 'Normal',
      CardFinishTier.foil => 'Foil',
      CardFinishTier.holo => 'Holo',
      CardFinishTier.prism => 'Prism',
      CardFinishTier.legendary => 'Legendary',
      CardFinishTier.secret => 'Secret',
    };

String _edition(String raw) {
  final value = raw.toLowerCase();
  if (value.startsWith('core')) return 'CORE';
  if (value.startsWith('event')) return 'EVENT';
  if (value == 'encounter') return 'ENCOUNTER';
  if (value == 'discovery') return 'DISCOVERY';
  if (value == 'starter') return 'STARTER';
  if (value == 'achievement') return 'ACHIEVEMENT';
  return raw.toUpperCase();
}
