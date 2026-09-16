import 'package:flutter/material.dart';

import '../core/ai_service.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.match});
  final MatchResult match;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _ai = const AiService();
  ConversationMode _mode = ConversationMode.fun;
  AiQuestionResult? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() => _loading = true);
    final language = Localizations.localeOf(context).toLanguageTag();
    final result = await _ai.generateQuestion(language: language, mode: _mode, match: widget.match);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modes = <ConversationMode, String>{
      ConversationMode.easy: l10n.modeEasy,
      ConversationMode.fun: l10n.modeFun,
      ConversationMode.debate: l10n.modeDebate,
      ConversationMode.deep: l10n.modeDeep,
      ConversationMode.guess: l10n.modeGuess,
      ConversationMode.surprise: l10n.modeSurprise,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.startConversation)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.conversationTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modes.entries.map((entry) => ChoiceChip(
              label: Text(entry.value),
              selected: _mode == entry.key,
              onSelected: (_) {
                setState(() => _mode = entry.key);
                _generate();
              },
            )).toList(),
          ),
          const SizedBox(height: 32),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                    : Column(
                        key: ValueKey(_result?.question),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome, size: 30),
                          const SizedBox(height: 18),
                          Text(
                            _result?.question ?? '',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.35),
                          ),
                          if (_result != null && !_result!.fromAi) ...[
                            const SizedBox(height: 18),
                            Text(l10n.aiUnavailable, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.anotherQuestion),
          ),
        ],
      ),
    );
  }
}
