import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/device.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../widgets/common.dart';
import 'device_detail_screen.dart';

class LostDevicesScreen extends StatefulWidget {
  const LostDevicesScreen({super.key});
  @override
  State<LostDevicesScreen> createState() => _LostDevicesScreenState();
}

class _LostDevicesScreenState extends State<LostDevicesScreen> {
  bool _loading = true;
  String? _error;
  List<DeviceListItem> _items = [];

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
      _items = await context.read<VaultApi>().getLostDevices();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Stolen Devices'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load',
                  subtitle: _error,
                  action:
                      FilledButton(onPressed: _load, child: const Text('Retry')))
              : _items.isEmpty
                  ? const EmptyState(
                      icon: Icons.verified_user_outlined,
                      title: 'No lost or stolen devices',
                      iconColor: AppColors.success)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final d = _items[i];
                          return Card(
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                    left: BorderSide(
                                        color: AppColors.danger, width: 4)),
                              ),
                              child: ListTile(
                                leading: PlatformIcon(d.platform),
                                title: Text(d.deviceIdentifier),
                                subtitle: Text(
                                    'Owner: ${d.ownerOfficerId.substring(0, 8)}…'),
                                trailing: StatusBadge.device(d.status),
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => DeviceDetailScreen(
                                            deviceId: d.id))),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
