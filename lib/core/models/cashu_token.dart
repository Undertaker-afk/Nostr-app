class CashuToken {
  final String token;
  final int amount;
  final String mint;
  final String? memo;
  final DateTime createdAt;

  CashuToken({
    required this.token,
    required this.amount,
    required this.mint,
    this.memo,
    required this.createdAt,
  });

  factory CashuToken.fromJson(Map<String, dynamic> json) {
    return CashuToken(
      token: json['token'] as String,
      amount: json['amount'] as int,
      mint: json['mint'] as String,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'amount': amount,
      'mint': mint,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CashuMint {
  final String url;
  final String name;
  final bool isActive;
  final List<int> supportedUnits;

  CashuMint({
    required this.url,
    required this.name,
    this.isActive = true,
    this.supportedUnits = const [1, 2, 4, 8, 16, 32, 64],
  });

  factory CashuMint.fromJson(Map<String, dynamic> json) {
    return CashuMint(
      url: json['url'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
      supportedUnits: (json['supportedUnits'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 4, 8, 16, 32, 64],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'isActive': isActive,
      'supportedUnits': supportedUnits,
    };
  }
}

class CashuTransaction {
  final String id;
  final TransactionType type;
  final int amount;
  final String? memo;
  final DateTime timestamp;
  final String? mint;

  CashuTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.memo,
    required this.timestamp,
    this.mint,
  });

  factory CashuTransaction.fromJson(Map<String, dynamic> json) {
    return CashuTransaction(
      id: json['id'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      amount: json['amount'] as int,
      memo: json['memo'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mint: json['mint'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'memo': memo,
      'timestamp': timestamp.toIso8601String(),
      'mint': mint,
    };
  }
}

enum TransactionType {
  receive,
  send,
  mint,
  melt,
}
