import 'dart:convert';

import 'secure_key_value_store.dart';

class PendingCardverseProofTicket {
  const PendingCardverseProofTicket({
    required this.ticket,
    required this.clientEventId,
    required this.capturedAt,
    required this.timezoneOffsetMinutes,
  });

  final String ticket;
  final String clientEventId;
  final DateTime capturedAt;
  final int timezoneOffsetMinutes;

  Map<String, dynamic> toJson() => {
        'ticket': ticket,
        'clientEventId': clientEventId,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
      };

  factory PendingCardverseProofTicket.fromJson(Map<String, dynamic> json) {
    final ticket = (json['ticket'] as String?)?.trim() ?? '';
    final eventId = (json['clientEventId'] as String?)?.trim() ?? '';
    final capturedAt = DateTime.tryParse((json['capturedAt'] as String?) ?? '');
    final timezoneOffsetMinutes =
        (json['timezoneOffsetMinutes'] as num?)?.toInt();
    if (!ticket.startsWith('ZP1.') ||
        ticket.length > 4096 ||
        eventId.isEmpty ||
        eventId.length > 160 ||
        capturedAt == null ||
        timezoneOffsetMinutes == null ||
        timezoneOffsetMinutes < -840 ||
        timezoneOffsetMinutes > 840) {
      throw const FormatException('Invalid pending Cardverse proof ticket');
    }
    return PendingCardverseProofTicket(
      ticket: ticket,
      clientEventId: eventId,
      capturedAt: capturedAt.toUtc(),
      timezoneOffsetMinutes: timezoneOffsetMinutes,
    );
  }
}

class PendingRelayProofCapability {
  const PendingRelayProofCapability({
    required this.sessionId,
    required this.proofCapability,
    required this.clientEventId,
    required this.capturedAt,
    required this.timezoneOffsetMinutes,
  });

  final String sessionId;
  final String proofCapability;
  final String clientEventId;
  final DateTime capturedAt;
  final int timezoneOffsetMinutes;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'proofCapability': proofCapability,
        'clientEventId': clientEventId,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
      };

  factory PendingRelayProofCapability.fromJson(Map<String, dynamic> json) {
    final sessionId = (json['sessionId'] as String?)?.trim() ?? '';
    final capability = (json['proofCapability'] as String?)?.trim() ?? '';
    final eventId = (json['clientEventId'] as String?)?.trim() ?? '';
    final capturedAt = DateTime.tryParse((json['capturedAt'] as String?) ?? '');
    final timezoneOffsetMinutes =
        (json['timezoneOffsetMinutes'] as num?)?.toInt();
    if (!RegExp(r'^[A-Za-z0-9_-]{22,64}$').hasMatch(sessionId) ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(capability) ||
        eventId.isEmpty ||
        eventId.length > 160 ||
        capturedAt == null ||
        timezoneOffsetMinutes == null ||
        timezoneOffsetMinutes < -840 ||
        timezoneOffsetMinutes > 840) {
      throw const FormatException('Invalid pending relay proof capability');
    }
    return PendingRelayProofCapability(
      sessionId: sessionId,
      proofCapability: capability,
      clientEventId: eventId,
      capturedAt: capturedAt.toUtc(),
      timezoneOffsetMinutes: timezoneOffsetMinutes,
    );
  }
}

class CardverseProofCache {
  CardverseProofCache({
    SecureKeyValueStore? storage,
  }) : _storage = storage ?? FlutterSecureKeyValueStore();

  static const _ticketKey = 'zync.cardverse.proof_tickets.v1';
  static const _capabilityKey = 'zync.cardverse.proof_capabilities.v1';
  static const _maxItems = 100;
  static const _capabilityLifetime = Duration(minutes: 10);
  static const _ticketLocalLifetime = Duration(days: 90);

  final SecureKeyValueStore _storage;

  Future<List<PendingCardverseProofTicket>> loadTickets({
    DateTime? now,
  }) async {
    final current = (now ?? DateTime.now()).toUtc();
    final items = _decodeList(
      await _storage.read(_ticketKey),
      PendingCardverseProofTicket.fromJson,
    ).where(
      (item) => current.difference(item.capturedAt) <= _ticketLocalLifetime,
    ).toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    await _writeList(
      _ticketKey,
      items.map((item) => item.toJson()).toList(),
    );
    return List.unmodifiable(items);
  }

  Future<List<PendingRelayProofCapability>> loadCapabilities({
    DateTime? now,
  }) async {
    final current = (now ?? DateTime.now()).toUtc();
    final items = _decodeList(
      await _storage.read(_capabilityKey),
      PendingRelayProofCapability.fromJson,
    ).where(
      (item) => current.difference(item.capturedAt) <= _capabilityLifetime,
    ).toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    await _writeList(
      _capabilityKey,
      items.map((item) => item.toJson()).toList(),
    );
    return List.unmodifiable(items);
  }

  Future<void> saveTicket(PendingCardverseProofTicket ticket) async {
    final current = (await loadTickets()).toList();
    current.removeWhere(
      (item) =>
          item.clientEventId == ticket.clientEventId ||
          item.ticket == ticket.ticket,
    );
    current.add(ticket);
    final bounded = current.length <= _maxItems
        ? current
        : current.sublist(current.length - _maxItems);
    await _writeList(
      _ticketKey,
      bounded.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> removeTicket({
    required String ticket,
    required String clientEventId,
  }) async {
    final current = (await loadTickets()).toList();
    current.removeWhere(
      (item) =>
          item.ticket == ticket &&
          item.clientEventId == clientEventId,
    );
    await _writeList(
      _ticketKey,
      current.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> saveCapability(
    PendingRelayProofCapability capability,
  ) async {
    final current = (await loadCapabilities()).toList();
    current.removeWhere(
      (item) =>
          item.clientEventId == capability.clientEventId ||
          item.sessionId == capability.sessionId,
    );
    current.add(capability);
    final bounded = current.length <= _maxItems
        ? current
        : current.sublist(current.length - _maxItems);
    await _writeList(
      _capabilityKey,
      bounded.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> removeCapability({
    required String sessionId,
    required String clientEventId,
  }) async {
    final current = (await loadCapabilities()).toList();
    current.removeWhere(
      (item) =>
          item.sessionId == sessionId &&
          item.clientEventId == clientEventId,
    );
    await _writeList(
      _capabilityKey,
      current.map((item) => item.toJson()).toList(),
    );
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) decoder,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final source = jsonDecode(raw) as List;
      final result = <T>[];
      for (final item in source.whereType<Map>()) {
        try {
          result.add(decoder(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Drop malformed secure-cache entries instead of poisoning the queue.
        }
      }
      return result;
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _writeList(
    String key,
    List<Map<String, dynamic>> items,
  ) =>
      _storage.write(key, jsonEncode(items));
}
