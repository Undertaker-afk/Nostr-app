import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/keys_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/providers/apps_provider.dart';
import 'core/services/nostr_service.dart';
import 'features/apps/pages/connected_apps_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/keys/pages/keys_page.dart';
import 'features/wallet/pages/wallet_page.dart';
import 'features/groups/pages/groups_page.dart';
import 'features/marketplace/pages/marketplace_page.dart';

void main() {
  runApp(const MyApp());
}

final _nostrService = NostrService();

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        final currentPath = state.uri.path;
        int currentIndex = 0;
        
        if (currentPath == '/keys') {
          currentIndex = 0;
        } else if (currentPath == '/apps') {
          currentIndex = 1;
        } else if (currentPath == '/wallet') {
          currentIndex = 2;
        } else if (currentPath == '/groups') {
          currentIndex = 3;
        } else if (currentPath == '/marketplace') {
          currentIndex = 4;
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/keys');
                  break;
                case 1:
                  context.go('/apps');
                  break;
                case 2:
                  context.go('/wallet');
                  break;
                case 3:
                  context.go('/groups');
                  break;
                case 4:
                  context.go('/marketplace');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.vpn_key),
                label: 'Keys',
              ),
              NavigationDestination(
                icon: Icon(Icons.apps),
                label: 'Apps',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              NavigationDestination(
                icon: Icon(Icons.group),
                label: 'Groups',
              ),
              NavigationDestination(
                icon: Icon(Icons.store),
                label: 'Market',
              ),
            ],
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/keys',
          builder: (context, state) => const KeysPage(),
        ),
        GoRoute(
          path: '/apps',
          builder: (context, state) => const ConnectedAppsPage(),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          path: '/groups',
          builder: (context, state) => const GroupsPage(),
        ),
        GoRoute(
          path: '/marketplace',
          builder: (context, state) => const MarketplacePage(),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => KeysProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => AppsProvider(_nostrService)),
      ],
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'Nostr App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
      ),
    );
  }
}

