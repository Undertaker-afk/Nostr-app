import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/connected_app.dart';
import '../models/nostr_event.dart';
import '../storage/secure_storage.dart';
import 'crypto_service.dart';
import 'nostr_service.dart';

// NIP-46 Nostr Connect / Bunker Service
class BunkerService {
  final NostrService _nostrService;
  final SecureStorage _storage = SecureStorage();
  static const String _appsStorageKey = 'connected_apps';
  final _uuid = const Uuid();

  BunkerService(this._nostrService);

  // Parse nostrconnect:// URI
  BunkerConnectionRequest? parseNostrConnectUri(String uri) {
    try {
      if (!uri.startsWith('nostrconnect://')) {
        return null;
      }

      final uriObj = Uri.parse(uri);
      final pubkey = uriObj.host;
      final relay = uriObj.queryParameters['relay'];
      final metadata = uriObj.queryParameters['metadata'];
      final secret = uriObj.queryParameters['secret'];

      Map<String, dynamic>? metadataJson;
      if (metadata != null) {
        metadataJson = jsonDecode(metadata) as Map<String, dynamic>;
      }

      return BunkerConnectionRequest(
        pubkey: pubkey,
        relay: relay,
        metadata: metadataJson,
        secret: secret,
      );
    } catch (e) {
      print('Failed to parse nostrconnect URI: $e');
      return null;
    }
  }

  // Parse bunker:// URI
  BunkerConnectionRequest? parseBunkerUri(String uri) {
    try {
      if (!uri.startsWith('bunker://')) {
        return null;
      }

      final uriObj = Uri.parse(uri);
      final pubkey = uriObj.host;
      final relay = uriObj.queryParameters['relay'];
      final secret = uriObj.queryParameters['secret'];

      return BunkerConnectionRequest(
        pubkey: pubkey,
        relay: relay,
        secret: secret,
      );
    } catch (e) {
      print('Failed to parse bunker URI: $e');
      return null;
    }
  }

  // Connect an app
  Future<ConnectedApp> connectApp({
    required String appPubkey,
    required String appName,
    required List<String> permissions,
    String? icon,
    String? url,
  }) async {
    final app = ConnectedApp(
      id: _uuid.v4(),
      name: appName,
      pubkey: appPubkey,
      permissions: permissions,
      connectedAt: DateTime.now(),
      icon: icon,
      url: url,
    );

    await _saveApp(app);
    return app;
  }

