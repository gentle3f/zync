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
    this.cluster = '',
    this.rank = 9999,
  });

  final String id;
  final String category;
  final Map<String, String> labels;
  final List<String> aliases;

  /// Related-interest neighborhood. This is deliberately separate from the
  /// canonical ID: sharing a cluster never makes two interests an exact match.
  final String cluster;

  /// Lower values are more useful during empty-query discovery.
  final int rank;

  String labelFor(String locale) {
    final normalized = locale.replaceAll('_', '-');
    final lower = normalized.toLowerCase();
    final canonical = lower.startsWith('zh')
        ? (lower.contains('hant') || lower.contains('-hk') || lower.contains('-tw') || lower.contains('-mo')
            ? 'zh-Hant'
            : 'zh-Hans')
        : normalized.split('-').first;
    return labels[normalized] ?? labels[canonical] ?? labels[canonical.split('-').first] ?? labels['en'] ?? id;
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

enum SocialPlatform { instagram, threads, facebook }

class SocialLink {
  const SocialLink({
    required this.platform,
    required this.value,
    this.shareAfterZync = false,
  });

  final SocialPlatform platform;
  final String value;

  /// Explicit opt-in: only links with this flag are included in a Zync QR.
  final bool shareAfterZync;

  String get displayValue {
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.lastWhere(
          (segment) => segment.trim().isNotEmpty,
          orElse: () => trimmed,
        );
      }
    }
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  String? get profileUrl {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final direct = Uri.tryParse(trimmed);
    if (direct != null &&
        (direct.scheme == 'https' || direct.scheme == 'http') &&
        direct.host.isNotEmpty) {
      return direct.replace(scheme: 'https').toString();
    }

    final handle = trimmed
        .replaceAll(RegExp(r'^@+'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
    if (handle.isEmpty) return null;

    return switch (platform) {
      SocialPlatform.instagram => 'https://www.instagram.com/$handle/',
      SocialPlatform.threads => 'https://www.threads.net/@$handle',
      SocialPlatform.facebook => 'https://www.facebook.com/$handle',
    };
  }

  Map<String, dynamic> toJson() => {
        'platform': platform.name,
        'value': value,
        'shareAfterZync': shareAfterZync,
      };

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    final rawPlatform = (json['platform'] as String?) ?? '';
    final platform = SocialPlatform.values.firstWhere(
      (item) => item.name == rawPlatform,
      orElse: () => SocialPlatform.instagram,
    );
    return SocialLink(
      platform: platform,
      value: (json['value'] as String?) ?? '',
      shareAfterZync: (json['shareAfterZync'] as bool?) ?? false,
    );
  }
}

class LocalProfile {
  const LocalProfile({
    required this.localId,
    required this.nickname,
    required this.language,
    required this.interests,
    this.socialLinks = const [],
  });

  final String localId;
  final String nickname;
  final String language;
  final List<SelectedInterest> interests;
  final List<SocialLink> socialLinks;

  LocalProfile copyWith({
    String? localId,
    String? nickname,
    String? language,
    List<SelectedInterest>? interests,
    List<SocialLink>? socialLinks,
  }) =>
      LocalProfile(
        localId: localId ?? this.localId,
        nickname: nickname ?? this.nickname,
        language: language ?? this.language,
        interests: interests ?? this.interests,
        socialLinks: socialLinks ?? this.socialLinks,
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'nickname': nickname,
        'language': language,
        'interests': interests.map((item) => item.toJson()).toList(),
        'socialLinks': socialLinks.map((item) => item.toJson()).toList(),
      };

  factory LocalProfile.fromJson(Map<String, dynamic> json) => LocalProfile(
        localId: json['localId'] as String,
        nickname: (json['nickname'] as String?) ?? '',
        language: (json['language'] as String?) ?? 'en',
        interests: ((json['interests'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => SelectedInterest.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        socialLinks: ((json['socialLinks'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => SocialLink.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.value.trim().isNotEmpty)
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
    this.socialLinks = const [],
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
  final List<SocialLink> socialLinks;

  factory QrProfilePayload.fromProfile(LocalProfile profile) => QrProfilePayload(
        version: currentVersion,
        localId: profile.localId,
        nickname: profile.nickname,
        language: profile.language,
        interests: profile.interests,
        socialLinks: profile.socialLinks
            .where((item) => item.shareAfterZync && item.profileUrl != null)
            .toList(growable: false),
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
        if (socialLinks.isNotEmpty)
          's': socialLinks
              .map((item) => <dynamic>[item.platform.name, item.value])
              .toList(),
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
    final socialLinks = ((json['s'] as List?) ?? const [])
        .whereType<List>()
        .map((entry) {
          if (entry.length < 2) return null;
          final platform = SocialPlatform.values.firstWhere(
            (item) => item.name == entry[0],
            orElse: () => SocialPlatform.instagram,
          );
          final link = SocialLink(
            platform: platform,
            value: (entry[1] as String?) ?? '',
            shareAfterZync: true,
          );
          return link.profileUrl == null ? null : link;
        })
        .whereType<SocialLink>()
        .toList(growable: false);
    return QrProfilePayload(
      version: version,
      localId: json['id'] as String,
      nickname: (json['name'] as String?) ?? '',
      language: (json['lang'] as String?) ?? 'en',
      interests: interests,
      socialLinks: socialLinks,
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
      final paddingCount = (4 - encoded.length % 4) % 4;
      final padded = '$encoded${List.filled(paddingCount, '=').join()}';
      final compressed = base64Url.decode(padded);
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

class SharedInterestDetail {
  const SharedInterestDetail({
    required this.mine,
    required this.theirs,
  });

  final SelectedInterest mine;
  final SelectedInterest theirs;

  String get id => mine.id;

  SelectedInterest get merged {
    final lower = mine.strength.wireValue < theirs.strength.wireValue
        ? mine.strength
        : theirs.strength;
    return SelectedInterest(
      id: id,
      strength: lower,
      customLabel: mine.customLabel ?? theirs.customLabel,
      customCategory: mine.customCategory ?? theirs.customCategory,
    );
  }
}

class MatchResult {
  const MatchResult({
    required this.shared,
    required this.onlyMine,
    required this.onlyTheirs,
    this.sharedDetails = const [],
  });

  final List<SelectedInterest> shared;
  final List<SelectedInterest> onlyMine;
  final List<SelectedInterest> onlyTheirs;

  /// Preserves both people's strength for the exact shared canonical ID.
  /// Older call sites can keep using [shared]; new Zync Session UX should use
  /// this richer view so "Love" vs "Want to try" becomes a conversation signal.
  final List<SharedInterestDetail> sharedDetails;

  SharedInterestDetail detailFor(String id) {
    for (final detail in sharedDetails) {
      if (detail.id == id) return detail;
    }
    final fallback = shared.firstWhere((item) => item.id == id);
    return SharedInterestDetail(mine: fallback, theirs: fallback);
  }
}

class ZyncQuestionMemory {
  const ZyncQuestionMemory({
    required this.connectionKey,
    required this.question,
    required this.mode,
    required this.createdAt,
    this.secondaryQuestion,
    this.connectionLabel,
    this.kind = 'shared',
  });

  final String connectionKey;
  final String question;
  final String mode;
  final DateTime createdAt;
  final String? secondaryQuestion;
  final String? connectionLabel;
  final String kind;

  Map<String, dynamic> toJson() => {
        'connectionKey': connectionKey,
        'question': question,
        'mode': mode,
        'createdAt': createdAt.toIso8601String(),
        if (secondaryQuestion != null && secondaryQuestion!.isNotEmpty)
          'secondaryQuestion': secondaryQuestion,
        if (connectionLabel != null && connectionLabel!.isNotEmpty)
          'connectionLabel': connectionLabel,
        'kind': kind,
      };

  factory ZyncQuestionMemory.fromJson(Map<String, dynamic> json) => ZyncQuestionMemory(
        connectionKey: (json['connectionKey'] as String?) ?? '',
        question: (json['question'] as String?) ?? '',
        mode: (json['mode'] as String?) ?? 'fun',
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        secondaryQuestion: json['secondaryQuestion'] as String?,
        connectionLabel: json['connectionLabel'] as String?,
        kind: (json['kind'] as String?) ?? 'shared',
      );
}

class ZyncHistoryEntry {
  const ZyncHistoryEntry({
    required this.peerId,
    required this.peerNickname,
    required this.previousSharedIds,
    required this.firstZyncAt,
    required this.lastZyncAt,
    required this.sessionCount,
    this.peerInterests = const [],
    this.seenInterestIds = const [],
    this.peerSocialLinks = const [],
    this.recentQuestions = const [],
  });

  final String peerId;
  final String peerNickname;
  final List<String> previousSharedIds;
  final DateTime firstZyncAt;
  final DateTime lastZyncAt;
  final int sessionCount;

  /// Latest limited profile received from this peer. Stored locally only so
  /// history can remember what you learned about the person.
  final List<SelectedInterest> peerInterests;

  /// Cumulative canonical/custom interest IDs ever observed for this peer.
  /// This is local-only progression memory so earned discovery achievements
  /// never move backwards when a peer later edits their current profile.
  final List<String> seenInterestIds;

  /// Latest social links that the peer explicitly consented to share.
  /// These remain local history on this device after the Zync session.
  final List<SocialLink> peerSocialLinks;

  /// Local-only memory of prompts actually shown during past Zync sessions.
  final List<ZyncQuestionMemory> recentQuestions;

  Map<String, dynamic> toJson() => {
        'peerId': peerId,
        'peerNickname': peerNickname,
        'previousSharedIds': previousSharedIds,
        'firstZyncAt': firstZyncAt.toIso8601String(),
        'lastZyncAt': lastZyncAt.toIso8601String(),
        'sessionCount': sessionCount,
        'peerInterests': peerInterests.map((item) => item.toJson()).toList(),
        'seenInterestIds': seenInterestIds,
        'peerSocialLinks': peerSocialLinks.map((item) => item.toJson()).toList(),
        'recentQuestions': recentQuestions.map((item) => item.toJson()).toList(),
      };

  factory ZyncHistoryEntry.fromJson(Map<String, dynamic> json) => ZyncHistoryEntry(
        peerId: json['peerId'] as String,
        peerNickname: (json['peerNickname'] as String?) ?? '',
        previousSharedIds: ((json['previousSharedIds'] as List?) ?? const []).whereType<String>().toList(),
        firstZyncAt: DateTime.parse(json['firstZyncAt'] as String),
        lastZyncAt: DateTime.parse(json['lastZyncAt'] as String),
        sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 1,
        peerInterests: ((json['peerInterests'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => SelectedInterest.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        seenInterestIds: ((json['seenInterestIds'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
        peerSocialLinks: ((json['peerSocialLinks'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => SocialLink.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.profileUrl != null)
            .toList(),
        recentQuestions: ((json['recentQuestions'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => ZyncQuestionMemory.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.question.trim().isNotEmpty)
            .toList(),
      );
}

enum ConversationMode { easy, fun, debate, deep, guess, surprise }
