import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/group_zync_protocol.dart';
import 'package:zync/core/interest_entity_metadata.dart';
import 'package:zync/core/zync_now_constraints_transport.dart';
import 'package:zync/core/zync_now_engine.dart';

void main() {
  const participantId = 'ABCDEFGHIJKLMNOPQRSTUVWX';

  test('private Zync Now constraints round-trip through structured tokens', () {
    const context = ZyncNowPrivateContext(
      constraints: ZyncNowConstraints(
        duration: ActivityDurationBand.under90m,
        maxCost: ActivityCostBand.low,
        energy: ActivityEnergy.moderate,
        setting: ActivitySetting.indoor,
        hardVetoVerbs: {ActivityVerb.challenge},
        hardVetoCategories: {'sports'},
      ),
      novelty: ZyncNowNoveltyPreference.mixed,
    );

    final input = ZyncNowConstraintsTransport.encode(
      roundNumber: 1,
      participantId: participantId,
      context: context,
    );
    expect(input.answerIds, hasLength(7));
    expect(input.answerIds, contains('VV-challenge'));
    expect(input.answerIds, contains('VC-sports'));

    final decoded = ZyncNowConstraintsTransport.decode(input);
    expect(decoded.constraints.duration, ActivityDurationBand.under90m);
    expect(decoded.constraints.maxCost, ActivityCostBand.low);
    expect(decoded.constraints.energy, ActivityEnergy.moderate);
    expect(decoded.constraints.setting, ActivitySetting.indoor);
    expect(decoded.constraints.hardVetoVerbs, {ActivityVerb.challenge});
    expect(decoded.constraints.hardVetoCategories, {'sports'});
    expect(decoded.novelty, ZyncNowNoveltyPreference.mixed);
  });

  test('private constraints survive encrypted Group Zync transport', () async {
    final now = DateTime.now().toUtc();
    final room = GroupRoomBootstrap.generate(
      maxParticipants: 2,
      now: now,
    );
    const context = ZyncNowPrivateContext(
      constraints: ZyncNowConstraints(
        duration: ActivityDurationBand.flexible,
        energy: ActivityEnergy.chill,
        setting: ActivitySetting.either,
        hardVetoVerbs: {ActivityVerb.make},
      ),
      novelty: ZyncNowNoveltyPreference.familiar,
    );

    final input = ZyncNowConstraintsTransport.encode(
      roundNumber: 2,
      participantId: participantId,
      context: context,
    );
    final encrypted = await GroupCrypto.encryptPrivateInput(
      room: room.qr,
      input: input,
    );

    expect(encrypted, isNot(contains('VV-make')));
    expect(encrypted, isNot(contains('N-FAM')));

    final clear = await GroupCrypto.decryptPrivateInput(
      room: room,
      participantId: participantId,
      roundNumber: 2,
      opaquePayload: encrypted,
      now: now.add(const Duration(minutes: 1)),
    );
    final decoded = ZyncNowConstraintsTransport.decode(clear);

    expect(decoded.constraints.duration, ActivityDurationBand.flexible);
    expect(decoded.constraints.energy, ActivityEnergy.chill);
    expect(decoded.constraints.setting, ActivitySetting.either);
    expect(decoded.constraints.hardVetoVerbs, {ActivityVerb.make});
    expect(decoded.novelty, ZyncNowNoveltyPreference.familiar);
  });

  test('constraint codec limits hard veto count to keep payload bounded', () {
    expect(
      () => ZyncNowConstraintsTransport.encode(
        roundNumber: 1,
        participantId: participantId,
        context: const ZyncNowPrivateContext(
          constraints: ZyncNowConstraints(
            hardVetoVerbs: {
              ActivityVerb.make,
              ActivityVerb.challenge,
              ActivityVerb.watch,
              ActivityVerb.listen,
            },
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('malformed duplicate dimension tokens are rejected', () {
    const input = GroupPrivateInput(
      roundNumber: 1,
      participantId: participantId,
      answerIds: [
        'D-30',
        'D-90',
        'C-ANY',
        'E-ANY',
        'S-EITHER',
        'N-MIX',
      ],
    );

    expect(
      () => ZyncNowConstraintsTransport.decode(input),
      throwsA(isA<FormatException>()),
    );
  });

  test('one familiar preference prevents novelty escalation', () {
    final modes = ZyncNowConstraintsTransport.preferredModes(const [
      ZyncNowPrivateContext(
        constraints: ZyncNowConstraints(),
        novelty: ZyncNowNoveltyPreference.adventurous,
      ),
      ZyncNowPrivateContext(
        constraints: ZyncNowConstraints(),
        novelty: ZyncNowNoveltyPreference.familiar,
      ),
      ZyncNowPrivateContext(
        constraints: ZyncNowConstraints(),
        novelty: ZyncNowNoveltyPreference.mixed,
      ),
    ]);

    expect(modes, [ZyncNowMode.familiar]);
  });

  test('all-adventurous group prioritizes new-to-everyone', () {
    final modes = ZyncNowConstraintsTransport.preferredModes(const [
      ZyncNowPrivateContext(
        constraints: ZyncNowConstraints(),
        novelty: ZyncNowNoveltyPreference.adventurous,
      ),
      ZyncNowPrivateContext(
        constraints: ZyncNowConstraints(),
        novelty: ZyncNowNoveltyPreference.adventurous,
      ),
    ]);

    expect(modes.first, ZyncNowMode.newToEveryone);
    expect(modes, contains(ZyncNowMode.surprise));
  });

  test('engineConstraints exposes only participant constraint objects', () {
    final mapped = ZyncNowConstraintsTransport.engineConstraints(const {
      'a': ZyncNowPrivateContext(
        constraints: ZyncNowConstraints(
          maxCost: ActivityCostBand.free,
        ),
      ),
      'b': ZyncNowPrivateContext(
        constraints: ZyncNowConstraints(
          energy: ActivityEnergy.active,
        ),
      ),
    });

    expect(mapped.keys, {'a', 'b'});
    expect(mapped['a']!.maxCost, ActivityCostBand.free);
    expect(mapped['b']!.energy, ActivityEnergy.active);
  });
}
