import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'services/token_store.dart';
import 'services/api_client.dart';
import 'services/vault_api.dart';
import 'state/auth_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'widgets/common.dart';

void main() {
  // Platform channels (secure storage) are touched during bootstrap, before
  // runApp, so the binding must be initialized first.
  WidgetsFlutterBinding.ensureInitialized();

  final store = TokenStore();
  final apiClient = ApiClient(store);
  final api = VaultApi(apiClient);
  final auth = AuthState(store, api);

  // When a token refresh fails mid-session, drop back to the login screen.
  apiClient.onAuthLost = () => auth.forceSignOut();

  auth.bootstrap();

  runApp(VaultApp(auth: auth, api: api));
}

class VaultApp extends StatelessWidget {
  final AuthState auth;
  final VaultApi api;
  const VaultApp({super.key, required this.auth, required this.api});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        Provider.value(value: api),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthState>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: LoadingView());
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const HomeShell();
    }
  }
}
