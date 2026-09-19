import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'models.dart';

const groupZyncProtocolVersion = 1;
const groupZyncRoomLifetime = Duration(minutes: 20);
const _groupMaxClockWindow = Duration(minutes: 30);
const _groupMaxDecodedBytes = 96 * 1024;
const _groupQrPrefix = 'ZG1:';
final _groupRoomIdPattern = RegExp(r'^[A-Za-z0-9_-]{22,64}$');
final _groupCapabilityPattern = RegExp(r'^[A-Za-z0-9_-]{22,64}$');

String _groupBase64UrlNoPad(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');

List<int> _groupBase64UrlDecodeNoPad(String value) {
  final padding = (4 - value.length % 4) % 4;
  return base64Url.decode('$value${'=' * padding}');
}

List<int> _groupRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(
    length,
    (_) => random.nextInt(256),
    growable: false,
  );
}

String generateGroupParticipantId() =>
    _groupBase64UrlNoPad(_groupRandomBytes(18));

String generateGroupParticipantCapability() =>
    _groupBase64UrlNoPad(_groupRandomBytes(24));

class GroupRoomBootstrap {
  const GroupRoomBootstrap({
    required this.roomId,
    required this.hostToken,
    required this.joinToken,
    required this.secretBytes,
    required this.expiresAt,
    required this.maxParticipants,
  });

  final String roomId;
  final String hostToken;
  final String joinToken;
  final List<int> secretBytes;
  final DateTime expiresAt;
  final int maxParticipants;

  factory GroupRoomBootstrap.generate({
    int maxParticipants = 8,
    DateTime? now,
  }) {
    if (maxParticipants < 3 || maxParticipants > 8) {
      throw ArgumentError.value(
        maxParticipants,
        'maxParticipants',
        'Group Zync supports 3 to 8 participants',
      );
    }
    final current = (now ?? DateTime.now()).toUtc();
    return GroupRoomBootstrap(
      roomId: _groupBase64UrlNoPad(_groupRandomBytes(18)),
      hostToken: _groupBase64UrlNoPad(_groupRandomBytes(24)),
      joinToken: _groupBase64UrlNoPad(_groupRandomBytes(24)),
      secretBytes: _groupRandomBytes(32),
      expiresAt: current.add(groupZyncRoomLifetime),
      maxParticipants: maxParticipants,
    );
  }

  GroupJoinQrPayload get qr => GroupJoinQrPayload(
        protocolVersion: groupZyncProtocolVersion,
        roomId: roomId,
        joinToken: joinToken,
        secretBytes: secretBytes,
        expiresAt: expiresAt,
        maxParticipants: maxParticipants,
      );
}

class GroupJoinQrPayload {
  const GroupJoinQrPayload({
    required this.protocolVersion,
    required this.roomId,
    required this.joinToken,
    required this.secretBytes,
    required this.expiresAt,
    required this.maxParticipants,
  });

  final int protocolVersion;
  final String roomId;
  final String joinToken;
  final List<int> secretBytes;
  final DateTime expiresAt;
  final int maxParticipants;

  String encode() {
    final body = jsonEncode({
      'v': protocolVersion,
      'rid': roomId,
      'j': joinToken,
      'k': _groupBase64UrlNoPad(secretBytes),
      'exp': expiresAt.toUtc().millisecondsSinceEpoch,
      'max': maxParticipants,
    });
    final compressed = zlib.encode(utf8.encode(body));
    return '$_groupQrPrefix${_groupBase64UrlNoPad(compressed)}';
  }

