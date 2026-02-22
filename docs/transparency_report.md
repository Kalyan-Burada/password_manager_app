# Transparency Report — User Story 5.18

**Period**: February 2026  
**System**: SE 12 Password Manager  
**Version**: 1.0

---

## 1. Encryption Practices

| Component | Method | Details |
|-----------|--------|---------|
| Vault data | XChaCha20-Poly1305 | Client-side encryption; server never sees plaintext |
| Authentication | Argon2id | Password hashed before any network transmission |
| Backup files | Fernet (AES-128-CBC + HMAC-SHA256) | Server-side encrypted at rest |
| Transport | TLS 1.2+ | HTTPS enforced via `run_secure_server.py` |

---

## 2. Security Controls

| Control | Status | Details |
|---------|--------|---------|
| HTTPS / TLS | ✅ Active | Self-signed cert for dev; CA cert recommended for prod |
| Rate Limiting | ✅ Active | 5 failed attempts → IP blocked for 60 seconds |
| Brute-force Detection | ✅ Active | Per-IP attempt tracking in `SecurityManager` |
| Multi-Factor Authentication | ✅ Available | TOTP via Google Authenticator (optional) |
| Encrypted Backups | ✅ Active | All backup files use `.enc` extension (Fernet-encrypted) |
| Audit Logging | ✅ Active | All vault, backup, and MFA events logged |

---

## 3. Incident History

| Date | Type | Resolution |
|------|------|------------|
| No incidents recorded | — | — |

---

## 4. Data Practices

| Practice | Status |
|----------|--------|
| Server stores vault content | ❌ Never (zero-knowledge) |
| Server stores master password | ❌ Never |
| Logs contain passwords | ❌ Never |
| User data shared with third parties | ❌ Never |

---

## 5. Monitoring Transparency

- Security alerts are logged to console when IPs are blocked
- Audit logs record all significant user actions (vault access, backup operations, MFA changes)
- Logs are reviewed for zero-knowledge compliance (see `zero_knowledge_compliance.md`)

---

## 6. Known Limitations

| Limitation | Impact | Mitigation Plan |
|------------|--------|-----------------|
| Audit logs stored in plaintext | Low (no sensitive data in logs) | Planned: encrypt logs (US 5.12) |
| Self-signed TLS certificate | Dev only | Use CA-signed cert in production |
| Sessions stored in memory | Lost on restart | Acceptable for academic scope |

---

## 7. Commitments

- We will maintain zero-knowledge architecture in all future updates
- Security issues will be disclosed in subsequent transparency reports
- All encryption primitives use industry-standard libraries (Python `cryptography`, Dart `pointycastle`)

---

*Published: February 2026*  
*SE 12 Password Manager — Academic Project*
