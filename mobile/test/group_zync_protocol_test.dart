import 'package:flutter_test/flutter_test.dart';
import 'package:zync/core/group_zync_protocol.dart';
import 'package:zync/core/models.dart';

const _host = LocalProfile(
  localId: 'permanent-local-id-must-not-leak',
  nickname: 'Host Person',
  language: 'zh-Hant',
  interests: [
    SelectedInterest(
      id: 'sports.badminton',
      strength: InterestStrength.love,
    ),
    SelectedInterest(
      id: 'custom.secret_interest',
      strength: InterestStrength.like,
      customLabel: 'Private custom thing',
    ),
  ],
  socialLinks: [
    SocialLink(
      platform: SocialPlatform.instagram,
      value: '@private_handle',
      shareAfterZync: true,
    ),
  ],
);

void main() {
  test('Group QR carries join capability but never host admin capability', () {
    final now = DateTime.utc(2026, 9, 19, 10);
    final room = GroupRoomBootstrap.generate(
      maxParticipants: 6,
      now: now,
    );
    final encoded = room.qr.encode();

    expect(encoded, startsWith('ZG1:'));
    expect(encoded, isNot(contains(room.hostToken)));

    final decoded = GroupJoinQrPayload.decode(
      encoded,
      now: now.add(const Duration(minutes: 1)),
    );
    expect(decoded.roomId, room.roomId);
    expect(decoded.joinToken, room.joinToken);
    expect(decoded.secretBytes, room.secretBytes);
    expect(decoded.maxParticipants, 6);
  });

  test('Group limited profile excludes permanent identity social links and custom interests',
      () {
    const participantId = 'ABCDEFGHIJKLMNOPQRSTUVWX';
    final payload = GroupParticipantProfile.fromLocalProfile(
      participantId: participantId,
      profile: _host,
      shareNickname: false,
    );
    final json = payload.toCompactJson().toString();

    expect(payload.participantId, participantId);
    expect(payload.nickname, isEmpty);
    expect(payload.interests.map((item) => item.id), ['sports.badminton']);
    expect(json, isNot(contains(_host.localId)));
    expect(json, isNot(contains('private_handle')));
    expect(json, isNot(contains('secret_interest')));
  });

  test('participant submission round-trips only through room crypto', () async {
    final now = DateTime.now().toUtc();
    final room = GroupRoomBootstrap.generate(now: now);
    final join = room.qr;
    const participantId = 'ZYXWVUTSRQPONMLKJIHGFEDC';
    final participant = GroupParticipantProfile.fromLocalProfile(
      participantId: participantId,
      profile: _host,
      shareNickname: true,
    );

    final encrypted = await GroupCrypto.encryptParticipant(
      room: join,
      participant: participant,
    );
    expect(encrypted, isNot(contains('sports.badminton')));
    expect(encrypted, isNot(contains(_host.nickname)));

    final decoded = await GroupCrypto.decryptParticipant(
      room: room,
      participantId: participantId,
      opaquePayload: encrypted,
      now: now.add(const Duration(minutes: 1)),
    );

    expect(decoded.participantId, participantId);
    expect(decoded.nickname, _host.nickname);
    expect(decoded.interests.single.id, 'sports.badminton');
  });

  test('participant ciphertext cannot be replayed under another participant ID',
      () async {
    final now = DateTime.now().toUtc();
    final room = GroupRoomBootstrap.generate(now: now);
    const participantId = 'ABCDEFGHIJKLMNOPQRSTUVWX';
    final participant = GroupParticipantProfile.fromLocalProfile(
      participantId: participantId,
      profile: _host,
    );

    final encrypted = await GroupCrypto.encryptParticipant(
      room: room.qr,
      participant: participant,
    );

    expect(
      () => GroupCrypto.decryptParticipant(
        room: room,
        participantId: 'ZYXWVUTSRQPONMLKJIHGFEDC',
        opaquePayload: encrypted,
        now: now.add(const Duration(minutes: 1)),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('private group input is encrypted and bound to participant plus round',
      () async {
    final now = DateTime.now().toUtc();
    final room = GroupRoomBootstrap.generate(now: now);
    const participantId = 'ABCDEFGHIJKLMNOPQRSTUVWX';
    const input = GroupPrivateInput(
      roundNumber: 2,
      participantId: participantId,
      answerIds: ['choice.b', 'rank.2'],
    );

    final encrypted = await GroupCrypto.encryptPrivateInput(
      room: room.qr,
      input: input,
    );
    expect(encrypted, isNot(contains('choice.b')));

    final decoded = await GroupCrypto.decryptPrivateInput(
      room: room,
      participantId: participantId,
      roundNumber: 2,
      opaquePayload: encrypted,
      now: now.add(const Duration(minutes: 1)),
    );
    expect(decoded.answerIds, ['choice.b', 'rank.2']);

    await expectLater(
      GroupCrypto.decryptPrivateInput(
        room: room,
        participantId: participantId,
        roundNumber: 3,
        opaquePayload: encrypted,
        now: now.add(const Duration(minutes: 1)),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('bounded group state is encrypted and revision-bound', () async {
    final now = DateTime.now().toUtc();
    final room = GroupRoomBootstrap.generate(now: now);
    const state = GroupBoundedState(
      revision: 4,
      phase: GroupRoomPhase.reveal,
      participantCount: 5,
      readyCount: 5,
      roundNumber: 2,
      mechanicType: 'hidden_cluster',
      prompt: 'Who shares this?',
      hiddenSubsetSize: 3,
      revealInterestId: 'sports.badminton',
      revealParticipantIds: [
        'ABCDEFGHIJKLMNOPQRSTUVWX',
        'ZYXWVUTSRQPONMLKJIHGFEDC',
      ],
    );

    final encrypted = await GroupCrypto.encryptBoundedState(
      room: room,
      state: state,
    );
    expect(encrypted, isNot(contains('sports.badminton')));

    final decoded = await GroupCrypto.decryptBoundedState(
      room: room.qr,
      revision: 4,
      opaquePayload: encrypted,
      now: now.add(const Duration(minutes: 1)),
    );
    expect(decoded.phase, GroupRoomPhase.reveal);
    expect(decoded.revision, 4);
    expect(decoded.revealInterestId, 'sports.badminton');

    expect(
      () => GroupCrypto.decryptBoundedState(
        room: room.qr,
        revision: 5,
        opaquePayload: encrypted,
        now: now.add(const Duration(minutes: 1)),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
