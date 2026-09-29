import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/status_colors.dart';
import '../models/alert.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _loading = true;
  String? _error;
  List<AlertItem> _items = [];
  String? _statusFilter; // null = all

  static const _statuses = ['Open', 'Acknowledged', 'Resolved'];

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
      final page = await context
          .read<VaultApi>()
          .listAlerts(status: _statusFilter, pageSize: 100);
      _items = page.items;
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(AlertItem a, bool acknowledge) async {
    final api = context.read<VaultApi>();
    try {
      if (acknowledge) {
        await api.acknowledgeAlert(a.id);
      } else {
        await api.resolveAlert(a.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(acknowledge ? 'Alert acknowledged' : 'Alert resolved')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAct = context.watch<AuthState>().hasRole(['Admin', 'SecurityOfficer']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            selected: _statusFilter,
            options: _statuses,
            onChanged: (v) {
              setState(() => _statusFilter = v);
              _load();
            },
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? MessageView(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load alerts',
                        subtitle: _error,
                        action: FilledButton(
                            onPressed: _load, child: const Text('Retry')),
                      )
                    : _items.isEmpty
                        ? const MessageView(
                            icon: Icons.check_circle_outline,
                            title: 'No alerts',
                            subtitle: 'Nothing matches this filter.')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _AlertCard(
                                alert: _items[i],
                                canAct: canAct,
                                onAcknowledge: () => _act(_items[i], true),
                                onResolve: () => _act(_items[i], false),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? selected;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _FilterBar(
      {required this.selected, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _chip(context, 'All', selected == null, () => onChanged(null)),
          for (final o in options) ...[
            const SizedBox(width: 8),
            _chip(context, o, selected == o, () => onChanged(o)),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext ctx, String label, bool active, VoidCallback tap) {
    final scheme = Theme.of(ctx).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => tap(),
      selectedColor: scheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: active ? scheme.primary : scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  final bool canAct;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  const _AlertCard({
    required this.alert,
    required this.canAct,
    required this.onAcknowledge,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy · HH:mm');
    final isOpen = alert.status.toLowerCase() == 'open';
    final isResolved = alert.status.toLowerCase() == 'resolved';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(
                    label: alert.severity,
                    color: StatusColors.severity(alert.severity)),
                const SizedBox(width: 8),
                StatusChip(
                    label: alert.status,
                    color: StatusColors.alertStatus(alert.status)),
                const Spacer(),
                Text(fmt.format(alert.createdAt.toLocal()),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
            const SizedBox(height: 10),
            Text(alert.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontSize: 15)),
            if (alert.detail != null && alert.detail!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(alert.detail!,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7))),
            ],
            Text('Type: ${alert.type}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
            if (canAct && !isResolved) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isOpen)
                    TextButton.icon(
                      onPressed: onAcknowledge,
                      icon: const Icon(Icons.done, size: 18),
                      label: const Text('Acknowledge'),
                    ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.task_alt, size: 18),
                    label: const Text('Resolve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
