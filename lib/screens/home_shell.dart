import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import 'dashboard_screen.dart';
import 'alerts_screen.dart';
import 'devices_screen.dart';
import 'officers_screen.dart';
import 'more_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    // Officers vault is restricted to vault-reading roles; others see a reduced set.
    final canReadVault =
        auth.hasRole(['Admin', 'Operator', 'Auditor']);

    final tabs = <_Tab>[
      _Tab('Dashboard', Icons.dashboard_outlined, Icons.dashboard,
          const DashboardScreen()),
      _Tab('Alerts', Icons.notifications_outlined, Icons.notifications,
          const AlertsScreen()),
      _Tab('Devices', Icons.devices_outlined, Icons.devices, const DevicesScreen()),
      if (canReadVault)
        _Tab('Officers', Icons.badge_outlined, Icons.badge,
            const OfficersScreen()),
      _Tab('More', Icons.menu_outlined, Icons.menu, const MoreScreen()),
    ];

    final safeIndex = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  _Tab(this.label, this.icon, this.activeIcon, this.screen);
}
