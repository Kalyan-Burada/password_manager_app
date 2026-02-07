import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  /// Derive encryption key from password and salt
  encrypt.Key deriveKey(String password, Uint8List salt) {
    // Use SHA-256 to derive a 32-byte key from password+salt
    final bytes = utf8.encode(password) + salt;
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  /// Decrypt the vault data
  Map<String, String> decryptVault(String encryptedData, String password, Uint8List salt) {
    try {
      final key = deriveKey(password, salt);
      
      // Split the encrypted data into IV and ciphertext
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        return {}; // Empty vault
      }
      
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedText = parts[1];
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
      
      // Parse JSON
      final Map<String, dynamic> data = json.decode(decrypted);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Decryption error: $e');
      return {};
    }
  }

  /// Encrypt the vault data
  String encryptVault(Map<String, String> vaultItems, String password, Uint8List salt) {
    final key = deriveKey(password, salt);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final jsonData = json.encode(vaultItems);
    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    
    return '${iv.base64}:${encrypted.base64}';
  }
}