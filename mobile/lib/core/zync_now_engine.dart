import 'activity_templates.dart';
import 'interest_catalog.dart';
import 'interest_entity_metadata.dart';
import 'models.dart';

enum ZyncNowMode {
  familiar,
  passThePassion,
  newToEveryone,
  meetInTheMiddle,
  surprise,
}

enum ZyncNowCandidateKind { safe, discovery, wildcard }

class ZyncNowParticipant {
  const ZyncNowParticipant({
    required this.id,
    required this.interests,
  });

  final String id;
  final List<SelectedInterest> interests;
}

class ZyncNowConstraints {
  const ZyncNowConstraints({
    this.duration,
    this.maxCost,
    this.energy,
    this.setting,
    this.hardVetoVerbs = const {},
  });

  final ActivityDurationBand? duration;
  final ActivityCostBand? maxCost;
  final ActivityEnergy? energy;
  final ActivitySetting? setting;
  final Set<ActivityVerb> hardVetoVerbs;
}

class ZyncNowCandidate {
  const ZyncNowCandidate({
    required this.id,
    required this.kind,
    required this.mode,
    required this.templateId,
    required this.sourceInterestIds,
    required this.score,
    required this.selectedParticipantCount,
    required this.participantCount,
  });

  final String id;
  final ZyncNowCandidateKind kind;
  final ZyncNowMode mode;
  final String templateId;
  final List<String> sourceInterestIds;
  final double score;
  final int selectedParticipantCount;
  final int participantCount;

  ActivityTemplate? get template => ActivityTemplates.byId[templateId];

  String titleFor(String locale) {
    final base = template?.titleFor(locale) ?? '';
    final labels = sourceInterestIds
        .map((id) => InterestCatalog.byId(id)?.labelFor(locale) ?? id)
        .toList(growable: false);
    if (labels.isEmpty) return base;
    if (labels.length == 1) return '$base · ${labels.first}';
    return '$base · ${labels.join(' × ')}';
  }

  String instructionFor(String locale) =>
      template?.instructionFor(locale) ?? '';
}

class ZyncNowEngine {
  const ZyncNowEngine._();

