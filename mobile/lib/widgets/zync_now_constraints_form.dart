import 'package:flutter/material.dart';

import '../core/interest_entity_metadata.dart';
import '../core/localized_domain_text.dart';
import '../core/zync_now_constraints_transport.dart';
import '../core/zync_now_engine.dart';
import '../ui/zync_design.dart';

class ZyncNowConstraintsForm extends StatefulWidget {
  const ZyncNowConstraintsForm({
    super.key,
    required this.onSubmit,
    this.submitLabel,
    this.enabled = true,
  });

  final Future<void> Function(ZyncNowPrivateContext context) onSubmit;
  final String? submitLabel;
  final bool enabled;

  @override
  State<ZyncNowConstraintsForm> createState() =>
      _ZyncNowConstraintsFormState();
}

class _ZyncNowConstraintsFormState extends State<ZyncNowConstraintsForm> {
  ActivityDurationBand _duration = ActivityDurationBand.flexible;
  ActivityCostBand? _cost;
  ActivityEnergy? _energy;
  ActivitySetting _setting = ActivitySetting.either;
  ZyncNowNoveltyPreference _novelty = ZyncNowNoveltyPreference.mixed;
  final Set<ActivityVerb> _vetoVerbs = {};
  final Set<String> _vetoCategories = {};
  bool _submitting = false;

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  Future<void> _submit() async {
    if (_submitting || !widget.enabled) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        ZyncNowPrivateContext(
          constraints: ZyncNowConstraints(
            duration: _duration,
            maxCost: _cost,
            energy: _energy,
            setting: _setting,
            hardVetoVerbs: Set.unmodifiable(_vetoVerbs),
            hardVetoCategories: Set.unmodifiable(_vetoCategories),
          ),
          novelty: _novelty,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int get _vetoCount => _vetoVerbs.length + _vetoCategories.length;

  void _toggleVerb(ActivityVerb verb, bool selected) {
    setState(() {
      if (selected) {
        if (_vetoCount < 3) _vetoVerbs.add(verb);
      } else {
        _vetoVerbs.remove(verb);
      }
    });
  }

  void _toggleCategory(String category, bool selected) {
    setState(() {
      if (selected) {
        if (_vetoCount < 3) _vetoCategories.add(category);
      } else {
        _vetoCategories.remove(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(_pick(
          en: 'How much time?',
          zhHant: '今次有幾多時間？',
          zhHans: '这次有多少时间？',
        )),
        _choiceWrap([
          _Choice<ActivityDurationBand>(
            value: ActivityDurationBand.under30m,
            label: _pick(en: 'Under 30m', zhHant: '30分鐘內', zhHans: '30分钟内'),
          ),
          _Choice<ActivityDurationBand>(
            value: ActivityDurationBand.under90m,
            label: _pick(en: '30–90m', zhHant: '30–90分鐘', zhHans: '30–90分钟'),
          ),
          _Choice<ActivityDurationBand>(
            value: ActivityDurationBand.halfDay,
            label: _pick(en: '2–4 hours', zhHant: '2–4小時', zhHans: '2–4小时'),
          ),
          _Choice<ActivityDurationBand>(
            value: ActivityDurationBand.flexible,
            label: _pick(en: 'Flexible', zhHant: '時間彈性', zhHans: '时间灵活'),
          ),
        ], _duration, (value) => setState(() => _duration = value)),
        const SizedBox(height: 20),

        _sectionTitle(_pick(
          en: 'Budget',
          zhHant: '預算',
          zhHans: '预算',
        )),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(_pick(en: 'Free', zhHant: '免費', zhHans: '免费')),
              selected: _cost == ActivityCostBand.free,
              onSelected: widget.enabled
                  ? (_) => setState(() => _cost = ActivityCostBand.free)
                  : null,
            ),
            ChoiceChip(
              label: Text(_pick(en: 'Low', zhHant: '低', zhHans: '低')),
              selected: _cost == ActivityCostBand.low,
              onSelected: widget.enabled
                  ? (_) => setState(() => _cost = ActivityCostBand.low)
                  : null,
            ),
            ChoiceChip(
              label: Text(_pick(en: 'Medium', zhHant: '中等', zhHans: '中等')),
              selected: _cost == ActivityCostBand.medium,
              onSelected: widget.enabled
                  ? (_) => setState(() => _cost = ActivityCostBand.medium)
                  : null,
            ),
            ChoiceChip(
              label: Text(_pick(en: 'Any', zhHant: '冇所謂', zhHans: '都可以')),
              selected: _cost == null,
              onSelected:
                  widget.enabled ? (_) => setState(() => _cost = null) : null,
            ),
          ],
        ),
        const SizedBox(height: 20),

        _sectionTitle(_pick(
          en: 'Energy',
          zhHant: '想郁幾多？',
          zhHans: '想活动多少？',
        )),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(_pick(en: 'Chill', zhHant: 'Chill', zhHans: '轻松')),
              selected: _energy == ActivityEnergy.chill,
              onSelected: widget.enabled
                  ? (_) => setState(() => _energy = ActivityEnergy.chill)
                  : null,
            ),
            ChoiceChip(
              label: Text(_pick(en: 'Moderate', zhHant: '適中', zhHans: '适中')),
              selected: _energy == ActivityEnergy.moderate,
              onSelected: widget.enabled
                  ? (_) => setState(() => _energy = ActivityEnergy.moderate)
                  : null,
            ),
            ChoiceChip(
              label: Text(_pick(en: 'Active', zhHant: '想郁', zhHans: '想动')),
              selected: _energy == ActivityEnergy.active,
              onSelected: widget.enabled
                  ? (_) => setState(() => _energy = ActivityEnergy.active)
                  : null,
            ),
            ChoiceChip(
              label: Text(_pick(en: 'Any', zhHant: '冇所謂', zhHans: '都可以')),
              selected: _energy == null,
              onSelected:
                  widget.enabled ? (_) => setState(() => _energy = null) : null,
            ),
          ],
        ),
        const SizedBox(height: 20),

        _sectionTitle(_pick(
          en: 'Where?',
          zhHant: '室內定室外？',
          zhHans: '室内还是室外？',
        )),
        _choiceWrap([
          _Choice<ActivitySetting>(
            value: ActivitySetting.indoor,
            label: _pick(en: 'Indoor', zhHant: '室內', zhHans: '室内'),
          ),
          _Choice<ActivitySetting>(
            value: ActivitySetting.outdoor,
            label: _pick(en: 'Outdoor', zhHant: '室外', zhHans: '室外'),
          ),
          _Choice<ActivitySetting>(
            value: ActivitySetting.either,
            label: _pick(en: 'Either', zhHant: '都得', zhHans: '都可以'),
          ),
        ], _setting, (value) => setState(() => _setting = value)),
        const SizedBox(height: 20),

        _sectionTitle(_pick(
          en: 'How adventurous?',
          zhHant: '今次想熟悉定試新嘢？',
          zhHans: '这次想熟悉还是试新东西？',
        )),
        _choiceWrap([
          _Choice<ZyncNowNoveltyPreference>(
            value: ZyncNowNoveltyPreference.familiar,
            label: _pick(en: 'Familiar', zhHant: '穩陣熟悉', zhHans: '熟悉稳妥'),
          ),
          _Choice<ZyncNowNoveltyPreference>(
            value: ZyncNowNoveltyPreference.mixed,
            label: _pick(en: 'Mix it up', zhHant: '一半新一半熟', zhHans: '新旧混合'),
          ),
          _Choice<ZyncNowNoveltyPreference>(
            value: ZyncNowNoveltyPreference.adventurous,
            label: _pick(en: 'Adventurous', zhHant: '試新嘢', zhHans: '试新东西'),
          ),
        ], _novelty, (value) => setState(() => _novelty = value)),
        const SizedBox(height: 20),

        _sectionTitle(_pick(
          en: 'Hard no',
          zhHant: '真係唔想做',
          zhHans: '真的不想做',
        )),
        Text(
          _pick(
            en: 'Optional · choose up to 3. Zync will never override these.',
            zhHant: '可選 · 最多3個。Zync 絕對唔會越過呢啲 veto。',
            zhHans: '可选 · 最多3个。Zync 绝不会越过这些 veto。',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(_pick(en: 'No sports', zhHant: '唔做運動', zhHans: '不做运动')),
              selected: _vetoCategories.contains('sports'),
              onSelected: widget.enabled
                  ? (value) => _toggleCategory('sports', value)
                  : null,
            ),
            FilterChip(
              label: Text(_pick(en: 'No making / cooking', zhHant: '唔整／唔煮', zhHans: '不制作／不烹饪')),
              selected: _vetoVerbs.contains(ActivityVerb.make),
              onSelected: widget.enabled
                  ? (value) => _toggleVerb(ActivityVerb.make, value)
                  : null,
            ),
            FilterChip(
              label: Text(_pick(en: 'No competition', zhHant: '唔比賽', zhHans: '不比赛')),
              selected: _vetoVerbs.contains(ActivityVerb.challenge),
              onSelected: widget.enabled
                  ? (value) => _toggleVerb(ActivityVerb.challenge, value)
                  : null,
            ),
            FilterChip(
              label: Text(_pick(en: 'No watching', zhHant: '唔想睇片', zhHans: '不想看视频')),
              selected: _vetoVerbs.contains(ActivityVerb.watch),
              onSelected: widget.enabled
                  ? (value) => _toggleVerb(ActivityVerb.watch, value)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 22),

        ZyncSurface(
          shadow: false,
          backgroundColor: const Color(0xFFF1EEFF),
          borderColor: const Color(0xFFE0D9FF),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded, color: ZyncPalette.plum),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocalizedDomainText.privateAnswerHint(_locale),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                widget.enabled && !_submitting ? _submit : null,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_rounded),
            label: Text(
              widget.submitLabel ??
                  _pick(
                    en: 'Lock my preferences',
                    zhHant: '鎖定我今次嘅選擇',
                    zhHans: '锁定我这次的选择',
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );

  Widget _choiceWrap<T>(
    List<_Choice<T>> choices,
    T selected,
    ValueChanged<T> onChanged,
  ) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final choice in choices)
            ChoiceChip(
              label: Text(choice.label),
              selected: choice.value == selected,
              onSelected: widget.enabled
                  ? (_) => onChanged(choice.value)
                  : null,
            ),
        ],
      );

  String _pick({
    required String en,
    required String zhHant,
    required String zhHans,
  }) {
    final raw = _locale.replaceAll('_', '-').toLowerCase();
    if (!raw.startsWith('zh')) return en;
    if (raw.contains('hans') ||
        raw.contains('-cn') ||
        raw.contains('-sg')) {
      return zhHans;
    }
    return zhHant;
  }
}

class _Choice<T> {
  const _Choice({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}
