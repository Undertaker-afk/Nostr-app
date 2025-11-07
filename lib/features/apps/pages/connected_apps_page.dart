
import 'package:flutter/material.dart';

class ConnectedAppsPage extends StatefulWidget {
  const ConnectedAppsPage({super.key});

  @override
  State<ConnectedAppsPage> createState() => _ConnectedAppsPageState();
}

class _ConnectedAppsPageState extends State<ConnectedAppsPage> {
  // TODO: Replace with actual connected apps data
  final List<String> _connectedApps = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Apps'),
      ),
      body: ListView.builder(
        itemCount: _connectedApps.length,
        itemBuilder: (context, index) {
          final app = _connectedApps[index];
          return ListTile(
            title: Text(app),
            trailing: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // TODO: Implement app disconnection
              },
            ),
          );
        },
      ),
    );
  }
}
