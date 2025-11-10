
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/keys_provider.dart';
import '../../../core/providers/auth_provider.dart';

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KeysProvider>().loadKeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keys'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddKeyDialog(context),
          ),
        ],
      ),
      body: Consumer2<KeysProvider, AuthProvider>(
        builder: (context, keysProvider, authProvider, child) {
          if (keysProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (keysProvider.keys.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.vpn_key_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No keys found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddKeyDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Key'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: keysProvider.keys.length,
            itemBuilder: (context, index) {
              final key = keysProvider.keys[index];
              final isActive = authProvider.activeKey?.npub == key.npub;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.grey,
                    child: Icon(
                      isActive ? Icons.check : Icons.vpn_key,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    key.name ?? 'Unnamed Key',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${key.npub.substring(0, 16)}...',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy_npub',
                        child: Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Copy npub'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy_nsec',
                        child: Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Copy nsec'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'qr',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code),
                            SizedBox(width: 8),
                            Text('Show QR'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Rename'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'copy_npub':
                          _copyToClipboard(context, key.npub, 'npub');
                          break;
                        case 'copy_nsec':
                          _copyToClipboard(context, key.nsec, 'nsec');
                          break;
                        case 'qr':
                          _showQRDialog(context, key);
                          break;
                        case 'rename':
                          _showRenameDialog(context, key);
                          break;
                        case 'delete':
                          _confirmDelete(context, key);
                          break;
                      }
                    },
                  ),
                  onTap: isActive
                      ? null
                      : () => authProvider.loginWithKey(key.npub),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Generate New Key'),
              onTap: () {
                Navigator.pop(context);
                _generateKey(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Import from nsec'),
              onTap: () {
                Navigator.pop(context);
                _showImportDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateKey(BuildContext context) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Key'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Key Name (optional)',
            hintText: 'My Key',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (name != null && context.mounted) {
      await context.read<KeysProvider>().generateKey(
            name: name.isEmpty ? null : name,
          );
    }
  }

  void _showImportDialog(BuildContext context) {
    final nsecController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nsecController,
              decoration: const InputDecoration(
                labelText: 'Private Key (nsec)',
                hintText: 'nsec1...',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Key Name (optional)',
                hintText: 'My Key',
              ),
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
              final nsec = nsecController.text.trim();
              final name = nameController.text.trim();
              Navigator.pop(context);

              if (nsec.isNotEmpty) {
                try {
                  await context.read<KeysProvider>().importFromNsec(
                        nsec,
                        name: name.isEmpty ? null : name,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Key imported successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to import: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  void _showQRDialog(BuildContext context, key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${key.name ?? "Key"} QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: key.nsec,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan to import private key',
              style: TextStyle(color: Colors.grey),
            ),
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

  void _showRenameDialog(BuildContext context, key) {
    final controller = TextEditingController(text: key.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Key Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<KeysProvider>().updateKeyName(key.npub, name);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Key'),
        content: Text('Are you sure you want to delete "${key.name ?? "this key"}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<KeysProvider>().deleteKey(key.npub);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
