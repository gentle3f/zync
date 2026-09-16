import 'package:flutter/material.dart';

import '../core/local_store.dart';
import '../core/models.dart';
import '../l10n/generated/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.peopleHistory)),
      body: FutureBuilder<List<ZyncHistoryEntry>>(
        future: LocalStore.loadHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final history = snapshot.data!;
          if (history.isEmpty) return Center(child: Text(l10n.noHistory));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = history[index];
              final name = entry.peerNickname.trim().isEmpty ? 'Zync #${entry.peerId.substring(0, 6)}' : entry.peerNickname;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(name),
                subtitle: Text('${entry.previousSharedIds.length} matches · ${entry.sessionCount} sessions'),
                trailing: Text(_shortDate(entry.lastZyncAt.toLocal())),
              );
            },
          );
        },
      ),
    );
  }

  String _shortDate(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
