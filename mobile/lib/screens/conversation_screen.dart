import 'package:flutter/material.dart';

import '../core/ai_service.dart';
import '../core/language_support.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.match,
    this.peerLanguage,
  });

  final MatchResult match;
  final String? peerLanguage;

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
    final result = await _ai.generateQuestion(
      language: language,
      secondaryLanguage: widget.peerLanguage,
      mode: _mode,
      match: widget.match,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final secondaryQuestion = _result?.secondaryQuestion;
    final modes = <ConversationMode, ({String label, IconData icon})>{
      ConversationMode.easy: (label: l10n.modeEasy, icon: Icons.waving_hand_outlined),
      ConversationMode.fun: (label: l10n.modeFun, icon: Icons.celebration_outlined),
      ConversationMode.debate: (label: l10n.modeDebate, icon: Icons.forum_outlined),
      ConversationMode.deep: (label: l10n.modeDeep, icon: Icons.nights_stay_outlined),
      ConversationMode.guess: (label: l10n.modeGuess, icon: Icons.psychology_alt_outlined),
      ConversationMode.surprise: (label: l10n.modeSurprise, icon: Icons.casino_outlined),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.startConversation)),
      body: ConnectionBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const ZyncMark(size: 44, strokeWidth: 4.3),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.conversationTitle, style: Theme.of(context).textTheme.headlineSmall),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: modes.entries.map((entry) {
                  final selected = _mode == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        entry.value.icon,
                        size: 18,
                        color: selected ? ZyncPalette.orangeDeep : ZyncPalette.inkSoft,
                      ),
                      label: Text(entry.value.label),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) {
                        if (_mode == entry.key) return;
                        setState(() => _mode = entry.key);
                        _generate();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 26),
            ZyncSurface(
              padding: EdgeInsets.zero,
              borderColor: const Color(0xFFE5DFFF),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -38,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: ZyncPalette.plum.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: _loading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                height: 210,
                                child: Center(
                                  child: SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: CircularProgressIndicator(strokeWidth: 2.8),
                                  ),
                                ),
                              )
                            : Column(
                                key: ValueKey('${_result?.question}|${_result?.secondaryQuestion}'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9E5FF),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.auto_awesome_rounded, color: ZyncPalette.plum),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _result?.question ?? '',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.35),
                                  ),
                                  if (secondaryQuestion != null && secondaryQuestion.isNotEmpty) ...[
                                    const SizedBox(height: 22),
                                    Divider(color: ZyncPalette.line.withValues(alpha: 0.9)),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        const Icon(Icons.translate_rounded, size: 18, color: ZyncPalette.plum),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE9E5FF),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            ZyncLanguage.nativeName(_result!.secondaryLanguage ?? widget.peerLanguage ?? 'en'),
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: ZyncPalette.plum),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      secondaryQuestion,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.4),
                                    ),
                                  ],
                                  if (_result != null && !_result!.fromAi) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: ZyncPalette.cream,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.offline_bolt_outlined, size: 18, color: ZyncPalette.inkSoft),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(l10n.aiUnavailable, style: Theme.of(context).textTheme.bodySmall)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _generate,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.anotherQuestion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
