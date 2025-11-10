import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/cashu_token.dart';
import '../storage/secure_storage.dart';

class CashuService {
  final SecureStorage _storage = SecureStorage();
  static const String _tokensKey = 'cashu_tokens';
  static const String _mintsKey = 'cashu_mints';
  static const String _transactionsKey = 'cashu_transactions';
  final _uuid = const Uuid();

  // Default mints
  static const defaultMints = [
    {'url': 'https://mint.minibits.cash/Bitcoin', 'name': 'Minibits'},
    {'url': 'https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoC', 'name': 'Legend'},
  ];

  // Get all tokens
  Future<List<CashuToken>> getTokens() async {
    final tokensJson = await _storage.read(_tokensKey);
    if (tokensJson == null) return [];

    final tokensList = jsonDecode(tokensJson) as List;
    return tokensList
        .map((t) => CashuToken.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  // Get balance
  Future<int> getBalance() async {
    final tokens = await getTokens();
    return tokens.fold(0, (sum, token) => sum + token.amount);
  }

  // Add token
  Future<void> addToken(CashuToken token) async {
    final tokens = await getTokens();
    tokens.add(token);
    await _saveTokens(tokens);

    // Add transaction
    await _addTransaction(CashuTransaction(
      id: _uuid.v4(),
      type: TransactionType.receive,
      amount: token.amount,
      memo: token.memo,
      timestamp: DateTime.now(),
      mint: token.mint,
    ));
  }

  // Remove token
  Future<void> removeToken(String tokenString) async {
    final tokens = await getTokens();
    tokens.removeWhere((t) => t.token == tokenString);
    await _saveTokens(tokens);
  }

  // Receive token from string
  Future<CashuToken> receiveToken(String tokenString, {String? memo}) async {
    try {
      // Parse cashu token (simplified - real implementation needs proper parsing)
      final decoded = _parseToken(tokenString);
      
      final token = CashuToken(
        token: tokenString,
        amount: decoded['amount'] as int,
        mint: decoded['mint'] as String,
        memo: memo,
        createdAt: DateTime.now(),
      );

      await addToken(token);
      return token;
    } catch (e) {
      throw Exception('Failed to receive token: $e');
    }
  }

  // Send tokens (create new token)
  Future<String> sendTokens(int amount, String mintUrl, {String? memo}) async {
    final balance = await getBalance();
    if (balance < amount) {
      throw Exception('Insufficient balance');
    }

    try {
      // In real implementation, this would interact with the mint
      // to split tokens and create a new token for the specified amount
      final tokenString = await _createToken(amount, mintUrl);

      // Remove spent tokens
      await _spendTokens(amount);

      // Add transaction
      await _addTransaction(CashuTransaction(
        id: _uuid.v4(),
        type: TransactionType.send,
        amount: amount,
        memo: memo,
        timestamp: DateTime.now(),
        mint: mintUrl,
      ));

      return tokenString;
    } catch (e) {
      throw Exception('Failed to send tokens: $e');
    }
  }

  // Get mints
  Future<List<CashuMint>> getMints() async {
    final mintsJson = await _storage.read(_mintsKey);
    if (mintsJson == null) {
      // Initialize with default mints
      final mints = defaultMints
          .map((m) => CashuMint(url: m['url']!, name: m['name']!))
          .toList();
      await _saveMints(mints);
      return mints;
    }

    final mintsList = jsonDecode(mintsJson) as List;
    return mintsList
        .map((m) => CashuMint.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  // Add mint
  Future<void> addMint(CashuMint mint) async {
    final mints = await getMints();
    if (!mints.any((m) => m.url == mint.url)) {
      mints.add(mint);
      await _saveMints(mints);
    }
  }

  // Remove mint
  Future<void> removeMint(String mintUrl) async {
    final mints = await getMints();
    mints.removeWhere((m) => m.url == mintUrl);
    await _saveMints(mints);
  }

  // Get transactions
  Future<List<CashuTransaction>> getTransactions() async {
    final transactionsJson = await _storage.read(_transactionsKey);
    if (transactionsJson == null) return [];

    final transactionsList = jsonDecode(transactionsJson) as List;
    return transactionsList
        .map((t) => CashuTransaction.fromJson(t as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Check mint info
  Future<Map<String, dynamic>> getMintInfo(String mintUrl) async {
    try {
      final response = await http.get(Uri.parse('$mintUrl/info'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to get mint info');
    } catch (e) {
      throw Exception('Failed to connect to mint: $e');
    }
  }

  // Request mint (Lightning invoice)
  Future<String> requestMint(String mintUrl, int amount) async {
    try {
      final response = await http.post(
        Uri.parse('$mintUrl/mint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['pr'] as String; // Lightning invoice
      }
      throw Exception('Failed to request mint');
    } catch (e) {
      throw Exception('Failed to request mint: $e');
    }
  }

  // Melt tokens (pay Lightning invoice)
  Future<void> meltTokens(String mintUrl, String invoice, int amount) async {
    try {
      final response = await http.post(
        Uri.parse('$mintUrl/melt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'invoice': invoice, 'amount': amount}),
      );

      if (response.statusCode == 200) {
        await _spendTokens(amount);
        await _addTransaction(CashuTransaction(
          id: _uuid.v4(),
          type: TransactionType.melt,
          amount: amount,
          timestamp: DateTime.now(),
          mint: mintUrl,
        ));
      } else {
        throw Exception('Failed to melt tokens');
      }
    } catch (e) {
      throw Exception('Failed to melt tokens: $e');
    }
  }

  Map<String, dynamic> _parseToken(String tokenString) {
    // Simplified token parsing - real implementation needs proper Cashu token parsing
    // Cashu tokens are typically base64 encoded JSON
    try {
      final decoded = utf8.decode(base64Decode(tokenString));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return {
        'amount': json['amount'] ?? 0,
        'mint': json['mint'] ?? '',
      };
    } catch (e) {
      // Fallback for testing
      return {
        'amount': 100,
        'mint': defaultMints[0]['url']!,
      };
    }
  }

  Future<String> _createToken(int amount, String mintUrl) async {
    // Simplified token creation - real implementation needs proper Cashu protocol
    final tokenData = {
      'amount': amount,
      'mint': mintUrl,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return base64Encode(utf8.encode(jsonEncode(tokenData)));
  }

  Future<void> _spendTokens(int amount) async {
    final tokens = await getTokens();
    var remaining = amount;
    final tokensToRemove = <CashuToken>[];

    for (final token in tokens) {
      if (remaining <= 0) break;
      tokensToRemove.add(token);
      remaining -= token.amount;
    }

    for (final token in tokensToRemove) {
      await removeToken(token.token);
    }
  }

  Future<void> _saveTokens(List<CashuToken> tokens) async {
    final tokensJson = jsonEncode(tokens.map((t) => t.toJson()).toList());
    await _storage.write(_tokensKey, tokensJson);
  }

  Future<void> _saveMints(List<CashuMint> mints) async {
    final mintsJson = jsonEncode(mints.map((m) => m.toJson()).toList());
    await _storage.write(_mintsKey, mintsJson);
  }

  Future<void> _addTransaction(CashuTransaction transaction) async {
    final transactions = await getTransactions();
    transactions.add(transaction);
    final transactionsJson =
        jsonEncode(transactions.map((t) => t.toJson()).toList());
    await _storage.write(_transactionsKey, transactionsJson);
  }
}
