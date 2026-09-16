import 'dart:convert';
import 'dart:io';

enum InterestStrength {
  wantToTry(0),
  like(1),
  love(2);

  const InterestStrength(this.wireValue);
  final int wireValue;

  static InterestStrength fromWire(int value) => InterestStrength.values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => InterestStrength.like,
      );
}

class InterestDefinition {
  const InterestDefinition({
    required this.id,
    required this.category,
    required this.labels,
    this.aliases = const [],
  });

  final String id;
  final String category;
  final Map<String, String> labels;
  final List<String> aliases;

  String labelFor(String locale) {
    final normalized = locale.replaceAll('_', '-');
    return labels[normalized] ?? labels[normalized.split('-').first] ?? labels['en'] ?? id;
  }
}

class SelectedInterest {
  const SelectedInterest({
    required this.id,
    required this.strength,
    this.customLabel,
    this.customCategory,
  });

  final String id;
  final InterestStrength strength;
  final String? customLabel;
  final String? customCategory;

  SelectedInterest copyWith({
    InterestStrength? strength,
    String? customLabel,
    String? customCategory,
  }) =>
      SelectedInterest(
        id: id,
        strength: strength ?? this.strength,
        customLabel: customLabel ?? this.customLabel,
        customCategory: customCategory ?? this.customCategory,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'strength': strength.wireValue,
        if (customLabel != null && customLabel!.isNotEmpty) 'label': customLabel,
        if (customCategory != null && customCategory!.isNotEmpty) 'category': customCategory,
      };

  factory SelectedInterest.fromJson(Map<String, dynamic> json) => SelectedInterest(
        id: json['id'] as String,
        strength: InterestStrength.fromWire((json['strength'] as num?)?.toInt() ?? 1),
        customLabel: json['label'] as String?,
        customCategory: json['category'] as String?,
      );
}

class LocalProfile {
  const LocalProfile({
    required this.localId,
    required this.nickname,
    required this.language,
    required this.interests,
  });

  final String localId;
  final String nickname;
  final String language;
  final List<SelectedInterest> interests;

  LocalProfile copyWith({
    String? localId,
    String? nickname,
    String? language,
    List<SelectedInterest>? interests,
  }) =>
      LocalProfile(
        localId: localId ?? this.localId,
        nickname: nickname ?? this.nickname,
        language: language ?? this.language,
        interests: interests ?? this.interests,
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'nickname': nickname,
        'language': language,
        'interests': interests.map((item) => item.toJson()).toList(),
      };

