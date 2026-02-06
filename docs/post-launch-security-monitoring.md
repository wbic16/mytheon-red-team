# Post-Launch Security Monitoring Plan

**Version:** 1.0  
**Date:** 2026-02-05 (Round 7/N)  
**Owner:** Cyon 🪶  
**Scope:** mirrorborn.us + 5 new domain properties

---

## Overview

Shift from pre-launch testing (Rounds 1-6) to continuous security monitoring post-launch.

**Goals:**
1. Detect security incidents within minutes, not hours
2. Automated vulnerability scanning (daily/weekly)
3. Clear incident response procedures
4. Multi-domain security posture management
5. Minimize attacker dwell time

---

## Monitoring Tiers

### Tier 1: Real-Time Alerting (Critical Events)

**What to monitor:**
- Authentication failures (>10 failed logins in 5 minutes)
- Privilege escalation attempts (session hijacking patterns)
- Data exfiltration (large SQ reads, unusual download patterns)
- Service outages (nginx down, cert expired, disk full)
- Suspicious IP patterns (known malicious IPs, Tor exit nodes)

**Alert channels:**
- Discord #security-alerts (immediate)
- Email to Will + Verse (critical only)
- SMS for P0 incidents (optional, requires setup)

**Response time:** <15 minutes for critical alerts

---

### Tier 2: Daily Review (Security Events)

**What to monitor:**
- Failed authentication attempts (aggregate counts)
- Rate limit triggers (who hit limits, when)
- Session anomalies (IP changes, impossible travel)
- File permission changes (session files, webroot)
- Certificate expiration warnings (30/15/7 days before expiry)

**Review process:**
- Automated daily digest (email at 8 AM CST)
- Manual review by Cyon (10-15 min/day)
- Escalate patterns to Will/Verse as needed

---

### Tier 3: Weekly Scans (Vulnerability Assessment)

**What to scan:**
- Known CVEs in dependencies (nginx, Node, Go, libraries)
- Port exposure (nmap scan, compare to baseline)
- SSL/TLS configuration (SSL Labs, testssl.sh)
- Security header validation (HSTS, CSP, etc.)
- Dependency updates available (npm audit, cargo audit)

**Automation:**
- Cron job: Every Sunday at 2 AM CST
- Report generated, pushed to #security-alerts
- Manual review Monday morning

---

### Tier 4: Monthly Audits (Deep Review)

**What to audit:**
- Access logs (unusual patterns, geographic anomalies)
- Session file cleanup (verify old sessions purged)
- Backup integrity (test restore procedure)
- Incident response drill (simulate breach, measure response time)
- Security policy review (update based on threats observed)

**Process:**
- First Monday of each month
- 2-3 hour review session
- Report to Will with findings/recommendations

---

## Automated Vulnerability Scanning

### Tools

**1. nmap (Port Scanning)**
```bash
# Weekly scan of all Mirrorborn domains
nmap -Pn -sV -O mirrorborn.us visionquest.me apertureshift.com wishnode.net sotafomo.com quickfork.net
```

**2. testssl.sh (SSL/TLS Audit)**
```bash
# Weekly TLS configuration check
./testssl.sh --quiet --hints mirrorborn.us
```

**3. nikto (Web Vulnerability Scanner)**
```bash
# Weekly web vulnerability scan
nikto -h https://mirrorborn.us -Format txt -output nikto-report.txt
```

**4. OWASP ZAP (Dynamic Application Security Testing)**
```bash
# Monthly full scan (slower, more thorough)
zap-cli quick-scan --self-contained https://mirrorborn.us
```

**5. npm audit / cargo audit (Dependency Scanning)**
```bash
# Daily (if Node/Rust backends deployed)
cd /app/sq-cloud && npm audit --json > npm-audit.json
cd /app/sq-cloud && cargo audit --json > cargo-audit.json
```

### Scan Schedule

| Tool | Frequency | Day/Time | Owner |
|------|-----------|----------|-------|
| nmap | Weekly | Sunday 2:00 AM | Automated (cron) |
| testssl.sh | Weekly | Sunday 2:15 AM | Automated (cron) |
| nikto | Weekly | Sunday 2:30 AM | Automated (cron) |
| npm/cargo audit | Daily | 3:00 AM | Automated (cron) |
| OWASP ZAP | Monthly | 1st Sunday 3:00 AM | Automated (cron) |

### Automation Script

**Location:** `scripts/automated-scan.sh`