  // Get all connected apps
  Future<List<ConnectedApp>> getConnectedApps() async {
    final appsJson = await _storage.read(_appsStorageKey);
    if (appsJson == null) return [];

    final appsList = jsonDecode(appsJson) as List;
    return appsList
        .map((a) => ConnectedApp.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  // Disconnect an app
  Future<void> disconnectApp(String appId) async {
    final apps = await getConnectedApps();
    apps.removeWhere((a) => a.id == appId);
    await _saveApps(apps);
  }

  // Update app last used
  Future<void> updateAppLastUsed(String appId) async {
    final apps = await getConnectedApps();
    final index = apps.indexWhere((a) => a.id == appId);
    if (index != -1) {
      apps[index] = apps[index].copyWith(lastUsed: DateTime.now());
      await _saveApps(apps);
    }
  }

  // Handle signing request from app
  Future<String?> handleSignRequest({
    required String appPubkey,
    required NostrEvent event,
    required String userPrivateKeyHex,
  }) async {
    // Check if app is connected
    final apps = await getConnectedApps();
    final app = apps.where((a) => a.pubkey == appPubkey).firstOrNull;

    if (app == null) {
      throw Exception('App not connected');
    }

    // Check permissions
    if (!app.permissions.contains('sign_event')) {
      throw Exception('App does not have sign_event permission');
    }

    // Sign the event
    final signature = CryptoService.sign(event.id, userPrivateKeyHex);
    await updateAppLastUsed(app.id);

    return signature;
  }

  // Handle encryption request
  Future<String?> handleEncryptRequest({
    required String appPubkey,
    required String content,
    required String recipientPubkey,
    required String userPrivateKeyHex,
  }) async {
    final apps = await getConnectedApps();
    final app = apps.where((a) => a.pubkey == appPubkey).firstOrNull;

    if (app == null) {
      throw Exception('App not connected');
    }

    if (!app.permissions.contains('nip04_encrypt')) {
      throw Exception('App does not have nip04_encrypt permission');
    }

    final encrypted = CryptoService.encrypt(
      content,
      userPrivateKeyHex,
      recipientPubkey,
    );
    await updateAppLastUsed(app.id);

    return encrypted;
  }

  // Handle decryption request
  Future<String?> handleDecryptRequest({
    required String appPubkey,
    required String encryptedContent,
    required String senderPubkey,
    required String userPrivateKeyHex,
  }) async {
    final apps = await getConnectedApps();
    final app = apps.where((a) => a.pubkey == appPubkey).firstOrNull;

    if (app == null) {
      throw Exception('App not connected');
    }

    if (!app.permissions.contains('nip04_decrypt')) {
      throw Exception('App does not have nip04_decrypt permission');
    }

    final decrypted = CryptoService.decrypt(
      encryptedContent,
      userPrivateKeyHex,
      senderPubkey,
    );
    await updateAppLastUsed(app.id);

    return decrypted;
  }

  // Process NIP-46 request
  Future<Map<String, dynamic>> processNip46Request({
    required Map<String, dynamic> request,
    required String userPrivateKeyHex,
  }) async {
    final method = request['method'] as String;
    final params = request['params'] as List;

    switch (method) {
      case 'sign_event':
        final eventJson = params[0] as Map<String, dynamic>;
        final event = NostrEvent.fromJson(eventJson);
        final signature = await handleSignRequest(
          appPubkey: request['appPubkey'] as String,
          event: event,
          userPrivateKeyHex: userPrivateKeyHex,
        );
        return {'result': signature};

      case 'nip04_encrypt':
        final content = params[0] as String;
        final recipientPubkey = params[1] as String;
        final encrypted = await handleEncryptRequest(
          appPubkey: request['appPubkey'] as String,
          content: content,
          recipientPubkey: recipientPubkey,
          userPrivateKeyHex: userPrivateKeyHex,
        );
        return {'result': encrypted};

      case 'nip04_decrypt':
        final encryptedContent = params[0] as String;
        final senderPubkey = params[1] as String;
        final decrypted = await handleDecryptRequest(
          appPubkey: request['appPubkey'] as String,
          encryptedContent: encryptedContent,
          senderPubkey: senderPubkey,
          userPrivateKeyHex: userPrivateKeyHex,
        );
        return {'result': decrypted};

      case 'get_public_key':
        final pubkey = CryptoService.getPublicKey(userPrivateKeyHex);
        return {'result': pubkey};

      default:
        throw Exception('Unknown method: $method');
    }
  }

  Future<void> _saveApp(ConnectedApp app) async {
    final apps = await getConnectedApps();
    apps.add(app);
    await _saveApps(apps);
  }

  Future<void> _saveApps(List<ConnectedApp> apps) async {
    final appsJson = jsonEncode(apps.map((a) => a.toJson()).toList());
    await _storage.write(_appsStorageKey, appsJson);
  }
}

class BunkerConnectionRequest {
  final String pubkey;
  final String? relay;
  final Map<String, dynamic>? metadata;
  final String? secret;

  BunkerConnectionRequest({
    required this.pubkey,
    this.relay,
    this.metadata,
    this.secret,
  });

  String get appName => metadata?['name'] as String? ?? 'Unknown App';
  String? get appIcon => metadata?['icon'] as String?;
  String? get appUrl => metadata?['url'] as String?;
}
