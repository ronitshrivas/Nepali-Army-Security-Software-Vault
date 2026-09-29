import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/policy.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../widgets/common.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});
  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  bool _loading = true;
  String? _error;
  List<PolicyDto> _policies = [];

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
      _policies = await context.read<VaultApi>().listPolicies();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PolicyFormScreen()));
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Policies'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New Policy'),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load policies',
                  subtitle: _error,
                  action:
                      FilledButton(onPressed: _load, child: const Text('Retry')))
              : _policies.isEmpty
                  ? const EmptyState(
                      icon: Icons.policy_outlined, title: 'No policies yet')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _policies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = _policies[i];
                          return Card(
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text([
                                if (p.minOsVersion != null)
                                  'Min OS ${p.minOsVersion}',
                                if (p.maxDaysSinceLastCheckIn != null)
                                  'Check-in ≤ ${p.maxDaysSinceLastCheckIn}d',
                                if (p.requireProtectionEnabled) 'Protection',
                                if (p.requireEncryption) 'Encryption',
                              ].join(' · ')),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class PolicyFormScreen extends StatefulWidget {
  const PolicyFormScreen({super.key});
  @override
  State<PolicyFormScreen> createState() => _PolicyFormScreenState();
}

class _PolicyFormScreenState extends State<PolicyFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _minOs = TextEditingController();
  final _maxCheckIn = TextEditingController();
  final _maxScan = TextEditingController();
  bool _protection = false;
  bool _encryption = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _desc, _minOs, _maxCheckIn, _maxScan]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<VaultApi>().createPolicy({
        'name': _name.text.trim(),
        'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'minOsVersion': _minOs.text.trim().isEmpty ? null : _minOs.text.trim(),
        'requireProtectionEnabled': _protection,
        'requireEncryption': _encryption,
        'maxDaysSinceLastScan': int.tryParse(_maxScan.text.trim()),
        'maxDaysSinceLastCheckIn': int.tryParse(_maxCheckIn.text.trim()),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Policy created')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Policy')),
      body: LoadingOverlay(
        visible: _loading,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _desc,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _minOs,
                decoration: const InputDecoration(
                    labelText: 'Minimum OS version (optional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _maxCheckIn,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Max days since last check-in'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _maxScan,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Max days since last scan'),
              ),
              SwitchListTile(
                title: const Text('Require protection enabled'),
                value: _protection,
                onChanged: (v) => setState(() => _protection = v),
              ),
              SwitchListTile(
                title: const Text('Require encryption'),
                value: _encryption,
                onChanged: (v) => setState(() => _encryption = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: const Text('Create policy')),
            ],
          ),
        ),
      ),
    );
  }
}
