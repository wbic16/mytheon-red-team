# Incident Response Runbook

**Version:** 1.0  
**Date:** 2026-02-05 (Round 7/N)  
**Owner:** Cyon 🪶  
**Scope:** Mirrorborn infrastructure (all domains)

---

## Overview

This runbook defines procedures for responding to security incidents across Mirrorborn infrastructure.

**Key Principles:**
1. **Speed over perfection** — Contain first, investigate later
2. **Communication is critical** — Alert team immediately
3. **Document everything** — Logs, actions, decisions
4. **Learn from every incident** — Post-mortem always

---

## Severity Classification

### P0 — Critical (Immediate Response)

**Criteria:**
- Active data breach (user data exfiltrated)
- Service completely down (all domains unreachable)
- Active intrusion (attacker has shell access)
- Certificate expired (HTTPS broken)

**Response Time:** <15 minutes  
**Escalation:** Discord @everyone + call Will immediately

---

### P1 — High (Urgent Response)

**Criteria:**
- Brute force attack in progress (>100 failed logins/min)
- DDoS attack (service degraded but not down)
- Vulnerability actively exploited (but no breach yet)
- Database/storage corruption detected

**Response Time:** <1 hour  
**Escalation:** Discord #security-alerts + ping Verse

---

### P2 — Medium (Scheduled Response)

**Criteria:**
- Failed authentication patterns (suspicious but not brute force)
- Known vulnerability discovered (not yet exploited)
- Configuration drift (security settings changed unexpectedly)
- Certificate expiring within 7 days

**Response Time:** <24 hours  
**Escalation:** Log in issue tracker, notify in next daily sync

---

### P3 — Low (Routine Maintenance)

**Criteria:**
- Dependency update available (no active exploit)
- Security best practice not followed (but no immediate risk)
- Certificate expiring within 30 days (auto-renewal expected)

**Response Time:** <1 week  
**Escalation:** Add to backlog, address in next sprint

---

## Incident Response Phases

### 1. Detection

**How incidents are discovered:**
- Automated alerts (monitoring system, cron jobs)
- User reports (Discord, email)
- Manual discovery (during routine checks)
- Third-party notification (security researcher, bug bounty)

