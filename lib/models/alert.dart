class AlertItem {
  final String id;
  final String type;
  final String severity;
  final String status;
  final String title;
  final String? detail;
  final String? deviceId;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  AlertItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.title,
    this.detail,
    this.deviceId,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id: j['id'].toString(),
        type: j['type']?.toString() ?? 'Unknown',
        severity: j['severity']?.toString() ?? 'Info',
        status: j['status']?.toString() ?? 'Open',
        title: j['title']?.toString() ?? '',
        detail: j['detail']?.toString(),
        deviceId: j['deviceId']?.toString(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        acknowledgedAt: _dt(j['acknowledgedAt']),
        resolvedAt: _dt(j['resolvedAt']),
      );

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

class AlertPage {
  final List<AlertItem> items;
  final int totalCount;
  AlertPage(this.items, this.totalCount);

  factory AlertPage.fromJson(Map<String, dynamic> j) => AlertPage(
        (j['items'] as List? ?? [])
            .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        (j['totalCount'] as num?)?.toInt() ?? 0,
      );
}
