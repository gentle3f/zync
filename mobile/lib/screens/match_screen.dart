import 'package:flutter/material.dart';

import '../core/interest_catalog.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import 'conversation_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    required this.peer,
    required this.match,
    required this.newMatchCount,
  });

  final QrProfilePayload peer;
  final MatchResult match;
  final int newMatchCount;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  int _revealed = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shared = widget.match.shared;
    final hasMatches = shared.isNotEmpty;
    final allRevealed = _revealed >= shared.length;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Spacer(),
              Icon(hasMatches ? Icons.auto_awesome : Icons.hub_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 18),
              Text(
                hasMatches ? l10n.youZync : l10n.noExactMatch,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                hasMatches ? l10n.hiddenMatches(shared.length) : l10n.findConnection,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.newMatchCount > 0) ...[
                const SizedBox(height: 8),
                Text(l10n.newMatches(widget.newMatchCount), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 30),
              if (hasMatches)
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    itemCount: _revealed,
                    itemBuilder: (context, index) {
                      final item = shared[index];
                      final label = InterestCatalog.byId(item.id)?.labelFor(locale) ?? item.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.favorite)),
                          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(_strengthText(item.strength)),
                        ),
                      );
                    },
                  ),
                )
              else
                const Spacer(flex: 2),
              if (hasMatches && !allRevealed)
                FilledButton.icon(
                  onPressed: () => setState(() => _revealed += 1),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(_revealed == 0 ? l10n.reveal : l10n.nextMatch),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                )
              else
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ConversationScreen(match: widget.match)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.startConversation),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _strengthText(InterestStrength strength) => switch (strength) {
        InterestStrength.love => '❤️❤️',
        InterestStrength.like => '👍',
        InterestStrength.wantToTry => '🤔',
      };
}
