import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/policy.dart';
import '../services/api_client.dart';
import '../services/vault_api.dart';
import '../widgets/common.dart';

class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({super.key});
  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  bool _loading = true;
  bool _enabling = false;
  String? _error;
  TotpSetup? _setup;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _setup = await context.read<VaultApi>().setupTotp();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enable() async {
    if (_code.text.trim().length < 6) return;
    setState(() => _enabling = true);
    try {
      await context.read<VaultApi>().enableTotp(_code.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Two-factor authentication enabled')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _enabling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not start setup',
                  subtitle: _error,
                  action:
                      FilledButton(onPressed: _load, child: const Text('Retry')))
              : LoadingOverlay(
                  visible: _enabling,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Scan this QR code with Google Authenticator, Authy, or any '
                        'TOTP app. Then enter the 6-digit code to confirm.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: QrImageView(
                            data: _setup!.provisioningUri,
                            size: 220,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _setup!.secret));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Secret copied')));
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: Text('Manual key: ${_setup!.secret}'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit code',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _enabling ? null : _enable,
                          child: const Text('Enable 2FA')),
                    ],
                  ),
                ),
    );
  }
}
