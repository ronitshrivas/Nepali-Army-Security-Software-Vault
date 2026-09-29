// Smoke test for the Secure Officer Vault app.
//
// Renders the login screen in isolation (with the app theme and a minimal auth
// provider) and confirms the sign-in UI builds. This avoids touching platform
// channels such as secure storage, which are not available in the test harness.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vault_security_software/core/theme.dart';
import 'package:vault_security_software/screens/login_screen.dart';
import 'package:vault_security_software/services/token_store.dart';
import 'package:vault_security_software/services/api_client.dart';
import 'package:vault_security_software/services/vault_api.dart';
import 'package:vault_security_software/state/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login screen renders the sign-in form', (tester) async {
    final store = TokenStore();
    final api = VaultApi(ApiClient(store));
    final auth = AuthState(store, api);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthState>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Secure Officer Vault'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