  factory GroupJoinQrPayload.decode(
    String raw, {
    DateTime? now,
  }) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(_groupQrPrefix)) {
      throw const FormatException('Not a Group Zync QR');
    }

    try {
      final compressed = _groupBase64UrlDecodeNoPad(
        trimmed.substring(_groupQrPrefix.length),
      );
      final decoded = zlib.decode(compressed);
      if (decoded.length > _groupMaxDecodedBytes) {
        throw const FormatException('Group Zync QR is too large');
      }

      final json =
          Map<String, dynamic>.from(jsonDecode(utf8.decode(decoded)) as Map);
      final version = (json['v'] as num?)?.toInt() ?? 0;
      if (version != groupZyncProtocolVersion) {
        throw const FormatException('Unsupported Group Zync version');
      }

      final roomId = (json['rid'] as String?)?.trim() ?? '';
      final joinToken = (json['j'] as String?)?.trim() ?? '';
      if (!_groupRoomIdPattern.hasMatch(roomId) ||
          !_groupCapabilityPattern.hasMatch(joinToken)) {
        throw const FormatException('Invalid Group Zync room');
      }

      final secretBytes =
          _groupBase64UrlDecodeNoPad((json['k'] as String?) ?? '');
      if (secretBytes.length != 32) {
        throw const FormatException('Invalid Group Zync secret');
      }

      final maxParticipants = (json['max'] as num?)?.toInt() ?? 0;
      if (maxParticipants < 3 || maxParticipants > 8) {
        throw const FormatException('Invalid Group Zync capacity');
      }

      final expiryMs = (json['exp'] as num?)?.toInt();
      if (expiryMs == null) {
        throw const FormatException('Invalid Group Zync expiry');
      }
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(expiryMs, isUtc: true);
      final current = (now ?? DateTime.now()).toUtc();
      final remaining = expiresAt.difference(current);
      if (remaining <= Duration.zero || remaining > _groupMaxClockWindow) {
        throw const FormatException('Expired Group Zync room');
      }

      return GroupJoinQrPayload(
        protocolVersion: version,
        roomId: roomId,
        joinToken: joinToken,
        secretBytes: secretBytes,
        expiresAt: expiresAt,
        maxParticipants: maxParticipants,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid Group Zync QR');
    }
  }
}

class GroupParticipantProfile {
  const GroupParticipantProfile({
    required this.participantId,
    required this.language,
    required this.interests,
    this.nickname = '',
  });

  final String participantId;
  final String nickname;
  final String language;
  final List<SelectedInterest> interests;

  factory GroupParticipantProfile.fromLocalProfile({
    required String participantId,
    required LocalProfile profile,
    bool shareNickname = false,
    bool includeCustomInterests = false,
  }) =>
      GroupParticipantProfile(
        participantId: participantId,
        nickname: shareNickname ? profile.nickname.trim() : '',
        language: profile.language,
        interests: profile.interests
            .where(
              (item) =>
                  includeCustomInterests || !item.id.startsWith('custom.'),
            )
            .map(
              (item) => SelectedInterest(
                id: item.id,
                strength: item.strength,
              ),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toCompactJson() => {
        'pid': participantId,
        if (nickname.isNotEmpty) 'name': nickname,
        'lang': language,
        'i': interests
            .map((item) => <dynamic>[item.id, item.strength.wireValue])
            .toList(growable: false),
      };

  factory GroupParticipantProfile.fromCompactJson(
    Map<String, dynamic> json,
  ) {
    final participantId = (json['pid'] as String?)?.trim() ?? '';
    if (!_groupRoomIdPattern.hasMatch(participantId)) {
      throw const FormatException('Invalid Group Zync participant');
    }

    final interests = ((json['i'] as List?) ?? const []).map((entry) {
      final pair = List<dynamic>.from(entry as List);
      if (pair.length < 2) {
        throw const FormatException('Invalid Group Zync interest');
      }
      final id = (pair[0] as String?)?.trim() ?? '';
      if (id.isEmpty || id.startsWith('custom.')) {
        throw const FormatException('Invalid Group Zync interest');
      }
      return SelectedInterest(
        id: id,
        strength: InterestStrength.fromWire((pair[1] as num).toInt()),
      );
    }).toList(growable: false);

    return GroupParticipantProfile(
      participantId: participantId,
      nickname: ((json['name'] as String?) ?? '').trim(),
      language: ((json['lang'] as String?) ?? 'en').trim(),
      interests: interests,
    );
  }
}


class GroupPrivateInput {
  const GroupPrivateInput({
    required this.roundNumber,
    required this.participantId,
    required this.answerIds,
  });

  final int roundNumber;
  final String participantId;

  /// Structured option IDs only. Free-text answers are deliberately excluded
  /// from the first Group Zync protocol to reduce accidental sensitive sharing.
  final List<String> answerIds;

  Map<String, dynamic> toJson() => {
        'round': roundNumber,
        'pid': participantId,
        'answers': answerIds,
      };

  factory GroupPrivateInput.fromJson(Map<String, dynamic> json) {
    final roundNumber = (json['round'] as num?)?.toInt() ?? 0;
    final participantId = (json['pid'] as String?)?.trim() ?? '';
    final answers = ((json['answers'] as List?) ?? const [])
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item.length <= 96)
        .take(8)
        .toList(growable: false);

    if (roundNumber < 1 ||
        roundNumber > 99 ||
        !_groupRoomIdPattern.hasMatch(participantId) ||
        answers.isEmpty) {
      throw const FormatException('Invalid Group Zync private input');
    }

    return GroupPrivateInput(
      roundNumber: roundNumber,
      participantId: participantId,
      answerIds: answers,
    );
  }
}

enum GroupRoomPhase {
  lobby,
  ready,
  roundPrepared,
  inputOpen,
  inputLocked,
  reveal,
  reaction,
  complete,
  zyncNowOptional,
  zyncNowInputOpen,
  zyncNowInputLocked,
  zyncNowResult,
  ended,
}


class GroupBoundedOption {
  const GroupBoundedOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
      };

