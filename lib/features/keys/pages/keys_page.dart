
import 'package:flutter/material.dart';

import '../models/npub_nsec.dart';

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});

  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  // TODO: Replace with actual key data
  final List<NpubNsec> _keys = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keys'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement key generation/import
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _keys.length,
        itemBuilder: (context, index) {
          final key = _keys[index];
          return ListTile(
            title: Text(key.npub),
            subtitle: Text(key.nsec),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // TODO: Implement key deletion
              },
            ),
          );
        },
      ),
    );
  }
}
