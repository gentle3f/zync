import 'dart:convert';

import 'package:http/http.dart' as http;

import 'group_zync_protocol.dart';

enum GroupRelayFailureKind {
  unavailable,
  expired,
  full,
  locked,
  unauthorized,
  conflict,
  invalid,
}

class GroupRelayException implements Exception {
  const GroupRelayException(this.kind);
  final GroupRelayFailureKind kind;
}

class GroupRelayParticipantEnvelope {
  const GroupRelayParticipantEnvelope({
    required this.participantId,
    required this.payload,
  });

  final String participantId;
  final String payload;
}

class GroupRelayInputEnvelope {
  const GroupRelayInputEnvelope({
    required this.participantId,
    required this.payload,
  });

  final String participantId;
  final String payload;
}

class GroupRelayHostSnapshot {
  const GroupRelayHostSnapshot({
    required this.participantCount,
    required this.maxParticipants,
    required this.locked,
    required this.participants,
  });

  final int participantCount;
  final int maxParticipants;
  final bool locked;
  final List<GroupRelayParticipantEnvelope> participants;
}

class GroupRelayStatePoll {
  const GroupRelayStatePoll({
    required this.ready,
    required this.revision,
    required this.participantCount,
    required this.maxParticipants,
    required this.locked,
    this.payload,
  });

  final bool ready;
  final int revision;
  final int participantCount;
  final int maxParticipants;
  final bool locked;
  final String? payload;
}

abstract class GroupRelayClient {
  Future<void> createRoom(GroupRoomBootstrap room);

  Future<int> join({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required String payload,
  });

  Future<void> leave({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
  });

  Future<GroupRelayHostSnapshot> takeParticipants(
    GroupRoomBootstrap room,
  );

  Future<void> lockRoom(GroupRoomBootstrap room);

  Future<void> submitInput({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required int roundNumber,
    required String payload,
  });

  Future<List<GroupRelayInputEnvelope>> takeInputs({
    required GroupRoomBootstrap room,
    required int roundNumber,
  });

  Future<void> publishState({
    required GroupRoomBootstrap room,
    required int revision,
    required String payload,
  });

  Future<GroupRelayStatePoll> pollState({
    required GroupJoinQrPayload room,
    required int sinceRevision,
  });

  Future<void> closeRoom(GroupRoomBootstrap room);
}

class HttpGroupRelayClient implements GroupRelayClient {
  HttpGroupRelayClient({
    this.baseUrl = const String.fromEnvironment('ZYNC_API_BASE'),
  });

  final String baseUrl;

