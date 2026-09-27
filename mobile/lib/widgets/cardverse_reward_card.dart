import 'package:flutter/material.dart';

import '../card_fx/card_fx_spec.dart';
import '../card_fx/zync_fx_card.dart';
import '../core/card_visual_recipe.dart';
import '../core/cardverse_models.dart';
import '../core/interest_catalog.dart';
import 'zync_card_preview.dart';

/// Production-facing Cardverse reward renderer.
///
/// Every reward uses the locked 1024x1536 rarity frame. Interests with an
/// accepted production artwork asset use it directly. Other interests retain
/// their approved semantic recipe only inside the artwork window; they never
/// fall back to the old full-card procedural mockup.
class CardverseRewardCard extends StatelessWidget {
  const CardverseRewardCard({
    super.key,
    required this.interestId,
    required this.finish,
    required this.editionLabel,
    required this.locale,
    this.recipe,
    this.focused = false,
  });

  final String interestId;
  final CardFinishTier finish;
  final String editionLabel;
  final String locale;
  final CardVisualRecipe? recipe;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final resolvedRecipe = recipe ?? CardVisualRecipeResolver.resolve(interestId);
    final interest = InterestCatalog.byId(interestId);
    final title = interest?.labelFor(locale) ?? interestId;
    final approved = _approvedArtwork[interestId];
    final rarity = rewardFxRarity(finish);

    final spec = ZyncFxCardSpec(
      id: interestId,
      title: title,
      subtitle: editionLabel,
      artworkAsset:
          approved?.asset ?? 'assets/card_fx/art/reading.jpg',
      rarity: rarity,
      ambientFx: approved?.ambient ?? _ambientFor(resolvedRecipe),
    );

    return KeyedSubtree(
      key: ValueKey('cardverse-formal-card-$interestId'),
      child: ZyncFxCard(
        spec: spec,
        enableDragTilt: focused,
        revealImpact: focused ? 0.24 : 0,
        artworkOverride: approved == null
            ? (resolvedRecipe != null
                ? ZyncCardArtwork(recipe: resolvedRecipe)
                : const _NeutralRewardArtwork())
            : null,
      ),
    );
  }
}

ZyncFxRarity rewardFxRarity(CardFinishTier finish) => switch (finish) {
      CardFinishTier.normal => ZyncFxRarity.common,
      CardFinishTier.foil => ZyncFxRarity.uncommon,
      CardFinishTier.holo => ZyncFxRarity.rare,
      CardFinishTier.prism => ZyncFxRarity.epic,
      CardFinishTier.legendary || CardFinishTier.secret =>
        ZyncFxRarity.legendary,
    };

ZyncAmbientFx _ambientFor(CardVisualRecipe? recipe) {
  if (recipe == null) return ZyncAmbientFx.none;
  if (recipe.visualFamily == 'technology_ai' ||
      recipe.visualFamily == 'technology_code') {
    return ZyncAmbientFx.digitalPulse;
  }
  if (recipe.categoryKit == 'learning' || recipe.categoryKit == 'books') {
    return ZyncAmbientFx.dust;
  }
  return ZyncAmbientFx.none;
}

class _NeutralRewardArtwork extends StatelessWidget {
  const _NeutralRewardArtwork();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF27334A),
              Color(0xFF17202F),
              Color(0xFF0D131D),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white70,
            size: 54,
          ),
        ),
      );
}

class _ApprovedArtwork {
  const _ApprovedArtwork(this.asset, this.ambient);

  final String asset;
  final ZyncAmbientFx ambient;
}

const _approvedArtwork = <String, _ApprovedArtwork>{
  'books.reading': _ApprovedArtwork(
    'assets/card_fx/art/reading.jpg',
    ZyncAmbientFx.dust,
  ),
  'technology.ai': _ApprovedArtwork(
    'assets/card_fx/art/ai.jpg',
    ZyncAmbientFx.digitalPulse,
  ),
  'food.coffee': _ApprovedArtwork(
    'assets/card_fx/art/coffee.jpg',
    ZyncAmbientFx.steam,
  ),
};