**Initial actions:**
- Acknowledge alert (so others know you're on it)
- Classify severity (P0/P1/P2/P3)
- Notify team in #security-alerts

---

### 2. Assessment

**Questions to answer:**
- What happened? (symptom: site down, logs show XYZ)
- When did it start? (check logs for first occurrence)
- What's affected? (which domains, services, users)
- Is it still happening? (active or resolved)
- Is data compromised? (exfiltration, corruption, unauthorized access)

**Assessment checklist:**
- [ ] Check monitoring dashboards (uptime, error rates)
- [ ] Review recent logs (nginx access/error, app logs)
- [ ] Check for known attacks (brute force, DDoS patterns)
- [ ] Verify backups are intact (in case restore needed)
- [ ] Estimate user impact (how many affected, severity)

**Documentation:**
- Create incident ticket (GitHub issue or Discord thread)
- Log timeline of events
- Note initial hypothesis

---

### 3. Containment

**Goal:** Stop the bleeding. Prevent further damage.

**Immediate actions (P0/P1):**

**If active intrusion:**
```bash
# Block attacker IP immediately
sudo iptables -A INPUT -s <attacker-ip> -j DROP

# Kill suspicious processes
ps aux | grep <suspicious-process>
sudo kill -9 <pid>

# Disable compromised service
sudo systemctl stop <service-name>
```

**If brute force attack:**
```bash
# Ban attacking IPs (manual)
sudo fail2ban-client set sshd banip <ip>

# Temporary rate limit (nginx)
# Add to nginx.conf:
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
limit_req zone=auth burst=10 nodelay;

sudo nginx -t && sudo systemctl reload nginx
```

**If data breach suspected:**
```bash
# Isolate affected system (firewall all traffic except ssh)
sudo iptables -P INPUT DROP
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Snapshot current state (forensics)
sudo tar -czf /tmp/forensics-$(date +%s).tar.gz /var/log /app /etc/nginx

# Preserve logs before they rotate
sudo cp -r /var/log /var/log.incident-backup
```

**If service outage:**
```bash
# Check service status
sudo systemctl status nginx
sudo systemctl status certbot

# Check disk space (common cause)
df -h

# Check cert expiration
sudo certbot certificates

# Restart services if safe
sudo systemctl restart nginx
```

**Communication during containment:**
- Post status updates every 15-30 minutes
- If >1 hour to fix, post external status (if users affected)
- Coordinate with Verse for infrastructure changes

---

### 4. Investigation

**Goal:** Understand root cause, determine full scope.

**Evidence collection:**
```bash
# Nginx access logs (look for attack patterns)
sudo tail -1000 /var/log/nginx/access.log | grep <suspicious-pattern>

# Auth logs (failed logins, privilege escalation)
sudo grep "Failed password" /var/log/auth.log
sudo grep "sudo" /var/log/auth.log

# Session files (check for tampering)
sudo ls -lah /app/sq-cloud/sessions/
sudo md5sum /app/sq-cloud/sessions/*.json

# Network connections (active connections, listening ports)
sudo netstat -tulpn
sudo ss -tulpn
```

**Analysis:**
- Timeline reconstruction (when did attack start/end)
- Attack vector identification (how did they get in)
- Privilege escalation path (what did they access)
- Data access audit (what files/databases touched)
- Persistence check (did they install backdoor)

**Forensics:**
- Preserve evidence (copy logs, filesystem snapshot)
- Never modify live evidence (use copies for analysis)
- Document chain of custody (who accessed what, when)

---

### 5. Remediation

**Goal:** Fix the vulnerability, harden defenses.

**Common remediation steps:**

**Patch vulnerability:**
```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Update dependencies
cd /app/sq-cloud && npm audit fix
cd /app/sq-cloud && cargo update

# Apply security patches immediately
```

**Harden configuration:**
```bash
# Fix file permissions (session files)
sudo chmod 600 /app/sq-cloud/sessions/*.json

# Add security headers (if missing)
# See remediation-guide-verse.md for nginx config

# Rotate secrets (if compromised)
# Generate new JWT secret, API keys, etc.
```

**Ban attackers:**
```bash
# Permanent IP ban
sudo iptables -A INPUT -s <attacker-ip> -j DROP
sudo iptables-save > /etc/iptables/rules.v4

# Add to fail2ban permanent ban list
echo "<attacker-ip>" | sudo tee -a /etc/fail2ban/ip.blacklist
```

**Revoke compromised credentials:**
```bash
# Revoke user sessions (delete session files)
sudo rm /app/sq-cloud/sessions/<compromised-user>.json

# Rotate API keys (invalidate old, issue new)
# Update SQ Cloud tenant records with new keys
```

---

### 6. Recovery

**Goal:** Restore service, validate fixes.

**Pre-recovery checklist:**
- [ ] Vulnerability patched and tested
- [ ] Attacker access revoked (IPs banned, credentials rotated)
- [ ] Backups verified intact (in case restore needed)
- [ ] Monitoring alerts configured (to detect recurrence)

**Service restoration:**
```bash
# Re-enable services
sudo systemctl start nginx
sudo systemctl start <backend-service>

# Verify services running
sudo systemctl status nginx
curl -I https://mirrorborn.us

# Check logs for errors
sudo tail -50 /var/log/nginx/error.log
```

**Validation:**
- Test full user journey (signup → login → use service)
- Verify security fixes applied (re-run security scan)
- Monitor logs for 30-60 minutes (watch for anomalies)

**User communication (if applicable):**
- Post-incident notification (email to affected users)
- Transparency: what happened, what we did, what changed
- Action required: password reset, re-login, etc.

---

### 7. Post-Mortem Review

**Goal:** Learn, improve, prevent recurrence.

**Post-mortem template:**

```markdown
## Incident Post-Mortem — [Date]

**Severity:** P0 / P1 / P2 / P3  
**Duration:** X hours (detection to resolution)  
**Impact:** X users affected, Y services down

### What Happened
[Brief description of incident]

### Timeline
- HH:MM — Incident detected (how?)
- HH:MM — Severity classified, team notified
- HH:MM — Containment actions taken
- HH:MM — Root cause identified
- HH:MM — Remediation applied
- HH:MM — Service restored
- HH:MM — Incident closed

### Root Cause
[Technical explanation of what went wrong]

### What Went Well
- [List things that worked during response]

### What Went Poorly
- [List things that didn't work or were delayed]

### Action Items
1. [ ] Immediate fix: [what we did]
2. [ ] Short-term improvement: [what we'll do next sprint]
3. [ ] Long-term prevention: [architectural changes needed]

### Lessons Learned
[Key takeaways for future incidents]
```

**Post-mortem meeting:**
- Schedule within 48 hours of incident resolution
- All responders attend (Cyon, Verse, Phex, Will if P0)
- No blame culture — focus on systems, not people
- Document action items, assign owners, set deadlines

---

## Communication Templates

### P0 — Critical Incident (Initial Alert)

**Discord #security-alerts:**
```
🚨 P0 SECURITY INCIDENT 🚨

**Status:** ACTIVE / CONTAINED / INVESTIGATING
**Affected:** [domain/service]
**Impact:** [user impact description]
**ETA:** [estimated time to resolution]

**Actions taken:**
- [bullet list of containment steps]

**Next update:** [time]

@everyone — Do not make changes to mirrorborn.us infrastructure until all-clear.
```

---

### P0 — Critical Incident (Resolution)

**Discord #security-alerts:**
```
✅ P0 INCIDENT RESOLVED

**Duration:** X hours
**Root cause:** [brief explanation]
**Fix applied:** [what we did]
**User impact:** [how users were affected]

**Post-mortem:** Scheduled for [date/time]

Thanks to @Verse @Cyon for rapid response. Service is stable.
```

---

### P1 — High Severity (Initial Alert)

**Discord #security-alerts:**
```
⚠️ P1 Security Event

**Type:** [brute force / vulnerability / DDoS / etc.]
**Status:** Investigating
**Impact:** [service degraded / no user impact / etc.]

**Actions:**
- [containment steps taken]

Monitoring closely. Will update in 1 hour.
```

---

### User Notification (Post-Incident)

**Email template:**
```
Subject: Security Update — [Brief Description]

Hi [User],

We're writing to inform you about a recent security incident that may have affected your account.

**What happened:**
[Brief, non-technical explanation]

**When it happened:**
[Date/time range]

**What we did:**
[Steps we took to resolve it]

**What you need to do:**
[Action required: password reset, re-login, etc.]
[Or: No action required if no user impact]

**Questions?**
Reply to this email or reach out in Discord.

We take security seriously. Thank you for your patience.

— The Mirrorborn Team
```

---

## Escalation Paths

### P0 — Critical
1. **Cyon detects** → Posts in #security-alerts with @everyone
2. **Verse responds** (infrastructure owner)
3. **Phex coordinates** (if multi-agent coordination needed)
4. **Will escalates** (if external help needed: AWS support, legal, etc.)

### P1 — High
1. **Cyon detects** → Posts in #security-alerts
2. **Verse responds** (if infrastructure change needed)
3. **Daily sync review** (escalate to P0 if worsens)

### P2 — Medium
1. **Cyon logs** → GitHub issue or Discord #security-alerts
2. **Next sprint planning** (prioritize in backlog)

### P3 — Low
1. **Cyon logs** → Backlog
2. **Monthly review** (batch with other maintenance)

---

## Contact List

| Role | Name | Discord | Response Time |
|------|------|---------|---------------|
| Security Lead | Cyon 🪶 | @Cyon | <15 min (P0) |
| Infrastructure | Verse 🌀 | @Verse | <30 min (P0) |
| Coordinator | Phex 🔱 | @Phex | <1 hour (P0) |
| Escalation | Will | @wbic16 | <2 hours (P0) |

---

## Runbook Drills

### Quarterly Incident Response Drill

**Goal:** Validate runbook, measure response time, identify gaps.

**Scenario examples:**
1. **Data Breach Simulation:** Attacker accessed session files, exfiltrated user emails
2. **Service Outage:** Certificate expired, HTTPS broken, users can't login
3. **Brute Force Attack:** 1000 failed login attempts in 10 minutes

**Drill procedure:**
1. **Announce drill:** "This is a drill. Scenario: [X]"
2. **Start timer:** Measure time to containment, resolution
3. **Execute runbook:** Follow procedures exactly as written
4. **Document gaps:** What was unclear? What took longer than expected?
5. **Update runbook:** Fix ambiguities, improve procedures

**Success criteria:**
- P0 incidents contained within 15 minutes
- All team members know their roles
- Communication clear and timely
- Runbook followed without confusion

---

## Next Steps (Round 7)

1. **Review runbook with Verse** (validate infrastructure procedures)
2. **Setup Discord webhook** (for automated alerts)
3. **Create incident ticket template** (GitHub or project management tool)
4. **Schedule first drill** (Q1 2026, after launch)

---

**Owner:** Cyon 🪶  
**Last Reviewed:** 2026-02-05  
**Next Review:** Monthly (or after any P0/P1 incident)

*Hope for the best. Plan for the worst.* 🔐
