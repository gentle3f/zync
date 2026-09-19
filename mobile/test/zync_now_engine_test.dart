import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_entity_metadata.dart';
import 'package:zync/core/models.dart';
import 'package:zync/core/zync_now_engine.dart';

SelectedInterest interest(
  String id, [
  InterestStrength strength = InterestStrength.like,
]) =>
    SelectedInterest(id: id, strength: strength);

ZyncNowParticipant participant(
  String id,
  List<SelectedInterest> interests,
) =>
    ZyncNowParticipant(id: id, interests: interests);

void main() {
  test('requires between two and eight participants', () {
    expect(
      () => ZyncNowEngine.generate(
        participants: [
          participant('a', [interest('sports.badminton')]),
        ],
        mode: ZyncNowMode.familiar,
      ),
      throwsArgumentError,
    );

    expect(
      () => ZyncNowEngine.generate(
        participants: [
          for (var i = 0; i < 9; i++)
            participant('p$i', [interest('sports.badminton')]),
        ],
        mode: ZyncNowMode.familiar,
      ),
      throwsArgumentError,
    );
  });

  test('two-person familiar mode prefers an exact shared activity', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('sports.badminton', InterestStrength.love),
          interest('food.coffee'),
        ]),
        participant('b', [
          interest('sports.badminton', InterestStrength.like),
          interest('media.movies'),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      seed: 'pair-familiar',
    );

    expect(result, isNotEmpty);
    expect(result.first.sourceInterestIds, contains('sports.badminton'));
    expect(result.first.selectedParticipantCount, 2);
    expect(result.first.participantCount, 2);
    expect(result.first.titleFor('zh-HK'), contains('羽毛球'));
  });

  test('familiar mode is group-native rather than requiring universal overlap', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [interest('sports.badminton', InterestStrength.love)]),
        participant('b', [interest('sports.badminton')]),
        participant('c', [interest('sports.tennis')]),
        participant('d', [interest('sports.tennis')]),
      ],
      mode: ZyncNowMode.familiar,
      seed: 'group-familiar',
    );

    expect(result, isNotEmpty);
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('sports.badminton') ||
          candidate.sourceInterestIds.contains('sports.tennis')),
      isTrue,
    );
    expect(result.every((candidate) => candidate.participantCount == 4), isTrue);
  });

  test('pass the passion treats Want to Try as an ideal learner signal', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('outdoors.bouldering', InterestStrength.love),
        ]),
        participant('b', [
          interest('outdoors.bouldering', InterestStrength.wantToTry),
          interest('food.coffee', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.passThePassion,
      seed: 'teach',
    );

    expect(result, isNotEmpty);
    expect(
      result.any((candidate) =>
          candidate.templateId == 'activity.peer_teaches_beginner'),
      isTrue,
    );
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('outdoors.bouldering')),
      isTrue,
    );
  });

  test('new to everyone only proposes interests nobody selected', () {
    final participants = [
      participant('a', [interest('sports.badminton', InterestStrength.love)]),
      participant('b', [interest('sports.badminton', InterestStrength.like)]),
    ];
    final selectedIds = participants
        .expand((item) => item.interests)
        .map((item) => item.id)
        .toSet();

    final result = ZyncNowEngine.generate(
      participants: participants,
      mode: ZyncNowMode.newToEveryone,
      seed: 'new',
    );

    expect(result, isNotEmpty);
    for (final candidate in result) {
      expect(candidate.selectedParticipantCount, 0);
      expect(
        candidate.sourceInterestIds.any(selectedIds.contains),
        isFalse,
      );
    }
  });


  test('new to everyone can prioritize a shared Want to Try interest', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('wellness.yoga', InterestStrength.wantToTry),
          interest('food.coffee'),
        ]),
        participant('b', [
          interest('wellness.yoga', InterestStrength.wantToTry),
          interest('media.movies'),
        ]),
      ],
      mode: ZyncNowMode.newToEveryone,
      seed: 'mutual-want-to-try',
    );

    expect(result, isNotEmpty);
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('wellness.yoga')),
      isTrue,
    );
  });

  test('meet in the middle creates a crossover from different interests', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('photography.general', InterestStrength.love),
        ]),
        participant('b', [
          interest('crafts.diy', InterestStrength.love),
        ]),
        participant('c', [
          interest('photography.general'),
          interest('crafts.diy'),
        ]),
      ],
      mode: ZyncNowMode.meetInTheMiddle,
      seed: 'creative-cross',
    );

    expect(result, isNotEmpty);
    expect(result.first.sourceInterestIds, hasLength(2));
    expect(result.first.templateId, 'activity.crossover_challenge');
    expect(result.first.titleFor('zh-Hant'), contains('×'));
  });

  test('hard verb veto is respected by the chosen template', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('food.cooking', InterestStrength.love),
        ]),
        participant('b', [
          interest('food.cooking', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      constraints: const ZyncNowConstraints(
        hardVetoVerbs: {ActivityVerb.make},
      ),
      seed: 'no-make',
    );

    for (final candidate in result) {
      final required = candidate.template?.requiredVerbs ?? const {};
      expect(required.contains(ActivityVerb.make), isFalse);
    }
  });

  test('free-only budget removes activities with no free-cost profile', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('outdoors.bouldering', InterestStrength.love),
          interest('sports.basketball', InterestStrength.love),
        ]),
        participant('b', [
          interest('outdoors.bouldering', InterestStrength.like),
          interest('sports.basketball', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      constraints: const ZyncNowConstraints(
        maxCost: ActivityCostBand.free,
      ),
      seed: 'free-only',
    );

    expect(result, isNotEmpty);
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('outdoors.bouldering')),
      isFalse,
    );
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('sports.basketball')),
      isTrue,
    );
  });

  test('one participant private free-only budget filters paid activity for everyone',
      () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('outdoors.bouldering', InterestStrength.love),
          interest('sports.basketball', InterestStrength.love),
        ]),
        participant('b', [
          interest('outdoors.bouldering', InterestStrength.like),
          interest('sports.basketball', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      participantConstraints: const {
        'b': ZyncNowConstraints(maxCost: ActivityCostBand.free),
      },
      seed: 'private-free-only',
    );

    expect(result, isNotEmpty);
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('outdoors.bouldering')),
      isFalse,
    );
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('sports.basketball')),
      isTrue,
    );
  });

  test('one participant private hard veto changes the chosen template', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('food.cooking', InterestStrength.love),
        ]),
        participant('b', [
          interest('food.cooking', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      participantConstraints: const {
        'b': ZyncNowConstraints(
          hardVetoVerbs: {ActivityVerb.make},
        ),
      },
      seed: 'private-no-make',
    );

    expect(result, isNotEmpty);
    for (final candidate in result) {
      expect(
        candidate.template?.requiredVerbs.contains(ActivityVerb.make) ?? false,
        isFalse,
      );
    }
  });

  test('private setting constraint is enforced for the whole candidate set', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('media.movies', InterestStrength.love),
        ]),
        participant('b', [
          interest('media.movies', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      participantConstraints: const {
        'b': ZyncNowConstraints(setting: ActivitySetting.outdoor),
      },
      seed: 'private-outdoor',
    );

    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('media.movies')),
      isFalse,
    );
  });

  test('flexible time and either setting behave as no-preference wildcards', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('sports.badminton', InterestStrength.love),
        ]),
        participant('b', [
          interest('sports.badminton', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      participantConstraints: const {
        'a': ZyncNowConstraints(
          duration: ActivityDurationBand.flexible,
          setting: ActivitySetting.either,
        ),
      },
      seed: 'private-flexible',
    );

    expect(result, isNotEmpty);
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('sports.badminton')),
      isTrue,
    );
  });

  test('one participant private category veto removes sports candidates', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('sports.badminton', InterestStrength.love),
          interest('food.coffee', InterestStrength.love),
        ]),
        participant('b', [
          interest('sports.badminton', InterestStrength.like),
          interest('food.coffee', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      participantConstraints: const {
        'b': ZyncNowConstraints(
          hardVetoCategories: {'sports'},
        ),
      },
      seed: 'private-no-sports',
    );

    expect(result, isNotEmpty);
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('sports.badminton')),
      isFalse,
    );
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('food.coffee')),
      isTrue,
    );
  });

  test('private constraints reject unknown participant IDs', () {
    expect(
      () => ZyncNowEngine.generate(
        participants: [
          participant('a', [interest('sports.badminton')]),
          participant('b', [interest('sports.badminton')]),
        ],
        mode: ZyncNowMode.familiar,
        participantConstraints: const {
          'not-in-room': ZyncNowConstraints(
            maxCost: ActivityCostBand.free,
          ),
        },
      ),
      throwsArgumentError,
    );
  });

  test('engine can use taxonomy defaults for interests without explicit metadata', () {
    final result = ZyncNowEngine.generate(
      participants: [
        participant('a', [
          interest('gaming.strategy', InterestStrength.love),
        ]),
        participant('b', [
          interest('gaming.strategy', InterestStrength.like),
        ]),
      ],
      mode: ZyncNowMode.familiar,
      seed: 'taxonomy-default',
    );

    expect(result, isNotEmpty);
    expect(
      result.any((candidate) =>
          candidate.sourceInterestIds.contains('gaming.strategy')),
      isTrue,
    );
  });

  test('recent activity repeat key lowers the same candidate score', () {
    final participants = [
      participant('a', [
        interest('sports.badminton', InterestStrength.love),
        interest('sports.tennis', InterestStrength.like),
      ]),
      participant('b', [
        interest('sports.badminton', InterestStrength.like),
        interest('sports.tennis', InterestStrength.like),
      ]),
    ];

    final baseline = ZyncNowEngine.generate(
      participants: participants,
      mode: ZyncNowMode.familiar,
      seed: 'repeat-penalty',
      limit: 20,
    );
    final badminton = baseline.firstWhere(
      (candidate) =>
          candidate.sourceInterestIds.contains('sports.badminton'),
    );

    final repeated = ZyncNowEngine.generate(
      participants: participants,
      mode: ZyncNowMode.familiar,
      priorActivityKeys: {badminton.repeatKey},
      seed: 'repeat-penalty',
      limit: 20,
    );
    final same = repeated.firstWhere(
      (candidate) => candidate.id == badminton.id,
    );

    expect(same.score, lessThan(badminton.score));
  });

  test('surprise mode is deterministic for the same session seed', () {
    final participants = [
      participant('a', [
        interest('sports.badminton'),
        interest('food.coffee'),
        interest('media.movies'),
      ]),
      participant('b', [
        interest('sports.tennis'),
        interest('music.pop'),
        interest('gaming.video'),
      ]),
      participant('c', [
        interest('crafts.diy'),
        interest('photography.general'),
      ]),
    ];

    final first = ZyncNowEngine.generate(
      participants: participants,
      mode: ZyncNowMode.surprise,
      seed: 'same-session',
    );
    final second = ZyncNowEngine.generate(
      participants: participants,
      mode: ZyncNowMode.surprise,
      seed: 'same-session',
    );

    expect(
      first.map((candidate) => candidate.id).toList(),
      second.map((candidate) => candidate.id).toList(),
    );
  });
}
