import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/audit.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../widgets/common.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  bool _loading = true;
  String? _error;
  List<AuditEntry> _items = [];
  bool? _chainIntact;
  int? _brokenAt;

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
      _items = await context.read<VaultApi>().auditLog(pageSize: 100);
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    try {
      final r = await context.read<VaultApi>().verifyChain();
      setState(() {
        _chainIntact = r.intact;
        _brokenAt = r.firstBrokenEntryId;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.intact
            ? 'Chain intact — no tampering.'
            : 'Chain BROKEN at entry ${r.firstBrokenEntryId}.'),
        backgroundColor: r.intact ? AppColors.success : AppColors.danger,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM · HH:mm:ss');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      _chainIntact == null
                          ? Icons.verified_user_outlined
                          : _chainIntact!
                              ? Icons.verified_outlined
                              : Icons.gpp_bad,
                      color: _chainIntact == false
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _chainIntact == null
                            ? 'Verify the hash chain to detect tampering.'
                            : _chainIntact!
                                ? 'Chain intact — no tampering detected.'
                                : 'Chain BROKEN at entry $_brokenAt.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    FilledButton(onPressed: _verify, child: const Text('Verify')),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? MessageView(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load audit log',
                        subtitle: _error,
                        action: FilledButton(
                            onPressed: _load, child: const Text('Retry')))
                    : _items.isEmpty
                        ? const MessageView(
                            icon: Icons.receipt_long_outlined,
                            title: 'No audit entries')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final e = _items[i];
                              return ListTile(
                                dense: true,
                                title: Text(e.action,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                subtitle: Text([
                                  e.actorUsername ?? 'system',
                                  if (e.targetType != null)
                                    '→ ${e.targetType}',
                                  if (e.detail != null) e.detail,
                                ].join('  ')),
                                trailing: Text(fmt.format(e.timestamp.toLocal()),
                                    style: const TextStyle(fontSize: 11)),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