  factory LocalProfile.fromJson(Map<String, dynamic> json) => LocalProfile(
        localId: json['localId'] as String,
        nickname: (json['nickname'] as String?) ?? '',
        language: (json['language'] as String?) ?? 'en',
        interests: ((json['interests'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => SelectedInterest.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );

  String encode() => jsonEncode(toJson());
  static LocalProfile decode(String value) => LocalProfile.fromJson(jsonDecode(value));
}

class QrProfilePayload {
  const QrProfilePayload({
    required this.version,
    required this.localId,
    required this.nickname,
    required this.language,
    required this.interests,
  });

  static const currentVersion = 1;
  static const compressedPrefix = 'Z2:';
  static const compressionThresholdBytes = 420;
  static const maxDecodedTransportBytes = 64 * 1024;

  final int version;
  final String localId;
  final String nickname;
  final String language;
  final List<SelectedInterest> interests;

  factory QrProfilePayload.fromProfile(LocalProfile profile) => QrProfilePayload(
        version: currentVersion,
        localId: profile.localId,
        nickname: profile.nickname,
        language: profile.language,
        interests: profile.interests,
      );

  Map<String, dynamic> toCompactJson() => {
        'v': version,
        'id': localId,
        'name': nickname,
        'lang': language,
        'i': interests.map((item) {
          if (item.customLabel == null && item.customCategory == null) {
            return <dynamic>[item.id, item.strength.wireValue];
          }
          return <dynamic>[
            item.id,
            item.strength.wireValue,
            item.customLabel,
            item.customCategory,
          ];
        }).toList(),
      };

  String encodeLegacyJson() => jsonEncode(toCompactJson());

  String encode() {
    final legacy = encodeLegacyJson();
    final legacyBytes = utf8.encode(legacy);
    if (legacyBytes.length < compressionThresholdBytes) return legacy;

    final compressed = zlib.encode(legacyBytes);
    final encoded = base64UrlEncode(compressed).replaceAll('=', '');
    final transport = '$compressedPrefix$encoded';

    return utf8.encode(transport).length < legacyBytes.length ? transport : legacy;
  }

  factory QrProfilePayload.decode(String raw) {
    final jsonText = _decodeTransport(raw);
    final json = Map<String, dynamic>.from(jsonDecode(jsonText) as Map);
    final version = (json['v'] as num?)?.toInt() ?? 0;
    if (version != currentVersion) {
      throw const FormatException('Unsupported Zync QR version');
    }
    final interests = ((json['i'] as List?) ?? const []).map((entry) {
      final pair = List<dynamic>.from(entry as List);
      if (pair.length < 2) throw const FormatException('Invalid Zync interest payload');
      return SelectedInterest(
        id: pair[0] as String,
        strength: InterestStrength.fromWire((pair[1] as num).toInt()),
        customLabel: pair.length > 2 ? pair[2] as String? : null,
        customCategory: pair.length > 3 ? pair[3] as String? : null,
      );
    }).toList();
    return QrProfilePayload(
      version: version,
      localId: json['id'] as String,
      nickname: (json['name'] as String?) ?? '',
      language: (json['lang'] as String?) ?? 'en',
      interests: interests,
    );
  }

  static String _decodeTransport(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(compressedPrefix)) return trimmed;

    final encoded = trimmed.substring(compressedPrefix.length);
    if (encoded.isEmpty) {
      throw const FormatException('Invalid compressed Zync QR payload');
    }

    try {
      final padding = (4 - encoded.length % 4) % 4;
      final compressed = base64Url.decode('$encoded${'=' * padding}');
      final decoded = zlib.decode(compressed);
      if (decoded.length > maxDecodedTransportBytes) {
        throw const FormatException('Zync QR payload is too large');
      }
      return utf8.decode(decoded);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid compressed Zync QR payload');
    }
  }
}

class MatchResult {
  const MatchResult({required this.shared, required this.onlyMine, required this.onlyTheirs});

  final List<SelectedInterest> shared;
  final List<SelectedInterest> onlyMine;
  final List<SelectedInterest> onlyTheirs;
}

class ZyncHistoryEntry {
  const ZyncHistoryEntry({
    required this.peerId,
    required this.peerNickname,
    required this.previousSharedIds,
    required this.firstZyncAt,
    required this.lastZyncAt,
    required this.sessionCount,
  });

  final String peerId;
  final String peerNickname;
  final List<String> previousSharedIds;
  final DateTime firstZyncAt;
  final DateTime lastZyncAt;
  final int sessionCount;

  Map<String, dynamic> toJson() => {
        'peerId': peerId,
        'peerNickname': peerNickname,
        'previousSharedIds': previousSharedIds,
        'firstZyncAt': firstZyncAt.toIso8601String(),
        'lastZyncAt': lastZyncAt.toIso8601String(),
        'sessionCount': sessionCount,
      };

  factory ZyncHistoryEntry.fromJson(Map<String, dynamic> json) => ZyncHistoryEntry(
        peerId: json['peerId'] as String,
        peerNickname: (json['peerNickname'] as String?) ?? '',
        previousSharedIds: ((json['previousSharedIds'] as List?) ?? const []).cast<String>(),
        firstZyncAt: DateTime.parse(json['firstZyncAt'] as String),
        lastZyncAt: DateTime.parse(json['lastZyncAt'] as String),
        sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 1,
      );
}

enum ConversationMode { easy, fun, debate, deep, guess, surprise }
