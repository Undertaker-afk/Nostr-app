
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/apps/pages/connected_apps_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/keys/pages/keys_page.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.vpn_key),
                label: 'Keys',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.app_registration),
                label: 'Apps',
              ),
            ],
            currentIndex: state.uri.toString() == '/keys' ? 0 : 1,
            onTap: (index) {
              if (index == 0) {
                context.go('/keys');
              } else {
                context.go('/apps');
              }
            },
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
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Nostr Key Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

