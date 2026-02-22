# Maintenance Policy — User Story 5.15

## Overview
This document describes how maintenance activities are performed without exposing vault data in plaintext.

## Core Guarantee
> All vault data remains encrypted at all times — before, during, and after any maintenance operation.

## Data Storage Review

| Data | Storage Format | Encrypted? |
|------|----------------|------------|
| User vault blob | `server/data/<username>.json` | ✅ Yes (XChaCha20-Poly1305, client-side) |
| Backup files | `backups/backup_<user>_<timestamp>.enc` | ✅ Yes (Fernet/AES-128) |
| Auth credentials | `server/auth_db.json` | ✅ Yes (Argon2id verifier, never plaintext) |
| Audit logs | `server/data/audit_log.json` | ⚠️ Plaintext (contains only usernames + actions, no passwords) |
| Encryption key | `server/secret.key` | ⚠️ File system (restrict access) |

## Maintenance Procedures

### Backup Maintenance
- Backups are always created in encrypted form via `backup.py`
- Decryption only happens in memory during restore — never written as plaintext
- `secret.key` must be present to create or restore backups

### Key Rotation
1. Generate a new Fernet key
2. Decrypt all existing `.enc` backup files with the old key
3. Re-encrypt with the new key
4. Replace `secret.key` securely
5. Shred / securely delete the old key

### Log Maintenance
- Audit logs are periodically archived
- Logs contain no passwords or vault content — safe to inspect without encryption concern
- Future improvement: encrypt logs at rest (User Story 5.12)

### Server Updates
- Stop server gracefully (no in-flight requests dropped mid-write)
- Deploy updated code
- Restart server — in-memory sessions are cleared (users must re-login)
- Verify HTTPS endpoints are responding correctly

## Prohibited Actions
- ❌ Never print or log vault blob content
- ❌ Never write decrypted vault data to a temp file
- ❌ Never expose `secret.key` in logs or error messages
- ❌ Never run the server without SSL in any environment that handles real data
