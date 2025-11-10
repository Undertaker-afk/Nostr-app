
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/keys_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nip05Controller = TextEditingController();
  final _nsecController = TextEditingController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _nip05Controller.dispose();
    _nsecController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Login'),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.vpn_key,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Nostr',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Decentralized social protocol',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Tab selector
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('NIP-05'),
                      icon: Icon(Icons.alternate_email),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Import Key'),
                      icon: Icon(Icons.key),
                    ),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedTab = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                if (_selectedTab == 0) ...[
                  // NIP-05 Login
                  TextField(
                    controller: _nip05Controller,
                    decoration: const InputDecoration(
                      labelText: 'NIP-05 Identifier',
                      hintText: 'name@domain.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _loginWithNip05(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Login with NIP-05'),
                  ),
                ] else ...[
                  // Import Key
                  TextField(
                    controller: _nsecController,
                    decoration: const InputDecoration(
                      labelText: 'Private Key (nsec)',
                      hintText: 'nsec1...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _importAndLogin(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Import & Login'),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                OutlinedButton.icon(
                  onPressed: () => _generateNewKey(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Generate New Key'),
                ),

                if (authProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loginWithNip05(BuildContext context) async {
    final identifier = _nip05Controller.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a NIP-05 identifier')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.loginWithNip05(identifier);

    if (authProvider.isAuthenticated && context.mounted) {
      context.go('/keys');
    }
  }

  Future<void> _importAndLogin(BuildContext context) async {
    final nsec = _nsecController.text.trim();
    if (nsec.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a private key')),
      );
      return;
    }

    try {
      final keysProvider = context.read<KeysProvider>();
      final key = await keysProvider.importFromNsec(nsec);
      
      if (context.mounted) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.loginWithKey(key.npub);
        
        if (authProvider.isAuthenticated && context.mounted) {
          context.go('/keys');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import key: $e')),
        );
      }
    }
  }

  Future<void> _generateNewKey(BuildContext context) async {
    try {
      final keysProvider = context.read<KeysProvider>();
      final key = await keysProvider.generateKey(name: 'My Key');
      
      if (context.mounted) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.loginWithKey(key.npub);
        
        if (authProvider.isAuthenticated && context.mounted) {
          context.go('/keys');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate key: $e')),
        );
      }
    }
  }
}
