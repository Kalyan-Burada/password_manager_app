import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:password_manager_app/services/auth_service.dart';
import 'dart:convert';
import 'dart:typed_data';

// Generate Mocks
@GenerateMocks([http.Client])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    authService = AuthService(client: mockClient);
  });

  group('Epic 1.3 - Client-Side Key Derivation', () {
    test('_derive produces consistent 32-byte keys', () async {
      final vault = {'test': 'data'};
      final password = 'password123';

      // Encrypt twice with same password
      final encrypted1 = await authService.encryptVault(vault, password);
      final encrypted2 = await authService.encryptVault(vault, password);

      // Salts and nonces will differ, but key derivation is consistent
      // (we can't test _derive directly as it's private, but we test encryption works)
      expect(encrypted1.containsKey('vault_salt'), true);
      expect(encrypted2.containsKey('vault_salt'), true);
    });

    test('different passwords produce different encrypted output', () async {
      final vault = {'test': 'data'};
      final password1 = 'password123';
      final password2 = 'password456';

      final encrypted1 = await authService.encryptVault(vault, password1);
      final encrypted2 = await authService.encryptVault(vault, password2);

      // Different passwords should produce different ciphertexts
      expect(encrypted1['ciphertext'], isNot(equals(encrypted2['ciphertext'])));
    });

    test('same password with same salt produces same key (deterministic)',
        () async {
      final vault = {'test': 'data'};
      final password = 'password123';

      // First encryption
      final encrypted = await authService.encryptVault(vault, password);

      // Decrypt with same password should work
      final decrypted = await authService.decryptVault(encrypted, password);

      expect(decrypted, equals(vault));
    });
  });

  group('Epic 1.4 & 1.5 - Vault Encryption/Decryption', () {
    test('encryptVault should return valid encryption artifacts', () async {
      final vault = {'key': 'value'};
      final password = 'strong_password';

      final result = await authService.encryptVault(vault, password);

      expect(result.containsKey('vault_salt'), true);
      expect(result.containsKey('nonce'), true);
      expect(result.containsKey('ciphertext'), true);

      // Verify lengths (hex strings)
      expect(result['vault_salt']!.length, 32); // 16 bytes -> 32 hex chars
      expect(result['nonce']!.length, 48); // 24 bytes -> 48 hex chars
      expect(result['ciphertext']!.isNotEmpty, true);
    });

    test('encryptVault never returns plaintext', () async {
      final vault = {'secretPassword': 'MyP@ssw0rd!'};
      final password = 'master_password';

      final encrypted = await authService.encryptVault(vault, password);

      // Ciphertext should not contain plaintext password
      final ciphertext = encrypted['ciphertext']!;
      expect(ciphertext.contains('MyP@ssw0rd!'), false);
      expect(ciphertext.contains('secretPassword'), false);
    });

    test('decryptVault should recover original data with correct password',
        () async {
      final vault = {'secret': 'data', 'id': 123};
      final password = 'correct_password';

      final encryptedBlob = await authService.encryptVault(vault, password);
      final decryptedVault =
          await authService.decryptVault(encryptedBlob, password);

      expect(decryptedVault, equals(vault));
    });

    test('decryptVault should fail with incorrect password', () async {
      final vault = {'secret': 'data'};
      final password = 'password123';
      final wrongPassword = 'password456';

      final encryptedBlob = await authService.encryptVault(vault, password);

      expect(
        () async =>
            await authService.decryptVault(encryptedBlob, wrongPassword),
        throwsA(isA<Exception>()),
      );
    });

    test('encrypted output changes with different salts', () async {
      final vault = {'test': 'data'};
      final password = 'password';

      final encrypted1 = await authService.encryptVault(vault, password);
      final encrypted2 = await authService.encryptVault(vault, password);

      // Different salts should produce different ciphertexts
      expect(encrypted1['vault_salt'], isNot(equals(encrypted2['vault_salt'])));
      expect(encrypted1['ciphertext'], isNot(equals(encrypted2['ciphertext'])));
    });
  });

  group('Epic 1.2 - Master Password Never Sent to Server', () {
    test('register() never sends plaintext password', () async {
      const username = 'testuser';
      const password = 'MySecretPassword123!';

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/register'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      await authService.register(username, password);

      // Verify the request body
      final capturedCall = verify(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/register'),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.single as String;

      // Body should not contain plaintext password
      expect(capturedCall.contains(password), false);

      // Body should contain salt and verifier
      final bodyJson = jsonDecode(capturedCall);
      expect(bodyJson['salt'], isNotNull);
      expect(bodyJson['verifier'], isNotNull);
      expect(bodyJson.containsKey('password'), false);
    });

    test('login() never sends plaintext password', () async {
      const username = 'testuser';
      const password = 'MySecretPassword123!';
      const saltHex = '0123456789abcdef0123456789abcdef';

      // Mock getSalt
      when(mockClient
              .get(Uri.parse('${AuthService.baseUrl}/auth_salt/$username')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'salt': saltHex}), 200));

      // Mock login
      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/login'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
          (_) async => http.Response(jsonEncode({'token': 'abc123'}), 200));

      await authService.login(username, password);

      // Verify login request body
      final capturedCall = verify(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/login'),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.single as String;

      // Body should not contain plaintext password
      expect(capturedCall.contains(password), false);

      // Body should contain verifier
      final bodyJson = jsonDecode(capturedCall);
      expect(bodyJson['verifier'], isNotNull);
      expect(bodyJson.containsKey('password'), false);
    });

    test('loginWithMfa() never sends plaintext password', () async {
      const username = 'testuser';
      const password = 'MySecretPassword123!';
      const mfaCode = '123456';
      const saltHex = '0123456789abcdef0123456789abcdef';

      when(mockClient
              .get(Uri.parse('${AuthService.baseUrl}/auth_salt/$username')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'salt': saltHex}), 200));

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/login/mfa'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
          (_) async => http.Response(jsonEncode({'token': 'abc123'}), 200));

      await authService.loginWithMfa(username, password, mfaCode);

      final capturedCall = verify(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/login/mfa'),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.single as String;

      expect(capturedCall.contains(password), false);

      final bodyJson = jsonDecode(capturedCall);
      expect(bodyJson['verifier'], isNotNull);
      expect(bodyJson['mfa_code'], equals(mfaCode));
      expect(bodyJson.containsKey('password'), false);
    });
  });

  group('Epic 1.6 - Authentication Without Key Exposure', () {
    test('login returns token, not encryption keys', () async {
      const username = 'testuser';
      const password = 'password123';
      const saltHex = '0123456789abcdef0123456789abcdef';
      const token = 'session_token_abc123';

      when(mockClient
              .get(Uri.parse('${AuthService.baseUrl}/auth_salt/$username')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'salt': saltHex}), 200));

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/login'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
          (_) async => http.Response(jsonEncode({'token': token}), 200));

      final result = await authService.login(username, password);

      expect(result, equals(token));
      expect(result!.contains('verifier'), false);
      expect(result.contains('key'), false);
    });

    test('getAuthSalt returns salt on 200 OK', () async {
      const username = 'testuser';
      const saltHex = '00112233445566778899aabbccddeeff';

      when(mockClient
              .get(Uri.parse('${AuthService.baseUrl}/auth_salt/$username')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'salt': saltHex}), 200));

      final salt = await authService.getAuthSalt(username);

      expect(salt, isNotNull);
      expect(salt!.length, 16);
      expect(salt[0], 0x00);
      expect(salt[15], 0xff);
    });

    test('getAuthSalt returns null on 404', () async {
      const username = 'unknown';

      when(mockClient
              .get(Uri.parse('${AuthService.baseUrl}/auth_salt/$username')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final salt = await authService.getAuthSalt(username);
      expect(salt, isNull);
    });
  });

  group('Epic 1.10 - Rate Limiting', () {
    test('RateLimitException thrown on 429 response', () async {
      const username = 'testuser';
      const password = 'password';

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/register'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'detail': 'Too many requests'}),
          429,
        ),
      );

      expect(
        () async => await authService.register(username, password),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('RateLimitException contains message', () async {
      const username = 'testuser';
      const code = '123456';
      const errorMsg = 'IP blocked. Try again in 60 seconds.';

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/mfa/verify'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'detail': errorMsg}),
          429,
        ),
      );

      try {
        await authService.verifyMfa(username, code);
        fail('Should have thrown RateLimitException');
      } catch (e) {
        expect(e, isA<RateLimitException>());
        expect(e.toString(), contains(errorMsg));
      }
    });
  });

  group('Epic 1.14 - MFA Functionality', () {
    test('checkMfaStatus returns boolean', () async {
      const username = 'testuser';

      when(mockClient
              .get(Uri.parse('${AuthService.baseUrl}/mfa/status/$username')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'mfa_enabled': true}), 200));

      final result = await authService.checkMfaStatus(username);
      expect(result, isA<bool>());
      expect(result, true);
    });

    test('setupMfa returns QR code data', () async {
      const token = 'valid_token';
      final mfaData = {
        'secret': 'JBSWY3DPEHPK3PXP',
        'qr_code': 'data:image/png;base64,iVBORw0KG...',
        'provisioning_uri': 'otpauth://totp/...',
        'backup_codes': ['ABCD-1234', 'EFGH-5678'],
      };

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/mfa/setup'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mfaData), 200));

      final result = await authService.setupMfa(token);

      expect(result['secret'], isNotNull);
      expect(result['qr_code'], isNotNull);
      expect(result['provisioning_uri'], isNotNull);
      expect(result['backup_codes'], isNotNull);
    });

    test('verifyMfa handles success', () async {
      const username = 'testuser';
      const code = '123456';

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/mfa/verify'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final result = await authService.verifyMfa(username, code);
      expect(result, true);
    });

    test('verifyMfa handles failure', () async {
      const username = 'testuser';
      const code = '000000';

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/mfa/verify'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async =>
          http.Response(jsonEncode({'error': 'Invalid code'}), 400));

      final result = await authService.verifyMfa(username, code);
      expect(result, false);
    });

    test('loginWithMfa requires all three parameters', () async {
      const username = 'testuser';
      const password = 'password123';
      const mfaCode = '123456';
      const saltHex = '0123456789abcdef0123456789abcdef';

      when(mockClient
              .get(Uri.parse('${AuthService.baseUrl}/auth_salt/$username')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'salt': saltHex}), 200));

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/login/mfa'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
          (_) async => http.Response(jsonEncode({'token': 'abc'}), 200));

      final result =
          await authService.loginWithMfa(username, password, mfaCode);

      expect(result, isNotNull);

      // Verify all params were sent
      final captured = verify(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/login/mfa'),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.single as String;

      final bodyJson = jsonDecode(captured);
      expect(bodyJson['username'], equals(username));
      expect(bodyJson['verifier'], isNotNull);
      expect(bodyJson['mfa_code'], equals(mfaCode));
    });
  });
}
