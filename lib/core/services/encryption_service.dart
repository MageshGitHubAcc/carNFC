import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  static const String _keyString = 'ABC_MALL_PARKING_SECRET_KEY_32'; // Change in production
  
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  EncryptionService() {
    // Generate a proper 32-byte key from the string
    final keyBytes = sha256.convert(utf8.encode(_keyString)).bytes;
    _key = encrypt.Key(Uint8List.fromList(keyBytes));
    
    // Use first 16 bytes of key hash as IV
    _iv = encrypt.IV(Uint8List.fromList(keyBytes.sublist(0, 16)));
    
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String encryptData(Map<String, dynamic> data) {
    try {
      final jsonString = jsonEncode(data);
      final encrypted = _encrypter.encrypt(jsonString, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  Map<String, dynamic> decryptData(String encryptedData) {
    try {
      final decrypted = _encrypter.decrypt64(encryptedData, iv: _iv);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  String encryptString(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('String encryption failed: $e');
    }
  }

  String decryptString(String encryptedText) {
    try {
      return _encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      throw Exception('String decryption failed: $e');
    }
  }
}