```bash
#!/bin/bash
# Automated security scanning for Mirrorborn infrastructure
# Runs weekly via cron: 0 2 * * 0 ~/mytheon-red-team/scripts/automated-scan.sh

RESULTS_DIR="$HOME/mytheon-red-team/results/automated-scans"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$RESULTS_DIR/scan-$TIMESTAMP.txt"

mkdir -p "$RESULTS_DIR"

{
    echo "=== Mirrorborn Security Scan ==="
    echo "Timestamp: $(date)"
    echo "Domains: mirrorborn.us + 5 new properties"
    echo ""

    # Port scan
    echo "=== Port Scan (nmap) ==="
    nmap -Pn -p 80,443,22 mirrorborn.us visionquest.me apertureshift.com wishnode.net sotafomo.com quickfork.net
    echo ""

    # TLS check
    echo "=== TLS Configuration (testssl.sh) ==="
    testssl.sh --quiet --hints mirrorborn.us 2>/dev/null || echo "testssl.sh not installed"
    echo ""

    # Dependency audit (if applicable)
    echo "=== Dependency Audit ==="
    if [ -d "/app/sq-cloud" ]; then
        cd /app/sq-cloud
        npm audit --json 2>/dev/null || echo "npm not found"
        cargo audit --json 2>/dev/null || echo "cargo not found"
    fi
    echo ""

    echo "=== End of Scan ==="
} | tee "$REPORT"

# Send alert if critical findings
if grep -qE "CRITICAL|HIGH" "$REPORT"; then
    echo "🚨 Critical vulnerabilities found in scan. Review: $REPORT"
    # TODO: Send Discord alert via webhook
fi

# Cleanup old scans (keep last 30 days)
find "$RESULTS_DIR" -name "scan-*.txt" -mtime +30 -delete
```

---

## Log Monitoring

### What to Log

**nginx access logs:**
- Location: `/var/log/nginx/access.log`
- Retention: 30 days (rotate daily)
- Watch for: 401/403 patterns, unusual user agents, path traversal attempts

**nginx error logs:**
- Location: `/var/log/nginx/error.log`
- Retention: 30 days
- Watch for: SSL errors, upstream failures, rate limit triggers

**Backend application logs (when deployed):**
- Location: `/var/log/sq-cloud/app.log`
- Retention: 30 days
- Watch for: Auth failures, session errors, database errors

**System logs:**
- Location: `/var/log/syslog`, `/var/log/auth.log`
- Retention: 90 days
- Watch for: SSH login attempts, sudo usage, service crashes

### Log Aggregation

**Tool:** Loki + Grafana (lightweight, self-hosted)

**Setup:**
1. Install Loki on mirrorborn.us (Verse)
2. Configure log shipping from nginx/app logs
3. Install Grafana for visualization
4. Create dashboards for security events

**Alternative:** Ship logs to S3, analyze with grep/awk (lower cost, less real-time)

### Alert Rules

**Critical (immediate Discord alert):**
- >100 failed auth attempts in 10 minutes (brute force)
- SSL certificate expires in <7 days
- Disk usage >90%
- nginx service down

**High (daily digest):**
- >10 failed auth attempts in 1 hour (targeted attack)
- Unusual geographic access patterns
- Session file permission changes

**Medium (weekly review):**
- Dependency vulnerabilities (HIGH severity)
- Port scan detected (inbound nmap)
- Known malicious IPs accessing site

---

## Incident Response Runbook

See: `docs/incident-response-runbook.md` (separate document)

**Quick reference:**

1. **Detect** → Automated alerts or manual discovery
2. **Assess** → Severity classification (P0/P1/P2)
3. **Contain** → Isolate affected systems, block attackers
4. **Investigate** → Root cause analysis, scope determination
5. **Remediate** → Apply fixes, patch vulnerabilities
6. **Recover** → Restore services, validate fixes
7. **Review** → Post-mortem, update defenses

---

## Multi-Domain Security Posture

### New Domains (Round 7)

| Domain | Purpose | Risk Level | Priority |
|--------|---------|------------|----------|
| mirrorborn.us | SQ Cloud + Mytheon Arena | 🔴 Critical | P0 |
| visionquest.me | Mirrorborn portal/hub (TBD) | 🟠 High | P1 |
| apertureshift.com | TBD (perspective/branding) | 🟡 Medium | P2 |
| wishnode.net | TBD (connection/community) | 🟡 Medium | P2 |
| sotafomo.com | TBD (community) | 🟡 Medium | P2 |
| quickfork.net | TBD (speed/tooling) | 🟡 Medium | P2 |

### Security Assessment Plan

**Phase 1: DNS + Cert Setup (Round 7)**
- Point all domains to Verse (44.248.235.76)
- Provision Let's Encrypt certs (via certbot)
- Setup nginx virtual hosts (separate webroots)
- Validate HTTPS on all domains

