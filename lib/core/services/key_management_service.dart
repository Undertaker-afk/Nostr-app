import '../storage/secure_storage.dart';
import 'crypto_service.dart';
import 'dart:convert';

class KeyPair {
  final String npub;
  final String nsec;
  final String publicKeyHex;
  final String privateKeyHex;
  final String? name;

  KeyPair({
    required this.npub,
    required this.nsec,
    required this.publicKeyHex,
    required this.privateKeyHex,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'npub': npub,
      'nsec': nsec,
      'publicKeyHex': publicKeyHex,
      'privateKeyHex': privateKeyHex,
      'name': name,
    };
  }

  factory KeyPair.fromJson(Map<String, dynamic> json) {
    return KeyPair(
      npub: json['npub'] as String,
      nsec: json['nsec'] as String,
      publicKeyHex: json['publicKeyHex'] as String,
      privateKeyHex: json['privateKeyHex'] as String,
      name: json['name'] as String?,
    );
  }
}

class KeyManagementService {
  final SecureStorage _storage = SecureStorage();
  static const String _keysStorageKey = 'nostr_keys';
  static const String _activeKeyStorageKey = 'active_key';

  // Generate a new key pair
  Future<KeyPair> generateKeyPair({String? name}) async {
    final privateKeyHex = CryptoService.generatePrivateKey();
    final publicKeyHex = CryptoService.getPublicKey(privateKeyHex);
    final npub = CryptoService.hexToNpub(publicKeyHex);
    final nsec = CryptoService.hexToNsec(privateKeyHex);

    final keyPair = KeyPair(
      npub: npub,
      nsec: nsec,
      publicKeyHex: publicKeyHex,
      privateKeyHex: privateKeyHex,
      name: name,
    );

    await saveKeyPair(keyPair);
    return keyPair;
  }

  // Import key from nsec
  Future<KeyPair> importFromNsec(String nsec, {String? name}) async {
    final privateKeyHex = CryptoService.nsecToHex(nsec);
    final publicKeyHex = CryptoService.getPublicKey(privateKeyHex);
    final npub = CryptoService.hexToNpub(publicKeyHex);

    final keyPair = KeyPair(
      npub: npub,
      nsec: nsec,
      publicKeyHex: publicKeyHex,
      privateKeyHex: privateKeyHex,
      name: name,
    );

    await saveKeyPair(keyPair);
    return keyPair;
  }

  // Import key from hex private key
  Future<KeyPair> importFromHex(String privateKeyHex, {String? name}) async {
    final publicKeyHex = CryptoService.getPublicKey(privateKeyHex);
    final npub = CryptoService.hexToNpub(publicKeyHex);
    final nsec = CryptoService.hexToNsec(privateKeyHex);

    final keyPair = KeyPair(
      npub: npub,
      nsec: nsec,
      publicKeyHex: publicKeyHex,
      privateKeyHex: privateKeyHex,
      name: name,
    );

    await saveKeyPair(keyPair);
    return keyPair;
  }

  // Save key pair
  Future<void> saveKeyPair(KeyPair keyPair) async {
    final keys = await getAllKeys();
    keys.add(keyPair);
    final keysJson = jsonEncode(keys.map((k) => k.toJson()).toList());
    await _storage.write(_keysStorageKey, keysJson);
  }

  // Get all keys
  Future<List<KeyPair>> getAllKeys() async {
    final keysJson = await _storage.read(_keysStorageKey);
    if (keysJson == null) return [];

    final keysList = jsonDecode(keysJson) as List;
    return keysList.map((k) => KeyPair.fromJson(k as Map<String, dynamic>)).toList();
  }

  // Delete key
  Future<void> deleteKey(String npub) async {
    final keys = await getAllKeys();
    keys.removeWhere((k) => k.npub == npub);
    final keysJson = jsonEncode(keys.map((k) => k.toJson()).toList());
    await _storage.write(_keysStorageKey, keysJson);

    // If deleted key was active, clear active key
    final activeKey = await getActiveKey();
    if (activeKey?.npub == npub) {
      await _storage.delete(_activeKeyStorageKey);
    }
  }

  // Set active key
  Future<void> setActiveKey(String npub) async {
    await _storage.write(_activeKeyStorageKey, npub);
  }

  // Get active key
  Future<KeyPair?> getActiveKey() async {
    final npub = await _storage.read(_activeKeyStorageKey);
    if (npub == null) return null;

    final keys = await getAllKeys();
    try {
      return keys.firstWhere((k) => k.npub == npub);
    } catch (e) {
      return null;
    }
  }

  // Update key name
  Future<void> updateKeyName(String npub, String name) async {
    final keys = await getAllKeys();
    final index = keys.indexWhere((k) => k.npub == npub);
    if (index != -1) {
      keys[index] = KeyPair(
        npub: keys[index].npub,
        nsec: keys[index].nsec,
        publicKeyHex: keys[index].publicKeyHex,
        privateKeyHex: keys[index].privateKeyHex,
        name: name,
      );
      final keysJson = jsonEncode(keys.map((k) => k.toJson()).toList());
      await _storage.write(_keysStorageKey, keysJson);
    }
  }

  // Export key as QR data
  String exportAsQR(KeyPair keyPair) {
    return keyPair.nsec;
  }

  // Get key by npub
  Future<KeyPair?> getKeyByNpub(String npub) async {
    final keys = await getAllKeys();
    try {
      return keys.firstWhere((k) => k.npub == npub);
    } catch (e) {
      return null;
    }
  }
}
