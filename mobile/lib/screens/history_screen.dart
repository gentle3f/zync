import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/interest_catalog.dart';
import '../core/local_store.dart';
import '../core/localized_domain_text.dart';
import '../core/models.dart';
import '../core/zync_alias.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.peopleHistory)),
      body: ConnectionBackdrop(
        child: FutureBuilder<List<ZyncHistoryEntry>>(
          future: LocalStore.loadHistory(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              );
            }
            final history = snapshot.data!;
            if (history.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: ZyncSurface(
                    shadow: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ZyncIconTile(
                          icon: Icons.people_alt_outlined,
                          size: 58,
                          backgroundColor: ZyncPalette.mint,
                          foregroundColor: Color(0xFF176B57),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noHistory,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.tagline,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = history[index];
                final name = ZyncAlias.displayName(
                  nickname: entry.peerNickname,
                  localId: entry.peerId,
                  locale: locale,
                );
                final questionCount = entry.recentQuestions.length;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ZyncHistoryDetailScreen(entry: entry),
                      ),
                    ),
                    child: ZyncSurface(
                      shadow: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const ZyncIconTile(
                            icon: Icons.person_outline_rounded,
                            backgroundColor: Color(0xFFE9E5FF),
                            foregroundColor: ZyncPalette.plum,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  LocalizedDomainText.historyMeta(
                                    matches: entry.previousSharedIds.length,
                                    sessions: entry.sessionCount,
                                    locale: locale,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (questionCount > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.questionsSavedCount(questionCount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: ZyncPalette.plum),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _shortDate(entry.lastZyncAt.toLocal()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                                color: ZyncPalette.inkSoft,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _shortDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class ZyncHistoryDetailScreen extends StatelessWidget {
  const ZyncHistoryDetailScreen({super.key, required this.entry});

  final ZyncHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final name = ZyncAlias.displayName(
      nickname: entry.peerNickname,
      localId: entry.peerId,
      locale: locale,
    );
    final shared = entry.previousSharedIds
        .map((id) => InterestCatalog.byId(id)?.labelFor(locale) ?? id)
        .toList(growable: false);
    final sharedIds = entry.previousSharedIds.toSet();
    final peerOnly = entry.peerInterests
        .where((item) => !sharedIds.contains(item.id))
        .toList()
      ..sort((a, b) {
        final strength = b.strength.wireValue.compareTo(a.strength.wireValue);
        return strength != 0 ? strength : a.id.compareTo(b.id);
      });

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ConnectionBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ZyncSurface(
              borderColor: const Color(0xFFE5DFFF),
              backgroundColor: const Color(0xFFF8F5FF),
              child: Row(
                children: [
                  const ZyncIconTile(
                    icon: Icons.auto_awesome_rounded,
                    size: 54,
                    backgroundColor: Color(0xFFE9E5FF),
                    foregroundColor: ZyncPalette.plum,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          l10n.zyncSessionsMeta(
                            entry.sessionCount,
                            _shortDate(entry.lastZyncAt.toLocal()),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: ZyncPalette.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle(
              icon: Icons.favorite_outline_rounded,
              title: l10n.thingsYouBothLike,
            ),
            const SizedBox(height: 10),
            if (shared.isEmpty)
              _EmptyMemory(text: l10n.noSharedSaved)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shared.map((label) => Chip(label: Text(label))).toList(),
              ),
            const SizedBox(height: 24),
            _SectionTitle(
              icon: Icons.lightbulb_outline_rounded,
              title: l10n.thingsLearnedAboutThem,
            ),
            const SizedBox(height: 10),
            if (peerOnly.isEmpty)
              _EmptyMemory(text: l10n.nothingExtraSaved)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: peerOnly.take(18).map((interest) {
                  final label = InterestCatalog.byId(interest.id)?.labelFor(locale) ??
                      interest.customLabel ??
                      interest.id;
                  final emoji = switch (interest.strength) {
                    InterestStrength.love => '❤️',
                    InterestStrength.like => '👍',
                    InterestStrength.wantToTry => '✨',
                  };
                  return Chip(label: Text('$emoji $label'));
                }).toList(),
              ),
            if (entry.peerSocialLinks.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.alternate_email_rounded,
                title: l10n.sharedSocials,
              ),
              const SizedBox(height: 10),
              for (final link in entry.peerSocialLinks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: ZyncSurface(
                    shadow: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, color: ZyncPalette.plum),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _platformLabel(l10n, link.platform),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                link.displayValue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.openProfile,
                          onPressed: () => _openSocial(link),
                          icon: const Icon(Icons.open_in_new_rounded),
                        ),
                        IconButton(
                          tooltip: l10n.showQr,
                          onPressed: () => _showSocialQr(context, link),
                          icon: const Icon(Icons.qr_code_2_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            _SectionTitle(
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.questionsYouTalkedAbout,
            ),
            const SizedBox(height: 10),
            if (entry.recentQuestions.isEmpty)
              _EmptyMemory(text: l10n.questionsNextTime)
            else
              ...entry.recentQuestions.map(
                (memory) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ZyncSurface(
                    shadow: false,
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (memory.connectionLabel?.trim().isNotEmpty ?? false) ...[
                          Text(
                            memory.connectionLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: ZyncPalette.plum),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          memory.question,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(height: 1.35),
                        ),
                        if (memory.secondaryQuestion?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Text(
                            memory.secondaryQuestion!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: ZyncPalette.inkSoft),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${_modeLabel(l10n, memory.mode)} · ${_shortDate(memory.createdAt.toLocal())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _platformLabel(
    AppLocalizations l10n,
    SocialPlatform platform,
  ) =>
      switch (platform) {
        SocialPlatform.instagram => l10n.instagram,
        SocialPlatform.threads => l10n.threads,
        SocialPlatform.facebook => l10n.facebook,
      };

  String _modeLabel(AppLocalizations l10n, String raw) {
    for (final mode in ConversationMode.values) {
      if (mode.name != raw) continue;
      return switch (mode) {
        ConversationMode.easy => l10n.modeEasy,
        ConversationMode.fun => l10n.modeFun,
        ConversationMode.debate => l10n.modeDebate,
        ConversationMode.deep => l10n.modeDeep,
        ConversationMode.guess => l10n.modeGuess,
        ConversationMode.surprise => l10n.modeSurprise,
      };
    }
    return raw;
  }

  Future<void> _openSocial(SocialLink link) async {
    final raw = link.profileUrl;
    final uri = raw == null ? null : Uri.tryParse(raw);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Optional convenience action; local history remains available.
    }
  }

  Future<void> _showSocialQr(
    BuildContext context,
    SocialLink link,
  ) async {
    final raw = link.profileUrl;
    if (raw == null) return;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _platformLabel(l10n, link.platform),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                link.displayValue,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: ZyncPalette.inkSoft),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                color: Colors.white,
                child: QrImageView(
                  data: raw,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  size: 230,
                  padding: EdgeInsets.zero,
                  gapless: true,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openSocial(link),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l10n.openProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 21, color: ZyncPalette.plum),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      );
}

class _EmptyMemory extends StatelessWidget {
  const _EmptyMemory({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => ZyncSurface(
        shadow: false,
        backgroundColor: Colors.white.withValues(alpha: 0.72),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: ZyncPalette.inkSoft),
        ),
      );
}
