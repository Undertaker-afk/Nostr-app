class ConnectedApp {
  final String id;
  final String name;
  final String pubkey;
  final List<String> permissions;
  final DateTime connectedAt;
  final DateTime? lastUsed;
  final String? icon;
  final String? url;

  ConnectedApp({
    required this.id,
    required this.name,
    required this.pubkey,
    required this.permissions,
    required this.connectedAt,
    this.lastUsed,
    this.icon,
    this.url,
  });

  factory ConnectedApp.fromJson(Map<String, dynamic> json) {
    return ConnectedApp(
      id: json['id'] as String,
      name: json['name'] as String,
      pubkey: json['pubkey'] as String,
      permissions: (json['permissions'] as List).map((e) => e.toString()).toList(),
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      icon: json['icon'] as String?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pubkey': pubkey,
      'permissions': permissions,
      'connectedAt': connectedAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'icon': icon,
      'url': url,
    };
  }

  ConnectedApp copyWith({
    String? id,
    String? name,
    String? pubkey,
    List<String>? permissions,
    DateTime? connectedAt,
    DateTime? lastUsed,
    String? icon,
    String? url,
  }) {
    return ConnectedApp(
      id: id ?? this.id,
      name: name ?? this.name,
      pubkey: pubkey ?? this.pubkey,
      permissions: permissions ?? this.permissions,
      connectedAt: connectedAt ?? this.connectedAt,
      lastUsed: lastUsed ?? this.lastUsed,
      icon: icon ?? this.icon,
      url: url ?? this.url,
    );
  }
}
