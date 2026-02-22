# Infrastructure Hardening — User Story 5.1

## Overview
This document describes the server hardening practices applied to the SE 12 Password Manager backend.

## Applied Hardening Practices

### 1. HTTPS-Only Communication
- The server runs exclusively over HTTPS using TLS certificates (`cert.pem`, `key.pem`)
- Started via `run_secure_server.py` with SSL enforced by uvicorn
- All HTTP traffic is rejected — no fallback to plaintext

### 2. Minimal Attack Surface
- Only port **8000** is exposed (configurable)
- No admin dashboard or debug endpoints are exposed
- FastAPI docs (`/docs`, `/redoc`) should be disabled in production

### 3. Disabled Unnecessary Services
- No FTP, Telnet, or other legacy services are running
- No remote desktop or SSH is exposed in the development environment
- Only the FastAPI application process runs

### 4. Firewall Rules (Production Recommendation)
| Rule | Action | Description |
|------|--------|-------------|
| Port 8000 TCP inbound | ALLOW | HTTPS API |
| All other inbound | DENY | Default deny |
| All outbound | ALLOW | Responses |

### 5. Process Isolation
- The server process runs as a non-root user (recommended for production)
- No shared secrets stored in environment variables without protection

## Production Hardening Checklist
- [ ] Use a proper CA-signed TLS certificate (e.g., Let's Encrypt)
- [ ] Enable OS-level firewall (e.g., UFW on Linux)
- [ ] Run server as a dedicated low-privilege service account
- [ ] Disable FastAPI's auto-generated `/docs` endpoint
- [ ] Set up fail2ban or equivalent for SSH brute force protection

## References
- [OWASP Server-Side Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Infrastructure_Security_Cheat_Sheet.html)
- NIST SP 800-123: Guide to General Server Security
