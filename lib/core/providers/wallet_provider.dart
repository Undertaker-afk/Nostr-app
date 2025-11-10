import 'package:flutter/foundation.dart';
import '../models/cashu_token.dart';
import '../services/cashu_service.dart';

class WalletProvider with ChangeNotifier {
  final CashuService _cashuService = CashuService();
  
  int _balance = 0;
  List<CashuTransaction> _transactions = [];
  List<CashuMint> _mints = [];
  bool _isLoading = false;
  String? _error;

  int get balance => _balance;
  List<CashuTransaction> get transactions => _transactions;
  List<CashuMint> get mints => _mints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadBalance();
      await loadTransactions();
      await loadMints();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBalance() async {
    try {
      _balance = await _cashuService.getBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTransactions() async {
    try {
      _transactions = await _cashuService.getTransactions();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMints() async {
    try {
      _mints = await _cashuService.getMints();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> receiveToken(String tokenString, {String? memo}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _cashuService.receiveToken(tokenString, memo: memo);
      await loadBalance();
      await loadTransactions();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> sendTokens(int amount, String mintUrl, {String? memo}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _cashuService.sendTokens(amount, mintUrl, memo: memo);
      await loadBalance();
      await loadTransactions();
      return token;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMint(String url, String name) async {
    try {
      final mint = CashuMint(url: url, name: name);
      await _cashuService.addMint(mint);
      await loadMints();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeMint(String url) async {
    try {
      await _cashuService.removeMint(url);
      await loadMints();
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
