import 'package:flutter/material.dart';

import '../card_fx/card_fx_spec.dart';
import '../card_fx/zync_fx_reveal.dart';
import '../card_fx/zync_fx_sensory.dart';
import '../core/cardverse_models.dart';
import '../ui/zync_design.dart';
import 'cardverse_reward_card.dart';

Future<void> showCardverseSingleDrawReveal({
  required BuildContext context,
  required CardverseSingleDrawReceipt receipt,
  required String locale,
}) async {
  final item = receipt.item;
  final finish = _finish(item.variant.finishId);
  final rarity = rewardFxRarity(finish);
  final isZh = locale.toLowerCase().startsWith('zh');
  var revealed = false;
  var revealing = false;
  var revealToken = 0;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        void reveal() {
          if (revealed || revealing) return;

          final reduceMotion =
              MediaQuery.maybeOf(sheetContext)?.disableAnimations ?? false;
          if (!reduceMotion) {
            ZyncFxSensory.playFromUserGesture(
              ZyncFxSensoryEvent.singleRevealStart,
              rarity: rarity,
            );
          }

          setSheetState(() {
            revealing = true;
            revealToken += 1;
          });
        }

        void finishReveal() {
          if (!sheetContext.mounted || !revealing) return;
          setSheetState(() {
            revealed = true;
            revealing = false;
          });
        }

        final rewardCard = CardverseRewardCard(
          interestId: item.variant.interestId,
          finish: finish,
          editionLabel: _edition(item.variant.editionId),
          locale: locale,
          focused: true,
        );

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
                  if (revealing)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: ZyncFxRevealStage(
                        key: ValueKey('single-draw-reveal-stage-$revealToken'),
                        spec: _singleRevealSpec(
                          interestId: item.variant.interestId,
                          finish: finish,
                        ),
                        tuning: const ZyncFxTuning(),
                        revealToken: revealToken,
                        startFromSettledBack: true,
                        frontCard: rewardCard,
                        onRevealComplete: finishReveal,
                      ),
                    )
                  else if (revealed)
                    KeyedSubtree(
                      key: const ValueKey('single-draw-card-front'),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 330),
                        child: rewardCard,
                      ),
                    )
                  else
                    SizedBox(
                      key: const ValueKey('single-draw-card-back'),
                      width: 276,
                      child: ZyncFxCardBack(
                        accent:
                            ZyncCardFxProfile.forRarity(rarity).accentColor,
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
}

ZyncFxCardSpec _singleRevealSpec({
  required String interestId,
  required CardFinishTier finish,
}) =>
    ZyncFxCardSpec(
      id: 'single-draw-$interestId-${finish.name}',
      title: interestId,
      subtitle: 'Cardverse reward',
      artworkAsset: 'assets/card_fx/art/reading.jpg',
      rarity: rewardFxRarity(finish),
      ambientFx: ZyncAmbientFx.none,
    );

CardFinishTier _finish(String raw) => switch (raw) {
      'foil' => CardFinishTier.foil,
      'holo' => CardFinishTier.holo,
      'prism' => CardFinishTier.prism,
      'legendary' => CardFinishTier.legendary,
      'secret' => CardFinishTier.secret,
      _ => CardFinishTier.normal,
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