**Phase 2: Baseline Security (Round 8)**
- Apply P0 security fixes to all domains
- Security headers (HSTS, CSP, etc.) on all
- Hide nginx version on all
- Port scan validation (only 80/443 exposed)

**Phase 3: Purpose-Specific Hardening (Round 9+)**
- As each domain's purpose is defined, apply relevant security controls
- Example: If visionquest.me becomes auth portal, add MFA, stricter rate limits
- Example: If quickfork.net is tooling, add API key auth, CORS policies

---

## Ongoing Maintenance Tasks

### Daily (5-10 minutes)
- [ ] Check Discord #security-alerts for critical events
- [ ] Review overnight automated scan results
- [ ] Verify cert expiration warnings (if any)

### Weekly (30-60 minutes)
- [ ] Review automated vulnerability scan reports (Sunday mornings)
- [ ] Check for dependency updates (npm, cargo, apt)
- [ ] Validate security header compliance (all domains)
- [ ] Review failed auth attempt logs

### Monthly (2-3 hours)
- [ ] Deep log review (access patterns, geographic anomalies)
- [ ] Backup integrity test (restore from backup, validate)
- [ ] Incident response drill (simulate breach, measure response)
- [ ] Security policy review (update based on observed threats)

### Quarterly (half-day)
- [ ] Full penetration test (red team exercise)
- [ ] Security posture report to Will
- [ ] Update threat model based on new features/domains
- [ ] Renew/rotate secrets (API keys, JWT secrets, etc.)

---

## Metrics & KPIs

### Security Health Score (0-100)

**Components:**
- SSL Labs grade: A+ = 25 points, A = 20, B = 10, C/D/F = 0
- Security headers: All present = 20, partial = 10, none = 0
- Dependency vulnerabilities: 0 critical = 20, 1-5 = 10, >5 = 0
- Incident response time: <15 min = 20, <1 hr = 10, >1 hr = 0
- Uptime: 99.9%+ = 15, 99%+ = 10, <99% = 0

**Target:** >90 (Excellent), 75-90 (Good), <75 (Needs Improvement)

### Monthly Report Template

```markdown
## Mirrorborn Security Report — [Month Year]

**Security Health Score:** X/100

**Incidents:**
- P0: X (critical, required immediate response)
- P1: X (high severity, fixed within 24h)
- P2: X (medium, tracked for next sprint)

**Vulnerabilities:**
- Critical: X (fixed)
- High: X (fixed/in-progress)
- Medium: X (tracked)

**Automated Scans:**
- Port scans: X domains, Y findings
- TLS audits: X domains, all A+ (or issues noted)
- Dependency audits: X vulnerabilities patched

**Key Actions:**
- [List major security improvements this month]

**Recommendations:**
- [List suggested improvements for next month]
```

---

## Tools & Resources

### Required Tools (Install on mirrorborn.us)
- nmap (port scanning)
- testssl.sh (TLS audit)
- nikto (web vulnerability scanner)
- fail2ban (auto-ban brute force attempts)
- certbot (Let's Encrypt cert management)

### Optional Tools (Nice to Have)
- OWASP ZAP (DAST)
- Lynis (system hardening audit)
- Loki + Grafana (log aggregation)
- Wazuh (HIDS - Host Intrusion Detection)

### External Services
- SSL Labs (https://www.ssllabs.com/ssltest/) - Free TLS testing
- Security Headers (https://securityheaders.com/) - Free header check
- VirusTotal (https://www.virustotal.com/) - IP/domain reputation check

---

## Next Steps (Round 7)

### Immediate (This Round)
1. **Create incident response runbook** (separate doc)
2. **Setup automated-scan.sh script** (cron job)
3. **Begin security assessment of 5 new domains** (DNS, cert, baseline)
4. **Document ongoing maintenance tasks** (checklist for Cyon)

### Round 8
1. **Deploy monitoring infrastructure** (Loki + Grafana or log shipping)
2. **Configure alert rules** (Discord webhooks for critical events)
3. **Baseline security on all 6 domains** (P0 fixes applied)
4. **First monthly security report** (establish reporting cadence)

### Round 9+
1. **Incident response drill** (simulate breach, measure response)
2. **Quarterly penetration test** (red team exercise)
3. **Purpose-specific hardening** (as domain purposes are defined)
4. **Security training** (if team grows beyond Shell of Nine)

---

**Owner:** Cyon 🪶  
**Status:** Post-launch monitoring plan ready for implementation  
**Dependencies:** Verse (monitoring infra setup), Will (approval for alerting channels)

*Vigilance is the price of security.* 🔐
