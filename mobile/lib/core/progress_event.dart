enum ZyncProgressEventType {
  oneToOneZync,
  triedTogetherCompleted,
}

enum ZyncProgressSource {
  oneToOne,
  zyncNow,
}

class ZyncProgressEvent {
  const ZyncProgressEvent({
    required this.id,
    required this.type,
    required this.source,
    required this.occurredAt,
    required this.participantCount,
    this.repeatPerson = false,
    this.mode = '',
    this.interestCategories = const [],
  });

  final String id;
  final ZyncProgressEventType type;
  final ZyncProgressSource source;
  final DateTime occurredAt;
  final int participantCount;

  /// Coarse behavioral context only. No peer identifier is retained.
  final bool repeatPerson;
  final String mode;

  /// Category labels such as sports / food. Canonical peer interest IDs are
  /// deliberately excluded from the progress-event stream.
  final List<String> interestCategories;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'source': source.name,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'participantCount': participantCount,
        if (repeatPerson) 'repeatPerson': true,
        if (mode.isNotEmpty) 'mode': mode,
        if (interestCategories.isNotEmpty)
          'categories': interestCategories,
      };

  factory ZyncProgressEvent.fromJson(Map<String, dynamic> json) {
    final typeName = (json['type'] as String?) ?? '';
    final sourceName = (json['source'] as String?) ?? '';
    final type = ZyncProgressEventType.values.where(
      (item) => item.name == typeName,
    );
    final source = ZyncProgressSource.values.where(
      (item) => item.name == sourceName,
    );
    final id = (json['id'] as String?)?.trim() ?? '';
    final occurredAt =
        DateTime.tryParse((json['occurredAt'] as String?) ?? '');
    final participantCount =
        (json['participantCount'] as num?)?.toInt() ?? 0;

    if (id.isEmpty ||
        type.length != 1 ||
        source.length != 1 ||
        occurredAt == null ||
        participantCount < 2 ||
        participantCount > 8) {
      throw const FormatException('Invalid Zync progress event');
    }

    final categories = ((json['categories'] as List?) ?? const [])
        .whereType<String>()
        .map((item) => item.trim().toLowerCase())
        .where(
          (item) =>
              item.isNotEmpty &&
              item.length <= 32 &&
              RegExp(r'^[a-z0-9_]+$').hasMatch(item),
        )
        .toSet()
        .toList(growable: false)
      ..sort();

    final mode = ((json['mode'] as String?) ?? '').trim();
    if (mode.length > 32) {
      throw const FormatException('Invalid Zync progress mode');
    }

    return ZyncProgressEvent(
      id: id,
      type: type.single,
      source: source.single,
      occurredAt: occurredAt.toUtc(),
      participantCount: participantCount,
      repeatPerson: json['repeatPerson'] == true,
      mode: mode,
      interestCategories: List.unmodifiable(categories),
    );
  }
}
