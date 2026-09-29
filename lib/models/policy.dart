class PolicyDto {
  final String id;
  final String name;
  final String? description;
  final String? minOsVersion;
  final bool requireProtectionEnabled;
  final bool requireEncryption;
  final int? maxDaysSinceLastScan;
  final int? maxDaysSinceLastCheckIn;
  final bool isActive;

  PolicyDto({
    required this.id,
    required this.name,
    this.description,
    this.minOsVersion,
    required this.requireProtectionEnabled,
    required this.requireEncryption,
    this.maxDaysSinceLastScan,
    this.maxDaysSinceLastCheckIn,
    required this.isActive,
  });

  factory PolicyDto.fromJson(Map<String, dynamic> j) => PolicyDto(
        id: j['id'].toString(),
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString(),
        minOsVersion: j['minOsVersion']?.toString(),
        requireProtectionEnabled: j['requireProtectionEnabled'] == true,
        requireEncryption: j['requireEncryption'] == true,
        maxDaysSinceLastScan: (j['maxDaysSinceLastScan'] as num?)?.toInt(),
        maxDaysSinceLastCheckIn: (j['maxDaysSinceLastCheckIn'] as num?)?.toInt(),
        isActive: j['isActive'] == true,
      );
}

class TotpSetup {
  final String secret;
  final String provisioningUri;
  TotpSetup(this.secret, this.provisioningUri);

  factory TotpSetup.fromJson(Map<String, dynamic> j) => TotpSetup(
        j['secret']?.toString() ?? '',
        (j['provisioningUri'] ?? j['qrCodeUri'])?.toString() ?? '',
      );
}
