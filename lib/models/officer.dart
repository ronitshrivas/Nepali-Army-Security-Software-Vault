class OfficerListItem {
  final String id;
  final String role;
  final String unit;
  final String assignment;
  final bool isActive;
  final DateTime updatedAt;

  OfficerListItem({
    required this.id,
    required this.role,
    required this.unit,
    required this.assignment,
    required this.isActive,
    required this.updatedAt,
  });

  factory OfficerListItem.fromJson(Map<String, dynamic> j) => OfficerListItem(
        id: j['id'].toString(),
        role: j['role']?.toString() ?? '',
        unit: j['unit']?.toString() ?? '',
        assignment: j['assignment']?.toString() ?? '',
        isActive: j['isActive'] == true,
        updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class OfficerDetail {
  final String id;
  final String fullName;
  final String idNumber;
  final String contactPhone;
  final String contactEmail;
  final String? notes;
  final String role;
  final String unit;
  final String assignment;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OfficerDetail({
    required this.id,
    required this.fullName,
    required this.idNumber,
    required this.contactPhone,
    required this.contactEmail,
    this.notes,
    required this.role,
    required this.unit,
    required this.assignment,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory OfficerDetail.fromJson(Map<String, dynamic> j) => OfficerDetail(
        id: j['id'].toString(),
        fullName: j['fullName']?.toString() ?? '',
        idNumber: j['idNumber']?.toString() ?? '',
        contactPhone: j['contactPhone']?.toString() ?? '',
        contactEmail: j['contactEmail']?.toString() ?? '',
        notes: j['notes']?.toString(),
        role: j['role']?.toString() ?? '',
        unit: j['unit']?.toString() ?? '',
        assignment: j['assignment']?.toString() ?? '',
        isActive: j['isActive'] == true,
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt'].toString()),
        updatedAt: j['updatedAt'] == null
            ? null
            : DateTime.tryParse(j['updatedAt'].toString()),
      );
}

class PagedResult<T> {
  final List<T> items;
  final int total;
  PagedResult(this.items, this.total);

  factory PagedResult.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) parse,
  ) =>
      PagedResult(
        (j['items'] as List? ?? [])
            .map((e) => parse(e as Map<String, dynamic>))
            .toList(),
        (j['total'] as num?)?.toInt() ?? 0,
      );
}