  factory GroupBoundedOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final label = (json['label'] as String?)?.trim() ?? '';
    if (!_groupRoomIdPattern.hasMatch(id) || label.isEmpty || label.length > 80) {
      throw const FormatException('Invalid Group Zync bounded option');
    }
    return GroupBoundedOption(id: id, label: label);
  }
}

class GroupBoundedState {
  const GroupBoundedState({
    required this.revision,
    required this.phase,
    required this.participantCount,
    required this.readyCount,
    required this.roundNumber,
    this.mechanicType = '',
    this.title = '',
    this.prompt = '',
    this.inputKind = '',
    this.requiredSelections = 0,
    this.options = const [],
    this.followUp = '',
    this.resultOptionId,
    this.hiddenSubsetSize,
    this.revealInterestId,
    this.revealParticipantIds = const [],
  });

  final int revision;
  final GroupRoomPhase phase;
  final int participantCount;
  final int readyCount;
  final int roundNumber;
  final String mechanicType;
  final String title;
  final String prompt;
  final String inputKind;
  final int requiredSelections;
  final List<GroupBoundedOption> options;
  final String followUp;
  final String? resultOptionId;
  final int? hiddenSubsetSize;
  final String? revealInterestId;
  final List<String> revealParticipantIds;

  Map<String, dynamic> toJson() => {
        'rev': revision,
        'phase': phase.name,
        'count': participantCount,
        'ready': readyCount,
        'round': roundNumber,
        if (mechanicType.isNotEmpty) 'mechanic': mechanicType,
        if (title.isNotEmpty) 'title': title,
        if (prompt.isNotEmpty) 'prompt': prompt,
        if (inputKind.isNotEmpty) 'input': inputKind,
        if (requiredSelections > 0) 'required': requiredSelections,
        if (options.isNotEmpty)
          'options': options.map((item) => item.toJson()).toList(growable: false),
        if (followUp.isNotEmpty) 'followUp': followUp,
        if (resultOptionId != null) 'resultOption': resultOptionId,
        if (hiddenSubsetSize != null) 'subset': hiddenSubsetSize,
        if (revealInterestId != null) 'interest': revealInterestId,
        if (revealParticipantIds.isNotEmpty) 'participants': revealParticipantIds,
      };

