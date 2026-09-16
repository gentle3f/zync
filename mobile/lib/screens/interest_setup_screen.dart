import 'package:flutter/material.dart';

import '../core/ai_service.dart';
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
  final _ai = const AiService();
  late Map<String, InterestStrength> _selected;
  late Map<String, SelectedInterest> _custom;
  bool _normalizing = false;

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
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
      } else {
        _selected[id] = InterestStrength.like;
      }
    });
  }

  Future<void> _normalizeAndAdd() async {
    final input = _search.text.trim();
    if (input.length < 2 || _normalizing) return;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).toLanguageTag();
    setState(() => _normalizing = true);
    final result = await _ai.normalizeInterest(input: input, language: language);
    if (!mounted) return;
    setState(() => _normalizing = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.aiUnavailable)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const ZyncIconTile(icon: Icons.auto_awesome_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.addInterest)),
          ],
        ),
        content: Text(l10n.aiSuggested(result.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.addInterest)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _selected[result.id] = InterestStrength.like;
      _custom[result.id] = SelectedInterest(
        id: result.id,
        strength: InterestStrength.like,
        customLabel: result.displayName,
        customCategory: result.category,
      );
      _search.clear();
    });
  }

  Future<void> _save() async {
    if (_selected.length < 5) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final profile = widget.profile.copyWith(
      nickname: _nickname.text.trim(),
      language: locale,
      interests: _selected.entries.map((entry) {
        final custom = _custom[entry.key];
        return SelectedInterest(
          id: entry.key,
          strength: entry.value,
          customLabel: custom?.customLabel,
          customCategory: custom?.customCategory,
        );
      }).toList(),
    );
    await widget.onSaved(profile);
    if (widget.editing && mounted) Navigator.of(context).pop(profile);
  }

  List<InterestDefinition> _customResults(String query, String locale) {
    final q = query.trim().toLowerCase();
    return _custom.values
        .where((item) {
          if (q.isEmpty) return true;
          return (item.customLabel ?? '').toLowerCase().contains(q) ||
              (item.customCategory ?? '').toLowerCase().contains(q) ||
              item.id.toLowerCase().contains(q);
        })
        .map((item) => InterestDefinition(
              id: item.id,
              category: item.customCategory ?? 'other',
              labels: {'en': item.customLabel ?? item.id, locale: item.customLabel ?? item.id},
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final query = _search.text.trim();
    final seedResults = InterestCatalog.search(query, locale);
    final customResults = _customResults(query, locale);
    final results = <InterestDefinition>[...customResults, ...seedResults];
    final canNormalize = query.length >= 2 && results.isEmpty;

    return Scaffold(
      appBar: widget.editing ? AppBar(title: Text(l10n.myInterests)) : null,
      body: ConnectionBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
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
                      const SizedBox(height: 24),
                    ],
                    Text(l10n.pickInterests, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(l10n.pickAtLeastFive, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
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
                    if (canNormalize || _normalizing) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _normalizing ? null : _normalizeAndAdd,
                          icon: _normalizing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(_normalizing ? l10n.normalizing : l10n.addWithAi(query)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
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
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final interest = results[index];
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
                                          const Icon(Icons.auto_awesome_rounded, size: 13, color: ZyncPalette.plum),
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
                  },
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
