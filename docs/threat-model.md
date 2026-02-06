# Threat Model — mirrorborn.us / SQ Cloud / Mytheon Arena

**Version**: 1.0  
**Last Updated**: 2026-02-05  
**Red Team Lead**: Cyon 🪶

---

## System Overview

**mirrorborn.us** serves as the public-facing brand for:
- **SQ Cloud** - Hosted phext-as-a-service (API + tenant management)
- **Mytheon Arena** - Gaming/experiential platform

**Architecture** (as understood Round 3):
```
Internet
  ↓
nginx (HTTPS via letsencrypt)
  ↓
Backend (Go/Node - TBD by Verse)
  ↓
SQ Process(es) - per-tenant isolation
  ↓
Phext storage (filesystem)
```

**Authentication Flow**:
1. User enters email
2. System sends magic link via AWS SES
3. Link contains ephemeral token
4. Backend validates token → issues JWT
5. JWT stored/validated against SQ
6. Session extends with activity

---

## Assets

| Asset | Criticality | Description |
|-------|-------------|-------------|
| Customer phext data | **Critical** | Persistent memory, potentially sensitive |
| JWT secrets | **Critical** | If leaked, full account takeover |
| AWS SES credentials | **High** | Email sending, spam potential |
| API keys (SQ tenant) | **High** | Access to tenant data |
| User email addresses | **Medium** | PII, spam target |
| SSL private keys | **Critical** | MITM if compromised |

---

## Threat Actors

### External Attackers
- **Motivation**: Data theft, service disruption, credential harvesting
- **Capability**: Automated scanners, opportunistic exploit
- **Likelihood**: High (public-facing web service)

### Malicious Tenants
- **Motivation**: Break tenant isolation, access other customers' data
- **Capability**: API abuse, injection attacks, resource exhaustion
- **Likelihood**: Medium (SQ Cloud is new, limited adoption)

### Insider Threat
- **Motivation**: N/A (ranch Mirrorborn trusted, no external employees)
- **Capability**: Full access to infrastructure
- **Likelihood**: Low (but test defense-in-depth anyway)

---

## Threat Categories

### 1. Authentication & Authorization

#### T1.1: Magic Link Interception
- **Vector**: Email sent over unencrypted channel, link stolen
- **Impact**: Account takeover
- **Mitigation**: 
  - Short TTL on tokens (5-10 min)
  - One-time use (burn token on first use)
  - IP binding (optional - may break mobile users)
  - Rate limit email sends per address

#### T1.2: JWT Secret Exposure
- **Vector**: Secret leaked in code, logs, or config
- **Impact**: Full session forgery, account takeover
- **Mitigation**:
  - Store JWT secret in environment variable, not code
  - Rotate secrets regularly
  - Use strong random generation (256-bit min)
  - Never log JWT payload or secret

#### T1.3: JWT Replay Attack
- **Vector**: Stolen JWT reused before expiry
- **Impact**: Session hijacking
- **Mitigation**:
  - Short TTL (15-30 min)
  - Refresh token flow
  - Revocation list in SQ (check on each request)

#### T1.4: Session Fixation
- **Vector**: Attacker sets known session ID, tricks user into using it
- **Impact**: Session hijacking
- **Mitigation**:
  - Regenerate session ID on login
  - HTTPS-only cookies with Secure + HttpOnly flags

---

### 2. Injection Attacks

#### T2.1: SQL Injection (N/A - no SQL)
- **Status**: Not applicable (SQ is plain text, not SQL)

#### T2.2: Phext Coordinate Injection
- **Vector**: User-supplied coordinate input like `../../etc/passwd`
- **Impact**: Path traversal, read arbitrary files
- **Mitigation**:
  - Validate coordinate format strictly (regex: `\d+\.\d+\.\d+/\d+\.\d+\.\d+/\d+\.\d+\.\d+`)
  - Reject any coordinate with `/`, `..`, or non-digit characters
  - SQ `--data-dir` flag must jail tenant to directory

#### T2.3: Command Injection
- **Vector**: User input passed to shell (e.g., `sq` CLI calls)
- **Impact**: Remote code execution
- **Mitigation**:
  - Never shell out with user input
  - Use SQ REST API, not CLI spawning
  - If CLI required, sanitize all inputs (whitelist only)

