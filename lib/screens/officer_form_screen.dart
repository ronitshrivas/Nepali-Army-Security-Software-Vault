import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/officer.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../widgets/common.dart';

class OfficerFormScreen extends StatefulWidget {
  final OfficerDetail? existing;
  const OfficerFormScreen({super.key, this.existing});
  bool get isEdit => existing != null;

  @override
  State<OfficerFormScreen> createState() => _OfficerFormScreenState();
}

class _OfficerFormScreenState extends State<OfficerFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _idNumber;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  late final TextEditingController _role;
  late final TextEditingController _unit;
  late final TextEditingController _assignment;
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _fullName = TextEditingController(text: e?.fullName ?? '');
    _idNumber = TextEditingController(text: e?.idNumber ?? '');
    _phone = TextEditingController(text: e?.contactPhone ?? '');
    _email = TextEditingController(text: e?.contactEmail ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _role = TextEditingController(text: e?.role ?? '');
    _unit = TextEditingController(text: e?.unit ?? '');
    _assignment = TextEditingController(text: e?.assignment ?? '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_fullName, _idNumber, _phone, _email, _notes, _role, _unit, _assignment]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final api = context.read<VaultApi>();
    final body = {
      'fullName': _fullName.text.trim(),
      'idNumber': _idNumber.text.trim(),
      'contactPhone': _phone.text.trim(),
      'contactEmail': _email.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'role': _role.text.trim(),
      'unit': _unit.text.trim(),
      'assignment': _assignment.text.trim(),
      if (widget.isEdit) 'isActive': _isActive,
    };
    try {
      if (widget.isEdit) {
        await api.updateOfficer(widget.existing!.id, body);
      } else {
        await api.createOfficer(body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isEdit ? 'Officer updated' : 'Officer created')));
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
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Officer' : 'New Officer')),
      body: LoadingOverlay(
        visible: _loading,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field(_fullName, 'Full name', required: true),
              _field(_idNumber, 'ID number', required: true),
              _field(_phone, 'Phone', required: true, keyboard: TextInputType.phone),
              _field(_email, 'Email', required: true, email: true),
              _field(_role, 'Rank / Role', required: true),
              _field(_unit, 'Unit', required: true),
              _field(_assignment, 'Assignment', required: true),
              _field(_notes, 'Notes (optional)', maxLines: 3),
              if (widget.isEdit)
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(widget.isEdit ? 'Save changes' : 'Create officer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool required = false,
      bool email = false,
      int maxLines = 1,
      TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return 'Required';
          if (email && v != null && v.isNotEmpty && !v.contains('@')) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
    );
  }
}
