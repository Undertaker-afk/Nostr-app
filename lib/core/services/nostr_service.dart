import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nostr_event.dart';
import '../models/nostr_filter.dart';
import '../models/nostr_relay.dart';
import 'crypto_service.dart';

class NostrService {
  final Map<String, WebSocketChannel> _connections = {};
  final Map<String, StreamController<NostrEvent>> _subscriptions = {};
  final List<NostrRelay> _relays = [];

  // Default relays
  static const defaultRelays = [
    'wss://relay.damus.io',
    'wss://relay.nostr.band',
    'wss://nos.lol',
    'wss://relay.snort.social',
  ];

  List<NostrRelay> get relays => _relays;

  // Connect to a relay
  Future<void> connectRelay(String url, {bool useTor = false}) async {
    if (_connections.containsKey(url)) return;

    try {
      final relay = NostrRelay(
        url: url,
        isOnion: url.contains('.onion'),
      );

      final uri = Uri.parse(url);
      final channel = WebSocketChannel.connect(uri);

      await channel.ready;

      relay.isConnected = true;
      relay.lastConnected = DateTime.now();

      _connections[url] = channel;
      _relays.add(relay);

      // Listen to messages
      channel.stream.listen(
        (message) => _handleMessage(url, message),
        onError: (error) => _handleError(url, error),
        onDone: () => _handleDisconnect(url),
      );
    } catch (e) {
      print('Failed to connect to relay $url: $e');
    }
  }

  // Disconnect from a relay
  void disconnectRelay(String url) {
    _connections[url]?.sink.close();
    _connections.remove(url);
    _relays.removeWhere((r) => r.url == url);
  }

  // Connect to default relays
  Future<void> connectDefaultRelays() async {
    for (final url in defaultRelays) {
      await connectRelay(url);
    }
  }

  // Publish an event
  Future<void> publishEvent(NostrEvent event) async {
    final message = jsonEncode(['EVENT', event.toJson()]);
    for (final channel in _connections.values) {
      channel.sink.add(message);
    }
  }

  // Subscribe to events
  String subscribe(NostrFilter filter, Function(NostrEvent) onEvent) {
    final subId = DateTime.now().millisecondsSinceEpoch.toString();
    final controller = StreamController<NostrEvent>();

    _subscriptions[subId] = controller;
    controller.stream.listen(onEvent);

    final message = jsonEncode(['REQ', subId, filter.toJson()]);
    for (final channel in _connections.values) {
      channel.sink.add(message);
    }

    return subId;
  }

  // Unsubscribe
  void unsubscribe(String subId) {
    final message = jsonEncode(['CLOSE', subId]);
    for (final channel in _connections.values) {
      channel.sink.add(message);
    }
    _subscriptions[subId]?.close();
    _subscriptions.remove(subId);
  }

  // Create and sign an event
  NostrEvent createEvent({
    required String privateKeyHex,
    required int kind,
    required String content,
    List<List<String>>? tags,
  }) {
    final pubkey = CryptoService.getPublicKey(privateKeyHex);
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final eventTags = tags ?? [];

    final id = NostrEvent.generateId(
      pubkey: pubkey,
      createdAt: createdAt,
      kind: kind,
      tags: eventTags,
      content: content,
    );

    final sig = CryptoService.sign(id, privateKeyHex);

    return NostrEvent(
      id: id,
      pubkey: pubkey,
      createdAt: createdAt,
      kind: kind,
      tags: eventTags,
      content: content,
      sig: sig,
    );
  }

  // Send a text note (kind 1)
  Future<void> sendTextNote(String privateKeyHex, String content) async {
    final event = createEvent(
      privateKeyHex: privateKeyHex,
      kind: 1,
      content: content,
    );
    await publishEvent(event);
  }

  // Send encrypted DM (kind 4)
  Future<void> sendEncryptedDM({
    required String privateKeyHex,
    required String recipientPubkey,
    required String content,
  }) async {
    final encryptedContent = CryptoService.encrypt(
      content,
      privateKeyHex,
      recipientPubkey,
    );

    final event = createEvent(
      privateKeyHex: privateKeyHex,
      kind: 4,
      content: encryptedContent,
      tags: [
        ['p', recipientPubkey]
      ],
    );

    await publishEvent(event);
  }

  // Get user metadata (kind 0)
  void getUserMetadata(String pubkey, Function(Map<String, dynamic>) onMetadata) {
    final filter = NostrFilter(
      authors: [pubkey],
      kinds: [0],
      limit: 1,
    );

    subscribe(filter, (event) {
      try {
        final metadata = jsonDecode(event.content) as Map<String, dynamic>;
        onMetadata(metadata);
      } catch (e) {
        print('Failed to parse metadata: $e');
      }
    });
  }

  // Set user metadata
  Future<void> setUserMetadata({
    required String privateKeyHex,
    String? name,
    String? about,
    String? picture,
    String? nip05,
  }) async {
    final metadata = <String, dynamic>{};
    if (name != null) metadata['name'] = name;
    if (about != null) metadata['about'] = about;
    if (picture != null) metadata['picture'] = picture;
    if (nip05 != null) metadata['nip05'] = nip05;

    final event = createEvent(
      privateKeyHex: privateKeyHex,
      kind: 0,
      content: jsonEncode(metadata),
    );

    await publishEvent(event);
  }

  void _handleMessage(String relayUrl, dynamic message) {
    try {
      final data = jsonDecode(message as String) as List;
      final type = data[0] as String;

      switch (type) {
        case 'EVENT':
          final subId = data[1] as String;
          final eventJson = data[2] as Map<String, dynamic>;
          final event = NostrEvent.fromJson(eventJson);
          _subscriptions[subId]?.add(event);
          break;
        case 'EOSE':
          // End of stored events
          break;
        case 'OK':
          // Event accepted
          break;
        case 'NOTICE':
          print('Notice from $relayUrl: ${data[1]}');
          break;
      }
    } catch (e) {
      print('Error handling message from $relayUrl: $e');
    }
  }

  void _handleError(String relayUrl, dynamic error) {
    print('Error from relay $relayUrl: $error');
    final relay = _relays.firstWhere((r) => r.url == relayUrl);
    relay.isConnected = false;
  }

  void _handleDisconnect(String relayUrl) {
    print('Disconnected from relay $relayUrl');
    final relay = _relays.firstWhere((r) => r.url == relayUrl);
    relay.isConnected = false;
    _connections.remove(relayUrl);
  }

  void dispose() {
    for (final channel in _connections.values) {
      channel.sink.close();
    }
    _connections.clear();
    for (final controller in _subscriptions.values) {
      controller.close();
    }
    _subscriptions.clear();
  }
}