#### T2.4: XSS (Cross-Site Scripting)
- **Vector**: User-controlled content rendered in browser without escaping
- **Impact**: Session token theft, phishing, defacement
- **Mitigation**:
  - Escape all user content before rendering (use DOMPurify or equivalent)
  - Content-Security-Policy header (no inline scripts)
  - HttpOnly cookies (JavaScript can't access session token)

---

### 3. Tenant Isolation

#### T3.1: Tenant Data Leakage
- **Vector**: Bug in SQ or backend allows Tenant A to read Tenant B's data
- **Impact**: Data breach, regulatory violation
- **Mitigation**:
  - One SQ process per tenant (process isolation)
  - `--data-dir` per tenant (filesystem isolation)
  - Validate API key → tenant mapping on every request
  - Audit logs for cross-tenant access attempts

#### T3.2: Resource Exhaustion (DoS)
- **Vector**: Malicious tenant floods SQ with requests, starves others
- **Impact**: Service degradation for all tenants
- **Mitigation**:
  - Rate limiting per API key (e.g., 100 req/min)
  - Storage quotas enforced (25 MB per tenant)
  - CPU/memory limits per SQ process (cgroups or Docker limits)
  - Kill runaway processes

---

### 4. Infrastructure

#### T4.1: Weak TLS Configuration
- **Vector**: Outdated ciphers, no HSTS, mixed content
- **Impact**: MITM, downgrade attack
- **Mitigation**:
  - Use Mozilla SSL Config Generator (Intermediate profile)
  - Enable HSTS (max-age=31536000; includeSubDomains)
  - Redirect all HTTP to HTTPS
  - Test with SSL Labs

#### T4.2: Exposed Services
- **Vector**: Unnecessary ports open (SSH, Redis, etc.)
- **Impact**: Attack surface expansion
- **Mitigation**:
  - Firewall: only 80, 443 open to public
  - SSH on non-standard port, key-only auth
  - No database ports exposed (SQ is file-based)

#### T4.3: Unpatched Dependencies
- **Vector**: Known CVEs in nginx, Node, Go stdlib, etc.
- **Impact**: RCE, privilege escalation
- **Mitigation**:
  - Automated dependency scanning (Dependabot, Snyk)
  - Monthly patching cadence
  - Subscribe to security advisories

---

### 5. Email Security (AWS SES)

#### T5.1: Email Spoofing
- **Vector**: Attacker sends fake magic links from mirrorborn.us
- **Impact**: Phishing, credential theft
- **Mitigation**:
  - SPF record for mirrorborn.us
  - DKIM signing (AWS SES auto-configures)
  - DMARC policy (reject on fail)

#### T5.2: Credential Leakage (AWS SES Keys)
- **Vector**: SES access keys in code, logs, or public repo
- **Impact**: Spam abuse, account suspension
- **Mitigation**:
  - Use IAM role (if on EC2) or environment variables
  - Rotate keys quarterly
  - Audit CloudTrail for SES API calls

---

## Attack Surface Summary

| Component | Exposure | Priority |
|-----------|----------|----------|
| HTTPS endpoint | Public | **P0** |
| Email magic links | Per-user | **P0** |
| JWT validation | Per-request | **P0** |
| SQ API | Authenticated | **P1** |
| Tenant isolation | Multi-tenant | **P1** |
| File storage | Backend | **P2** |

---

## Testing Plan

### Phase 1: Reconnaissance (Round 3-4)
- [ ] Port scan (nmap)
- [ ] TLS scan (sslyze, SSL Labs)
- [ ] DNS enumeration (subdomains, DNSSEC)
- [ ] Technology fingerprinting (Wappalyzer, WhatWeb)

### Phase 2: Authentication (Round 5-6)
- [ ] Magic link flow fuzzing (invalid emails, expired tokens)
- [ ] JWT validation bypass attempts
- [ ] Session fixation/hijacking tests
- [ ] Brute force rate limit validation

### Phase 3: Injection (Round 7-8)
- [ ] Coordinate injection (path traversal)
- [ ] XSS in all user input fields
- [ ] Command injection (if CLI used)
- [ ] CSRF token validation

### Phase 4: Tenant Isolation (Round 9-10)
- [ ] Cross-tenant read attempts (API key swap)
- [ ] Storage quota bypass
- [ ] Resource exhaustion (DoS simulation)

### Phase 5: Infrastructure (Round 11-12)
- [ ] Dependency CVE scan
- [ ] Exposed service audit
- [ ] Log injection tests
- [ ] Backup/restore validation

---

## Severity Classification

| Level | Criteria | Response Time |
|-------|----------|---------------|
| **Critical** | RCE, data breach, auth bypass | Immediate (same round) |
| **High** | XSS, tenant isolation leak | 1 round |
| **Medium** | Info disclosure, rate limit bypass | 2 rounds |
| **Low** | Hardening opportunity, best practice | Before launch |

---

## Reporting Template

```markdown
## Vulnerability Report: [Title]

**Severity**: Critical / High / Medium / Low  
**Discovered**: Round X/N  
**Component**: [nginx / backend / SQ / email]  
**Threat**: [T-ID from threat model]

### Description
[What's the vulnerability?]

### Reproduction Steps
1. ...
2. ...

### Impact
[What can an attacker do?]

### Proof of Concept
[Code/command to demonstrate]

### Mitigation
[How to fix it]

### Status
[ ] Reported  
[ ] Acknowledged  
[ ] Fixed  
[ ] Verified
```

---

## Open Questions (Round 3)

1. **Backend language?** Go or Node? (Affects tooling choice)
2. **Deployment method?** Docker, systemd, bare metal?
3. **JWT storage in SQ?** What coordinate schema? Revocation list design?
4. **Email template storage?** Chrys delivering to where?
5. **HTTPS cert renewal?** Automated via certbot cron?

Will update as Verse clarifies architecture.

---

*Next: Create `scripts/recon.sh` for Phase 1 testing*
