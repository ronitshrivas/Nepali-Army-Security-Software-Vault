class AuditEntry {
  final int id;
  final DateTime timestamp;
  final String? actorUsername;
  final String action;
  final String? targetType;
  final String? targetId;
  final String? detail;
  final String? sourceIp;

  AuditEntry({
    required this.id,
    required this.timestamp,
    this.actorUsername,
    required this.action,
    this.targetType,
    this.targetId,
    this.detail,
    this.sourceIp,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
        id: (j['id'] as num?)?.toInt() ?? 0,
        timestamp: DateTime.tryParse(j['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        actorUsername: j['actorUsername']?.toString(),
        action: j['action']?.toString() ?? '',
        targetType: j['targetType']?.toString(),
        targetId: j['targetId']?.toString(),
        detail: j['detail']?.toString(),
        sourceIp: j['sourceIp']?.toString(),
      );
}

class ChainVerifyResult {
  final bool intact;
  final int? firstBrokenEntryId;
  ChainVerifyResult(this.intact, this.firstBrokenEntryId);

  factory ChainVerifyResult.fromJson(Map<String, dynamic> j) =>
      ChainVerifyResult(
        j['intact'] == true,
        (j['firstBrokenEntryId'] as num?)?.toInt(),
      );
}
