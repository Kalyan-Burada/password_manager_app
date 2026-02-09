import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:argon2/argon2.dart';
import 'package:cryptography/cryptography.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<Uint8List> _derive(String password, Uint8List salt) async {
    final argon2 = Argon2BytesGenerator();

    final params = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: 3,
      memoryPowerOf2: 17, // 128 MB
      lanes: 4,
    );

    argon2.init(params);

    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final hash = Uint8List(32);
    argon2.generateBytes(passwordBytes, hash);

    return hash;
  }

  Future<Map<String, String>> encryptVault(
    Map<String, dynamic> vault,
    String password,
  ) async {
    // Generate salt (matches Python)
    final vaultSalt = _randomBytes(16);

    // Derive vault key
    final keyBytes = await _derive(password, vaultSalt);
    final secretKey = SecretKey(keyBytes);

    // Generate XChaCha20 nonce (24 bytes)
    final nonce = _randomBytes(24);

    // Encrypt
    final algorithm = Xchacha20.poly1305Aead();
    final plaintext = utf8.encode(jsonEncode(vault));

    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Python concatenates MAC to ciphertext
    final combinedCiphertext = secretBox.cipherText + secretBox.mac.bytes;

    return {
      'vault_salt': _bytesToHex(vaultSalt),
      'nonce': _bytesToHex(nonce),
      'ciphertext': _bytesToHex(Uint8List.fromList(combinedCiphertext)),
    };
  }

  Future<Map<String, dynamic>> decryptVault(
    Map<String, dynamic> blob,
    String password,
  ) async {
    final vaultSalt = _hexToBytes(blob['vault_salt']);
    final nonce = _hexToBytes(blob['nonce']);
    final ciphertext = _hexToBytes(blob['ciphertext']);

    // Split ciphertext and MAC (last 16 bytes)
    final cipherTextOnly = ciphertext.sublist(0, ciphertext.length - 16);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);

    final keyBytes = await _derive(password, vaultSalt);
    final secretKey = SecretKey(keyBytes);

    final algorithm = Xchacha20.poly1305Aead();

    final secretBox = SecretBox(
      cipherTextOnly,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return jsonDecode(utf8.decode(plaintext));
  }

  Future<Uint8List?> getAuthSalt(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/auth_salt/$username'));

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Failed to get auth salt');
    }

    final data = json.decode(response.body);
    return _hexToBytes(data['salt']);
  }

  Future<void> register(String username, String password) async {
    final salt = _randomBytes(16);
    final verifier = await _derive(password, salt);

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'salt': _bytesToHex(salt),
        'verifier': _bytesToHex(verifier),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Registration failed');
    }
  }

  Future<String?> login(String username, String password) async {
    final salt = await getAuthSalt(username);
    if (salt == null) return null;

    final verifier = await _derive(password, salt);

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'verifier': _bytesToHex(verifier),
      }),
    );

    if (response.statusCode != 200) return null;

    return json.decode(response.body)['token'];
  }

  Future<Map<String, dynamic>> getVault(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vault'),
      headers: {'Authorization': token},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch vault');
    }
    return json.decode(response.body);
  }

  Future<bool> updateVault(
    String token,
    Map<String, String> encryptedBlob,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vault'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'blob': encryptedBlob,
      }),
    );

    return response.statusCode == 200;
  }

  // MFA Methods
  Future<bool> checkMfaStatus(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mfa/status/$username'),
    );

    if (response.statusCode != 200) {
      return false;
    }

    final data = json.decode(response.body);
    return data['mfa_enabled'] ?? false;
  }

  Future<Map<String, dynamic>> setupMfa(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mfa/setup'),
      headers: {'Authorization': token},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to setup MFA');
    }

    return json.decode(response.body);
  }

  Future<bool> verifyMfa(String username, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mfa/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'code': code,
      }),
    );

    return response.statusCode == 200;
  }

  Future<String?> loginWithMfa(
    String username,
    String password,
    String mfaCode,
  ) async {
    final salt = await getAuthSalt(username);
    if (salt == null) return null;

    final verifier = await _derive(password, salt);

    final response = await http.post(
      Uri.parse('$baseUrl/login/mfa'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'verifier': _bytesToHex(verifier),
        'mfa_code': mfaCode,
      }),
    );

    if (response.statusCode != 200) return null;

    return json.decode(response.body)['token'];
  }

  Future<bool> disableMfa(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mfa/disable'),
      headers: {'Authorization': token},
    );

    return response.statusCode == 200;
  }

  // Backup Methods

  Future<List<String>> getBackups(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/backups'),
      headers: {'Authorization': token},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch backups');
    }

    final data = json.decode(response.body);
    return List<String>.from(data['backups']);
  }

  Future<String> createBackup(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/backups'),
      headers: {'Authorization': token},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create backup');
    }

    return json.decode(response.body)['filename'];
  }

  Future<void> restoreBackup(String token, String filename) async {
    final response = await http.post(
      Uri.parse('$baseUrl/backups/restore'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'filename': filename}),
    );

    if (response.statusCode != 200) {
      final error =
          json.decode(response.body)['detail'] ?? 'Failed to restore backup';
      throw Exception(error);
    }
  }

  Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => rnd.nextInt(256)),
    );
  }

  String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
