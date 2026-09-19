import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'interest_catalog.dart';
import 'models.dart';
import 'progress_event.dart';
import 'zync_now_engine.dart';
import 'zync_now_memory.dart';

class LocalStore {
  const LocalStore._();

  static const _profileKey = 'zync.profile.v1';
  static const _historyKey = 'zync.history.v1';
  static const _zyncNowActivityKey = 'zync.zync_now.activities.v1';
  static const _progressEventKey = 'zync.progress.events.v1';
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
      final seenInterestIds = <String>{
        ...previous.seenInterestIds,
        ...previous.previousSharedIds,
        ...previous.peerInterests.map((item) => item.id),
        ...sharedIds,
        ...peerInterests.map((item) => item.id),
      }.toList(growable: false);
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
        seenInterestIds: seenInterestIds,
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
        seenInterestIds: <String>{
          ...sharedIds,
          ...peerInterests.map((item) => item.id),
        }.toList(growable: false),
        peerSocialLinks: List<SocialLink>.from(peerSocialLinks),
        recentQuestions: const [],
      );
      history.add(updated);
    }

    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((entry) => entry.toJson()).toList()),
    );
    await _appendProgressEvent(
      prefs,
      ZyncProgressEvent(
        id: _uuid.v4(),
        type: ZyncProgressEventType.oneToOneZync,
        source: ZyncProgressSource.oneToOne,
        occurredAt: now,
        participantCount: 2,
        repeatPerson: index >= 0,
        interestCategories: _interestCategories({
          ...sharedIds,
          ...peerInterests.map((item) => item.id),
        }),
      ),
    );
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
      seenInterestIds: previous.seenInterestIds,
      peerSocialLinks: previous.peerSocialLinks,
      recentQuestions: questions,
    );
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((entry) => entry.toJson()).toList()),
    );
  }


  static Future<List<ZyncNowActivityMemory>> loadZyncNowActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_zyncNowActivityKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      final items = decoded
          .whereType<Map>()
          .map((item) =>
              ZyncNowActivityMemory.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty && item.repeatKey.isNotEmpty)
          .toList()
        ..sort((a, b) => b.chosenAt.compareTo(a.chosenAt));
      return items;
    } catch (_) {
      return const [];
    }
  }

  static Future<ZyncNowActivityMemory> recordZyncNowChoice({
    required ZyncNowCandidate candidate,
    DateTime? chosenAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = (await loadZyncNowActivities()).toList();
    final memory = ZyncNowActivityMemory(
      id: _uuid.v4(),
      candidateId: candidate.id,
      repeatKey: candidate.repeatKey,
      templateId: candidate.templateId,
      sourceInterestIds: List<String>.from(candidate.sourceInterestIds),
      groupSize: candidate.participantCount,
      mode: candidate.mode.name,
      chosenAt: (chosenAt ?? DateTime.now()).toUtc(),
    );
    history.insert(0, memory);
    await _saveZyncNowActivities(prefs, history);
    return memory;
  }

  static Future<ZyncNowActivityMemory?> recordZyncNowOutcome({
    required String memoryId,
    required ZyncNowActivityStatus status,
    DateTime? at,
  }) async {
    if (status == ZyncNowActivityStatus.chosen) {
      throw ArgumentError.value(
        status,
        'status',
        'Outcome must be completed or skipped',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final history = (await loadZyncNowActivities()).toList();
    final index = history.indexWhere((item) => item.id == memoryId);
    if (index < 0) return null;

    final previous = history[index];
    final completedAt = status == ZyncNowActivityStatus.completed
        ? (at ?? DateTime.now()).toUtc()
        : previous.completedAt;
    final updated = previous.copyWith(
      status: status,
      completedAt: completedAt,
    );
    history[index] = updated;
    await _saveZyncNowActivities(prefs, history);

    if (status == ZyncNowActivityStatus.completed &&
        previous.status != ZyncNowActivityStatus.completed) {
      await _appendProgressEvent(
        prefs,
        ZyncProgressEvent(
          id: _uuid.v4(),
          type: ZyncProgressEventType.triedTogetherCompleted,
          source: ZyncProgressSource.zyncNow,
          occurredAt: completedAt!,
          participantCount: previous.groupSize,
          mode: previous.mode,
          interestCategories: _interestCategories(
            previous.sourceInterestIds.toSet(),
          ),
        ),
      );
    }
    return updated;
  }

  static Future<Set<String>> recentZyncNowActivityKeys({
    int limit = 40,
  }) async {
    if (limit <= 0) return const {};
    final history = await loadZyncNowActivities();
    return history
        .where((item) => item.status != ZyncNowActivityStatus.skipped)
        .take(limit)
        .map((item) => item.repeatKey)
        .toSet();
  }

  static Future<void> _saveZyncNowActivities(
    SharedPreferences prefs,
    List<ZyncNowActivityMemory> history,
  ) async {
    // Bound SharedPreferences growth. This is lightweight local activity memory,
    // not a permanent event log.
    final bounded = history.take(200).toList(growable: false);
    await prefs.setString(
      _zyncNowActivityKey,
      jsonEncode(bounded.map((item) => item.toJson()).toList()),
    );
  }

  static Future<List<ZyncProgressEvent>> loadProgressEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressEventKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      final items = decoded
          .whereType<Map>()
          .map(
            (item) => ZyncProgressEvent.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return List.unmodifiable(items);
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _appendProgressEvent(
    SharedPreferences prefs,
    ZyncProgressEvent event,
  ) async {
    final events = (await loadProgressEvents()).toList();
    if (events.any((item) => item.id == event.id)) return;
    events.insert(0, event);
    final bounded = events.take(500).toList(growable: false);
    await prefs.setString(
      _progressEventKey,
      jsonEncode(bounded.map((item) => item.toJson()).toList()),
    );
  }

  static List<String> _interestCategories(Set<String> interestIds) {
    final categories = <String>{};
    final categoryPattern = RegExp(r'^[a-z0-9_]+\$');
    for (final id in interestIds) {
      final category = InterestCatalog.byId(id)?.category.trim().toLowerCase();
      if (category != null &&
          category.isNotEmpty &&
          categoryPattern.hasMatch(category)) {
        categories.add(category);
      }
    }
    final ordered = categories.toList()..sort();
    return List.unmodifiable(ordered);
  }

  static Future<ZyncHistoryEntry?> findHistory(String peerId) async {
    final history = await loadHistory();
    for (final entry in history) {
      if (entry.peerId == peerId) return entry;
    }
    return null;
  }
}
