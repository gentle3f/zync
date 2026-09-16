import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/interest_catalog.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';
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

  Future<void> _revealNext() async {
    if (_revealed >= widget.match.shared.length) return;
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _revealed += 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shared = widget.match.shared;
    final hasMatches = shared.isNotEmpty;
    final allRevealed = _revealed >= shared.length;
    final peerName = widget.peer.nickname.trim();

    return Scaffold(
      appBar: AppBar(),
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: hasMatches ? ZyncPalette.peach : const Color(0xFFE9E5FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: hasMatches
                      ? const ZyncMark(size: 58, strokeWidth: 5.5)
                      : const Icon(Icons.hub_outlined, size: 42, color: ZyncPalette.plum),
                ),
                const SizedBox(height: 20),
                Text(
                  hasMatches ? l10n.youZync : l10n.noExactMatch,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  hasMatches ? l10n.hiddenMatches(shared.length) : l10n.findConnection,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ZyncPalette.inkSoft),
                ),
                if (peerName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(peerName, style: Theme.of(context).textTheme.titleMedium),
                ],
                if (widget.newMatchCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: ZyncPalette.mint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.newMatches(widget.newMatchCount),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF176B57)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (hasMatches)
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _revealed == 0
                          ? Center(
                              key: const ValueKey('hidden'),
                              child: ZyncSurface(
                                shadow: false,
                                backgroundColor: Colors.white.withValues(alpha: 0.78),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.visibility_off_outlined, color: ZyncPalette.inkSoft),
                                    const SizedBox(height: 10),
                                    Text(
                                      l10n.hiddenMatches(shared.length),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              key: ValueKey(_revealed),
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: _revealed,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = shared[index];
                                final label = InterestCatalog.byId(item.id)?.labelFor(locale) ?? item.customLabel ?? item.id;
                                final isNewest = index == _revealed - 1;
                                final card = ZyncSurface(
                                  shadow: false,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  child: Row(
                                    children: [
                                      ZyncIconTile(
                                        icon: _strengthIcon(item.strength),
                                        backgroundColor: _strengthBackground(item.strength),
                                        foregroundColor: _strengthColor(item.strength),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
                                      ),
                                      Text(_strengthText(item.strength), style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                );
                                if (!isNewest) return card;
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey('reveal-${item.id}-$_revealed'),
                                  tween: Tween(begin: 0.96, end: 1),
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) => Transform.scale(
                                    scale: value,
                                    child: Opacity(opacity: ((value - 0.96) / 0.04).clamp(0, 1), child: child),
                                  ),
                                  child: card,
                                );
                              },
                            ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: hasMatches && !allRevealed
                      ? FilledButton.icon(
                          onPressed: _revealNext,
                          icon: const Icon(Icons.visibility_outlined),
                          label: Text(_revealed == 0 ? l10n.reveal : l10n.nextMatch),
                        )
                      : FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ConversationScreen(match: widget.match)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: Text(l10n.startConversation),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _strengthText(InterestStrength strength) => switch (strength) {
        InterestStrength.love => '❤️',
        InterestStrength.like => '👍',
        InterestStrength.wantToTry => '✨',
      };

  IconData _strengthIcon(InterestStrength strength) => switch (strength) {
        InterestStrength.love => Icons.favorite_rounded,
        InterestStrength.like => Icons.thumb_up_alt_rounded,
        InterestStrength.wantToTry => Icons.explore_outlined,
      };

  Color _strengthBackground(InterestStrength strength) => switch (strength) {
        InterestStrength.love => ZyncPalette.peach,
        InterestStrength.like => ZyncPalette.mint,
        InterestStrength.wantToTry => const Color(0xFFE9E5FF),
      };

  Color _strengthColor(InterestStrength strength) => switch (strength) {
        InterestStrength.love => ZyncPalette.orangeDeep,
        InterestStrength.like => const Color(0xFF176B57),
        InterestStrength.wantToTry => ZyncPalette.plum,
      };
}
