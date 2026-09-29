import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/officer.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';
import 'officer_form_screen.dart';

class OfficersScreen extends StatefulWidget {
  const OfficersScreen({super.key});
  @override
  State<OfficersScreen> createState() => _OfficersScreenState();
}

class _OfficersScreenState extends State<OfficersScreen> {
  bool _loading = true;
  String? _error;
  List<OfficerListItem> _items = [];
  final _search = TextEditingController();

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context
          .read<VaultApi>()
          .searchOfficers(q: _search.text.trim(), pageSize: 100);
      _items = page.items;
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(OfficerListItem o) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => OfficerDetailScreen(officerId: o.id),
    ));
    if (changed == true) _load();
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const OfficerFormScreen()));
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate =
        context.watch<AuthState>().hasRole(['Admin', 'Operator']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officers'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('New'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search by unit, role, assignment…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward), onPressed: _load),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? EmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load officers',
                        subtitle: _error,
                        action: FilledButton(
                            onPressed: _load, child: const Text('Retry')))
                    : _items.isEmpty
                        ? const EmptyState(
                            icon: Icons.badge_outlined,
                            title: 'No officers found')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _OfficerCard(
                                  _items[i], () => _openDetail(_items[i])),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _OfficerCard extends StatelessWidget {
  final OfficerListItem o;
  final VoidCallback onTap;
  const _OfficerCard(this.o, this.onTap);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.olive,
                child: Text(o.role.isNotEmpty ? o.role[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.role,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${o.unit} · ${o.assignment}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              StatusBadge(
                label: o.isActive ? 'Active' : 'Inactive',
                color: o.isActive ? AppColors.success : AppColors.neutral,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfficerDetailScreen extends StatefulWidget {
  final String officerId;
  const OfficerDetailScreen({super.key, required this.officerId});
  @override
  State<OfficerDetailScreen> createState() => _OfficerDetailScreenState();
}

class _OfficerDetailScreenState extends State<OfficerDetailScreen> {
  bool _loading = true;
  String? _error;
  OfficerDetail? _o;
  bool _changed = false;

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
      _o = await context.read<VaultApi>().getOfficer(widget.officerId);
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => OfficerFormScreen(existing: _o)));
    if (saved == true) {
      _changed = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<AuthState>().hasRole(['Admin', 'Operator']);
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          title: const Text('Officer Record'),
          actions: [
            if (canEdit && _o != null)
              IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
          ],
        ),
        body: _loading
            ? const LoadingView()
            : _error != null
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load record',
                    subtitle: _error,
                    action: FilledButton(
                        onPressed: _load, child: const Text('Retry')))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(_o!.role,
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                          ),
                          StatusBadge(
                            label: _o!.isActive ? 'Active' : 'Inactive',
                            color: _o!.isActive
                                ? AppColors.success
                                : AppColors.neutral,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      RevealableText(label: 'Full name', value: _o!.fullName),
                      RevealableText(label: 'ID number', value: _o!.idNumber),
                      RevealableText(label: 'Phone', value: _o!.contactPhone),
                      RevealableText(label: 'Email', value: _o!.contactEmail),
                      InfoRow(label: 'Unit', value: _o!.unit, copyable: true),
                      InfoRow(label: 'Assignment', value: _o!.assignment),
                      if (_o!.notes != null && _o!.notes!.isNotEmpty)
                        InfoRow(label: 'Notes', value: _o!.notes!),
                    ],
                  ),
    );
  }
}
