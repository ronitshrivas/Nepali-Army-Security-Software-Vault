import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/officer.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../widgets/common.dart';

const _platforms = ['Windows', 'Android', 'IOS', 'MacOS', 'Linux'];

class EnrollDeviceScreen extends StatefulWidget {
  const EnrollDeviceScreen({super.key});
  @override
  State<EnrollDeviceScreen> createState() => _EnrollDeviceScreenState();
}

class _EnrollDeviceScreenState extends State<EnrollDeviceScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _osVersion = TextEditingController();
  final _engine = TextEditingController();
  final _publicKey = TextEditingController();
  String _platform = 'Windows';
  bool _protection = false;
  bool _encryption = false;
  OfficerListItem? _owner;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_identifier, _osVersion, _engine, _publicKey]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickOwner() async {
    final chosen = await showModalBottomSheet<OfficerListItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _OwnerPicker(),
    );
    if (chosen != null) setState(() => _owner = chosen);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_owner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select an owner officer')));
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await context.read<VaultApi>().enrollDevice({
        'deviceIdentifier': _identifier.text.trim(),
        'platform': _platform,
        'osVersion': _osVersion.text.trim(),
        'ownerOfficerId': _owner!.id,
        'publicKeyPem': _publicKey.text.trim(),
        'protectionEngine':
            _engine.text.trim().isEmpty ? null : _engine.text.trim(),
        'protectionEnabled': _protection,
        'encryptionEnabled': _encryption,
      });
      if (!mounted) return;
      await _showToken(resp.attestationToken);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showToken(String token) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enrollment Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This token is shown only once. Save it now and give it to the '
              'device agent — it cannot be retrieved again.',
              style: TextStyle(color: AppColors.warning, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(token,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Token copied')));
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Token'),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enroll Device')),
      body: LoadingOverlay(
        visible: _loading,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _identifier,
                decoration: const InputDecoration(
                    labelText: 'Device identifier (hostname / serial)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _platform,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: _platforms
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _platform = v ?? _platform),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _osVersion,
                decoration: const InputDecoration(labelText: 'OS version'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(_owner == null
                      ? 'Select owner officer'
                      : '${_owner!.role} · ${_owner!.unit}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickOwner,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _engine,
                decoration: const InputDecoration(
                    labelText: 'Protection engine (optional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _publicKey,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Public key (PEM)',
                  hintText:
                      'In production this is generated by the device agent. Paste its public key here.',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SwitchListTile(
                title: const Text('Protection enabled'),
                value: _protection,
                onChanged: (v) => setState(() => _protection = v),
              ),
              SwitchListTile(
                title: const Text('Encryption enabled'),
                value: _encryption,
                onChanged: (v) => setState(() => _encryption = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: const Text('Enroll device')),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerPicker extends StatefulWidget {
  const _OwnerPicker();
  @override
  State<_OwnerPicker> createState() => _OwnerPickerState();
}

class _OwnerPickerState extends State<_OwnerPicker> {
  final _search = TextEditingController();
  bool _loading = true;
  List<OfficerListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await context
          .read<VaultApi>()
          .searchOfficers(q: _search.text.trim(), pageSize: 50);
      _items = page.items;
    } catch (_) {
      _items = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Search officers…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward), onPressed: _load),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: _loading
                ? const LoadingView()
                : _items.isEmpty
                    ? const EmptyState(
                        icon: Icons.badge_outlined, title: 'No officers')
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final o = _items[i];
                          return ListTile(
                            title: Text(o.role),
                            subtitle: Text('${o.unit} · ${o.assignment}'),
                            onTap: () => Navigator.pop(context, o),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
