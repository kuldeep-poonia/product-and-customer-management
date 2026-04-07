import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/auth_screen.dart';
import '../screens/backup/backup_screen.dart';
import '../screens/billing/billing_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/khata/khata_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';

final _shellKey = GlobalKey<NavigatorState>();

// ✅ Accept Ref instead of WidgetRef
GoRouter buildRouter(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == '/login';
      final isAuthenticated =
          authState.status == AuthStatus.authenticated;
      final isUnknown = authState.status == AuthStatus.unknown;

      if (isUnknown) return null;

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (c, s) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (ctx, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/khata',
            builder: (c, s) => const KhataScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (c, s) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (c, s) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (c, s) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (c, s) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/billing',
        builder: (c, s) => const BillingScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        builder: (c, s) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (c, s) => const BackupScreen(),
      ),
    ],
  );
}

// ✅ No casting needed
final routerProvider = Provider<GoRouter>((ref) {
  return buildRouter(ref);
});

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    '/',
    '/khata',
    '/inventory',
    '/orders',
    '/reports',
    '/settings',
  ];

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.book_outlined),
      activeIcon: Icon(Icons.book),
      label: 'Khata',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_outlined),
      activeIcon: Icon(Icons.inventory_2),
      label: 'Stock',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.delivery_dining_outlined),
      activeIcon: Icon(Icons.delivery_dining),
      label: 'Orders',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_outlined),
      activeIcon: Icon(Icons.bar_chart),
      label: 'Reports',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  int _indexFromLocation(String location) {
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (idx) => context.go(_tabs[idx]),
        items: _items,
      ),
    );
  }
}