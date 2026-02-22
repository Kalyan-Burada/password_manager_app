# Incident Response Plan — User Story 5.9

## Overview
This document defines the steps to take when a security incident is detected in the SE 12 Password Manager system.

## Incident Types

| Type | Example |
|------|---------|
| Credential compromise | Unusual login from unknown IP |
| Brute-force attack | 5+ failed login attempts from one IP |
| Data breach | Unauthorized access to backup files |
| Server compromise | Unexpected process or file changes |

## Response Steps

### Step 1 — Detect
- Monitor server logs and the `audit_log.json` for anomalies
- Rate limiter automatically blocks IPs exceeding 5 failed login attempts
- Review audit logs via the `/logs` endpoint (authenticated)

### Step 2 — Contain
1. **Revoke all active sessions**: Restart the server to clear the in-memory `SESSIONS` dict
2. **Block suspicious IPs**: Enforce firewall rules to block the attacker's IP
3. **Disable affected accounts** if credential stuffing is suspected

### Step 3 — Recover
1. **Rotate the backup encryption key**: Replace `server/secret.key` with a new Fernet key
   - Existing backups encrypted with old key must be re-encrypted
2. **Restore from clean backup** if data was tampered with
3. **Verify vault integrity** by reviewing encrypted blobs

### Step 4 — Notify
- Inform affected users to change their master password
- Document the incident in a security incident log

### Step 5 — Review & Improve
- Review `audit_log.json` to trace the incident timeline
- Update firewall rules, rate limits, or code as needed
- Document lessons learned

## Roles

| Role | Responsibility |
|------|----------------|
| Developer | Detect, contain, fix code |
| System Admin | Apply firewall rules, restart services |
| Affected User | Change master password |

## Escalation
1. Developer detects issue → attempts to contain
2. If uncontained within 1 hour → escalate to project lead
3. If data breach confirmed → notify all users immediately

## Contact
- Project Lead: [student name / email]
- Academic Supervisor: [supervisor name]
