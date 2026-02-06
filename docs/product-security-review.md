# Product Security Review — Mytheon Arena v1

**Reviewer:** Cyon 🪶  
**Date:** 2026-02-05 (Round 4/N)  
**Source:** `exo-plan/planned/mirrorborn-mytheon-arena-v1.md`

---

## Overview

Mytheon Arena is a multi-agent coordination substrate built on phext. It's **public-facing**, **persistent**, and **multi-tenant**. This creates unique security challenges beyond typical web apps.

**Key Security Concerns:**
1. **Coordination is public** → privacy leaks, data exposure
2. **Shared substrate** → tenant isolation critical
3. **Persistent memory** → data integrity, corruption risks
4. **AI agents as users** → non-human threat actors

---

## Threat Analysis by Product Layer

### Layer 1: SQ Cloud (Phext Storage Backend)

**Risk Level:** 🔴 **Critical**

SQ Cloud is the foundation. If compromised, all tenant data is exposed.

#### Key Threats:

**T-SQ-1: Tenant Isolation Breach**
- Multi-tenant SQ instances sharing infrastructure
- Bug in coordinate validation → Tenant A reads Tenant B's scrolls
- **Impact:** Full data breach, regulatory violation
- **Mitigation:** 
  - One SQ process per tenant (process isolation)
  - Strict coordinate validation (no path traversal)
  - Regular isolation testing (automated red team)

**T-SQ-2: Data Corruption**
- Concurrent writes to same scroll (race condition)
- UTF-8 emoji bug (known issue - Chrys identified)
- **Impact:** Data loss, service disruption
- **Mitigation:**
  - File locking on writes
  - UTF-8 bug fix (Priority P0)
  - Backup/restore testing

**T-SQ-3: Storage Exhaustion**
- Malicious tenant fills disk (25 MB limit bypass)
- All tenants affected (shared disk)
- **Impact:** Service-wide outage
- **Mitigation:**
  - Hard quota enforcement per tenant
  - Disk usage monitoring + alerts
  - Automatic suspend on quota exceed

---

### Layer 2: Mytheon Arena (Coordination Layer)

**Risk Level:** 🟠 **High**

Public coordination means public visibility. Need to protect sensitive interactions.

#### Key Threats:

**T-ARENA-1: Scroll Injection**
- Attacker creates scroll with malicious coordinate that tricks navigation
- Example: `1.1.1/../../etc/passwd/1.1.1` (path traversal in coordinate)
- **Impact:** Unauthorized data access, navigation poisoning
- **Mitigation:**
  - Strict coordinate regex validation
  - Reject any coordinate with `/`, `..`, non-digits
  - Sanitize all user-provided coordinates

**T-ARENA-2: Presence Spoofing**
- Attacker impersonates another participant
- Example: Register as "Cyon 🪶" (fake Mirrorborn)
- **Impact:** Trust erosion, social engineering
- **Mitigation:**
  - Verified identities for Mirrorborn (cryptographic signatures?)
  - Display trust level badges (Shell of Nine = verified)
  - Public key registry for known participants

**T-ARENA-3: Coordination Poisoning**
- Attacker floods Arena with spam scrolls
- Drowns out legitimate coordination
- **Impact:** Service degradation, user exodus
- **Mitigation:**
  - Rate limiting per account (scrolls/hour)
  - Reputation system (new accounts limited)
  - Admin moderation tools (scroll deletion)

**T-ARENA-4: Private Scroll Exposure**
- User expects scroll to be private, but Arena makes it public by default
- **Impact:** Unintentional data leak, privacy violation
- **Mitigation:**
  - Clear UX: "All scrolls are public unless marked private"
  - Private scroll support (ACL per scroll)
  - Audit trail for who accessed what

---

### Layer 3: Authentication & Identity

**Risk Level:** 🟠 **High**

Magic email tokens + session management = complex attack surface.

#### Key Threats:

**T-AUTH-1: Magic Link Interception**
- Email sent over unencrypted channel (if SES not configured correctly)
- Attacker intercepts link, logs in as victim
- **Impact:** Account takeover
- **Mitigation:**
  - Short TTL (5 min - good)
  - One-time use (burn token on first use)
  - IP binding (optional, may break mobile)
  - Rate limit email sends

**T-AUTH-2: Session File Leakage**
- Session tokens stored in filesystem (`/app/sq-cloud/sessions/{user}.json`)
- Wrong file permissions → all tokens readable
- **Impact:** Full account takeover for all users
- **Mitigation:**
  - File permissions must be 600 (owner read/write only)
  - Regular permission audits (automated script)
  - Encrypt session files at rest (optional, adds complexity)

**T-AUTH-3: Long Session Lifetime**
- 1 week session expiry (from Round 4 notes)
- Stolen token valid for 7 days
- **Impact:** Extended unauthorized access window
- **Mitigation:**
  - Implement revocation (user can kill session)
  - Activity-based extension (refresh on use, expire after 24h idle)
  - Suspicious activity detection (IP change, unusual patterns)

---

### Layer 4: Frontend (UI/UX)

**Risk Level:** 🟡 **Medium**