  Uri? get _uri {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    final uri = Uri.tryParse('$trimmed/api/v1/group-relay');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  Future<({int status, Map<String, dynamic> body})> _post(
    Map<String, dynamic> body,
  ) async {
    final uri = _uri;
    if (uri == null) {
      throw const GroupRelayException(GroupRelayFailureKind.unavailable);
    }
    try {
      final response = await http
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      return (status: response.statusCode, body: decoded);
    } catch (_) {
      throw const GroupRelayException(GroupRelayFailureKind.unavailable);
    }
  }

  GroupRelayException _mapFailure(
    int status,
    Map<String, dynamic> body,
  ) {
    final error = body['error'] as String? ?? '';
    if (status == 410) {
      return const GroupRelayException(GroupRelayFailureKind.expired);
    }
    if (error == 'group_room_full') {
      return const GroupRelayException(GroupRelayFailureKind.full);
    }
    if (error == 'group_room_locked' ||
        error == 'group_round_not_started') {
      return const GroupRelayException(GroupRelayFailureKind.locked);
    }
    if (status == 403) {
      return const GroupRelayException(GroupRelayFailureKind.unauthorized);
    }
    if (status == 409) {
      return const GroupRelayException(GroupRelayFailureKind.conflict);
    }
    if (status == 400 || status == 413 || status == 502) {
      return const GroupRelayException(GroupRelayFailureKind.invalid);
    }
    return const GroupRelayException(GroupRelayFailureKind.unavailable);
  }

  @override
  Future<void> createRoom(GroupRoomBootstrap room) async {
    final result = await _post({
      'action': 'create',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'hostToken': room.hostToken,
      'joinToken': room.joinToken,
      'expiresAt': room.expiresAt.toUtc().toIso8601String(),
      'maxParticipants': room.maxParticipants,
    });
    if (result.status != 200 && result.status != 201) {
      throw _mapFailure(result.status, result.body);
    }
  }

  @override
  Future<int> join({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required String payload,
  }) async {
    final result = await _post({
      'action': 'join',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'joinToken': room.joinToken,
      'participantId': participantId,
      'participantToken': participantToken,
      'payload': payload,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }
    return (result.body['participantCount'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> leave({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
  }) async {
    final result = await _post({
      'action': 'leave',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'joinToken': room.joinToken,
      'participantId': participantId,
      'participantToken': participantToken,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }
  }

  @override
  Future<GroupRelayHostSnapshot> takeParticipants(
    GroupRoomBootstrap room,
  ) async {
    final result = await _post({
      'action': 'take_participants',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'hostToken': room.hostToken,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }

    final participants =
        ((result.body['participants'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) {
              final map = Map<String, dynamic>.from(item);
              final participantId =
                  (map['participantId'] as String?)?.trim() ?? '';
              final payload = (map['payload'] as String?)?.trim() ?? '';
              if (participantId.isEmpty || payload.isEmpty) {
                throw const GroupRelayException(
                  GroupRelayFailureKind.invalid,
                );
              }
              return GroupRelayParticipantEnvelope(
                participantId: participantId,
                payload: payload,
              );
            })
            .toList(growable: false);

    return GroupRelayHostSnapshot(
      participantCount:
          (result.body['participantCount'] as num?)?.toInt() ?? 0,
      maxParticipants:
          (result.body['maxParticipants'] as num?)?.toInt() ?? 0,
      locked: result.body['locked'] as bool? ?? false,
      participants: participants,
    );
  }

  @override
  Future<void> lockRoom(GroupRoomBootstrap room) async {
    final result = await _post({
      'action': 'lock',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'hostToken': room.hostToken,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }
  }

  @override
  Future<void> submitInput({
    required GroupJoinQrPayload room,
    required String participantId,
    required String participantToken,
    required int roundNumber,
    required String payload,
  }) async {
    final result = await _post({
      'action': 'submit_input',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'joinToken': room.joinToken,
      'participantId': participantId,
      'participantToken': participantToken,
      'roundNumber': roundNumber,
      'payload': payload,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }
  }

  @override
  Future<List<GroupRelayInputEnvelope>> takeInputs({
    required GroupRoomBootstrap room,
    required int roundNumber,
  }) async {
    final result = await _post({
      'action': 'take_inputs',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'hostToken': room.hostToken,
      'roundNumber': roundNumber,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }

    return ((result.body['inputs'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final participantId =
              (map['participantId'] as String?)?.trim() ?? '';
          final payload = (map['payload'] as String?)?.trim() ?? '';
          if (participantId.isEmpty || payload.isEmpty) {
            throw const GroupRelayException(GroupRelayFailureKind.invalid);
          }
          return GroupRelayInputEnvelope(
            participantId: participantId,
            payload: payload,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> publishState({
    required GroupRoomBootstrap room,
    required int revision,
    required String payload,
  }) async {
    final result = await _post({
      'action': 'publish_state',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'hostToken': room.hostToken,
      'revision': revision,
      'payload': payload,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }
  }

  @override
  Future<GroupRelayStatePoll> pollState({
    required GroupJoinQrPayload room,
    required int sinceRevision,
  }) async {
    final result = await _post({
      'action': 'poll_state',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'joinToken': room.joinToken,
      'sinceRevision': sinceRevision,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }

    final status = result.body['status'] as String? ?? '';
    final payload = (result.body['payload'] as String?)?.trim();
    final ready = status == 'ready';
    if (status != 'waiting' && !ready) {
      throw const GroupRelayException(GroupRelayFailureKind.invalid);
    }
    if (ready && (payload == null || payload.isEmpty)) {
      throw const GroupRelayException(GroupRelayFailureKind.invalid);
    }

    return GroupRelayStatePoll(
      ready: ready,
      revision: (result.body['revision'] as num?)?.toInt() ?? -1,
      participantCount:
          (result.body['participantCount'] as num?)?.toInt() ?? 0,
      maxParticipants:
          (result.body['maxParticipants'] as num?)?.toInt() ?? 0,
      locked: result.body['locked'] as bool? ?? false,
      payload: payload,
    );
  }

  @override
  Future<void> closeRoom(GroupRoomBootstrap room) async {
    final result = await _post({
      'action': 'close',
      'protocolVersion': groupZyncProtocolVersion,
      'roomId': room.roomId,
      'hostToken': room.hostToken,
    });
    if (result.status != 200) {
      throw _mapFailure(result.status, result.body);
    }
  }
}
