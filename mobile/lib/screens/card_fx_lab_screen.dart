import 'package:flutter/material.dart';

import '../card_fx/card_fx_profile.dart';
import '../card_fx/card_fx_surface.dart';
import '../core/card_visual_recipe.dart';
import '../core/cardverse_models.dart';
import '../core/interest_catalog.dart';
import '../ui/zync_design.dart';
import '../widgets/zync_card_preview.dart';

class CardFxLabScreen extends StatefulWidget {
  const CardFxLabScreen({super.key});

  @override
  State<CardFxLabScreen> createState() => _CardFxLabScreenState();
}

class _CardFxLabScreenState extends State<CardFxLabScreen> {
  static const _samples = <_FxLabSample>[
    _FxLabSample(
      interestId: 'food.coffee',
      finish: CardFinishTier.legendary,
      ambientFx: CardAmbientFx.steam,
    ),
    _FxLabSample(
      interestId: 'technology.ai',
      finish: CardFinishTier.prism,
      ambientFx: CardAmbientFx.digitalPulse,
    ),
    _FxLabSample(
      interestId: 'books.reading',
      finish: CardFinishTier.holo,
      ambientFx: CardAmbientFx.dust,
    ),
  ];

  int _sampleIndex = 0;
  int _revealNonce = 0;
  bool _showReveal = true;
  CardFinishTier _finish = _samples.first.finish;
  CardAmbientFx _ambientFx = _samples.first.ambientFx;
  double _effectIntensity = 1;
  double _tiltStrength = 1;

  _FxLabSample get _sample => _samples[_sampleIndex];

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final recipe = CardVisualRecipeResolver.resolve(_sample.interestId);
    final interest = InterestCatalog.byId(_sample.interestId);

    if (recipe == null || interest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Card FX Lab')),
        body: const Center(child: Text('FX Lab sample recipe unavailable.')),
      );
    }

    final title = interest.labelFor(locale);
    final card = ZyncCardPreview(
      recipe: recipe,
      title: title,
      subtitle: '${_finishLabel(_finish)} · FX LAB',
      finish: _finish,
      editionLabel: 'FX LAB',
      cardNumberLabel: 'LIVE',
      animateFinish: false,
    );

    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 2),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Card FX Lab',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const _RuntimeBadge(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('card-fx-lab'),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
                  children: [
                    ZyncSurface(
                      shadow: false,
                      backgroundColor: const Color(0xFFF1EEFF),
                      borderColor: const Color(0xFFE0D9FF),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ZyncIconTile(
                            icon: Icons.auto_awesome_rounded,
                            backgroundColor: Color(0xFFE9E5FF),
                            foregroundColor: ZyncPalette.plum,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Runtime FX only: drag the focused card to tilt it. '
                              'Foil, glow, ambient motion and reveal timing are reusable layers — '
                              'not per-card videos. Production artwork/frame assets can replace the '
                              'preview child later without changing this engine.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle(context, 'Samples'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _samples.length; i++)
                          ChoiceChip(
                            key: ValueKey('fx-sample-${_samples[i].interestId}'),
                            label: Text(
                              InterestCatalog.byId(_samples[i].interestId)
                                      ?.labelFor(locale) ??
                                  _samples[i].interestId,
                            ),
                            selected: _sampleIndex == i,
                            onSelected: (_) {
                              setState(() {
                                _sampleIndex = i;
                                _finish = _samples[i].finish;
                                _ambientFx = _samples[i].ambientFx;
                                _revealNonce++;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: AspectRatio(
                          aspectRatio: 5 / 7,
                          child: _showReveal
                              ? ZyncCardReveal(
                                  key: ValueKey(
                                    'fx-reveal-${_sample.interestId}-$_revealNonce',
                                  ),
                                  front: card,
                                  finish: _finish,
                                  ambientFx: _ambientFx,
                                  effectIntensity: _effectIntensity,
                                  tiltStrength: _tiltStrength,
                                )
                              : ZyncCardFxSurface(
                                  key: ValueKey(
                                    'fx-inspect-${_sample.interestId}',
                                  ),
                                  finish: _finish,
                                  ambientFx: _ambientFx,
                                  effectIntensity: _effectIntensity,
                                  tiltStrength: _tiltStrength,
                                  child: card,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey('fx-replay-reveal'),
                            onPressed: () {
                              setState(() {
                                _showReveal = true;
                                _revealNonce++;
                              });
                            },
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Replay reveal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('fx-inspect-mode'),
                            onPressed: () => setState(() => _showReveal = false),
                            icon: const Icon(Icons.threed_rotation),
                            label: const Text('Inspect / tilt'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'Rarity / finish'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final finish in CardFinishTier.values)
                          ChoiceChip(
                            key: ValueKey('fx-finish-${finish.name}'),
                            label: Text(_finishLabel(finish)),
                            selected: _finish == finish,
                            onSelected: (_) {
                              setState(() {
                                _finish = finish;
                                _revealNonce++;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(context, 'Ambient FX'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final effect in CardAmbientFx.values)
                          ChoiceChip(
                            key: ValueKey('fx-ambient-${effect.name}'),
                            label: Text(effect.label),
                            selected: _ambientFx == effect,
                            onSelected: (_) => setState(() => _ambientFx = effect),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _slider(
                      context,
                      label: 'FX intensity',
                      value: _effectIntensity,
                      min: 0,
                      max: 1.5,
                      onChanged: (value) =>
                          setState(() => _effectIntensity = value),
                    ),
                    _slider(
                      context,
                      label: 'Tilt / parallax strength',
                      value: _tiltStrength,
                      min: 0,
                      max: 1.5,
                      onChanged: (value) =>
                          setState(() => _tiltStrength = value),
                    ),
                    const SizedBox(height: 12),
                    ZyncSurface(
                      shadow: false,
                      backgroundColor: const Color(0xFFFFF7F2),
                      borderColor: ZyncPalette.peach,
                      child: Text(
                        'V1 deliberately uses Flutter runtime painting only — no GIF/video '
                        'and no new sensor dependency. Once the feel is locked, phone gyroscope '
                        'can feed the same normalized tilt input and production artwork + rarity '
                        'frame PNGs can replace the current procedural preview.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(value.toStringAsFixed(2)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      );

  Widget _sectionTitle(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      );

  String _finishLabel(CardFinishTier finish) => switch (finish) {
        CardFinishTier.normal => 'Common',
        CardFinishTier.foil => 'Uncommon',
        CardFinishTier.holo => 'Rare',
        CardFinishTier.prism => 'Epic',
        CardFinishTier.legendary => 'Legendary',
        CardFinishTier.secret => 'Secret',
      };
}

class _FxLabSample {
  const _FxLabSample({
    required this.interestId,
    required this.finish,
    required this.ambientFx,
  });

  final String interestId;
  final CardFinishTier finish;
  final CardAmbientFx ambientFx;
}

class _RuntimeBadge extends StatelessWidget {
  const _RuntimeBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFBEEAD7)),
        ),
        child: Text(
          'RUNTIME',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF176B4E),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
        ),
      );
}