  static List<ZyncNowCandidate> generate({
    required List<ZyncNowParticipant> participants,
    required ZyncNowMode mode,
    ZyncNowConstraints constraints = const ZyncNowConstraints(),
    String seed = '',
    int limit = 3,
  }) {
    if (participants.length < 2) {
      throw ArgumentError.value(
        participants.length,
        'participants',
        'Zync Now requires at least two participants',
      );
    }
    if (participants.length > 8) {
      throw ArgumentError.value(
        participants.length,
        'participants',
        'Zync Now v1 supports at most eight participants',
      );
    }
    if (limit < 1) return const [];

    final raw = mode == ZyncNowMode.meetInTheMiddle
        ? _crossoverCandidates(
            participants: participants,
            constraints: constraints,
            seed: seed,
          )
        : _singleInterestCandidates(
            participants: participants,
            mode: mode,
            constraints: constraints,
            seed: seed,
          );

    raw.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.id.compareTo(b.id);
    });

    final diversified = <ZyncNowCandidate>[];
    final seenFamilies = <String>{};
    for (final candidate in raw) {
      final family = _candidateFamily(candidate);
      if (diversified.length < 2 && seenFamilies.contains(family)) {
        continue;
      }
      diversified.add(candidate);
      seenFamilies.add(family);
      if (diversified.length >= limit) break;
    }

    if (diversified.length < limit) {
      for (final candidate in raw) {
        if (diversified.any((item) => item.id == candidate.id)) continue;
        diversified.add(candidate);
        if (diversified.length >= limit) break;
      }
    }

    return List.unmodifiable([
      for (var i = 0; i < diversified.length; i++)
        _withKind(
          diversified[i],
          switch (i) {
            0 => ZyncNowCandidateKind.safe,
            1 => ZyncNowCandidateKind.discovery,
            _ => ZyncNowCandidateKind.wildcard,
          },
        ),
    ]);
  }

  static ZyncNowCandidate _withKind(
    ZyncNowCandidate source,
    ZyncNowCandidateKind kind,
  ) =>
      ZyncNowCandidate(
        id: source.id,
        kind: kind,
        mode: source.mode,
        templateId: source.templateId,
        sourceInterestIds: source.sourceInterestIds,
        score: source.score,
        selectedParticipantCount: source.selectedParticipantCount,
        participantCount: source.participantCount,
      );

  static List<ZyncNowCandidate> _singleInterestCandidates({
    required List<ZyncNowParticipant> participants,
    required ZyncNowMode mode,
    required ZyncNowConstraints constraints,
    required String seed,
  }) {
    final result = <ZyncNowCandidate>[];

    for (final metadata in InterestEntityMetadataRegistry.zyncNowEligible) {
      final activity = metadata.activity!;
      if (!_profileFits(activity, participants.length, constraints)) continue;

      final selected = [
        for (final participant in participants)
          _findInterest(participant.interests, metadata.interestId),
      ];
      final selectedCount = selected.whereType<SelectedInterest>().length;
      final selectedStrongCount = selected
          .whereType<SelectedInterest>()
          .where((item) => item.strength != InterestStrength.wantToTry)
          .length;

      final fits = <double>[
        for (var i = 0; i < participants.length; i++)
          _participantFit(
            participant: participants[i],
            interestId: metadata.interestId,
            selected: selected[i],
            firstTimerFriendly: activity.firstTimerFriendly,
          ),
      ];

      if (!_modeAllows(
        mode: mode,
        participantCount: participants.length,
        selectedCount: selectedCount,
        selectedStrongCount: selectedStrongCount,
        activity: activity,
        fits: fits,
      )) {
        continue;
      }

      final templateId = _templateFor(
        activity: activity,
        mode: mode,
        constraints: constraints,
      );
      if (templateId == null) continue;

      final minFit = fits.reduce((a, b) => a < b ? a : b);
      final meanFit =
          fits.fold<double>(0, (sum, value) => sum + value) / fits.length;
      final coverage = selectedCount / participants.length;
      final score = minFit * 30 +
          meanFit * 25 +
          coverage * 20 +
          _modeFit(
                mode: mode,
                selectedCount: selectedCount,
                selectedStrongCount: selectedStrongCount,
                participantCount: participants.length,
                activity: activity,
                meanFit: meanFit,
              ) *
              20 +
          5 +
          _jitter(
            '$seed|${mode.name}|${metadata.interestId}|$templateId',
            mode == ZyncNowMode.surprise ? 8.0 : 0.8,
          );

      result.add(
        ZyncNowCandidate(
          id: 'zyncnow.${mode.name}.${metadata.interestId}.$templateId',
          kind: ZyncNowCandidateKind.safe,
          mode: mode,
          templateId: templateId,
          sourceInterestIds: [metadata.interestId],
          score: score,
          selectedParticipantCount: selectedCount,
          participantCount: participants.length,
        ),
      );
    }

    return result;
  }

  static List<ZyncNowCandidate> _crossoverCandidates({
    required List<ZyncNowParticipant> participants,
    required ZyncNowConstraints constraints,
    required String seed,
  }) {
    final ids = <String>{};
    for (final participant in participants) {
      for (final interest in participant.interests) {
        if (InterestEntityMetadataRegistry
                .byInterestId(interest.id)
                ?.activity
                ?.eligible ??
            false) {
          ids.add(interest.id);
        }
      }
    }

    final orderedIds = ids.toList()..sort();
    final result = <ZyncNowCandidate>[];

    for (var i = 0; i < orderedIds.length; i++) {
      for (var j = i + 1; j < orderedIds.length; j++) {
        final aId = orderedIds[i];
        final bId = orderedIds[j];
        final a = InterestEntityMetadataRegistry.byInterestId(aId)?.activity;
        final b = InterestEntityMetadataRegistry.byInterestId(bId)?.activity;
        if (a == null || b == null) continue;
        if (!_profileFits(a, participants.length, constraints) ||
            !_profileFits(b, participants.length, constraints)) {
          continue;
        }

        final sharedTags = a.crossoverTags.intersection(b.crossoverTags);
        final relationship = InterestCatalog.relationshipDistance(aId, bId);
        if (sharedTags.isEmpty && relationship > 4) continue;

        final fits = <double>[];
        var selectedCount = 0;

        for (final participant in participants) {
          final aSelected = _findInterest(participant.interests, aId);
          final bSelected = _findInterest(participant.interests, bId);
          if (aSelected != null || bSelected != null) selectedCount++;

          final aFit = _participantFit(
            participant: participant,
            interestId: aId,
            selected: aSelected,
            firstTimerFriendly: a.firstTimerFriendly,
          );
          final bFit = _participantFit(
            participant: participant,
            interestId: bId,
            selected: bSelected,
            firstTimerFriendly: b.firstTimerFriendly,
          );
          fits.add(aFit > bFit ? aFit : bFit);
        }

        final minFit = fits.reduce((x, y) => x < y ? x : y);
        final meanFit =
            fits.fold<double>(0, (sum, value) => sum + value) / fits.length;
        final coverage = selectedCount / participants.length;
        final boundedSharedTags =
            sharedTags.length < 1 ? 1 : (sharedTags.length > 3 ? 3 : sharedTags.length);
        final crossFit = sharedTags.isNotEmpty
            ? 0.75 + boundedSharedTags * 0.08
            : 0.55;

        final score = minFit * 30 +
            meanFit * 25 +
            coverage * 20 +
            crossFit * 20 +
            5 +
            _jitter('$seed|crossover|$aId|$bId', 1.2);

        result.add(
          ZyncNowCandidate(
            id: 'zyncnow.meet.$aId.$bId',
            kind: ZyncNowCandidateKind.wildcard,
            mode: ZyncNowMode.meetInTheMiddle,
            templateId: 'activity.crossover_challenge',
            sourceInterestIds: [aId, bId],
            score: score,
            selectedParticipantCount: selectedCount,
            participantCount: participants.length,
          ),
        );
      }
    }

    return result;
  }

  static bool _modeAllows({
    required ZyncNowMode mode,
    required int participantCount,
    required int selectedCount,
    required int selectedStrongCount,
    required ActivityProfile activity,
    required List<double> fits,
  }) {
    final meanFit =
        fits.fold<double>(0, (sum, value) => sum + value) / fits.length;

    return switch (mode) {
      ZyncNowMode.familiar =>
        selectedCount >= 2 &&
            selectedCount / participantCount >= 0.5 &&
            meanFit >= 0.45,
      ZyncNowMode.passThePassion =>
        selectedStrongCount >= 1 &&
            selectedCount < participantCount &&
            activity.peerTeachable &&
            activity.firstTimerFriendly,
      ZyncNowMode.newToEveryone =>
        selectedCount == 0 &&
            activity.firstTimerFriendly &&
            meanFit >= 0.22,
      ZyncNowMode.surprise => meanFit >= 0.18,
      ZyncNowMode.meetInTheMiddle => false,
    };
  }

  static double _modeFit({
    required ZyncNowMode mode,
    required int selectedCount,
    required int selectedStrongCount,
    required int participantCount,
    required ActivityProfile activity,
    required double meanFit,
  }) =>
      switch (mode) {
        ZyncNowMode.familiar => selectedCount / participantCount,
        ZyncNowMode.passThePassion =>
          (selectedStrongCount / participantCount) * 0.5 +
              (activity.peerTeachable ? 0.5 : 0),
        ZyncNowMode.newToEveryone =>
          activity.firstTimerFriendly ? 0.8 + meanFit * 0.2 : 0,
        ZyncNowMode.surprise => 0.5 + meanFit * 0.5,
        ZyncNowMode.meetInTheMiddle => 0,
      };

  static String? _templateFor({
    required ActivityProfile activity,
    required ZyncNowMode mode,
    required ZyncNowConstraints constraints,
  }) {
    final ordered = switch (mode) {
      ZyncNowMode.passThePassion => [
          'activity.peer_teaches_beginner',
          ...activity.templateIds,
        ],
      ZyncNowMode.newToEveryone => activity.templateIds.toList(),
      ZyncNowMode.familiar => activity.templateIds.toList(),
      ZyncNowMode.surprise => activity.templateIds.toList(),
      ZyncNowMode.meetInTheMiddle => const <String>[],
    };

    for (final templateId in ordered) {
      final template = ActivityTemplates.byId[templateId];
      if (template == null) continue;
      if (template.requiredVerbs.any(constraints.hardVetoVerbs.contains)) {
        continue;
      }
      if (template.requiredVerbs.isNotEmpty &&
          !template.requiredVerbs.every(activity.verbs.contains)) {
        continue;
      }
      return templateId;
    }
    return null;
  }

  static bool _profileFits(
    ActivityProfile profile,
    int participantCount,
    ZyncNowConstraints constraints,
  ) {
    if (participantCount < profile.minGroupSize ||
        participantCount > profile.maxGroupSize) {
      return false;
    }
    if (constraints.duration != null &&
        !profile.durationBands.contains(constraints.duration)) {
      return false;
    }
    if (constraints.maxCost != null &&
        !_fitsMaxCost(profile.costBands, constraints.maxCost!)) {
      return false;
    }
    if (constraints.energy != null &&
        !profile.energy.contains(constraints.energy)) {
      return false;
    }
    if (constraints.setting != null &&
        !_fitsSetting(profile.settings, constraints.setting!)) {
      return false;
    }
    if (profile.verbs.isNotEmpty &&
        profile.verbs.difference(constraints.hardVetoVerbs).isEmpty) {
      return false;
    }
    return true;
  }

  static bool _fitsMaxCost(
    Set<ActivityCostBand> bands,
    ActivityCostBand maxCost,
  ) {
    int rank(ActivityCostBand value) => switch (value) {
          ActivityCostBand.free => 0,
          ActivityCostBand.low => 1,
          ActivityCostBand.medium => 2,
          ActivityCostBand.high => 3,
        };
    return bands.any((band) => rank(band) <= rank(maxCost));
  }

  static bool _fitsSetting(
    Set<ActivitySetting> settings,
    ActivitySetting requested,
  ) {
    if (settings.contains(ActivitySetting.either)) return true;
    if (settings.contains(requested)) return true;
    if (requested == ActivitySetting.indoor &&
        settings.contains(ActivitySetting.homePossible)) {
      return true;
    }
    return false;
  }

  static double _participantFit({
    required ZyncNowParticipant participant,
    required String interestId,
    required SelectedInterest? selected,
    required bool firstTimerFriendly,
  }) {
    if (selected != null) {
      return switch (selected.strength) {
        InterestStrength.love => 1.0,
        InterestStrength.like => 0.82,
        InterestStrength.wantToTry => 0.68,
      };
    }

    var bestDistance = 99;
    for (final interest in participant.interests) {
      final distance =
          InterestCatalog.relationshipDistance(interest.id, interestId);
      if (distance < bestDistance) bestDistance = distance;
    }

    final relatedFit = switch (bestDistance) {
      0 => 0.7,
      1 => 0.58,
      2 => 0.48,
      3 => 0.36,
      4 => 0.27,
      5 => 0.20,
      6 => 0.14,
      _ => 0.08,
    };
    if (firstTimerFriendly && relatedFit < 0.22) return 0.22;
    return relatedFit;
  }

  static SelectedInterest? _findInterest(
    List<SelectedInterest> interests,
    String id,
  ) {
    for (final item in interests) {
      if (item.id == id) return item;
    }
    return null;
  }

  static double _jitter(String value, double amplitude) {
    final hash = _stableHash(value);
    return (hash % 1000) / 1000 * amplitude;
  }

  static int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final code in value.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static String _candidateFamily(ZyncNowCandidate candidate) {
    if (candidate.sourceInterestIds.isEmpty) return candidate.templateId;
    return InterestCatalog
            .byId(candidate.sourceInterestIds.first)
            ?.category ??
        candidate.templateId;
  }
}
