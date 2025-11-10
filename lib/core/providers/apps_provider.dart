import 'package:flutter/foundation.dart';
import '../models/connected_app.dart';
import '../services/bunker_service.dart';
import '../services/nostr_service.dart';

class AppsProvider with ChangeNotifier {
  late final BunkerService _bunkerService;
  
  List<ConnectedApp> _apps = [];
  bool _isLoading = false;
  String? _error;

  List<ConnectedApp> get apps => _apps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AppsProvider(NostrService nostrService) {
    _bunkerService = BunkerService(nostrService);
  }

  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      _apps = await _bunkerService.getConnectedApps();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ConnectedApp> connectApp({
    required String appPubkey,
    required String appName,
    required List<String> permissions,
    String? icon,
    String? url,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final app = await _bunkerService.connectApp(
        appPubkey: appPubkey,
        appName: appName,
        permissions: permissions,
        icon: icon,
        url: url,
      );
      await loadApps();
      return app;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnectApp(String appId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _bunkerService.disconnectApp(appId);
      await loadApps();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  BunkerConnectionRequest? parseNostrConnectUri(String uri) {
    return _bunkerService.parseNostrConnectUri(uri);
  }

  BunkerConnectionRequest? parseBunkerUri(String uri) {
    return _bunkerService.parseBunkerUri(uri);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