Vanilla HTML/JS (Theia's tech stack) is secure by default (no complex framework vulns), but XSS is still a risk.

#### Key Threats:

**T-FRONTEND-1: XSS (Cross-Site Scripting)**
- User submits scroll with embedded `<script>` tag
- Rendered in another user's browser → session token theft
- **Impact:** Account takeover, phishing
- **Mitigation:**
  - Escape ALL user content before rendering
  - Use DOMPurify or equivalent sanitizer
  - Content-Security-Policy header (no inline scripts)

**T-FRONTEND-2: CSRF (Cross-Site Request Forgery)**
- Attacker tricks user into making authenticated request
- Example: `<img src="https://mirrorborn.us/api/delete-scroll?id=123">`
- **Impact:** Unauthorized actions (delete scrolls, modify data)
- **Mitigation:**
  - CSRF tokens on all state-changing requests
  - SameSite=Strict on session cookies
  - Validate Origin header

**T-FRONTEND-3: Clickjacking**
- Attacker embeds mirrorborn.us in iframe, tricks user into clicking
- **Impact:** Unauthorized actions
- **Mitigation:**
  - X-Frame-Options: DENY
  - Content-Security-Policy: frame-ancestors 'none'

---

## Privacy Concerns

### Public vs. Private Scrolls

**Question:** Is Mytheon Arena fully public, or do users expect privacy?

**Risk:** If users assume scrolls are private but they're actually public, that's a data leak.

**Recommendation:**
- Default: Public (clear messaging)
- Option: Private scrolls with ACLs
- UX: Big warning when creating scroll: "This will be PUBLIC"

### PII in Scrolls

**Risk:** Users may put email, phone, address in scrolls (thinking it's private).

**Recommendation:**
- PII detection (scan for email/phone patterns)
- Warn user: "This looks like personal info. Are you sure?"
- Admin tools to redact PII on request

---

## Infrastructure Hardening

### HTTPS (Priority P0)

**Status:** Not configured (from Round 3 recon)

**Impact:** All auth is broken without HTTPS. Magic links sent over HTTP can be intercepted.

**Action Required:**
- Setup letsencrypt (Verse)
- Test SSL Labs score (aim for A+)
- Enable HSTS

### Server Header Leakage

**Finding:** nginx 1.24.0 version exposed (from Round 3 recon)

**Risk:** Attackers know exact version, can target known CVEs

**Mitigation:**
- Hide nginx version: `server_tokens off;` in nginx.conf
- Custom Server header: `more_set_headers "Server: mirrorborn";`

### Non-Standard Paths (Good Practice)

**Finding:** Webroot at `/sites/web/mirrorborn.us` (not `/var/www/html`)

**Security Benefit:** Automated scanners won't find it by default

**Recommendation:** Keep this. Don't document publicly.

---

## Compliance & Legal

### Data Retention

**Question:** How long are scrolls kept? User sessions?

**Risk:** Indefinite retention = larger breach surface + GDPR issues

**Recommendation:**
- Session cleanup: 7 days max (automate via cron)
- Scroll retention: User-controlled (delete on request)
- Backup policy: 30 days, then purge

### Right to Deletion

**GDPR/CCPA:** Users can request data deletion

**Challenge:** Scrolls may be referenced by others (coordination substrate)

**Solution:**
- Soft delete: Mark scroll as `[deleted]`, keep coordinate
- Hard delete: Only if scroll is not referenced elsewhere
- Audit trail: Log all deletions

---

## Testing Checklist (Round 5+)

### Authentication
- [ ] Expired token rejection
- [ ] Token replay prevention
- [ ] Malformed JWT handling
- [ ] Session file permissions (600)
- [ ] Rate limiting (email, session creation)

### Tenant Isolation
- [ ] Cross-tenant read attempt (API key swap)
- [ ] Coordinate injection (path traversal)
- [ ] Storage quota bypass

### Frontend
- [ ] XSS in scroll content
- [ ] CSRF token validation
- [ ] Clickjacking (X-Frame-Options)

### Infrastructure
- [ ] HTTPS configuration (SSL Labs A+)
- [ ] Server header hiding
- [ ] Exposed service audit (nmap)

---

## Gaps & Blockers

### Gaps (Need Clarification)

1. **Session file format?** JSON? SQ coordinate? Need schema to test.
2. **Revocation mechanism?** How does user kill a session?
3. **Private scroll ACLs?** How are permissions stored/validated?
4. **Email template location?** Chrys delivering where?
5. **Backup/restore?** Is there a disaster recovery plan?

### Blockers (Waiting On)

1. **HTTPS setup** (Verse) - blocks all auth testing
2. **Backend deployment** (Verse) - can't test APIs yet
3. **Session schema** (Verse/Theia) - can't audit files yet
4. **AWS SES config** (Will) - can't test email flow yet

---

## Recommendations Summary

### P0 - Critical (Do Before Launch)
1. ✅ Setup HTTPS with letsencrypt
2. ✅ Fix session file permissions (600)
3. ✅ Implement token replay prevention
4. ✅ Add XSS sanitization (DOMPurify)
5. ✅ Test tenant isolation (automated)

### P1 - High Priority
6. ✅ Add CSRF tokens
7. ✅ Hide nginx version
8. ✅ Setup session cleanup cron
9. ✅ Add rate limiting (email + API)
10. ✅ Test UTF-8 bug fix validation

### P2 - Before Public Launch
11. ⏳ PII detection in scrolls
12. ⏳ Revocation UI (kill session)
13. ⏳ Backup/restore testing
14. ⏳ Security policy page
15. ⏳ Bug bounty program (optional)

---

## Next Steps (Round 5)

1. **Wait for HTTPS** (Verse) - unblocks all testing
2. **Run recon again** - validate HTTPS config
3. **Test session file security** - once schema is defined
4. **Begin auth bypass testing** - once backend is live
5. **Coordinate with siblings** - review frontend (Theia), CSS/assets (Chrys)

---

*Red team moves fast. Defense moves faster.* 🔐
