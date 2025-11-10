import 'dart:convert';
import 'package:http/http.dart' as http;
import 'crypto_service.dart';

class Nip05Service {
  // Verify NIP-05 identifier and get public key
  static Future<String?> verifyNip05(String identifier) async {
    try {
      // Parse identifier (name@domain.com)
      final parts = identifier.split('@');
      if (parts.length != 2) {
        throw Exception('Invalid NIP-05 format. Use: name@domain.com');
      }

      final name = parts[0];
      final domain = parts[1];

      // Fetch .well-known/nostr.json
      final url = 'https://$domain/.well-known/nostr.json?name=$name';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch NIP-05 data');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final names = data['names'] as Map<String, dynamic>?;

      if (names == null || !names.containsKey(name)) {
        throw Exception('Name not found in NIP-05 data');
      }

      final pubkeyHex = names[name] as String;
      return pubkeyHex;
    } catch (e) {
      print('NIP-05 verification failed: $e');
      return null;
    }
  }

  // Get NIP-05 identifier from public key
  static Future<String?> getNip05FromPubkey(String pubkeyHex) async {
    // This would require querying relays for kind 0 events
    // and checking the nip05 field in metadata
    // Implementation depends on NostrService
    return null;
  }

  // Validate NIP-05 format
  static bool isValidFormat(String identifier) {
    final regex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(identifier);
  }

  // Convert pubkey hex to npub
  static String pubkeyToNpub(String pubkeyHex) {
    return CryptoService.hexToNpub(pubkeyHex);
  }
}
