import 'group_zync_protocol.dart';
import 'interest_entity_metadata.dart';
import 'zync_now_engine.dart';

enum ZyncNowNoveltyPreference {
  familiar,
  mixed,
  adventurous,
}

class ZyncNowPrivateContext {
  const ZyncNowPrivateContext({
    required this.constraints,
    this.novelty = ZyncNowNoveltyPreference.mixed,
  });

  final ZyncNowConstraints constraints;
  final ZyncNowNoveltyPreference novelty;
}

class ZyncNowConstraintsTransport {
  const ZyncNowConstraintsTransport._();

  static const String inputKind = 'zync_now_constraints';

  static GroupPrivateInput encode({
    required int roundNumber,
    required String participantId,
    required ZyncNowPrivateContext context,
  }) {
    final answers = <String>[
      _durationToken(context.constraints.duration),
      _costToken(context.constraints.maxCost),
      _energyToken(context.constraints.energy),
      _settingToken(context.constraints.setting),
      _noveltyToken(context.novelty),
    ];

    final vetoTokens = <String>[
      ...context.constraints.hardVetoVerbs
          .map((verb) => 'VV-${verb.name}'),
      ...context.constraints.hardVetoCategories.map((category) {
        final normalized = category.trim().toLowerCase();
        if (!RegExp(r'^[a-z0-9_]{1,24}$').hasMatch(normalized)) {
          throw ArgumentError.value(
            category,
            'hardVetoCategories',
            'Invalid Zync Now veto category',
          );
        }
        return 'VC-$normalized';
      }),
    ]..sort();

    if (vetoTokens.length > 3) {
      throw ArgumentError(
        'Zync Now v1 supports at most three private hard vetoes',
      );
    }

    answers.addAll(vetoTokens);

    final input = GroupPrivateInput(
      roundNumber: roundNumber,
      participantId: participantId,
      answerIds: List.unmodifiable(answers),
    );

    GroupPrivateInput.fromJson(input.toJson());
    return input;
  }

  static ZyncNowPrivateContext decode(GroupPrivateInput input) {
    String? durationToken;
    String? costToken;
    String? energyToken;
    String? settingToken;
    String? noveltyToken;
    final vetoVerbs = <ActivityVerb>{};
    final vetoCategories = <String>{};

    for (final token in input.answerIds) {
      if (token.startsWith('D-')) {
        if (durationToken != null) {
          throw const FormatException('Duplicate Zync Now duration');
        }
        durationToken = token;
        continue;
      }
      if (token.startsWith('C-')) {
        if (costToken != null) {
          throw const FormatException('Duplicate Zync Now cost');
        }
        costToken = token;
        continue;
      }
      if (token.startsWith('E-')) {
        if (energyToken != null) {
          throw const FormatException('Duplicate Zync Now energy');
        }
        energyToken = token;
        continue;
      }
      if (token.startsWith('S-')) {
        if (settingToken != null) {
          throw const FormatException('Duplicate Zync Now setting');
        }
        settingToken = token;
        continue;
      }
      if (token.startsWith('N-')) {
        if (noveltyToken != null) {
          throw const FormatException('Duplicate Zync Now novelty');
        }
        noveltyToken = token;
        continue;
      }
      if (token.startsWith('VV-')) {
        final name = token.substring(3);
        final verb = ActivityVerb.values.where(
          (item) => item.name == name,
        );
        if (verb.length != 1 || !vetoVerbs.add(verb.single)) {
          throw const FormatException('Invalid Zync Now verb veto');
        }
        continue;
      }
      if (token.startsWith('VC-')) {
        final category = token.substring(3);
        if (!RegExp(r'^[a-z0-9_]{1,24}$').hasMatch(category) ||
            !vetoCategories.add(category)) {
          throw const FormatException('Invalid Zync Now category veto');
        }
        continue;
      }

      throw const FormatException('Unknown Zync Now constraint token');
    }

    if (durationToken == null ||
        costToken == null ||
        energyToken == null ||
        settingToken == null ||
        noveltyToken == null ||
        vetoVerbs.length + vetoCategories.length > 3) {
      throw const FormatException('Incomplete Zync Now private constraints');
    }

    return ZyncNowPrivateContext(
      constraints: ZyncNowConstraints(
        duration: _decodeDuration(durationToken),
        maxCost: _decodeCost(costToken),
        energy: _decodeEnergy(energyToken),
        setting: _decodeSetting(settingToken),
        hardVetoVerbs: Set.unmodifiable(vetoVerbs),
        hardVetoCategories: Set.unmodifiable(vetoCategories),
      ),
      novelty: _decodeNovelty(noveltyToken),
    );
  }

