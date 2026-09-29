class FleetHealthReport {
  final int totalDevices;
  final int activeDevices;
  final int lostDevices;
  final int retiredDevices;
  final int openAlerts;
  final int highSeverityEventsLast24h;
  final int nonCompliantDevices;

  FleetHealthReport({
    required this.totalDevices,
    required this.activeDevices,
    required this.lostDevices,
    required this.retiredDevices,
    required this.openAlerts,
    required this.highSeverityEventsLast24h,
    required this.nonCompliantDevices,
  });

  factory FleetHealthReport.fromJson(Map<String, dynamic> j) => FleetHealthReport(
        totalDevices: _int(j['totalDevices']),
        activeDevices: _int(j['activeDevices']),
        lostDevices: _int(j['lostDevices']),
        retiredDevices: _int(j['retiredDevices']),
        openAlerts: _int(j['openAlerts']),
        highSeverityEventsLast24h: _int(j['highSeverityEventsLast24h']),
        nonCompliantDevices: _int(j['nonCompliantDevices']),
      );

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
}

class ComplianceResult {
  final String deviceId;
  final String policyId;
  final String state;
  final List<String> reasons;
  final DateTime evaluatedAt;

  ComplianceResult({
    required this.deviceId,
    required this.policyId,
    required this.state,
    required this.reasons,
    required this.evaluatedAt,
  });

  factory ComplianceResult.fromJson(Map<String, dynamic> j) => ComplianceResult(
        deviceId: j['deviceId'].toString(),
        policyId: j['policyId'].toString(),
        state: j['state']?.toString() ?? 'Unknown',
        reasons: (j['reasons'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        evaluatedAt: DateTime.tryParse(j['evaluatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class SecurityEventItem {
  final String id;
  final String deviceId;
  final String type;
  final String rawType;
  final String severity;
  final String engineName;
  final String engineVersion;
  final DateTime reportedAt;
  final DateTime receivedAt;

  SecurityEventItem({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.rawType,
    required this.severity,
    required this.engineName,
    required this.engineVersion,
    required this.reportedAt,
    required this.receivedAt,
  });

  factory SecurityEventItem.fromJson(Map<String, dynamic> j) =>
      SecurityEventItem(
        id: j['id'].toString(),
        deviceId: j['deviceId'].toString(),
        type: j['type']?.toString() ?? 'Unknown',
        rawType: j['rawType']?.toString() ?? '',
        severity: j['severity']?.toString() ?? 'Info',
        engineName: j['engineName']?.toString() ?? '',
        engineVersion: j['engineVersion']?.toString() ?? '',
        reportedAt: DateTime.tryParse(j['reportedAt']?.toString() ?? '') ??
            DateTime.now(),
        receivedAt: DateTime.tryParse(j['receivedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
