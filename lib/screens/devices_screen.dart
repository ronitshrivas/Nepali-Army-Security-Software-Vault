import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/device.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';
import 'device_detail_screen.dart';
import 'enroll_device_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _loading = true;
  String? _error;
  List<DeviceListItem> _items = [];
  String? _statusFilter;

  static const _statuses = ['Active', 'Lost', 'Retired'];

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
          .listDevices(status: _statusFilter, pageSize: 100);
      _items = page.items;
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(DeviceListItem d) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(deviceId: d.id)));
    _load();
  }

  Future<void> _enroll() async {
    final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const EnrollDeviceScreen()));
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final canEnroll =
        context.watch<AuthState>().hasRole(['Admin', 'Operator']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: canEnroll
          ? FloatingActionButton.extended(
              onPressed: _enroll,
              icon: const Icon(Icons.add),
              label: const Text('Enroll'))
          : null,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _chip('All', _statusFilter == null, () {
                  setState(() => _statusFilter = null);
                  _load();
                }),
                for (final s in _statuses) ...[
                  const SizedBox(width: 8),
                  _chip(s, _statusFilter == s, () {
                    setState(() => _statusFilter = s);
                    _load();
                  }),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? EmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load devices',
                        subtitle: _error,
                        action: FilledButton(
                            onPressed: _load, child: const Text('Retry')))
                    : _items.isEmpty
                        ? const EmptyState(
                            icon: Icons.devices_other_outlined,
                            title: 'No devices',
                            subtitle: 'Nothing matches this filter.')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  _DeviceCard(_items[i], () => _open(_items[i])),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback tap) {
    final scheme = Theme.of(context).colorScheme;
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

class _DeviceCard extends StatelessWidget {
  final DeviceListItem d;
  final VoidCallback onTap;
  const _DeviceCard(this.d, this.onTap);

  bool get _stale =>
      d.lastCheckInAt != null &&
      DateTime.now().difference(d.lastCheckInAt!.toLocal()).inDays > 7;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLost = d.status.toLowerCase() == 'lost';
    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isLost ? AppColors.danger : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: PlatformIcon(d.platform),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(d.deviceIdentifier,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 15)),
                          ),
                          if (_stale) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.warning_amber_rounded,
                                size: 16, color: AppColors.warning),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${d.platform} · ${d.osVersion}',
                          style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface.withValues(alpha: 0.7))),
                      const SizedBox(height: 6),
                      Text('Last check-in: ${TimeAgoText.format(d.lastCheckInAt)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                StatusBadge.device(d.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
