import 'package:flutter/material.dart';

import '../core/interest_catalog.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../ui/zync_design.dart';

class InterestDnaScreen extends StatelessWidget {
  const InterestDnaScreen({super.key, required this.profile});
  final LocalProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoryScores = <String, int>{};
    var total = 0;
    for (final selected in profile.interests) {
      final definition = InterestCatalog.byId(selected.id);
      final category = definition?.category ?? selected.customCategory ?? 'other';
      final weight = selected.strength.wireValue + 1;
      categoryScores.update(category, (value) => value + weight, ifAbsent: () => weight);
      total += weight;
    }
    final entries = categoryScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.interestDna)),
      body: ConnectionBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            ZyncSurface(
              borderColor: const Color(0xFFE5DFFF),
              backgroundColor: const Color(0xFFF9F7FF),
              child: Row(
                children: [
                  const ZyncIconTile(
                    icon: Icons.bubble_chart_rounded,
                    size: 58,
                    backgroundColor: Color(0xFFE9E5FF),
                    foregroundColor: ZyncPalette.plum,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.interestDna, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          l10n.interestsCount(profile.interests.length),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...entries.asMap().entries.map((indexed) {
              final index = indexed.key;
              final entry = indexed.value;
              final fraction = total == 0 ? 0.0 : entry.value / total;
              final color = _accent(index);
              final soft = _softAccent(index);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ZyncSurface(
                  shadow: false,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(13)),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_pretty(entry.key), style: Theme.of(context).textTheme.titleMedium)),
                          Text(
                            '${(fraction * 100).round()}%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 9,
                          backgroundColor: ZyncPalette.line.withValues(alpha: 0.65),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _accent(int index) => switch (index % 4) {
        0 => ZyncPalette.orangeDeep,
        1 => ZyncPalette.plum,
        2 => const Color(0xFF167A62),
        _ => const Color(0xFF356AA6),
      };

  Color _softAccent(int index) => switch (index % 4) {
        0 => ZyncPalette.peach,
        1 => const Color(0xFFE9E5FF),
        2 => ZyncPalette.mint,
        _ => const Color(0xFFE5F0FF),
      };

  String _pretty(String raw) => raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
}
