import 'package:flutter/material.dart';

import '../core/interest_catalog.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.profile.nickname);
    _selected = {for (final item in widget.profile.interests) item.id: item.strength};
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

  Future<void> _save() async {
    if (_selected.length < 5) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final profile = widget.profile.copyWith(
      nickname: _nickname.text.trim(),
      language: locale,
      interests: _selected.entries
          .map((entry) => SelectedInterest(id: entry.key, strength: entry.value))
          .toList(),
    );
    await widget.onSaved(profile);
    if (widget.editing && mounted) Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final results = InterestCatalog.search(_search.text, locale);

    return Scaffold(
      appBar: widget.editing ? AppBar(title: Text(l10n.myInterests)) : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.editing) ...[
                    Text('Zync', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(l10n.tagline, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _nickname,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.nicknameOptional,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  Text(l10n.pickInterests, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(l10n.pickAtLeastFive),
                  const SizedBox(height: 14),
                  SearchBar(
                    controller: _search,
                    hintText: l10n.searchAnything,
                    leading: const Icon(Icons.search),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(l10n.selectedCount(_selected.length), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (_selected.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: InterestStrength.values.map((strength) {
                            final count = _selected.values.where((value) => value == strength).length;
                            if (count == 0) return const SizedBox.shrink();
                            return Text('${_strengthEmoji(strength)}$count');
                          }).toList(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final interest = results[index];
                  final selected = _selected[interest.id];
                  return ListTile(
                    onTap: () => _toggle(interest.id),
                    leading: Icon(
                      selected == null ? Icons.add_circle_outline : Icons.check_circle,
                      color: selected == null ? null : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(interest.labelFor(locale)),
                    subtitle: Text(interest.category),
                    trailing: selected == null
                        ? null
                        : PopupMenuButton<InterestStrength>(
                            tooltip: '',
                            initialValue: selected,
                            onSelected: (value) => setState(() => _selected[interest.id] = value),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: InterestStrength.love, child: Text('❤️ ${l10n.love}')),
                              PopupMenuItem(value: InterestStrength.like, child: Text('👍 ${l10n.like}')),
                              PopupMenuItem(value: InterestStrength.wantToTry, child: Text('🤔 ${l10n.wantToTry}')),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('${_strengthEmoji(selected)} ${_strengthLabel(l10n, selected)}'),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FilledButton.icon(
        onPressed: _selected.length >= 5 ? _save : null,
        icon: const Icon(Icons.arrow_forward),
        label: Text(l10n.saveAndContinue),
        style: FilledButton.styleFrom(minimumSize: const Size(220, 54)),
      ),
    );
  }

  String _strengthEmoji(InterestStrength strength) => switch (strength) {
        InterestStrength.love => '❤️',
        InterestStrength.like => '👍',
        InterestStrength.wantToTry => '🤔',
      };

  String _strengthLabel(AppLocalizations l10n, InterestStrength strength) => switch (strength) {
        InterestStrength.love => l10n.love,
        InterestStrength.like => l10n.like,
        InterestStrength.wantToTry => l10n.wantToTry,
      };
}
