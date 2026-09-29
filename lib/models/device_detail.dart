class DeviceDetail {
  final String id;
  final String deviceIdentifier;
  final String platform;
  final String osVersion;
  final String? protectionEngine;
  final bool protectionEnabled;
  final bool encryptionEnabled;
  final String status;
  final String ownerOfficerId;
  final DateTime enrolledAt;
  final DateTime? lastCheckInAt;
  final DateTime? lastScanAt;
  final String? lastKnownLocation;
  final String? groupName;

  DeviceDetail({
    required this.id,
    required this.deviceIdentifier,
    required this.platform,
    required this.osVersion,
    this.protectionEngine,
    required this.protectionEnabled,
    required this.encryptionEnabled,
    required this.status,
    required this.ownerOfficerId,
    required this.enrolledAt,
    this.lastCheckInAt,
    this.lastScanAt,
    this.lastKnownLocation,
    this.groupName,
  });

  factory DeviceDetail.fromJson(Map<String, dynamic> j) => DeviceDetail(
        id: j['id'].toString(),
        deviceIdentifier: j['deviceIdentifier']?.toString() ?? '',
        platform: j['platform']?.toString() ?? 'Unknown',
        osVersion: j['osVersion']?.toString() ?? '',
        protectionEngine: j['protectionEngine']?.toString(),
        protectionEnabled: j['protectionEnabled'] == true,
        encryptionEnabled: j['encryptionEnabled'] == true,
        status: j['status']?.toString() ?? 'Active',
        ownerOfficerId: j['ownerOfficerId']?.toString() ?? '',
        enrolledAt: DateTime.tryParse(j['enrolledAt']?.toString() ?? '') ??
            DateTime.now(),
        lastCheckInAt: _dt(j['lastCheckInAt']),
        lastScanAt: _dt(j['lastScanAt']),
        lastKnownLocation: j['lastKnownLocation']?.toString(),
        groupName: j['groupName']?.toString(),
      );

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

class EnrollDeviceResponse {
  final String deviceId;
  final String attestationToken;
  EnrollDeviceResponse(this.deviceId, this.attestationToken);

  factory EnrollDeviceResponse.fromJson(Map<String, dynamic> j) =>
      EnrollDeviceResponse(
        j['deviceId'].toString(),
        j['attestationToken']?.toString() ?? '',
      );
}

class DispatchCommandResponse {
  final String commandId;
  final String status;
  final bool requiresConfirmation;
  final String? confirmationToken;

  DispatchCommandResponse({
    required this.commandId,
    required this.status,
    required this.requiresConfirmation,
    this.confirmationToken,
  });

  factory DispatchCommandResponse.fromJson(Map<String, dynamic> j) =>
      DispatchCommandResponse(
        commandId: j['commandId'].toString(),
        status: j['status']?.toString() ?? '',
        requiresConfirmation: j['requiresConfirmation'] == true,
        confirmationToken: j['confirmationToken']?.toString(),
      );
}

class DocumentInfo {
  final String id;
  final String fileName;
  final String contentType;
  final DateTime uploadedAt;

  DocumentInfo({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.uploadedAt,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> j) => DocumentInfo(
        id: j['id'].toString(),
        fileName: j['fileName']?.toString() ?? 'document',
        contentType: j['contentType']?.toString() ?? '',
        uploadedAt: DateTime.tryParse(
                (j['uploadedAt'] ?? j['createdAt'])?.toString() ?? '') ??
            DateTime.now(),
      );
}
