import 'package:flutter/foundation.dart';
import '../services/key_management_service.dart';
import '../services/nip05_service.dart';
import '../services/nostr_service.dart';

class AuthProvider with ChangeNotifier {
  final KeyManagementService _keyService = KeyManagementService();
  final NostrService _nostrService = NostrService();
  
  KeyPair? _activeKey;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  KeyPair? get activeKey => _activeKey;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeKey = await _keyService.getActiveKey();
      _isAuthenticated = _activeKey != null;
      
      if (_isAuthenticated) {
        await _nostrService.connectDefaultRelays();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithNip05(String identifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!Nip05Service.isValidFormat(identifier)) {
        throw Exception('Invalid NIP-05 format');
      }

      final pubkeyHex = await Nip05Service.verifyNip05(identifier);
      if (pubkeyHex == null) {
        throw Exception('Failed to verify NIP-05 identifier');
      }

      // Check if we have this key
      final npub = Nip05Service.pubkeyToNpub(pubkeyHex);
      final key = await _keyService.getKeyByNpub(npub);

      if (key == null) {
        throw Exception('Key not found. Please import your private key first.');
      }

      await _keyService.setActiveKey(npub);
      _activeKey = key;
      _isAuthenticated = true;
      
      await _nostrService.connectDefaultRelays();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithKey(String npub) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final key = await _keyService.getKeyByNpub(npub);
      if (key == null) {
        throw Exception('Key not found');
      }

      await _keyService.setActiveKey(npub);
      _activeKey = key;
      _isAuthenticated = true;
      
      await _nostrService.connectDefaultRelays();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _activeKey = null;
    _isAuthenticated = false;
    _nostrService.dispose();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