  static List<ZyncNowMode> preferredModes(
    Iterable<ZyncNowPrivateContext> contexts,
  ) {
    final values = contexts.toList(growable: false);
    if (values.isEmpty) {
      return const [ZyncNowMode.surprise];
    }

    if (values.any(
      (item) => item.novelty == ZyncNowNoveltyPreference.familiar,
    )) {
      return const [ZyncNowMode.familiar];
    }

    if (values.every(
      (item) => item.novelty == ZyncNowNoveltyPreference.adventurous,
    )) {
      return const [
        ZyncNowMode.newToEveryone,
        ZyncNowMode.surprise,
        ZyncNowMode.meetInTheMiddle,
      ];
    }

    return const [
      ZyncNowMode.passThePassion,
      ZyncNowMode.surprise,
      ZyncNowMode.familiar,
    ];
  }

  static Map<String, ZyncNowConstraints> engineConstraints(
    Map<String, ZyncNowPrivateContext> contexts,
  ) =>
      Map.unmodifiable({
        for (final entry in contexts.entries)
          entry.key: entry.value.constraints,
      });

  static String _durationToken(ActivityDurationBand? value) => switch (value) {
        ActivityDurationBand.under30m => 'D-30',
        ActivityDurationBand.under90m => 'D-90',
        ActivityDurationBand.halfDay => 'D-HALF',
        ActivityDurationBand.flexible || null => 'D-FLEX',
      };

  static ActivityDurationBand _decodeDuration(String token) => switch (token) {
        'D-30' => ActivityDurationBand.under30m,
        'D-90' => ActivityDurationBand.under90m,
        'D-HALF' => ActivityDurationBand.halfDay,
        'D-FLEX' => ActivityDurationBand.flexible,
        _ => throw const FormatException('Invalid Zync Now duration'),
      };

  static String _costToken(ActivityCostBand? value) => switch (value) {
        ActivityCostBand.free => 'C-FREE',
        ActivityCostBand.low => 'C-LOW',
        ActivityCostBand.medium => 'C-MED',
        ActivityCostBand.high => 'C-HIGH',
        null => 'C-ANY',
      };

  static ActivityCostBand? _decodeCost(String token) => switch (token) {
        'C-FREE' => ActivityCostBand.free,
        'C-LOW' => ActivityCostBand.low,
        'C-MED' => ActivityCostBand.medium,
        'C-HIGH' => ActivityCostBand.high,
        'C-ANY' => null,
        _ => throw const FormatException('Invalid Zync Now cost'),
      };

  static String _energyToken(ActivityEnergy? value) => switch (value) {
        ActivityEnergy.chill => 'E-CHILL',
        ActivityEnergy.moderate => 'E-MOD',
        ActivityEnergy.active => 'E-ACTIVE',
        null => 'E-ANY',
      };

  static ActivityEnergy? _decodeEnergy(String token) => switch (token) {
        'E-CHILL' => ActivityEnergy.chill,
        'E-MOD' => ActivityEnergy.moderate,
        'E-ACTIVE' => ActivityEnergy.active,
        'E-ANY' => null,
        _ => throw const FormatException('Invalid Zync Now energy'),
      };

  static String _settingToken(ActivitySetting? value) => switch (value) {
        ActivitySetting.indoor => 'S-IN',
        ActivitySetting.outdoor => 'S-OUT',
        ActivitySetting.homePossible => 'S-HOME',
        ActivitySetting.either || null => 'S-EITHER',
      };

  static ActivitySetting _decodeSetting(String token) => switch (token) {
        'S-IN' => ActivitySetting.indoor,
        'S-OUT' => ActivitySetting.outdoor,
        'S-HOME' => ActivitySetting.homePossible,
        'S-EITHER' => ActivitySetting.either,
        _ => throw const FormatException('Invalid Zync Now setting'),
      };

  static String _noveltyToken(ZyncNowNoveltyPreference value) =>
      switch (value) {
        ZyncNowNoveltyPreference.familiar => 'N-FAM',
        ZyncNowNoveltyPreference.mixed => 'N-MIX',
        ZyncNowNoveltyPreference.adventurous => 'N-ADV',
      };

  static ZyncNowNoveltyPreference _decodeNovelty(String token) =>
      switch (token) {
        'N-FAM' => ZyncNowNoveltyPreference.familiar,
        'N-MIX' => ZyncNowNoveltyPreference.mixed,
        'N-ADV' => ZyncNowNoveltyPreference.adventurous,
        _ => throw const FormatException('Invalid Zync Now novelty'),
      };
}
