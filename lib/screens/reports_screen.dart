import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../models/reports.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  String? _error;
  FleetHealthReport? _health;
  List<ComplianceResult> _compliance = [];

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
      _compliance = await api.getComplianceStatus();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _export() {
    final h = _health;
    if (h == null) return;
    final b = StringBuffer()
      ..writeln('SECURE OFFICER VAULT — FLEET HEALTH')
      ..writeln('Generated: ${DateTime.now()}')
      ..writeln('')
      ..writeln('Total devices: ${h.totalDevices}')
      ..writeln('Active: ${h.activeDevices}')
      ..writeln('Lost: ${h.lostDevices}')
      ..writeln('Retired: ${h.retiredDevices}')
      ..writeln('Open alerts: ${h.openAlerts}')
      ..writeln('High-severity events (24h): ${h.highSeverityEventsLast24h}')
      ..writeln('Non-compliant devices: ${h.nonCompliantDevices}')
      ..writeln('')
      ..writeln('COMPLIANCE (${_compliance.length} records):');
    for (final c in _compliance) {
      b.writeln('- ${c.deviceId} · ${c.state}'
          '${c.reasons.isNotEmpty ? " · ${c.reasons.join("; ")}" : ""}');
    }
    Share.share(b.toString(), subject: 'Fleet Health Report');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(onPressed: _export, icon: const Icon(Icons.ios_share)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load reports',
                  subtitle: _error,
                  action:
                      FilledButton(onPressed: _load, child: const Text('Retry')))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.7,
                        children: [
                          _mini('Total', _health!.totalDevices, AppColors.info),
                          _mini('Active', _health!.activeDevices, AppColors.success),
                          _mini('Lost', _health!.lostDevices, AppColors.crimson),
                          _mini('Retired', _health!.retiredDevices, AppColors.neutral),
                          _mini('Open Alerts', _health!.openAlerts, AppColors.danger),
                          _mini('Non-Compliant', _health!.nonCompliantDevices, AppColors.warning),
                        ],
                      ),
                      const SectionHeader('Compliance'),
                      if (_compliance.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No compliance records yet.'),
                        )
                      else
                        ..._compliance.map((c) {
                          final bad = c.state.toLowerCase() == 'noncompliant';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: bad ? AppColors.danger : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                title: Text('Device ${c.deviceId.substring(0, 8)}…'),
                                subtitle: c.reasons.isEmpty
                                    ? null
                                    : Text(c.reasons.join('; ')),
                                trailing: StatusBadge.compliance(c.state),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _mini(String label, int value, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$value',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700, color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65))),
            ],
          ),
        ),
      );
}
