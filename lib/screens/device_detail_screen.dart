import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/device_detail.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});
  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  DeviceDetail? _d;
  String? _lastCommandInfo;

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
      _d = await context.read<VaultApi>().getDevice(widget.deviceId);
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markLost() async {
    final noteController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark device as lost?'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark Lost')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await context
          .read<VaultApi>()
          .markDeviceLost(widget.deviceId, note: noteController.text.trim());
      await _load();
    }, 'Device marked as lost');
  }

  Future<void> _dispatch(String type) async {
    if (type == 'Wipe') {
      final ok = await showDoubleConfirmDialog(context,
          title: 'Wipe device?',
          body:
              'This will queue an irreversible remote wipe of the device data.');
      if (!ok) return;
    } else if (type == 'Lock') {
      final ok = await showConfirmationDialog(context,
          title: 'Lock device?',
          body: 'This will queue a remote lock command.',
          danger: true);
      if (!ok) return;
    }

    await _run(() async {
      final api = context.read<VaultApi>();
      final resp = await api.dispatchCommand(widget.deviceId, type);
      _lastCommandInfo = '$type · ${resp.status} · ${resp.commandId}';

      if (resp.requiresConfirmation && resp.confirmationToken != null) {
        // Two-step: confirm the destructive command to arm it.
        final confirm = await showConfirmationDialog(context,
            title: 'Confirm $type',
            body:
                'Review complete. Confirm to queue this $type command for the device.',
            confirmLabel: 'Confirm & Queue',
            danger: true);
        if (confirm) {
          await api.confirmCommand(resp.commandId, resp.confirmationToken!);
          _lastCommandInfo = '$type · Queued · ${resp.commandId}';
        } else {
          _lastCommandInfo = '$type · Awaiting confirmation · ${resp.commandId}';
        }
      }
    }, '$type command dispatched');
  }

  Future<void> _run(Future<void> Function() action, String successMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMsg)));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canTheft = context.watch<AuthState>().hasRole(['Admin', 'SecurityOfficer']);
    return Scaffold(
      appBar: AppBar(title: const Text('Device')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load device',
                  subtitle: _error,
                  action:
                      FilledButton(onPressed: _load, child: const Text('Retry')))
              : LoadingOverlay(
                  visible: _busy,
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            PlatformIcon(_d!.platform, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_d!.deviceIdentifier,
                                  style: Theme.of(context).textTheme.titleLarge),
                            ),
                            StatusBadge.device(_d!.status),
                          ],
                        ),
                        const Divider(height: 28),
                        InfoRow(label: 'Platform', value: '${_d!.platform} · ${_d!.osVersion}'),
                        InfoRow(label: 'Protection engine', value: _d!.protectionEngine ?? '—'),
                        _boolRow('Protection enabled', _d!.protectionEnabled),
                        _boolRow('Encryption enabled', _d!.encryptionEnabled),
                        InfoRow(label: 'Last check-in', value: TimeAgoText.format(_d!.lastCheckInAt)),
                        InfoRow(label: 'Last scan', value: TimeAgoText.format(_d!.lastScanAt)),
                        InfoRow(
                            label: 'Last known location',
                            value: _d!.lastKnownLocation ?? 'Unknown',
                            copyable: _d!.lastKnownLocation != null),
                        if (_d!.groupName != null)
                          InfoRow(label: 'Group', value: _d!.groupName!),
                        if (_lastCommandInfo != null) ...[
                          const SizedBox(height: 8),
                          Card(
                            color: AppColors.olive.withValues(alpha: 0.25),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                const Icon(Icons.terminal, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Last command: $_lastCommandInfo')),
                              ]),
                            ),
                          ),
                        ],
                        if (canTheft) ...[
                          const SectionHeader('Theft Protection'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _markLost,
                                icon: const Icon(Icons.report_gmailerrorred_outlined),
                                label: const Text('Mark Lost'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.warning),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _dispatch('Locate'),
                                icon: const Icon(Icons.my_location_outlined),
                                label: const Text('Locate'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _dispatch('Lock'),
                                icon: const Icon(Icons.lock_outline),
                                label: const Text('Lock'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger),
                              ),
                              FilledButton.icon(
                                onPressed: () => _dispatch('Wipe'),
                                icon: const Icon(Icons.delete_forever_outlined),
                                label: const Text('Wipe'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.danger),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _boolRow(String label, bool value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(value ? Icons.check_circle : Icons.cancel,
              color: value ? AppColors.success : AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}
