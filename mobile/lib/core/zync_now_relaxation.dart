import 'interest_entity_metadata.dart';
import 'zync_now_constraints_transport.dart';
import 'zync_now_engine.dart';

enum ZyncNowRelaxationKind {
  time,
  cost,
  energy,
  setting,
  novelty,
}

class ZyncNowRelaxationPlanner {
  const ZyncNowRelaxationPlanner._();

  static List<ZyncNowRelaxationKind> available(
    Iterable<ZyncNowPrivateContext> contexts,
  ) {
    final values = contexts.toList(growable: false);
    final result = <ZyncNowRelaxationKind>[];

    if (values.any((item) {
      final value = item.constraints.duration;
      return value != null && value != ActivityDurationBand.flexible;
    })) {
      result.add(ZyncNowRelaxationKind.time);
    }
    if (values.any((item) => item.constraints.maxCost != null)) {
      result.add(ZyncNowRelaxationKind.cost);
    }
    if (values.any((item) => item.constraints.energy != null)) {
      result.add(ZyncNowRelaxationKind.energy);
    }
    if (values.any((item) {
      final value = item.constraints.setting;
      return value != null && value != ActivitySetting.either;
    })) {
      result.add(ZyncNowRelaxationKind.setting);
    }
    if (values.any(
      (item) => item.novelty != ZyncNowNoveltyPreference.mixed,
    )) {
      result.add(ZyncNowRelaxationKind.novelty);
    }

    return List.unmodifiable(result);
  }

  static Map<String, ZyncNowPrivateContext> apply(
    Map<String, ZyncNowPrivateContext> contexts,
    ZyncNowRelaxationKind kind,
  ) {
    return Map.unmodifiable({
      for (final entry in contexts.entries)
        entry.key: _relax(entry.value, kind),
    });
  }

  static ZyncNowPrivateContext _relax(
    ZyncNowPrivateContext context,
    ZyncNowRelaxationKind kind,
  ) {
    final previous = context.constraints;

    final constraints = ZyncNowConstraints(
      duration: kind == ZyncNowRelaxationKind.time
          ? ActivityDurationBand.flexible
          : previous.duration,
      maxCost: kind == ZyncNowRelaxationKind.cost
          ? null
          : previous.maxCost,
      energy: kind == ZyncNowRelaxationKind.energy
          ? null
          : previous.energy,
      setting: kind == ZyncNowRelaxationKind.setting
          ? ActivitySetting.either
          : previous.setting,
      hardVetoVerbs: Set.unmodifiable(previous.hardVetoVerbs),
      hardVetoCategories: Set.unmodifiable(previous.hardVetoCategories),
    );

    return ZyncNowPrivateContext(
      constraints: constraints,
      novelty: kind == ZyncNowRelaxationKind.novelty
          ? ZyncNowNoveltyPreference.mixed
          : context.novelty,
    );
  }
}
