# Multi-Domain Security Assessment

**Version:** 1.0  
**Date:** 2026-02-05 (Round 7/N)  
**Owner:** Cyon 🪶  
**Scope:** 5 new Mirrorborn brand domains

---

## Overview

Assessing security posture for Mirrorborn's expanding domain portfolio:

| Domain | Status | Purpose | Priority |
|--------|--------|---------|----------|
| mirrorborn.us | ✅ Live | SQ Cloud + Mytheon Arena | P0 (Critical) |
| visionquest.me | 🟡 TBD | Mirrorborn portal/hub | P1 (High) |
| apertureshift.com | 🟡 TBD | Perspective/branding | P2 (Medium) |
| wishnode.net | 🟡 TBD | Connection/community | P2 (Medium) |
| sotafomo.com | 🟡 TBD | Community | P2 (Medium) |
| quickfork.net | 🟡 TBD | Speed/tooling | P2 (Medium) |

---

## Security Assessment Framework

### Phase 1: Infrastructure Baseline (Round 7)

**Goal:** Establish secure foundation before defining purposes.

**Tasks:**
1. DNS configuration (all domains point to Verse's IP)
2. HTTPS certificate provisioning (Let's Encrypt)
3. nginx virtual host setup (separate webroots)
4. Baseline security (headers, server hardening)
5. Monitoring integration (uptime, alerts)

**Success Criteria:**
- All domains resolve to 44.248.235.76
- All domains have valid HTTPS certificates
- All domains return proper security headers
- No server version disclosure on any domain

---

### Phase 2: Purpose-Specific Hardening (Round 8+)

**Goal:** Apply security controls based on each domain's function.

**Approach:**
- As each domain's purpose is defined, assess unique threats
- Apply appropriate security controls (auth, rate limiting, CORS, etc.)
- Test and validate before launch

---

## Domain-by-Domain Assessment

### 1. mirrorborn.us (P0 — Critical)

**Status:** ✅ Live (HTTPS configured, baseline security applied)

**Purpose:** SQ Cloud + Mytheon Arena (multi-tenant phext storage + coordination)

**Threat Profile:**
- Multi-tenant data isolation (highest risk)
- User authentication (magic links, sessions)
- Persistent storage (phext files, session files)
- Public-facing API (SQ REST endpoints)

**Security Controls (Applied):**
- ✅ HTTPS with Let's Encrypt
- 🔴 Security headers (P0 - pending Verse)
- 🔴 nginx version hiding (P0 - pending Verse)
- 🟠 Session file permissions (P1 - pending backend deploy)
- 🟠 Rate limiting (P1 - pending backend deploy)

**Next Steps:**
- Validate P0 fixes (Round 7)
- Complete P1 testing (Round 8)
- Production launch (Round 8-9)

---

### 2. visionquest.me (P1 — High)

**Status:** 🟡 Not yet configured

**Proposed Purpose:** Mirrorborn portal/hub (entry point, navigation, branding)

**Threat Profile (Estimated):**
- Landing page (static content, low risk)
- Navigation links (potential for abuse if not validated)
- Contact forms (spam, injection risks)
- Branding assets (CDN, content integrity)

**Recommended Security Controls:**

**Phase 1 (Baseline):**
- [ ] DNS A record → 44.248.235.76
- [ ] Let's Encrypt certificate
- [ ] nginx virtual host (webroot: `/sites/web/visionquest.me`)
- [ ] Security headers (HSTS, CSP, X-Frame-Options)
- [ ] Server version hiding

**Phase 2 (Purpose-Specific):**
- [ ] Content Security Policy (strict, since mostly static)
- [ ] Subresource Integrity (SRI) for any CDN assets
- [ ] Form validation + CAPTCHA (if contact forms added)
- [ ] Rate limiting (form submissions, API calls)

**Threat Scenarios:**
1. **Defacement:** Attacker modifies landing page
   - Mitigation: File integrity monitoring, backup/restore
2. **Phishing:** Attacker creates look-alike subdomain
   - Mitigation: DNSSEC, DMARC, certificate transparency monitoring
3. **SEO Spam:** Attacker injects hidden links for SEO
   - Mitigation: CSP, regular content audits

**Launch Timeline:** Round 8-9 (after mirrorborn.us stabilizes)

---

### 3. apertureshift.com (P2 — Medium)

**Status:** 🟡 Not yet configured

**Proposed Purpose:** Perspective/branding (TBD by team)

**Potential Use Cases:**
- Blog/content platform (writing, updates, announcements)
- Documentation hub (technical docs, guides, tutorials)
- Image/media gallery (branding assets, screenshots, demos)

**Threat Profile (Estimated):**
- **If blog/CMS:** High (XSS, CSRF, auth bypass, content injection)
- **If static docs:** Low (mostly static HTML/markdown)
- **If media gallery:** Medium (file upload, MIME-type validation)

**Recommended Security Controls:**

**Phase 1 (Baseline):**
- [ ] DNS + HTTPS (same as visionquest.me)
- [ ] Security headers
- [ ] Server hardening

**Phase 2 (Purpose-Specific - CMS scenario):**
- [ ] Admin authentication (separate from SQ Cloud auth)
- [ ] Content sanitization (markdown → HTML with XSS protection)
- [ ] File upload validation (if media uploads allowed)
- [ ] Version control for content (audit trail)
- [ ] Backup/restore for content database

**Phase 2 (Purpose-Specific - Static docs scenario):**
- [ ] Static site generator (Hugo, Jekyll, etc.)
- [ ] No database, no auth (lower attack surface)
- [ ] Content versioned in Git (audit trail built-in)
- [ ] Automated deploy pipeline (CI/CD with validation)

**Threat Scenarios:**
1. **Content Injection:** Attacker edits blog post, injects malicious script
   - Mitigation: Content sanitization, version control
2. **File Upload Exploit:** Attacker uploads PHP shell disguised as image
   - Mitigation: MIME-type validation, file extension whitelist, no script execution in upload dir
3. **SEO Hijacking:** Attacker adds spammy content for search ranking
   - Mitigation: Admin notifications on content changes, regular audits

**Launch Timeline:** Round 9-10 (after visionquest.me)

---

### 4. wishnode.net (P2 — Medium)

**Status:** 🟡 Not yet configured

**Proposed Purpose:** Connection/community (TBD by team)

**Potential Use Cases:**
- Community forum (discussion, Q&A, support)
- Social network (profiles, connections, messaging)
- Collaboration space (shared projects, coordination)

**Threat Profile (Estimated):**
- **If community forum:** High (spam, abuse, doxxing, credential stuffing)
- **If collaboration space:** High (data leakage, unauthorized access)

**Recommended Security Controls:**

**Phase 1 (Baseline):**
- [ ] DNS + HTTPS
- [ ] Security headers
- [ ] Server hardening

**Phase 2 (Purpose-Specific - Forum scenario):**
- [ ] User authentication (email verification required)
- [ ] Rate limiting (posts, signups, logins)
- [ ] Spam detection (CAPTCHA, content filters)
- [ ] Abuse reporting (flagging, moderation tools)
- [ ] Data privacy (GDPR compliance, user data export/deletion)

**Phase 2 (Purpose-Specific - Collaboration scenario):**
- [ ] Role-based access control (RBAC)
- [ ] Audit logging (who accessed what, when)
- [ ] Data encryption at rest (sensitive collaboration data)
- [ ] Backup/restore (collaboration content)

**Threat Scenarios:**
1. **Spam Flood:** Bots create accounts, post spam
   - Mitigation: Email verification, CAPTCHA, rate limiting
2. **Doxxing:** User posts personal info about others
   - Mitigation: Content moderation, abuse reporting, user education
3. **Data Breach:** Unauthorized access to private messages/projects
   - Mitigation: Encryption, access controls, audit logging

**Launch Timeline:** Round 10+ (complex, requires planning)

---

### 5. sotafomo.com (P2 — Medium)

**Status:** 🟡 Not yet configured

**Proposed Purpose:** Community (TBD by team)

**Potential Use Cases:**
- Event calendar (meetups, launches, announcements)
- Newsletter/mailing list (updates, engagement)
- Community directory (members, projects, resources)

**Threat Profile (Estimated):**
- **If event calendar:** Low-Medium (spam, fake events)
- **If newsletter:** Medium (spam, unsubscribe abuse)
- **If directory:** Medium (profile abuse, SEO spam)

**Recommended Security Controls:**

**Phase 1 (Baseline):**
- [ ] DNS + HTTPS
- [ ] Security headers
- [ ] Server hardening

**Phase 2 (Purpose-Specific):**
- [ ] Email verification (for newsletter signups)
- [ ] Rate limiting (event submissions, signups)
- [ ] Spam detection (CAPTCHA, content filters)
- [ ] Unsubscribe compliance (one-click, no auth required)
- [ ] Data privacy (GDPR, mailing list export)

**Threat Scenarios:**
1. **Newsletter Spam:** Attacker subscribes thousands of fake emails
   - Mitigation: CAPTCHA, email verification, rate limiting
2. **Fake Events:** Attacker creates phishing event listing
   - Mitigation: Event moderation, verified organizers only
3. **Directory SEO Spam:** Attacker creates fake profiles with spam links
   - Mitigation: Profile moderation, link validation, nofollow tags

**Launch Timeline:** Round 10+ (after wishnode.net)

---

### 6. quickfork.net (P2 — Medium)

**Status:** 🟡 Not yet configured

**Proposed Purpose:** Speed/tooling (TBD by team)

**Potential Use Cases:**
- Developer tools (CLI, API, libraries)
- Code snippets/gists (sharing, collaboration)
- CI/CD platform (build, test, deploy)
- API gateway (unified access to Mirrorborn services)

**Threat Profile (Estimated):**
- **If developer tools:** High (supply chain attacks, malicious packages)
- **If code snippets:** Medium (XSS, code injection)
- **If CI/CD:** Critical (build server compromise, deployment hijacking)
- **If API gateway:** Critical (API abuse, credential theft, DoS)

**Recommended Security Controls:**

**Phase 1 (Baseline):**
- [ ] DNS + HTTPS
- [ ] Security headers
- [ ] Server hardening

**Phase 2 (Purpose-Specific - Developer tools scenario):**
- [ ] Code signing (packages, binaries)
- [ ] Checksum verification (SHA256 hashes published)
- [ ] Supply chain security (dependency scanning, SBOM)
- [ ] Malware scanning (uploaded packages)

**Phase 2 (Purpose-Specific - API gateway scenario):**
- [ ] API key authentication (rate-limited, per-key quotas)
- [ ] OAuth 2.0 support (for third-party integrations)
- [ ] Rate limiting (per-endpoint, per-key, global)
- [ ] DDoS protection (Cloudflare, rate limiting, IP blocking)
- [ ] API versioning (backward compatibility, deprecation policy)

**Threat Scenarios:**
1. **Supply Chain Attack:** Attacker uploads malicious tool/package
   - Mitigation: Code review, malware scanning, community vetting
2. **API Abuse:** Attacker hammers API with requests, causes DoS
   - Mitigation: Rate limiting, API keys, DDoS protection
3. **Credential Theft:** Attacker intercepts API keys in transit
   - Mitigation: HTTPS only, no keys in URLs, rotation policy

**Launch Timeline:** Round 11+ (complex, requires infrastructure planning)

---

## Shared Security Requirements (All Domains)

### Baseline (Apply to All)

1. **DNS Configuration:**
   - A record pointing to 44.248.235.76
   - CAA record: `0 issue "letsencrypt.org"`
   - DNSSEC (optional, improves trust)

2. **HTTPS:**
   - Let's Encrypt certificate (auto-renewal via certbot)
   - HTTP → HTTPS redirect (301)
   - HSTS header (max-age=31536000)

3. **Security Headers:**
   - Strict-Transport-Security (HSTS)
   - Content-Security-Policy (CSP)
   - X-Frame-Options: DENY
   - X-Content-Type-Options: nosniff
   - X-XSS-Protection: 1; mode=block
   - Referrer-Policy: strict-origin-when-cross-origin

4. **Server Hardening:**
   - Hide nginx version (`server_tokens off`)
   - Minimal attack surface (only ports 80, 443 exposed)
   - Firewall rules (iptables, fail2ban)

5. **Monitoring:**
   - Uptime monitoring (all domains)
   - Certificate expiration alerts (30/15/7 days)
   - Error rate tracking (nginx logs)
   - Security event logging (failed auth, suspicious patterns)

---

## Deployment Checklist (Per Domain)

### Phase 1: Infrastructure Setup

- [ ] **DNS Configuration**
  - [ ] A record → 44.248.235.76
  - [ ] CAA record for letsencrypt.org
  - [ ] Verify DNS propagation (dig +short)

- [ ] **Certificate Provisioning**
  - [ ] Run certbot: `sudo certbot certonly --nginx -d <domain>`
  - [ ] Verify cert: `sudo certbot certificates`
  - [ ] Test HTTPS: `curl -I https://<domain>`

- [ ] **nginx Configuration**
  - [ ] Create virtual host config: `/etc/nginx/sites-available/<domain>`
  - [ ] Set webroot: `/sites/web/<domain>`
  - [ ] Add security headers
  - [ ] Hide server version
  - [ ] HTTP → HTTPS redirect
  - [ ] Enable config: `ln -s /etc/nginx/sites-available/<domain> /etc/nginx/sites-enabled/`
  - [ ] Test config: `sudo nginx -t`
  - [ ] Reload: `sudo systemctl reload nginx`

- [ ] **Security Validation**
  - [ ] Run port scan: `nmap -Pn -p 80,443 <domain>`
  - [ ] Check SSL Labs: https://www.ssllabs.com/ssltest/
  - [ ] Verify headers: `curl -I https://<domain> | grep -E "Strict-Transport|X-Frame|Content-Security"`

- [ ] **Monitoring Integration**
  - [ ] Add to uptime monitoring
  - [ ] Configure cert expiration alerts
  - [ ] Add to automated security scan (weekly)

### Phase 2: Purpose-Specific Security

- [ ] **Threat Model**
  - [ ] Document intended purpose
  - [ ] Identify threat actors (who would attack this?)
  - [ ] List attack vectors (how would they attack?)
  - [ ] Assess impact (what's the worst-case scenario?)

- [ ] **Security Controls**
  - [ ] Apply purpose-specific hardening (see domain sections above)
  - [ ] Test security controls (pen test, automated scan)
  - [ ] Document exceptions/risks (if any controls can't be applied)

- [ ] **Launch Readiness**
  - [ ] Security review (Cyon validates)
  - [ ] Penetration test (red team exercise)
  - [ ] Incident response plan (specific to domain)
  - [ ] Backup/restore procedure tested

---

## Risk Summary

### High-Risk Domains (Require Extra Scrutiny)

1. **mirrorborn.us** (P0)
   - Multi-tenant, persistent storage, public API
   - Already live, highest exposure

2. **quickfork.net** (P2)
   - If used for CI/CD or API gateway
   - Critical infrastructure, supply chain risk

3. **wishnode.net** (P2)
   - If used for community/collaboration
   - User-generated content, abuse potential

### Medium-Risk Domains

1. **visionquest.me** (P1)
   - Landing page, mostly static
   - Branding asset, reputational risk

2. **apertureshift.com** (P2)
   - If used for blog/CMS
   - Content injection, XSS risk

3. **sotafomo.com** (P2)
   - If used for events/newsletter
   - Spam, privacy compliance

---

## Next Steps (Round 7)

### Immediate Actions

1. **Coordinate with Verse:**
   - Confirm DNS records for 5 new domains
   - Plan nginx virtual host setup
   - Schedule cert provisioning

2. **Create Deployment Script:**
   - Automate DNS + cert + nginx setup
   - Parameterize by domain
   - Test on one domain (visionquest.me), then replicate

3. **Baseline Security Validation:**
   - Run automated-scan.sh on all 6 domains
   - Document findings
   - Track remediation

### Round 8+

1. **Purpose Definition:**
   - Team defines purpose for each domain
   - Cyon assesses purpose-specific threats
   - Apply appropriate security controls

2. **Phased Launch:**
   - mirrorborn.us → production (Round 8)
   - visionquest.me → production (Round 9)
   - Others as purposes are defined

---

**Owner:** Cyon 🪶  
**Status:** Ready to begin Phase 1 infrastructure setup  
**Dependencies:** Verse (DNS + nginx config), Team (purpose definition for domains)

*Six domains. One security posture. Zero compromises.* 🔐
