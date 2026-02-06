# Ongoing Security Maintenance Tasks

**Owner:** Cyon 🪶  
**Last Updated:** 2026-02-05 (Round 7/N)  
**Scope:** Mirrorborn infrastructure (all 6 domains)

---

## Daily Tasks (5-10 minutes)

### Morning Security Check

**Time:** First thing each day, 8-9 AM CST

**Tasks:**
- [ ] Check Discord #security-alerts for overnight alerts
- [ ] Review automated scan results (if run overnight)
- [ ] Verify cert expiration warnings (if any)
- [ ] Check uptime monitoring dashboard
- [ ] Scan failed auth attempt logs (quick grep)

**Tools:**
- Discord (alerts)
- Monitoring dashboard (when deployed)
- `sudo grep "Failed password" /var/log/auth.log | tail -20`

**Expected Time:** 5 minutes if no issues, 30+ minutes if investigating alerts

**Escalation:** If critical alerts, follow incident response runbook

---

## Weekly Tasks (30-60 minutes)

### Sunday Morning Security Review

**Time:** Every Sunday, 9-10 AM CST (after automated scan runs at 2 AM)

**Tasks:**
- [ ] Review automated vulnerability scan report
- [ ] Check for dependency updates (npm, cargo, apt)
- [ ] Validate security header compliance (all 6 domains)
- [ ] Review failed auth attempt patterns (weekly aggregate)
- [ ] Check for new CVEs affecting our stack (nginx, Node, Rust)

**Tools:**
- `~/mytheon-red-team/results/automated-scans/scan-[latest].txt`
- `sudo apt list --upgradable`
- `cd /app/sq-cloud && npm outdated`
- `cd /app/sq-cloud && cargo outdated`
- CVE tracking: https://nvd.nist.gov/

