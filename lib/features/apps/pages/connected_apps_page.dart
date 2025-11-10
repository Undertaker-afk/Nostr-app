
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/apps_provider.dart';
import '../../../core/services/nostr_service.dart';

class ConnectedAppsPage extends StatefulWidget {
  const ConnectedAppsPage({super.key});

  @override
  State<ConnectedAppsPage> createState() => _ConnectedAppsPageState();
}

class _ConnectedAppsPageState extends State<ConnectedAppsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppsProvider>().loadApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _showConnectDialog(context),
          ),
        ],
      ),
      body: Consumer<AppsProvider>(
        builder: (context, appsProvider, child) {
          if (appsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appsProvider.apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apps_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No connected apps',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect apps using nostrconnect:// or bunker:// URIs',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showConnectDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Connect App'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: appsProvider.apps.length,
            itemBuilder: (context, index) {
              final app = appsProvider.apps[index];
              final dateFormat = DateFormat('MMM d, y');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: app.icon != null
                        ? Image.network(app.icon!, errorBuilder: (_, __, ___) {
                            return const Icon(Icons.apps, color: Colors.white);
                          })
                        : const Icon(Icons.apps, color: Colors.white),
                  ),
                  title: Text(
                    app.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected: ${dateFormat.format(app.connectedAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (app.lastUsed != null)
                        Text(
                          'Last used: ${dateFormat.format(app.lastUsed!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: app.permissions
                            .map((p) => Chip(
                                  label: Text(
                                    p,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () => _confirmDisconnect(context, app),
                  ),
                  onTap: () => _showAppDetails(context, app),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showConnectDialog(BuildContext context) {
    final uriController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uriController,
              decoration: const InputDecoration(
                labelText: 'Connection URI',
                hintText: 'nostrconnect:// or bunker://',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Paste the connection URI from the app you want to connect',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final uri = uriController.text.trim();
              Navigator.pop(context);

              if (uri.isNotEmpty) {
                await _connectApp(context, uri);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectApp(BuildContext context, String uri) async {
    final appsProvider = context.read<AppsProvider>();
    
    BunkerConnectionRequest? request;
    if (uri.startsWith('nostrconnect://')) {
      request = appsProvider.parseNostrConnectUri(uri);
    } else if (uri.startsWith('bunker://')) {
      request = appsProvider.parseBunkerUri(uri);
    }

    if (request == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid connection URI')),
        );
      }
      return;
    }

    // Show permission dialog
    final permissions = await showDialog<List<String>>(
      context: context,
      builder: (context) => _PermissionDialog(appName: request.appName),
    );

    if (permissions != null && context.mounted) {
      try {
        await appsProvider.connectApp(
          appPubkey: request.pubkey,
          appName: request.appName,
          permissions: permissions,
          icon: request.appIcon,
          url: request.appUrl,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${request.appName} connected successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect: $e')),
          );
        }
      }
    }
  }

  void _showAppDetails(BuildContext context, app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(app.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (app.url != null) ...[
              const Text('URL:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(app.url!),
              const SizedBox(height: 8),
            ],
            const Text('Public Key:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${app.pubkey.substring(0, 16)}...',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...app.permissions.map((p) => Text('• $p')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect App'),
        content: Text('Are you sure you want to disconnect "${app.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppsProvider>().disconnectApp(app.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _PermissionDialog extends StatefulWidget {
  final String appName;

  const _PermissionDialog({required this.appName});

  @override
  State<_PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<_PermissionDialog> {
  final Map<String, bool> _permissions = {
    'sign_event': true,
    'nip04_encrypt': false,
    'nip04_decrypt': false,
    'get_public_key': true,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Grant Permissions to ${widget.appName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _permissions.entries.map((entry) {
          return CheckboxListTile(
            title: Text(entry.key),
            value: entry.value,
            onChanged: (value) {
              setState(() {
                _permissions[entry.key] = value ?? false;
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final granted = _permissions.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList();
            Navigator.pop(context, granted);
          },
          child: const Text('Grant'),
        ),
      ],
    );
  }
}
