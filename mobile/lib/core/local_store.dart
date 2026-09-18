import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

class LocalStore {
  const LocalStore._();

  static const _profileKey = 'zync.profile.v1';
  static const _historyKey = 'zync.history.v1';
  static const _uuid = Uuid();

  static Future<LocalProfile> loadOrCreateProfile({required String language}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw != null) {
      try {
        final stored = LocalProfile.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        if (stored.language != language) {
          final updated = stored.copyWith(language: language);
          await saveProfile(updated);
          return updated;
        }
        return stored;
      } catch (_) {
        // Fall through and create a clean local profile if old local data is malformed.
      }
    }
    final profile = LocalProfile(localId: _uuid.v4(), nickname: '', language: language, interests: const []);
    await saveProfile(profile);
    return profile;
  }

  static Future<void> saveProfile(LocalProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  static Future<List<ZyncHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map((item) => ZyncHistoryEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => b.lastZyncAt.compareTo(a.lastZyncAt));
    } catch (_) {
      return const [];
    }
  }

  static Future<ZyncHistoryEntry> recordZync({
    required String peerId,
    required String peerNickname,
    required List<String> sharedIds,
    List<SelectedInterest> peerInterests = const [],
    List<SocialLink> peerSocialLinks = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = (await loadHistory()).toList();
    final now = DateTime.now().toUtc();
    final index = history.indexWhere((entry) => entry.peerId == peerId);

    late final ZyncHistoryEntry updated;
    if (index >= 0) {
      final previous = history[index];
      updated = ZyncHistoryEntry(
        peerId: peerId,
        peerNickname: peerNickname,
        previousSharedIds: List<String>.from(sharedIds),
        firstZyncAt: previous.firstZyncAt,
        lastZyncAt: now,
        sessionCount: previous.sessionCount + 1,
        peerInterests: peerInterests.isEmpty
            ? previous.peerInterests
            : List<SelectedInterest>.from(peerInterests),
        peerSocialLinks: peerSocialLinks.isEmpty
            ? previous.peerSocialLinks
            : List<SocialLink>.from(peerSocialLinks),
        recentQuestions: previous.recentQuestions,
      );
      history[index] = updated;
    } else {
      updated = ZyncHistoryEntry(
        peerId: peerId,
        peerNickname: peerNickname,
        previousSharedIds: List<String>.from(sharedIds),
        firstZyncAt: now,
        lastZyncAt: now,
        sessionCount: 1,
        peerInterests: List<SelectedInterest>.from(peerInterests),
        peerSocialLinks: List<SocialLink>.from(peerSocialLinks),
        recentQuestions: const [],
      );
      history.add(updated);
    }

    await prefs.setString(_historyKey, jsonEncode(history.map((entry) => entry.toJson()).toList()));
    return updated;
  }

  static Future<void> recordQuestion({
    required String peerId,
    required ZyncQuestionMemory memory,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = (await loadHistory()).toList();
    final index = history.indexWhere((entry) => entry.peerId == peerId);
    if (index < 0) return;

    final previous = history[index];
    final deduped = previous.recentQuestions
        .where((item) =>
            item.connectionKey != memory.connectionKey ||
            item.mode != memory.mode ||
            item.question != memory.question)
        .toList();
    final questions = [memory, ...deduped].take(24).toList(growable: false);
    history[index] = ZyncHistoryEntry(
      peerId: previous.peerId,
      peerNickname: previous.peerNickname,
      previousSharedIds: previous.previousSharedIds,
      firstZyncAt: previous.firstZyncAt,
      lastZyncAt: previous.lastZyncAt,
      sessionCount: previous.sessionCount,
      peerInterests: previous.peerInterests,
      peerSocialLinks: previous.peerSocialLinks,
      recentQuestions: questions,
    );
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((entry) => entry.toJson()).toList()),
    );
  }

  static Future<ZyncHistoryEntry?> findHistory(String peerId) async {
    final history = await loadHistory();
    for (final entry in history) {
      if (entry.peerId == peerId) return entry;
    }
    return null;
  }
}
