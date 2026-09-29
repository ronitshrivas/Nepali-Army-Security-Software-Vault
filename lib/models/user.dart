class UserListItem {
  final String id;
  final String username;
  final String role;
  final bool twoFactorEnabled;
  final bool isLockedOut;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserListItem({
    required this.id,
    required this.username,
    required this.role,
    required this.twoFactorEnabled,
    required this.isLockedOut,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserListItem.fromJson(Map<String, dynamic> j) => UserListItem(
        id: j['id'].toString(),
        username: j['username']?.toString() ?? '',
        role: j['role']?.toString() ?? '',
        twoFactorEnabled: j['twoFactorEnabled'] == true,
        isLockedOut: j['isLockedOut'] == true,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        lastLoginAt: j['lastLoginAt'] == null
            ? null
            : DateTime.tryParse(j['lastLoginAt'].toString()),
      );
}
