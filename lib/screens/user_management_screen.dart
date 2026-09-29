import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../widgets/common.dart';

const kRoles = ['Admin', 'Operator', 'Auditor', 'SecurityOfficer'];

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _loading = true;
  String? _error;
  List<UserListItem> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _users = await context.read<VaultApi>().listUsers();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createUser() async {
    final username = TextEditingController();
    final password = TextEditingController();
    String role = 'Operator';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 10),
              TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password (min 10 chars)')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: kRoles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => role = v ?? role),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await context
          .read<VaultApi>()
          .createUser(username.text.trim(), password.text, role);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User created')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  void _openActions(UserListItem u) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _UserActions(user: u, onDone: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createUser,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add User'),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load users',
                  subtitle: _error,
                  action:
                      FilledButton(onPressed: _load, child: const Text('Retry')))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _openActions(u),
                          leading: Icon(
                            u.isLockedOut ? Icons.lock : Icons.person,
                            color: u.isLockedOut ? AppColors.danger : null,
                          ),
                          title: Text(u.username,
                              style: TextStyle(
                                  color: u.isLockedOut
                                      ? AppColors.neutral
                                      : null,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              'Last login: ${TimeAgoText.format(u.lastLoginAt)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (u.twoFactorEnabled)
                                const Icon(Icons.verified_user,
                                    size: 16, color: AppColors.success),
                              const SizedBox(width: 6),
                              StatusChip(label: u.role, color: AppColors.olive),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _UserActions extends StatelessWidget {
  final UserListItem user;
  final VoidCallback onDone;
  const _UserActions({required this.user, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final api = context.read<VaultApi>();
    Future<void> run(Future<void> Function() f, String msg) async {
      Navigator.pop(context);
      try {
        await f();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        onDone();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(user.username,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Change Role'),
            onTap: () async {
              final role = await _pickRole(context, user.role);
              if (role != null) {
                await run(() => api.changeUserRole(user.id, role),
                    'Role changed to $role');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Reset Password'),
            onTap: () async {
              final pw = await _pickPassword(context);
              if (pw != null) {
                await run(() => api.resetUserPassword(user.id, pw),
                    'Password reset');
              }
            },
          ),
          ListTile(
            leading: Icon(user.isLockedOut ? Icons.lock_open : Icons.lock,
                color: AppColors.warning),
            title: Text(user.isLockedOut ? 'Unlock Account' : 'Lock Account'),
            onTap: () => run(
                () => user.isLockedOut
                    ? api.unlockUser(user.id)
                    : api.lockUser(user.id),
                user.isLockedOut ? 'Unlocked' : 'Locked'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Revoke All Sessions'),
            onTap: () => run(
                () => api.revokeUserSessions(user.id), 'Sessions revoked'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<String?> _pickRole(BuildContext context, String current) {
    String role = current;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Change Role'),
          content: DropdownButtonFormField<String>(
            initialValue: kRoles.contains(role) ? role : kRoles.first,
            items: kRoles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => role = v ?? role),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, role),
                child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickPassword(BuildContext context) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: c,
          obscureText: true,
          decoration:
              const InputDecoration(labelText: 'New password (min 10 chars)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Reset')),
        ],
      ),
    );
  }
}
