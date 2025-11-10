import 'package:flutter/foundation.dart';
import '../services/key_management_service.dart';

class KeysProvider with ChangeNotifier {
  final KeyManagementService _keyService = KeyManagementService();
  
  List<KeyPair> _keys = [];
  bool _isLoading = false;
  String? _error;

  List<KeyPair> get keys => _keys;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadKeys() async {
    _isLoading = true;
    notifyListeners();

    try {
      _keys = await _keyService.getAllKeys();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<KeyPair> generateKey({String? name}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final key = await _keyService.generateKeyPair(name: name);
      await loadKeys();
      return key;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<KeyPair> importFromNsec(String nsec, {String? name}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final key = await _keyService.importFromNsec(nsec, name: name);
      await loadKeys();
      return key;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteKey(String npub) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _keyService.deleteKey(npub);
      await loadKeys();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateKeyName(String npub, String name) async {
    try {
      await _keyService.updateKeyName(npub, name);
      await loadKeys();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
