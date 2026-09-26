import 'package:flutter/material.dart';

import '../card_fx/card_fx_spec.dart';
import '../card_fx/zync_fx_card.dart';
import '../card_fx/zync_pack_opening.dart';

enum _FxLabMode { inspect, reveal }

class CardFxLabScreen extends StatefulWidget {
  const CardFxLabScreen({super.key});

  @override
  State<CardFxLabScreen> createState() => _CardFxLabScreenState();
}

class _CardFxLabScreenState extends State<CardFxLabScreen> {
  int _sampleIndex = 2;
  int _revealToken = 0;
  _FxLabMode _mode = _FxLabMode.inspect;
  ZyncFxRarity? _rarityOverride;
  ZyncFxTuning _tuning = const ZyncFxTuning();
  double _revealSpeed = 1.0;
  ZyncOpeningPrototype _openingPrototype = ZyncOpeningPrototype.tearUp;

  void _restartReveal() {
    setState(() {
      _mode = _FxLabMode.reveal;
      _revealToken++;
    });
  }

  void _showInspect() {
    setState(() => _mode = _FxLabMode.inspect);
  }

  ZyncFxCardSpec get _spec {
    final base = cardFxLabSamples[_sampleIndex];
    final rarity = _rarityOverride ?? base.rarity;
    if (rarity == base.rarity) return base;
    return ZyncFxCardSpec(
      id: base.id,
      title: base.title,
      subtitle: base.subtitle,
      artworkAsset: base.artworkAsset,
      rarity: rarity,
      ambientFx: base.ambientFx,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context)
        .toLanguageTag()
        .toLowerCase()
        .startsWith('zh');

    return Scaffold(
      backgroundColor: const Color(0xFF080B11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1119),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Card FX Lab'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'V1 · LOCAL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 880;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _preview(isZh)),
                        const SizedBox(width: 24),
                        SizedBox(width: 340, child: _controls(isZh)),
                      ],
                    )
                  : Column(
                      children: [
                        _preview(isZh),
                        const SizedBox(height: 24),
                        _controls(isZh),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _preview(bool isZh) {
    return Column(
      children: [
        _sampleSelector(),
        const SizedBox(height: 14),
        _modeSelector(isZh),
        if (_mode == _FxLabMode.reveal) ...[
          const SizedBox(height: 10),
          _openingPrototypeSelector(),
        ],
        const SizedBox(height: 12),
        _raritySelector(isZh),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: _mode == _FxLabMode.inspect
              ? ZyncFxCard(
                  key: ValueKey(
                    'fx-inspect-${_spec.id}-${_spec.rarity.name}',
                  ),
                  spec: _spec,
                  tuning: _tuning,
                  respectReduceMotion: false,
                )
              : ZyncPackOpeningStage(
                  key: ValueKey(
                    'fx-opening-${_spec.id}-${_spec.rarity.name}-${_openingPrototype.name}-$_revealToken',
                  ),
                  spec: _spec,
                  tuning: _tuning,
                  prototype: _openingPrototype,
                  openToken: _revealToken,
                  speed: _revealSpeed,
                  respectReduceMotion: false,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          _mode == _FxLabMode.inspect
              ? (isZh
                  ? '用手指拖張卡：試 3D tilt、parallax、foil 同 ambient FX。'
                  : 'Drag the card to test 3D tilt, parallax, foil and ambient FX.')
              : (isZh
                  ? 'Opening Lab：揀包 → 做手勢 → reveal；唔會改卡、rarity 或任何 server 結果。'
                  : 'Opening Lab: choose a pack, perform the gesture, then reveal. It cannot change card results or rarity.'),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white60, height: 1.4),
        ),
      ],
    );
  }

  Widget _sampleSelector() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < cardFxLabSamples.length; i++)
          ChoiceChip(
            selected: _sampleIndex == i,
            onSelected: (_) {
              setState(() {
                _sampleIndex = i;
                _rarityOverride = null;
                _revealToken++;
              });
            },
            label: Text(
              cardFxLabSamples[i].title +
                  ' · ' +
                  cardFxLabSamples[i].profile.label,
            ),
          ),
      ],
    );
  }

  Widget _modeSelector(bool isZh) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('fx-inspect-button'),
          onPressed: _showInspect,
          icon: const Icon(Icons.threesixty_rounded),
          label: const Text('Inspect'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: _mode == _FxLabMode.inspect
                ? _spec.profile.accentColor.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.06),
            side: BorderSide(
              color: _mode == _FxLabMode.inspect
                  ? _spec.profile.secondaryColor.withValues(alpha: 0.72)
                  : Colors.white24,
            ),
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('fx-draw-reveal-button'),
          onPressed: _restartReveal,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(isZh ? '開包' : 'Open pack'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: _mode == _FxLabMode.reveal
                ? _spec.profile.accentColor.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.06),
            side: BorderSide(
              color: _mode == _FxLabMode.reveal
                  ? _spec.profile.secondaryColor.withValues(alpha: 0.72)
                  : Colors.white24,
            ),
          ),
        ),
        if (_mode == _FxLabMode.reveal)
          FilledButton.icon(
            key: const ValueKey('fx-replay-button'),
            onPressed: _restartReveal,
            icon: const Icon(Icons.replay_rounded),
            label: Text(isZh ? '再播' : 'Replay'),
          ),
      ],
    );
  }

  Widget _openingPrototypeSelector() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final prototype in ZyncOpeningPrototype.values)
          ChoiceChip(
            key: ValueKey('opening-prototype-${prototype.name}'),
            selected: _openingPrototype == prototype,
            onSelected: (_) {
              setState(() {
                _openingPrototype = prototype;
                _revealToken++;
              });
            },
            avatar: CircleAvatar(
              radius: 11,
              backgroundColor: _openingPrototype == prototype
                  ? _spec.profile.accentColor.withValues(alpha: 0.26)
                  : Colors.white10,
              child: Text(
                prototype.code,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            label: Text(prototype.label),
          ),
      ],
    );
  }

  Widget _raritySelector(bool isZh) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        ChoiceChip(
          key: const ValueKey('fx-rarity-default'),
          label: Text(isZh ? '原本' : 'Default'),
          selected: _rarityOverride == null,
          onSelected: (_) {
            setState(() {
              _rarityOverride = null;
              _revealToken++;
            });
          },
        ),
        for (final rarity in ZyncFxRarity.values)
          ChoiceChip(
            key: ValueKey('fx-rarity-${rarity.name}'),
            label: Text(ZyncCardFxProfile.forRarity(rarity).label),
            selected: _rarityOverride == rarity,
            onSelected: (_) {
              setState(() {
                _rarityOverride = rarity;
                _revealToken++;
              });
            },
          ),
      ],
    );
  }

  Widget _controls(bool isZh) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                isZh ? 'FX Debug Panel' : 'FX Debug Panel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tuning = const ZyncFxTuning();
                    _revealSpeed = 1.0;
                  });
                },
                child: Text(isZh ? 'Reset' : 'Reset'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isZh
                ? '呢啲slider只係 Lab tuning；搵到啱feel先freeze做rarity profile。'
                : 'Lab tuning only. Once it feels right, these values become the rarity profile.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white54, height: 1.35),
          ),
          const SizedBox(height: 16),
          _slider(
            label: 'Tilt strength',
            value: _tuning.tilt,
            min: 0,
            max: 1.8,
            onChanged: (value) =>
                setState(() => _tuning = _tuning.copyWith(tilt: value)),
          ),
          _slider(
            label: 'Parallax depth',
            value: _tuning.parallax,
            min: 0,
            max: 1.8,
            onChanged: (value) =>
                setState(() => _tuning = _tuning.copyWith(parallax: value)),
          ),
          _slider(
            label: 'Foil intensity',
            value: _tuning.foil,
            min: 0,
            max: 1.8,
            onChanged: (value) =>
                setState(() => _tuning = _tuning.copyWith(foil: value)),
          ),
          _slider(
            label: 'Edge glow',
            value: _tuning.glow,
            min: 0,
            max: 1.8,
            onChanged: (value) =>
                setState(() => _tuning = _tuning.copyWith(glow: value)),
          ),
          _slider(
            label: 'Ambient FX',
            value: _tuning.ambient,
            min: 0,
            max: 1.8,
            onChanged: (value) =>
                setState(() => _tuning = _tuning.copyWith(ambient: value)),
          ),
          _slider(
            label: 'Reveal particles',
            value: _tuning.particles,
            min: 0,
            max: 1.8,
            onChanged: (value) =>
                setState(() => _tuning = _tuning.copyWith(particles: value)),
          ),
          _slider(
            label: 'Reveal speed',
            value: _revealSpeed,
            min: 0.6,
            max: 1.6,
            onChanged: (value) => setState(() => _revealSpeed = value),
          ),
          const Divider(height: 28, color: Colors.white12),
          _profileSummary(isZh),
        ],
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSummary(bool isZh) {
    final profile = _spec.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.label + ' PROFILE',
          style: TextStyle(
            color: profile.accentColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        _fact('Artwork', _spec.id),
        _fact('Ambient', _spec.ambientFx.name),
        _fact('Max tilt', profile.maxTiltDegrees.toStringAsFixed(1) + '°'),
        _fact('Particles', profile.particleCount.toString()),
        const SizedBox(height: 10),
        Text(
          isZh
              ? '下一步：gyro tilt → 真正 pack-opening 接入。'
              : 'Next: gyro tilt → pack-opening integration.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _fact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
