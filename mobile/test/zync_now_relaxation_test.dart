import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/interest_entity_metadata.dart';
import 'package:zync/core/zync_now_constraints_transport.dart';
import 'package:zync/core/zync_now_engine.dart';
import 'package:zync/core/zync_now_relaxation.dart';

void main() {
  const original = ZyncNowPrivateContext(
    constraints: ZyncNowConstraints(
      duration: ActivityDurationBand.under30m,
      maxCost: ActivityCostBand.free,
      energy: ActivityEnergy.chill,
      setting: ActivitySetting.indoor,
      hardVetoVerbs: {
        ActivityVerb.make,
        ActivityVerb.challenge,
      },
      hardVetoCategories: {'sports'},
    ),
    novelty: ZyncNowNoveltyPreference.familiar,
  );

  test('planner exposes only soft preferences that can actually broaden', () {
    final available = ZyncNowRelaxationPlanner.available(const [original]);

    expect(
      available,
      containsAll([
        ZyncNowRelaxationKind.time,
        ZyncNowRelaxationKind.cost,
        ZyncNowRelaxationKind.energy,
        ZyncNowRelaxationKind.setting,
        ZyncNowRelaxationKind.novelty,
      ]),
    );
  });

  test('time relaxation preserves every hard veto', () {
    final relaxed = ZyncNowRelaxationPlanner.apply(
      const {'a': original},
      ZyncNowRelaxationKind.time,
    )['a']!;

    expect(
      relaxed.constraints.duration,
      ActivityDurationBand.flexible,
    );
    expect(relaxed.constraints.maxCost, ActivityCostBand.free);
    expect(relaxed.constraints.energy, ActivityEnergy.chill);
    expect(relaxed.constraints.setting, ActivitySetting.indoor);
    expect(
      relaxed.constraints.hardVetoVerbs,
      original.constraints.hardVetoVerbs,
    );
    expect(
      relaxed.constraints.hardVetoCategories,
      original.constraints.hardVetoCategories,
    );
    expect(relaxed.novelty, ZyncNowNoveltyPreference.familiar);
  });

  test('cost relaxation removes only the budget ceiling', () {
    final relaxed = ZyncNowRelaxationPlanner.apply(
      const {'a': original},
      ZyncNowRelaxationKind.cost,
    )['a']!;

    expect(relaxed.constraints.maxCost, isNull);
    expect(
      relaxed.constraints.duration,
      ActivityDurationBand.under30m,
    );
    expect(
      relaxed.constraints.hardVetoCategories,
      {'sports'},
    );
  });

  test('setting relaxation becomes either without touching no-sports', () {
    final relaxed = ZyncNowRelaxationPlanner.apply(
      const {'a': original},
      ZyncNowRelaxationKind.setting,
    )['a']!;

    expect(relaxed.constraints.setting, ActivitySetting.either);
    expect(
      relaxed.constraints.hardVetoCategories,
      {'sports'},
    );
  });

  test('novelty relaxation broadens to mixed but preserves hard vetoes', () {
    final relaxed = ZyncNowRelaxationPlanner.apply(
      const {'a': original},
      ZyncNowRelaxationKind.novelty,
    )['a']!;

    expect(relaxed.novelty, ZyncNowNoveltyPreference.mixed);
    expect(
      relaxed.constraints.hardVetoVerbs,
      {ActivityVerb.make, ActivityVerb.challenge},
    );
    expect(
      relaxed.constraints.hardVetoCategories,
      {'sports'},
    );
  });

  test('already broad defaults offer no meaningless relaxation', () {
    const broad = ZyncNowPrivateContext(
      constraints: ZyncNowConstraints(
        duration: ActivityDurationBand.flexible,
        setting: ActivitySetting.either,
      ),
      novelty: ZyncNowNoveltyPreference.mixed,
    );

    expect(
      ZyncNowRelaxationPlanner.available(const [broad]),
      isEmpty,
    );
  });
}
