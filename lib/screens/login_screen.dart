import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../models/auth.dart';
import '../state/auth_state.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _totp = TextEditingController();

  bool _loading = false;
  bool _needTotp = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _totp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthState>();
    final result = await auth.login(
      _username.text.trim(),
      _password.text,
      totpCode: _needTotp ? _totp.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result.outcome) {
      case LoginOutcome.success:
        // AuthState notifies -> router swaps to the shell automatically.
        break;
      case LoginOutcome.twoFactorRequired:
        setState(() {
          _needTotp = true;
          _error = 'Enter the 6-digit code from your authenticator app.';
        });
        break;
      default:
        setState(() => _error = result.message ?? 'Login failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.forest, AppColors.bgDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VaultCrest(size: 84),
                    const SizedBox(height: 20),
                    Text(AppConfig.appName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      AppConfig.orgName.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.brass,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _username,
                                textInputAction: TextInputAction.next,
                                enabled: !_needTotp,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                enabled: !_needTotp,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              if (_needTotp) ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _totp,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Authenticator code',
                                    prefixIcon: Icon(Icons.pin_outlined),
                                    counterText: '',
                                  ),
                                  validator: (v) =>
                                      (_needTotp && (v == null || v.length < 6))
                                          ? 'Enter the 6-digit code'
                                          : null,
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.error.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: scheme.error
                                            .withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 18, color: scheme.error),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_error!,
                                            style: TextStyle(
                                                color: scheme.error,
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Text(_needTotp ? 'Verify & Sign in' : 'Sign in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Authorised personnel only. All access is audited.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
