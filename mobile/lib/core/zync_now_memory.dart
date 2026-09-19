import 'zync_now_engine.dart';

enum ZyncNowActivityStatus { chosen, completed, skipped }

class ZyncNowActivityMemory {
  const ZyncNowActivityMemory({
    required this.id,
    required this.candidateId,
    required this.repeatKey,
    required this.templateId,
    required this.sourceInterestIds,
    required this.groupSize,
    required this.mode,
    required this.chosenAt,
    this.status = ZyncNowActivityStatus.chosen,
    this.completedAt,
  });

  final String id;
  final String candidateId;
  final String repeatKey;
  final String templateId;
  final List<String> sourceInterestIds;
  final int groupSize;
  final String mode;
  final DateTime chosenAt;
  final ZyncNowActivityStatus status;
  final DateTime? completedAt;

  bool get didIt => status == ZyncNowActivityStatus.completed;

  ZyncNowActivityMemory copyWith({
    ZyncNowActivityStatus? status,
    DateTime? completedAt,
  }) =>
      ZyncNowActivityMemory(
        id: id,
        candidateId: candidateId,
        repeatKey: repeatKey,
        templateId: templateId,
        sourceInterestIds: sourceInterestIds,
        groupSize: groupSize,
        mode: mode,
        chosenAt: chosenAt,
        status: status ?? this.status,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'candidateId': candidateId,
        'repeatKey': repeatKey,
        'templateId': templateId,
        'sourceInterestIds': sourceInterestIds,
        'groupSize': groupSize,
        'mode': mode,
        'chosenAt': chosenAt.toIso8601String(),
        'status': status.name,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  factory ZyncNowActivityMemory.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String?) ?? '';
    final status = ZyncNowActivityStatus.values.firstWhere(
      (item) => item.name == rawStatus,
      orElse: () => ZyncNowActivityStatus.chosen,
    );

    return ZyncNowActivityMemory(
      id: (json['id'] as String?) ?? '',
      candidateId: (json['candidateId'] as String?) ?? '',
      repeatKey: (json['repeatKey'] as String?) ?? '',
      templateId: (json['templateId'] as String?) ?? '',
      sourceInterestIds: ((json['sourceInterestIds'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      groupSize: (json['groupSize'] as num?)?.toInt() ?? 2,
      mode: (json['mode'] as String?) ?? ZyncNowMode.surprise.name,
      chosenAt: DateTime.tryParse((json['chosenAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: status,
      completedAt: DateTime.tryParse((json['completedAt'] as String?) ?? ''),
    );
  }
}
