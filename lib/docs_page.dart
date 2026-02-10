import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentationPage extends StatefulWidget {
  const DocumentationPage({super.key});

  @override
  State<DocumentationPage> createState() => _DocumentationPageState();
}

class _DocumentationPageState extends State<DocumentationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zero-Knowledge Architecture'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title Card
          _buildTitleCard(),
          const SizedBox(height: 24),
          
          // Core Guarantee
          _buildCoreGuaranteeCard(),
          const SizedBox(height: 24),
          
          // Architecture Flow
          _buildArchitectureSection(),
          const SizedBox(height: 24),
          
          // Key Features
          _buildFeaturesGrid(),
          const SizedBox(height: 24),
          
          // Security Properties
          _buildSecuritySection(),
          const SizedBox(height: 24),
          
          // Threat Model
          _buildThreatModelSection(),
        ],
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF00B894),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.white, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Zero-Knowledge Architecture',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Your master password never leaves your device. The server cannot decrypt, view, or access your vault data, even if compromised.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreGuaranteeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C5CE7), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF6C5CE7), size: 28),
              SizedBox(width: 12),
              Text(
                'Core Guarantee',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBulletPoint('Server admins cannot access vault data', Icons.check_circle, const Color(0xFF00B894)),
          _buildBulletPoint('Database breaches expose no passwords', Icons.check_circle, const Color(0xFF00B894)),
          _buildBulletPoint('Court orders cannot compel decryption', Icons.check_circle, const Color(0xFF00B894)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFE8E8E8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Flow Architecture',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Client Side
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _buildFlowCard(
              'YOUR DEVICE (Client)',
              const Color(0xFF6C5CE7),
              [
                '1. Master Password: "MySecretPassword123"',
                '2. Derive Auth Key: Argon2(password + auth_salt)',
                '   → Used for authentication only',
                '3. Derive Vault Key: Argon2(password + vault_salt)',
                '   → Used for vault encryption only',
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Arrow
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 500,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_downward, color: Color(0xFF00B894), size: 32),
                SizedBox(height: 8),
                Text(
                  'Send encrypted data only',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0B0B0),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Server Side  
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _buildFlowCard(
              'SERVER (Backend)',
              const Color(0xFF00B894),
              [
                'Stores (ALL ENCRYPTED):',
                '  • auth_salt (public)',
                '  • verifier (hashed auth key)',
                '  • vault_salt (transmitted with vault)',
                '  • encrypted_vault (XChaCha20-Poly1305 ciphertext)',
                '',
                '❌ NEVER has:',
                '  • Master password',
                '  • Vault decryption key',
                '  • Plaintext passwords',
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowCard(String title, Color accentColor, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFE8E8E8),
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Features',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.0,
          children: [
            _buildFeatureCard('End-to-End\nEncryption', Icons.lock),
            _buildFeatureCard('Argon2id\nHashing', Icons.vpn_key),
            _buildFeatureCard('XChaCha20\nCipher', Icons.enhanced_encryption),
            _buildFeatureCard('Zero\nKnowledge', Icons.visibility_off),
            _buildFeatureCard('Client-Side\nCrypto', Icons.computer),
            _buildFeatureCard('No Password\nRecovery', Icons.block),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.2),
            const Color(0xFF00B894).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF9B8EFF), size: 18),
          const SizedBox(width: 8),
          Text(
            title.replaceAll('\n', ' '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Properties',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildPropertyCard(
          'Authentication Without Password Transmission',
          'Your password is never sent to the server. Instead, we derive a verifier using Argon2(password, salt) and send only that.',
          const Color(0xFF6C5CE7),
        ),
        const SizedBox(height: 12),
        _buildPropertyCard(
          'Separation of Concerns: Two Keys',
          'Authentication key (for login) and Vault key (for encryption) are derived separately. Compromising one doesn\'t compromise the other.',
          const Color(0xFF00B894),
        ),
        const SizedBox(height: 12),
        _buildPropertyCard(
          'End-to-End Encryption',
          'Your device encrypts data before sending. The server only sees ciphertext. Decryption happens only on your device.',
          const Color(0xFF9B8EFF),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(String title, String description, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB0B0B0),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Threat Model',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Protects Against
        _buildThreatCard(
          'Protects Against ✅',
          const Color(0xFF00B894),
          [
            'Server Compromise',
            'Database Breach',
            'Network Eavesdropping (with HTTPS)',
            'Rogue Employee',
            'Government Subpoena',
          ],
          true,
        ),
        
        const SizedBox(height: 12),
        
        // Does NOT Protect Against
        _buildThreatCard(
          'Does NOT Protect Against ❌',
          const Color(0xFFFF6B6B),
          [
            'Weak Master Password',
            'Client-Side Malware',
            'Phishing Attacks',
            'Forgotten Password (= permanent data loss)',
          ],
          false,
        ),
      ],
    );
  }

  Widget _buildThreatCard(String title, Color color, List<String> items, bool isProtected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isProtected ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE8E8E8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
