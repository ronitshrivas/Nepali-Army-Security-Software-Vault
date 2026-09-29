class DeviceListItem {
  final String id;
  final String deviceIdentifier;
  final String platform;
  final String osVersion;
  final String status;
  final String ownerOfficerId;
  final DateTime? lastCheckInAt;

  DeviceListItem({
    required this.id,
    required this.deviceIdentifier,
    required this.platform,
    required this.osVersion,
    required this.status,
    required this.ownerOfficerId,
    this.lastCheckInAt,
  });

  factory DeviceListItem.fromJson(Map<String, dynamic> j) => DeviceListItem(
        id: j['id'].toString(),
        deviceIdentifier: j['deviceIdentifier']?.toString() ?? '',
        platform: j['platform']?.toString() ?? 'Unknown',
        osVersion: j['osVersion']?.toString() ?? '',
        status: j['status']?.toString() ?? 'Active',
        ownerOfficerId: j['ownerOfficerId']?.toString() ?? '',
        lastCheckInAt: j['lastCheckInAt'] == null
            ? null
            : DateTime.tryParse(j['lastCheckInAt'].toString()),
      );
}
