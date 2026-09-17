import 'dart:async';

import 'package:flutter/material.dart';

import '../core/analytics_service.dart';
import '../core/interest_catalog.dart';
import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

class InterestSetupScreen extends StatefulWidget {
  const InterestSetupScreen({
    super.key,
    required this.profile,
    required this.onSaved,
    this.editing = false,
  });

  final LocalProfile profile;
  final Future<void> Function(LocalProfile profile) onSaved;
  final bool editing;

  @override
  State<InterestSetupScreen> createState() => _InterestSetupScreenState();
}

class _InterestSetupScreenState extends State<InterestSetupScreen> {
  late final TextEditingController _nickname;
  final _search = TextEditingController();
  late Map<String, InterestStrength> _selected;
  late Map<String, SelectedInterest> _custom;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.profile.nickname);
    _selected = {for (final item in widget.profile.interests) item.id: item.strength};
    _custom = {
      for (final item in widget.profile.interests)
        if (InterestCatalog.byId(item.id) == null && item.customLabel != null) item.id: item,
    };
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nickname.dispose();
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    final adding = !_selected.containsKey(id);
    setState(() {
      if (!adding) {
        _selected.remove(id);
      } else {
        _selected[id] = InterestStrength.like;
      }
    });
    if (adding) {
      unawaited(
        ZyncAnalytics.instance.track(
          AnalyticsEvent.interestAdded,
          properties: {
            'source': _custom.containsKey(id) ? 'saved_custom' : 'catalog',
            'selected_count': _selected.length,
          },
        ),
      );
    }
  }

  void _addInstantInterest() {
    final input = _search.text.trim();
    if (input.length < 2) return;
    SelectedInterest selection;
    try {
      selection = InterestCatalog.instantSelection(input);
    } on FormatException {
      return;
    }
    final adding = !_selected.containsKey(selection.id);
    setState(() {
      _selected[selection.id] = selection.strength;
      if (selection.customLabel != null) _custom[selection.id] = selection;
      _search.clear();
      _selectedCategory = null;
    });
    if (adding) {
      unawaited(
        ZyncAnalytics.instance.track(
          AnalyticsEvent.interestAdded,
          properties: {
            'source': selection.customLabel == null ? 'catalog_exact' : 'local_custom',
            'selected_count': _selected.length,
          },
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_selected.length < 5) return;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final normalized = <String, SelectedInterest>{};
    for (final entry in _selected.entries) {
      final custom = _custom[entry.key];
      final known = custom?.customLabel == null ? null : InterestCatalog.exact(custom!.customLabel!);
      final item = known == null
          ? SelectedInterest(
              id: entry.key,
              strength: entry.value,
              customLabel: custom?.customLabel,
              customCategory: custom?.customCategory,
            )
          : SelectedInterest(id: known.id, strength: entry.value);
      normalized[item.id] = item;
    }

    final profile = widget.profile.copyWith(
      nickname: _nickname.text.trim(),
      language: locale,
      interests: normalized.values.toList(),
    );
    await widget.onSaved(profile);
    if (!widget.editing) {
      unawaited(
        ZyncAnalytics.instance.track(
          AnalyticsEvent.interestSetupComplete,
          properties: {'selected_count': normalized.length},
        ),
      );
    }
    if (widget.editing && mounted) Navigator.of(context).pop(profile);
  }

  List<InterestDefinition> _customResults(String query, String locale) {
    final q = InterestCatalog.normalizeText(query);
    return _custom.values
        .where((item) {
          if (q.isEmpty) return true;
          return InterestCatalog.normalizeText(item.customLabel ?? '').contains(q) ||
              InterestCatalog.normalizeText(item.customCategory ?? '').contains(q) ||
              InterestCatalog.normalizeText(item.id).contains(q);
        })
        .map((item) => InterestDefinition(
              id: item.id,
              category: item.customCategory ?? 'other',
              labels: {'en': item.customLabel ?? item.id, locale: item.customLabel ?? item.id},
              rank: 0,
            ))
        .toList();
  }

  List<InterestDefinition> _discoveryResults() {
    final result = <InterestDefinition>[];
    final seen = <String>{};

    void addAll(Iterable<InterestDefinition?> items) {
      for (final item in items.whereType<InterestDefinition>()) {
        if (seen.add(item.id)) result.add(item);
      }
    }

    addAll(_selected.keys.map(InterestCatalog.byId));
    if (_selected.isNotEmpty) {
      addAll(InterestCatalog.relatedTo(_selected.keys, limit: 28));
    }
    addAll(InterestCatalog.popular(limit: 60));
    return result.take(80).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final query = _search.text.trim();

    final catalogResults = query.isNotEmpty
        ? InterestCatalog.search(query, locale, limit: 80)
        : _selectedCategory == null
            ? _discoveryResults()
            : InterestCatalog.popular(category: _selectedCategory, limit: 80);
    final customResults = _customResults(query, locale);
    final results = <InterestDefinition>[];
    final seen = <String>{};
    for (final item in [...customResults, ...catalogResults]) {
      if (seen.add(item.id)) results.add(item);
    }

    final exact = query.length < 2 ? null : InterestCatalog.exact(query);
    final showInstantAdd = query.length >= 2 && exact == null;
    final sectionTitle = query.isNotEmpty
        ? null
        : _selectedCategory != null
            ? LocalizedDomainText.category(_selectedCategory!, locale)
            : _selected.isNotEmpty
                ? LocalizedDomainText.suggestedForYou(locale)
                : LocalizedDomainText.popularInterests(locale);

    return Scaffold(
      appBar: widget.editing ? AppBar(title: Text(l10n.myInterests)) : null,
      body: ConnectionBackdrop(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.editing) ...[
                        Row(
                          children: [
                            const ZyncMark(size: 46, strokeWidth: 4.5),
                            const SizedBox(width: 12),
                            Text('Zync', style: Theme.of(context).textTheme.headlineMedium),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(l10n.tagline, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft)),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nickname,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.nicknameOptional,
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                      Text(l10n.pickInterests, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 5),
                      Text(l10n.pickAtLeastFive, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 3),
                      Text(
                        LocalizedDomainText.catalogCount(InterestCatalog.count, locale),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ZyncPalette.inkSoft),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          if (showInstantAdd) _addInstantInterest();
                        },
                        decoration: InputDecoration(
                          hintText: l10n.searchAnything,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _search.clear,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      if (showInstantAdd) ...[
                        const SizedBox(height: 9),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _addInstantInterest,
                            borderRadius: BorderRadius.circular(16),
                            child: Ink(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F0FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFD9CCF5)),
                              ),
                              child: Row(
                                children: [
                                  const ZyncIconTile(
                                    icon: Icons.add_rounded,
                                    size: 38,
                                    backgroundColor: Color(0xFFE7DDF8),
                                    foregroundColor: ZyncPalette.plum,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LocalizedDomainText.addExactly(query, locale),
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          LocalizedDomainText.noAiNeeded(locale),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ZyncPalette.inkSoft),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: InterestCatalog.categories.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 7),
                          itemBuilder: (context, index) {
                            final category = index == 0 ? null : InterestCatalog.categories[index - 1];
                            final selected = _selectedCategory == category && query.isEmpty;
                            return ChoiceChip(
                              selected: selected,
                              label: Text(
                                category == null
                                    ? LocalizedDomainText.allInterests(locale)
                                    : LocalizedDomainText.category(category, locale),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = category;
                                  _search.clear();
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _selected.length >= 5 ? ZyncPalette.mint : ZyncPalette.peach,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.selectedCount(_selected.length),
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: _selected.length >= 5 ? const Color(0xFF176B57) : ZyncPalette.orangeDeep,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          if (_selected.isNotEmpty)
                            Wrap(
                              spacing: 7,
                              children: InterestStrength.values.map((strength) {
                                final count = _selected.values.where((value) => value == strength).length;
                                if (count == 0) return const SizedBox.shrink();
                                return Text('${_strengthEmoji(strength)} $count', style: Theme.of(context).textTheme.bodySmall);
                              }).toList(),
                            ),
                        ],
                      ),
                      if (sectionTitle != null) ...[
                        const SizedBox(height: 10),
                        Text(sectionTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ZyncPalette.inkSoft)),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.only(bottom: index == results.length - 1 ? 0 : 8),
                      child: _interestTile(
                        context: context,
                        interest: results[index],
                        locale: locale,
                        l10n: l10n,
                      ),
                    ),
                    childCount: results.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: FilledButton.icon(
            onPressed: _selected.length >= 5 ? _save : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l10n.saveAndContinue),
          ),
        ),
      ),
    );
  }

  Widget _interestTile({
    required BuildContext context,
    required InterestDefinition interest,
    required String locale,
    required AppLocalizations l10n,
  }) {
    final selected = _selected[interest.id];
    final isCustom = InterestCatalog.byId(interest.id) == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _toggle(interest.id),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected == null ? ZyncPalette.surface : const Color(0xFFFFF4ED),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected == null ? ZyncPalette.line : ZyncPalette.peach),
          ),
          child: Row(
            children: [
              ZyncIconTile(
                icon: selected == null ? Icons.add_rounded : Icons.check_rounded,
                size: 42,
                backgroundColor: selected == null ? const Color(0xFFF1EEEB) : ZyncPalette.peach,
                foregroundColor: selected == null ? ZyncPalette.inkSoft : ZyncPalette.orangeDeep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(interest.labelFor(locale), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            LocalizedDomainText.category(interest.category, locale),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, size: 13, color: ZyncPalette.plum),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (selected != null)
                PopupMenuButton<InterestStrength>(
                  tooltip: '',
                  initialValue: selected,
                  onSelected: (value) => setState(() {
                    _selected[interest.id] = value;
                    final custom = _custom[interest.id];
                    if (custom != null) _custom[interest.id] = custom.copyWith(strength: value);
                  }),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: InterestStrength.love, child: Text('❤️ ${l10n.love}')),
                    PopupMenuItem(value: InterestStrength.like, child: Text('👍 ${l10n.like}')),
                    PopupMenuItem(value: InterestStrength.wantToTry, child: Text('✨ ${l10n.wantToTry}')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: ZyncPalette.line),
                    ),
                    child: Text('${_strengthEmoji(selected)} ${_strengthLabel(l10n, selected)}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _strengthEmoji(InterestStrength strength) => switch (strength) {
        InterestStrength.love => '❤️',
        InterestStrength.like => '👍',
        InterestStrength.wantToTry => '✨',
      };

  String _strengthLabel(AppLocalizations l10n, InterestStrength strength) => switch (strength) {
        InterestStrength.love => l10n.love,
        InterestStrength.like => l10n.like,
        InterestStrength.wantToTry => l10n.wantToTry,
      };
}
