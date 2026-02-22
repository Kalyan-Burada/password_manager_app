# Penetration Testing Plan — User Story 5.16

## Overview
This document outlines the penetration testing plan for the SE 12 Password Manager system to identify and document security weaknesses.

## Scope

| Target | In Scope |
|--------|----------|
| Authentication endpoints (`/login`, `/register`) | ✅ |
| Rate limiting & brute-force protection | ✅ |
| Backup API (`/backups`, `/backups/restore`) | ✅ |
| HTTPS/TLS configuration | ✅ |
| Audit log endpoint (`/logs`) | ✅ |
| Client Flutter app | ✅ |
| OS-level server hardening | ⚠️ Out of scope for academic version |

## Test Cases

### 1. Authentication
| Test | Method | Expected Result |
|------|--------|-----------------|
| Login with wrong password | `POST /login` with bad verifier | 401 Unauthorized |
| Login with non-existent user | `GET /auth_salt/unknown` | 404 Not Found |
| Register duplicate user | `POST /register` twice | 400 Bad Request |

### 2. Rate Limiting & Brute Force
| Test | Method | Expected Result |
|------|--------|-----------------|
| 5 failed logins from same IP | Repeated `POST /login` | 429 Too Many Requests |
| Verify IP block duration | Wait 60s after block | Login allowed again |
| Test with `test_rate_limit.py` | `pytest test_rate_limit.py` | All tests pass |

### 3. Authorization
| Test | Method | Expected Result |
|------|--------|-----------------|
| Access vault without token | `GET /vault` with no header | 401 Unauthorized |
| Access another user's backup | `POST /backups/restore` with wrong filename | 400 Bad Request |
| Delete another user's backup | `DELETE /backups/<other_user_file>` | 400 Bad Request |

### 4. HTTPS / TLS
| Test | Method | Expected Result |
|------|--------|-----------------|
| Connect via HTTP | `curl http://localhost:8000` | Connection refused |
| Verify TLS certificate | `verify_https.py` | Certificate valid |
| Test with expired cert | Replace cert with expired one | TLS handshake fails |

### 5. Input Validation
| Test | Method | Expected Result |
|------|--------|-----------------|
| Path traversal in backup filename | `../../../etc/passwd` | 400 Invalid filename |
| Empty username/password | Blank fields | Error returned |
| SQL/injection in username | `'; DROP TABLE users--` | Treated as literal string |

## Tools
- `curl` — manual endpoint testing
- `pytest` — automated test suite in `tests/`
- `verify_https.py` — HTTPS certificate check
- OWASP ZAP (recommended for full assessment)

## Findings Log

| Date | Finding | Severity | Status |
|------|---------|----------|--------|
| — | Rate limiting confirmed working | Info | ✅ Verified |
| — | Path traversal blocked in backup filenames | Info | ✅ Verified |
| — | Unauthorized vault access blocked | Info | ✅ Verified |

## Remediation Tracking
All findings are tracked in this file. Critical/High severity findings must be patched before submission.
