import 'package:flutter/material.dart';

import '../core/interest_catalog.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';

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
      if (definition == null) continue;
      final weight = selected.strength.wireValue + 1;
      categoryScores.update(definition.category, (value) => value + weight, ifAbsent: () => weight);
      total += weight;
    }
    final entries = categoryScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.interestDna)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.interestsCount(profile.interests.length), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ...entries.map((entry) {
            final fraction = total == 0 ? 0.0 : entry.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_pretty(entry.key), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${(fraction * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(value: fraction, minHeight: 8, borderRadius: BorderRadius.circular(99)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _pretty(String raw) => raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
}