  factory GroupBoundedState.fromJson(Map<String, dynamic> json) {
    final rawPhase = (json['phase'] as String?) ?? '';
    final phase = GroupRoomPhase.values.firstWhere(
      (item) => item.name == rawPhase,
      orElse: () => GroupRoomPhase.lobby,
    );

    return GroupBoundedState(
      revision: (json['rev'] as num?)?.toInt() ?? 0,
      phase: phase,
      participantCount: (json['count'] as num?)?.toInt() ?? 0,
      readyCount: (json['ready'] as num?)?.toInt() ?? 0,
      roundNumber: (json['round'] as num?)?.toInt() ?? 0,
      mechanicType: (json['mechanic'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      prompt: (json['prompt'] as String?) ?? '',
      inputKind: (json['input'] as String?) ?? '',
      requiredSelections: (json['required'] as num?)?.toInt() ?? 0,
      options: ((json['options'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => GroupBoundedOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      followUp: (json['followUp'] as String?) ?? '',
      resultOptionId: json['resultOption'] as String?,
      hiddenSubsetSize: (json['subset'] as num?)?.toInt(),
      revealInterestId: json['interest'] as String?,
      revealParticipantIds: ((json['participants'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

class GroupCrypto {
  const GroupCrypto._();

  static final _algorithm = AesGcm.with256bits();

  static List<int> _joinAad(
    String roomId,
    String participantId,
  ) =>
      utf8.encode(
        'zync-group-v1:$roomId:participant:$participantId',
      );

  static List<int> _stateAad(
    String roomId,
    int revision,
  ) =>
      utf8.encode('zync-group-v1:$roomId:state:$revision');

  static List<int> _inputAad(
    String roomId,
    String participantId,
    int roundNumber,
  ) =>
      utf8.encode(
        'zync-group-v1:$roomId:input:$roundNumber:$participantId',
      );

  static Future<String> encryptParticipant({
    required GroupJoinQrPayload room,
    required GroupParticipantProfile participant,
  }) async {
    if (!DateTime.now().toUtc().isBefore(room.expiresAt)) {
      throw const FormatException('Group Zync room expired');
    }

    final clear = utf8.encode(jsonEncode({
      'v': groupZyncProtocolVersion,
      'rid': room.roomId,
      'exp': room.expiresAt.toUtc().millisecondsSinceEpoch,
      'p': participant.toCompactJson(),
    }));
    if (clear.length > _groupMaxDecodedBytes) {
      throw const FormatException('Group participant payload is too large');
    }

    final box = await _algorithm.encrypt(
      clear,
      secretKey: SecretKey(room.secretBytes),
      aad: _joinAad(room.roomId, participant.participantId),
    );
    return _encodeEnvelope(box);
  }

  static Future<GroupParticipantProfile> decryptParticipant({
    required GroupRoomBootstrap room,
    required String participantId,
    required String opaquePayload,
    DateTime? now,
  }) async {
    try {
      final clear = await _decryptEnvelope(
        opaquePayload: opaquePayload,
        secretBytes: room.secretBytes,
        aad: _joinAad(room.roomId, participantId),
      );
      final json =
          Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
      if ((json['v'] as num?)?.toInt() != groupZyncProtocolVersion ||
          json['rid'] != room.roomId ||
          (json['exp'] as num?)?.toInt() !=
              room.expiresAt.toUtc().millisecondsSinceEpoch) {
        throw const FormatException('Group participant session mismatch');
      }
      final current = (now ?? DateTime.now()).toUtc();
      if (!current.isBefore(room.expiresAt)) {
        throw const FormatException('Group participant response expired');
      }

      final profile = GroupParticipantProfile.fromCompactJson(
        Map<String, dynamic>.from(json['p'] as Map),
      );
      if (profile.participantId != participantId) {
        throw const FormatException('Group participant identity mismatch');
      }
      return profile;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid encrypted Group Zync participant');
    }
  }


  static Future<String> encryptPrivateInput({
    required GroupJoinQrPayload room,
    required GroupPrivateInput input,
  }) async {
    if (input.roundNumber < 1 ||
        input.roundNumber > 99 ||
        input.answerIds.isEmpty) {
      throw const FormatException('Invalid Group Zync private input');
    }
    final clear = utf8.encode(jsonEncode({
      'v': groupZyncProtocolVersion,
      'rid': room.roomId,
      'exp': room.expiresAt.toUtc().millisecondsSinceEpoch,
      'input': input.toJson(),
    }));
    if (clear.length > _groupMaxDecodedBytes) {
      throw const FormatException('Group private input is too large');
    }
    final box = await _algorithm.encrypt(
      clear,
      secretKey: SecretKey(room.secretBytes),
      aad: _inputAad(
        room.roomId,
        input.participantId,
        input.roundNumber,
      ),
    );
    return _encodeEnvelope(box);
  }

  static Future<GroupPrivateInput> decryptPrivateInput({
    required GroupRoomBootstrap room,
    required String participantId,
    required int roundNumber,
    required String opaquePayload,
    DateTime? now,
  }) async {
    try {
      final clear = await _decryptEnvelope(
        opaquePayload: opaquePayload,
        secretBytes: room.secretBytes,
        aad: _inputAad(room.roomId, participantId, roundNumber),
      );
      final json =
          Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
      if ((json['v'] as num?)?.toInt() != groupZyncProtocolVersion ||
          json['rid'] != room.roomId ||
          (json['exp'] as num?)?.toInt() !=
              room.expiresAt.toUtc().millisecondsSinceEpoch) {
        throw const FormatException('Group private input session mismatch');
      }
      final current = (now ?? DateTime.now()).toUtc();
      if (!current.isBefore(room.expiresAt)) {
        throw const FormatException('Group private input expired');
      }
      final input = GroupPrivateInput.fromJson(
        Map<String, dynamic>.from(json['input'] as Map),
      );
      if (input.participantId != participantId ||
          input.roundNumber != roundNumber) {
        throw const FormatException('Group private input identity mismatch');
      }
      return input;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid encrypted Group Zync input');
    }
  }

  static Future<String> encryptBoundedState({
    required GroupRoomBootstrap room,
    required GroupBoundedState state,
  }) async {
    final clear = utf8.encode(jsonEncode({
      'v': groupZyncProtocolVersion,
      'rid': room.roomId,
      'exp': room.expiresAt.toUtc().millisecondsSinceEpoch,
      's': state.toJson(),
    }));
    if (clear.length > _groupMaxDecodedBytes) {
      throw const FormatException('Group state is too large');
    }

    final box = await _algorithm.encrypt(
      clear,
      secretKey: SecretKey(room.secretBytes),
      aad: _stateAad(room.roomId, state.revision),
    );
    return _encodeEnvelope(box);
  }

  static Future<GroupBoundedState> decryptBoundedState({
    required GroupJoinQrPayload room,
    required int revision,
    required String opaquePayload,
    DateTime? now,
  }) async {
    try {
      final clear = await _decryptEnvelope(
        opaquePayload: opaquePayload,
        secretBytes: room.secretBytes,
        aad: _stateAad(room.roomId, revision),
      );
      final json =
          Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
      if ((json['v'] as num?)?.toInt() != groupZyncProtocolVersion ||
          json['rid'] != room.roomId ||
          (json['exp'] as num?)?.toInt() !=
              room.expiresAt.toUtc().millisecondsSinceEpoch) {
        throw const FormatException('Group state session mismatch');
      }
      final current = (now ?? DateTime.now()).toUtc();
      if (!current.isBefore(room.expiresAt)) {
        throw const FormatException('Group state expired');
      }

      final state = GroupBoundedState.fromJson(
        Map<String, dynamic>.from(json['s'] as Map),
      );
      if (state.revision != revision) {
        throw const FormatException('Group state revision mismatch');
      }
      return state;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid encrypted Group Zync state');
    }
  }

  static String _encodeEnvelope(SecretBox box) {
    final envelope = utf8.encode(jsonEncode({
      'n': _groupBase64UrlNoPad(box.nonce),
      'c': _groupBase64UrlNoPad(box.cipherText),
      'm': _groupBase64UrlNoPad(box.mac.bytes),
    }));
    return _groupBase64UrlNoPad(envelope);
  }

  static Future<List<int>> _decryptEnvelope({
    required String opaquePayload,
    required List<int> secretBytes,
    required List<int> aad,
  }) async {
    final envelopeBytes = _groupBase64UrlDecodeNoPad(opaquePayload);
    if (envelopeBytes.length > _groupMaxDecodedBytes) {
      throw const FormatException('Group envelope is too large');
    }
    final envelope = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(envelopeBytes)) as Map,
    );
    final nonce =
        _groupBase64UrlDecodeNoPad((envelope['n'] as String?) ?? '');
    final cipherText =
        _groupBase64UrlDecodeNoPad((envelope['c'] as String?) ?? '');
    final mac = _groupBase64UrlDecodeNoPad((envelope['m'] as String?) ?? '');

    final clear = await _algorithm.decrypt(
      SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(mac),
      ),
      secretKey: SecretKey(secretBytes),
      aad: aad,
    );
    if (clear.length > _groupMaxDecodedBytes) {
      throw const FormatException('Group decrypted payload is too large');
    }
    return clear;
  }
}