**Outputs:**
- Weekly security digest (Discord #security-alerts)
- Prioritized fix list (if vulnerabilities found)

**Template:**
```markdown
## Weekly Security Digest — [Date]

**Scan Results:**
- Domains scanned: 6
- Critical findings: X
- Warnings: Y

**Dependency Updates:**
- npm: X packages (Y critical)
- cargo: X crates (Y critical)
- apt: X packages (Y security)

**Failed Auth Attempts:**
- Total: X
- Unique IPs: Y
- Blocked: Z (via fail2ban)

**Action Items:**
- [ ] Fix: [critical issue]
- [ ] Update: [dependency]
- [ ] Monitor: [suspicious pattern]

**Next Week:**
- [Any scheduled maintenance]
```

---

## Monthly Tasks (2-3 hours)

### First Monday Security Audit

**Time:** First Monday of each month, 2-5 PM CST

**Tasks:**
- [ ] Deep log review (nginx access/error, auth, syslog)
- [ ] Session file cleanup validation (old sessions purged?)
- [ ] Backup integrity test (restore from backup, validate)
- [ ] Certificate expiration forecast (next 90 days)
- [ ] Security policy review (update based on observed threats)

**Deep Log Review Checklist:**
- [ ] Geographic anomalies (access from unexpected countries)
- [ ] Time-based patterns (unusual activity at odd hours)
- [ ] User agent analysis (bots, scrapers, unusual clients)
- [ ] Error spike investigation (what caused 500s, 401s)
- [ ] Slow query detection (performance anomalies)

**Backup Integrity Test:**
```bash
# Test backup restore (on staging, never production)
sudo tar -xzf /backup/latest.tar.gz -C /tmp/restore-test
sudo diff -r /app/sq-cloud /tmp/restore-test/app/sq-cloud
# Validate: files match, no corruption
```

**Outputs:**
- Monthly security report (detailed, for Will + team)
- Updated threat model (if new threats observed)
- Remediation plan (prioritized fixes)

---

## Quarterly Tasks (half-day, 4-6 hours)

### Quarterly Security Deep Dive

**Time:** Last Friday of quarter (March, June, September, December)

**Tasks:**
- [ ] Full penetration test (red team exercise)
- [ ] Security posture report (comprehensive assessment)
- [ ] Threat model update (new features, new domains, new threats)
- [ ] Secret rotation (API keys, JWT secrets, SSH keys)
- [ ] Incident response drill (simulate breach, measure response)

**Penetration Test Scope:**
- All 6 domains (mirrorborn.us + 5 new properties)
- All attack vectors (auth, injection, DoS, privilege escalation)
- Fresh perspective (pretend you've never seen the system before)

**Secret Rotation Checklist:**
- [ ] JWT signing secret (rotate, invalidate old sessions)
- [ ] API keys (SQ Cloud tenant keys, rotate on schedule)
- [ ] SSH keys (generate new, revoke old)
- [ ] Let's Encrypt account key (optional, low priority)
- [ ] Discord webhook URLs (rotate if exposed)

**Security Posture Report Sections:**
1. Executive Summary (overall health score, key metrics)
2. Infrastructure Status (uptime, performance, incidents)
3. Vulnerability Summary (critical/high/medium/low counts)
4. Threat Landscape (new threats observed, industry trends)
5. Incident Review (P0/P1 incidents this quarter)
6. Roadmap (upcoming security improvements)

---

## Ad-Hoc Tasks (As Needed)

### When New Features Launch

**Trigger:** New domain goes live, new feature added to existing domain

**Tasks:**
- [ ] Threat model update (new attack surface analysis)
- [ ] Security controls validation (purpose-specific hardening)
- [ ] Penetration test (focus on new feature)
- [ ] Monitoring integration (alerts for new endpoints)
- [ ] Documentation update (security runbooks, incident response)

---

### When Incidents Occur

**Trigger:** P0/P1 security incident

**Tasks:**
- [ ] Immediate response (follow incident response runbook)
- [ ] Post-mortem (within 48 hours of resolution)
- [ ] Remediation (fix root cause, harden defenses)
- [ ] Monitoring enhancement (detect similar incidents faster)
- [ ] Runbook update (improve procedures based on lessons learned)

---

### When CVEs Announced

**Trigger:** New CVE affecting our stack (nginx, Node, Rust, dependencies)

**Tasks:**
- [ ] Impact assessment (are we affected? which domains?)
- [ ] Severity classification (P0/P1/P2 based on exploitability)
- [ ] Patch availability check (is fix available?)
- [ ] Testing (apply patch to staging, validate)
- [ ] Production deployment (follow change management process)
- [ ] Validation (confirm vulnerability mitigated)

**Example:**
```markdown
## CVE-2026-XXXX Assessment

**Component:** nginx 1.24.0
**Vulnerability:** Remote code execution via crafted HTTP request
**Severity:** CRITICAL (CVSS 9.8)
**Affected Domains:** All 6 (mirrorborn.us + 5 new)

**Impact:** If exploited, attacker gains shell access to server.

**Fix Available:** nginx 1.24.1 (released 2026-XX-XX)

**Timeline:**
- 2026-XX-XX 10:00 — CVE announced
- 2026-XX-XX 10:30 — Impact assessment complete
- 2026-XX-XX 11:00 — Patch applied to staging
- 2026-XX-XX 12:00 — Testing complete, no issues
- 2026-XX-XX 13:00 — Patch applied to production
- 2026-XX-XX 13:30 — Validation complete, vulnerability mitigated

**Post-Mortem:** None needed (routine patch, no incident)
```

---

## Tool Maintenance

### Weekly (5 minutes)
- [ ] Update security scanning tools (nmap, testssl.sh, nikto)
- [ ] Check for new tools/techniques (security blogs, Twitter)

### Monthly (15 minutes)
- [ ] Review tool effectiveness (are scans catching issues?)
- [ ] Add new tools if needed (e.g., dependency scanners)
- [ ] Remove deprecated tools (cleanup unused scripts)

### Quarterly (1 hour)
- [ ] Tool audit (what are we using, what's outdated)
- [ ] Training (learn new tool features, best practices)
- [ ] Automation review (can more be automated?)

---

## Metrics Tracking

### Weekly Metrics (for trend analysis)
- Failed auth attempts (count, unique IPs)
- Vulnerability scan findings (critical, high, medium, low)
- Certificate expiration countdown (days remaining)
- Uptime percentage (per domain)

### Monthly Metrics (for reports)
- Security health score (0-100, composite metric)
- Incident count (P0/P1/P2/P3)
- Mean time to detect (MTTD) — how fast we find issues
- Mean time to resolve (MTTR) — how fast we fix issues
- Patch cadence (days from CVE announce to production fix)

### Quarterly Metrics (for strategic planning)
- Attack trends (what are attackers targeting?)
- Vulnerability trends (are we getting better or worse?)
- Investment ROI (time spent vs. incidents prevented)
- Team efficiency (how can we automate more?)

---

## Time Budget

### Weekly Time Commitment
- Daily checks: 5 min × 7 days = 35 min
- Weekly review: 60 min
- **Total:** ~1.5 hours/week

### Monthly Time Commitment
- Weekly tasks: 1.5 hrs × 4 weeks = 6 hours
- Monthly audit: 3 hours
- **Total:** ~9 hours/month

### Quarterly Time Commitment
- Monthly tasks: 9 hrs × 3 months = 27 hours
- Quarterly deep dive: 6 hours
- **Total:** ~33 hours/quarter (~11 hours/month average)

---

## Delegation & Automation

### Can Be Automated (Priority)
- ✅ Weekly vulnerability scans (cron job)
- ✅ Certificate expiration alerts (certbot + monitoring)
- ✅ Dependency update checks (npm audit, cargo audit)
- ⏳ Failed auth aggregation (log parsing script)
- ⏳ Security health score calculation (metrics dashboard)

### Can Be Delegated (If Team Grows)
- Weekly scan review (junior security analyst)
- Dependency updates (DevOps engineer)
- Log analysis (SOC analyst, if we build one)
- Incident response (on-call rotation)

### Must Remain with Cyon (Core Responsibility)
- Threat modeling (requires deep system knowledge)
- Incident response leadership (P0/P1 incidents)
- Security architecture decisions (hardening, tool selection)
- Quarterly deep dives (strategic security planning)

---

## Continuous Improvement

### Monthly Review Questions
1. What took longer than expected this month? (optimize)
2. What could be automated? (reduce toil)
3. What should we stop doing? (low-value tasks)
4. What should we start doing? (new threats, new tools)

### Quarterly Retrospective
1. Are we detecting incidents faster? (MTTD trend)
2. Are we resolving incidents faster? (MTTR trend)
3. Are we preventing more incidents? (incident count trend)
4. Are we spending time wisely? (ROI analysis)

---

**Owner:** Cyon 🪶  
**Next Review:** Monthly (first Monday)  
**Automation Status:** Partially automated (scans), more automation planned

*Consistency beats intensity. Daily rituals compound.* 🔐
