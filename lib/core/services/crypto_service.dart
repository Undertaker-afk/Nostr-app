import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:bech32/bech32.dart';

class CryptoService {
  static final _secureRandom = FortunaRandom();
  static bool _initialized = false;

  static void _initRandom() {
    if (_initialized) return;
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    _secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    _initialized = true;
  }

  // Generate a new private key
  static String generatePrivateKey() {
    _initRandom();
    final keyParams = ECKeyGeneratorParameters(ECCurve_secp256k1());
    final generator = ECKeyGenerator();
    generator.init(ParametersWithRandom(keyParams, _secureRandom));
    final keyPair = generator.generateKeyPair();
    final privateKey = keyPair.privateKey as ECPrivateKey;
    return HEX.encode(privateKey.d!.toRadixString(16).padLeft(64, '0').codeUnits);
  }

  // Get public key from private key
  static String getPublicKey(String privateKeyHex) {
    final privateKeyInt = BigInt.parse(privateKeyHex, radix: 16);
    final params = ECCurve_secp256k1();
    final point = params.G * privateKeyInt;
    final x = point!.x!.toBigInteger()!.toRadixString(16).padLeft(64, '0');
    return x;
  }

  // Convert hex to npub (bech32)
  static String hexToNpub(String hex) {
    final data = HEX.decode(hex);
    final words = _convertBits(data, 8, 5, true);
    final bech32Data = Bech32('npub', words);
    return bech32Encode(bech32Data);
  }

  // Convert hex to nsec (bech32)
  static String hexToNsec(String hex) {
    final data = HEX.decode(hex);
    final words = _convertBits(data, 8, 5, true);
    final bech32Data = Bech32('nsec', words);
    return bech32Encode(bech32Data);
  }

  // Convert npub to hex
  static String npubToHex(String npub) {
    final decoded = bech32Decode(npub);
    final data = _convertBits(decoded.data, 5, 8, false);
    return HEX.encode(data);
  }

  // Convert nsec to hex
  static String nsecToHex(String nsec) {
    final decoded = bech32Decode(nsec);
    final data = _convertBits(decoded.data, 5, 8, false);
    return HEX.encode(data);
  }

  // Sign a message with private key
  static String sign(String messageHash, String privateKeyHex) {
    final privateKeyInt = BigInt.parse(privateKeyHex, radix: 16);
    final params = ECCurve_secp256k1();
    final privateKey = ECPrivateKey(privateKeyInt, params);
    
    final signer = ECDSASigner(SHA256Digest());
    signer.init(true, PrivateKeyParameter(privateKey));
    
    final messageBytes = HEX.decode(messageHash);
    final signature = signer.generateSignature(Uint8List.fromList(messageBytes)) as ECSignature;
    
    final r = signature.r.toRadixString(16).padLeft(64, '0');
    final s = signature.s.toRadixString(16).padLeft(64, '0');
    
    return r + s;
  }

  // Verify signature
  static bool verify(String messageHash, String signature, String publicKeyHex) {
    try {
      final params = ECCurve_secp256k1();
      final publicKeyInt = BigInt.parse(publicKeyHex, radix: 16);
      final point = params.G * publicKeyInt;
      final publicKey = ECPublicKey(point, params);
      
      final verifier = ECDSASigner(SHA256Digest());
      verifier.init(false, PublicKeyParameter(publicKey));
      
      final r = BigInt.parse(signature.substring(0, 64), radix: 16);
      final s = BigInt.parse(signature.substring(64), radix: 16);
      final ecSignature = ECSignature(r, s);
      
      final messageBytes = HEX.decode(messageHash);
      return verifier.verifySignature(Uint8List.fromList(messageBytes), ecSignature);
    } catch (e) {
      return false;
    }
  }

  // Encrypt content (NIP-04)
  static String encrypt(String content, String privateKeyHex, String recipientPubKeyHex) {
    // Simplified NIP-04 encryption - in production use proper implementation
    final sharedSecret = _getSharedSecret(privateKeyHex, recipientPubKeyHex);
    final iv = _generateIV();
    final encrypted = _aesEncrypt(content, sharedSecret, iv);
    return '${base64Encode(encrypted)}?iv=${base64Encode(iv)}';
  }

  // Decrypt content (NIP-04)
  static String decrypt(String encryptedContent, String privateKeyHex, String senderPubKeyHex) {
    final parts = encryptedContent.split('?iv=');
    if (parts.length != 2) throw Exception('Invalid encrypted content format');
    
    final encrypted = base64Decode(parts[0]);
    final iv = base64Decode(parts[1]);
    final sharedSecret = _getSharedSecret(privateKeyHex, senderPubKeyHex);
    
    return _aesDecrypt(encrypted, sharedSecret, iv);
  }

  static Uint8List _getSharedSecret(String privateKeyHex, String publicKeyHex) {
    final privateKeyInt = BigInt.parse(privateKeyHex, radix: 16);
    final publicKeyInt = BigInt.parse(publicKeyHex, radix: 16);
    final params = ECCurve_secp256k1();
    final point = params.G * publicKeyInt;
    final sharedPoint = point! * privateKeyInt;
    final sharedSecret = sharedPoint.x!.toBigInteger()!.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList(HEX.decode(sharedSecret));
  }

  static Uint8List _generateIV() {
    _initRandom();
    return _secureRandom.nextBytes(16);
  }

  static Uint8List _aesEncrypt(String plaintext, Uint8List key, Uint8List iv) {
    final cipher = CBCBlockCipher(AESEngine());
    final params = ParametersWithIV(KeyParameter(key.sublist(0, 32)), iv);
    cipher.init(true, params);
    
    final input = Uint8List.fromList(utf8.encode(plaintext));
    final paddedInput = _addPadding(input);
    final output = Uint8List(paddedInput.length);
    
    for (var i = 0; i < paddedInput.length; i += 16) {
      cipher.processBlock(paddedInput, i, output, i);
    }
    
    return output;
  }

  static String _aesDecrypt(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    final cipher = CBCBlockCipher(AESEngine());
    final params = ParametersWithIV(KeyParameter(key.sublist(0, 32)), iv);
    cipher.init(false, params);
    
    final output = Uint8List(ciphertext.length);
    
    for (var i = 0; i < ciphertext.length; i += 16) {
      cipher.processBlock(ciphertext, i, output, i);
    }
    
    final unpadded = _removePadding(output);
    return utf8.decode(unpadded);
  }

  static Uint8List _addPadding(Uint8List input) {
    final blockSize = 16;
    final paddingLength = blockSize - (input.length % blockSize);
    final padded = Uint8List(input.length + paddingLength);
    padded.setAll(0, input);
    for (var i = input.length; i < padded.length; i++) {
      padded[i] = paddingLength;
    }
    return padded;
  }

  static Uint8List _removePadding(Uint8List input) {
    final paddingLength = input.last;
    return input.sublist(0, input.length - paddingLength);
  }

  static List<int> _convertBits(List<int> data, int fromBits, int toBits, bool pad) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << toBits) - 1;

    for (final value in data) {
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (toBits - bits)) & maxv);
      }
    } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0) {
      throw Exception('Invalid data');
    }

    return result;
  }
}
