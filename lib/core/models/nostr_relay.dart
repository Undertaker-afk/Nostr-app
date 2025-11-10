class NostrRelay {
  final String url;
  final bool isOnion;
  bool isConnected;
  DateTime? lastConnected;

  NostrRelay({
    required this.url,
    this.isOnion = false,
    this.isConnected = false,
    this.lastConnected,
  });

  factory NostrRelay.fromJson(Map<String, dynamic> json) {
    return NostrRelay(
      url: json['url'] as String,
      isOnion: json['isOnion'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? false,
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'isOnion': isOnion,
      'isConnected': isConnected,
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }
}
