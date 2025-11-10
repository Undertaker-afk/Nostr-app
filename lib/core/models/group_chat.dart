// NIP-29 Group Chat Models

class GroupChat {
  final String id;
  final String name;
  final String? description;
  final String? picture;
  final bool isPrivate;
  final List<String> admins;
  final List<String> members;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  GroupChat({
    required this.id,
    required this.name,
    this.description,
    this.picture,
    this.isPrivate = false,
    required this.admins,
    required this.members,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      picture: json['picture'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      admins: (json['admins'] as List).map((e) => e.toString()).toList(),
      members: (json['members'] as List).map((e) => e.toString()).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'picture': picture,
      'isPrivate': isPrivate,
      'admins': admins,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }

  GroupChat copyWith({
    String? id,
    String? name,
    String? description,
    String? picture,
    bool? isPrivate,
    List<String>? admins,
    List<String>? members,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) {
    return GroupChat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picture: picture ?? this.picture,
      isPrivate: isPrivate ?? this.isPrivate,
      admins: admins ?? this.admins,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

class GroupMessage {
  final String id;
  final String groupId;
  final String authorPubkey;
  final String content;
  final DateTime timestamp;
  final List<String> mentions;
  final String? replyTo;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.authorPubkey,
    required this.content,
    required this.timestamp,
    this.mentions = const [],
    this.replyTo,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      authorPubkey: json['authorPubkey'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mentions: (json['mentions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      replyTo: json['replyTo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'authorPubkey': authorPubkey,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'mentions': mentions,
      'replyTo': replyTo,
    };
  }
}
