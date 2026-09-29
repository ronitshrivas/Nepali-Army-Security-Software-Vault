import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../models/alert.dart';
import '../models/reports.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  FleetHealthReport? _health;
  List<AlertItem> _recentAlerts = [];
  DateTime? _updatedAt;

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
    final api = context.read<VaultApi>();
    try {
      _health = await api.getFleetHealth();
      final alerts = await api.listAlerts(status: 'Open', pageSize: 5);
      _recentAlerts = alerts.items;
      _updatedAt = DateTime.now();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load overview',
                      subtitle: _error,
                      action: FilledButton(
                          onPressed: _load, child: const Text('Retry')),
                    ),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Banner(role: auth.role),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _StatTile(
                              label: 'Active Devices',
                              value: '${_health?.activeDevices ?? 0}',
                              icon: Icons.verified_user_outlined,
                              color: AppColors.success),
                          _StatTile(
                              label: 'Lost Devices',
                              value: '${_health?.lostDevices ?? 0}',
                              icon: Icons.gpp_bad_outlined,
                              color: AppColors.crimson),
                          _StatTile(
                              label: 'Open Alerts',
                              value: '${_health?.openAlerts ?? 0}',
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.danger),
                          _StatTile(
                              label: 'Non-Compliant',
                              value: '${_health?.nonCompliantDevices ?? 0}',
                              icon: Icons.rule_outlined,
                              color: AppColors.warning),
                          _StatTile(
                              label: 'High Threats 24h',
                              value: '${_health?.highSeverityEventsLast24h ?? 0}',
                              icon: Icons.local_fire_department_outlined,
                              color: const Color(0xFFE0662B)),
                          _StatTile(
                              label: 'Total Devices',
                              value: '${_health?.totalDevices ?? 0}',
                              icon: Icons.devices_outlined,
                              color: AppColors.info),
                        ],
                      ),
                      if (_updatedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text('Last updated ${TimeAgoText.format(_updatedAt)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5))),
                        ),
                      const SizedBox(height: 8),
                      if (_recentAlerts.isNotEmpty) ...[
                        const SectionHeader('Recent Open Alerts'),
                        ..._recentAlerts.map((a) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(Icons.warning_amber_rounded,
                                    color: AppColors.danger),
                                title: Text(a.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(a.type),
                                trailing: SeverityBadge(severity: a.severity),
                              ),
                            )),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String? role;
  const _Banner({this.role});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const VaultCrest(size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConfig.appName,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('Signed in as ${role ?? "—"}',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(label,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
