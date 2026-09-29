import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';
import 'alerts_screen.dart';
import 'audit_screen.dart';
import 'reports_screen.dart';
import 'lost_devices_screen.dart';
import 'user_management_screen.dart';
import 'policy_screen.dart';
import 'totp_setup_screen.dart';
import 'change_password_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isAdmin = auth.hasRole(['Admin']);
    final isAuditor = auth.hasRole(['Admin', 'Auditor']);
    final isManager = auth.hasRole(['Admin', 'Operator', 'SecurityOfficer']);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const VaultCrest(size: 44),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Role: ${auth.role ?? "—"}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(AppConfig.orgName,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SectionHeader('Security'),
          _tile(context, Icons.notifications_outlined, 'Alerts',
              () => const AlertsScreen()),
          if (isAuditor)
            _tile(context, Icons.receipt_long_outlined, 'Audit Log',
                () => const AuditScreen()),
          _tile(context, Icons.assessment_outlined, 'Reports & Fleet Health',
              () => const ReportsScreen()),
          if (isManager) ...[
            const SectionHeader('Management'),
            _tile(context, Icons.gpp_bad_outlined, 'Lost Devices',
                () => const LostDevicesScreen()),
            if (isAdmin)
              _tile(context, Icons.manage_accounts_outlined, 'User Management',
                  () => const UserManagementScreen()),
            if (isAdmin)
              _tile(context, Icons.policy_outlined, 'Policies',
                  () => const PolicyScreen()),
          ],
          const SectionHeader('Account'),
          _tile(context, Icons.security_outlined, 'Two-Factor Auth',
              () => const TotpSetupScreen()),
          _tile(context, Icons.password_outlined, 'Change Password',
              () => const ChangePasswordScreen()),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Sign out',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w600)),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('${AppConfig.appName} · v1.0.0',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4))),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, IconData icon, String title,
      Widget Function() builder) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(ctx)
          .push(MaterialPageRoute(builder: (_) => builder())),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showConfirmationDialog(context,
        title: 'Sign out?',
        body: 'You will need to sign in again to continue.',
        confirmLabel: 'Sign out');
    if (ok && context.mounted) {
      await context.read<AuthState>().logout();
    }
  }
}
