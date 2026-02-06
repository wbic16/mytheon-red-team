# Launch Readiness Checklist v2 — Feb 13, 2026

**Version:** 2.0 (Updated Round 12)  
**Red Team Lead:** Cyon 🪶  
**Scope:** 6 domains (mirrorborn.us + 5 new properties)  
**Coordination:** Discord voice call (11:00 AM - 5:00 PM CST)

---

## Changes from v1 (Round 10)

**Expanded scope:**
- v1: Single domain (mirrorborn.us)
- v2: 6 domains (mirrorborn.us + visionquest.me + apertureshift.com + wishnode.net + sotafomo.com + quickfork.net)

**New metrics:**
- Fleet security score (aggregate of all domains)
- Per-domain security health tracking
- Multi-domain incident response procedures

**Lessons from Round 11:**
- security.txt deployment process clarified
- File ownership/permissions validation added
- DNS propagation checks added

---

## Pre-Launch Validation (T-24 Hours)

### Critical Security Checks — Must Pass Before Launch

#### mirrorborn.us (Primary Domain)

**Infrastructure:**
- [ ] Security health score ≥85/100 (primary domain standard)
- [ ] HTTPS A+ on SSL Labs
- [ ] Security headers present (HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
- [ ] nginx version hidden
- [ ] security.txt accessible at /.well-known/security.txt
- [ ] No critical vulnerabilities (SQ v0.5.2 or later)

**Backend:**
- [ ] Auth flow working (magic link → JWT → session)
- [ ] Session file permissions: 600
- [ ] Session directory permissions: 700
- [ ] Rate limiting configured (100 read/min, 10 write/min)
- [ ] SQ API responsive (<500ms avg)

**Monitoring:**
- [ ] Alert automation deployed and tested
- [ ] Discord webhook delivering alerts
- [ ] Critical alerts: No false positives in past 24h
- [ ] Daily digest sent this morning
- [ ] Incident response runbook accessible

**Backup/Recovery:**
- [ ] Backup completed within 24 hours
- [ ] Restore tested successfully
- [ ] Rollback procedure documented and accessible

---

#### New Domains (visionquest.me, apertureshift.com, wishnode.net, sotafomo.com, quickfork.net)

**Minimum baseline for ALL:**
- [ ] HTTPS accessible with valid certificate (A or A+ grade)
- [ ] Security headers present
- [ ] nginx version hidden
- [ ] Placeholder page or redirect (no 404s on homepage)
- [ ] Certificate auto-renewal configured (certbot)
- [ ] DNS propagation complete (dig +short returns 44.248.235.76)

**Acceptable compromises:**
- Placeholder pages OK (full sites can launch later)
- Security score ≥65/100 acceptable (vs 85 for primary)
- Monitoring can be added post-launch

---

### Fleet Security Score

**Formula:**
```
Fleet Score = (mirrorborn.us × 0.5) + (average of 5 new domains × 0.5)
```

**Minimum for launch:**
```
Fleet ≥ 75/100
```

**Target breakdown:**
- mirrorborn.us: 85/100
- New domains average: 65/100
- Fleet: (85 × 0.5) + (65 × 0.5) = 75/100 ✅

---

## T-1 Hour Security Checklist (11:00 AM CST)

### Cyon's Pre-Flight Checks

#### mirrorborn.us Validation

**Run automated scan:**
```bash
cd ~/mytheon-red-team/scripts
./recon.sh
```

**Manual checks:**
```bash
# Security headers
curl -I https://mirrorborn.us | grep -E "Strict-Transport|Content-Security|X-Frame|X-Content-Type|Referrer"

# nginx version
curl -I https://mirrorborn.us | grep -i "server:"
# Expected: "server: nginx" (no version)

# security.txt
curl https://mirrorborn.us/.well-known/security.txt | head -5
# Expected: Contact info, not HTML

# SSL Labs (if time permits)
# Visit: https://www.ssllabs.com/ssltest/analyze.html?d=mirrorborn.us
```

**Backend checks:**
```bash
# SQ API responsive
time curl -I https://mirrorborn.us/1.1.1/1.1.1/1.1.1
# Expected: <500ms, 200 or 404

# Session directory (if SSH access)
ssh wbic16@44.248.235.76 "ls -la /app/sq-cloud/sessions/ 2>&1 || echo 'Not deployed yet'"
```

---

#### New Domains Validation

**For each domain:**
```bash
for domain in visionquest.me apertureshift.com wishnode.net sotafomo.com quickfork.net; do
    echo "=== $domain ==="
    
    # HTTPS accessible
    curl -I https://$domain | head -1
    
    # Certificate valid
    echo | openssl s_client -connect $domain:443 -servername $domain 2>/dev/null | openssl x509 -noout -dates | grep "notAfter"
    
    # Security headers
    curl -I https://$domain | grep -E "Strict-Transport|X-Frame"
    
    # nginx version
    curl -I https://$domain | grep -i "server:"
    
    echo ""
done
```

**Expected results:**
- All domains return 200 or 302
- All certificates valid (expires >30 days)
- Security headers present on all
- nginx version hidden on all

---

#### Monitoring Systems Check

**Alert automation:**
```bash
# Check cron jobs running
crontab -l | grep -E "critical-alerts|high-alerts|daily-digest"

# Test Discord webhook (if configured)
curl -X POST "$DISCORD_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content": "🔐 Launch day test alert - Cyon"}'
```

**Incident response:**
```bash
# Verify runbook accessible
cat ~/mytheon-red-team/docs/incident-response-runbook.md | head -5

# Verify Verse contact info
# Discord: @Verse, Phone: [TBD]
```

---

## T-0: Launch Moment (12:00 PM CST)

### Security Go/No-Go Decision

**Cyon reports:**
- Fleet security score: [X]/100
- mirrorborn.us score: [Y]/100
- New domains: [Z passed]/5

**Go criteria:**
- ✅ Fleet score ≥75/100
- ✅ mirrorborn.us score ≥85/100
- ✅ At least 4/5 new domains baseline secure (65/100+)
- ✅ No P0 vulnerabilities
- ✅ Monitoring functional

**Conditional Go (acceptable):**
- Fleet score 70-74/100
- mirrorborn.us 80-84/100
- 3/5 new domains secure (fix others within 24h)

**No-Go (delay launch):**
- Fleet score <70/100
- mirrorborn.us <80/100
- <3/5 new domains secure
- Any P0 vulnerability unpatched
- Monitoring non-functional

---

## Hour 1-2: Active Monitoring (12:00 - 2:00 PM CST)

### Multi-Domain Monitoring Protocol

**Every 5 minutes:**
- [ ] Check critical alerts (should be zero)
- [ ] Review nginx error log tail (mirrorborn.us)
- [ ] Monitor auth attempt patterns
- [ ] Watch for unusual traffic spikes (any domain)

**Every 15 minutes:**
- [ ] Security dashboard check
- [ ] Scan for failed auth patterns
- [ ] Review rate limit triggers
- [ ] Quick check of all 6 domains (curl -I)

**Tools:**
```bash
# Terminal 1: mirrorborn.us error log
ssh wbic16@44.248.235.76 "sudo tail -f /var/log/nginx/error.log | grep -i 'error\|crit'"

# Terminal 2: mirrorborn.us auth log
ssh wbic16@44.248.235.76 "sudo tail -f /var/log/auth.log | grep 'Failed\|sshd'"

# Terminal 3: Multi-domain health check (loop every 30 sec)
watch -n 30 'for d in mirrorborn.us visionquest.me apertureshift.com wishnode.net sotafomo.com quickfork.net; do curl -I -s -m 5 https://$d | head -1; done'

# Terminal 4: Discord #security-alerts (visual monitoring)
```

---

### Expected Traffic Patterns (Normal)

**mirrorborn.us:**
- Steady increase in 200 OK responses
- Occasional 404s (bots, typos)
- Few failed auth attempts (<10/hour)
- No 500 errors
- Response times <500ms

**New domains:**
- Low traffic (redirects or placeholders)
- Mostly 302s (if redirecting) or 200s (if placeholder)
- Minimal errors (should be static content)

---

### Warning Signs (Require Immediate Action)

**Critical (P0):**
- Sudden 500 error spike (backend crash)
- Certificate error (HTTPS broken)
- High failed auth rate (>100/10min) - brute force
- DDoS-like traffic (10x normal, slow responses)
- Session file permission errors

**High (P1):**
- Elevated 404 rate (broken links in deployed content)
- Slow response times (>2 seconds avg)
- Failed auth pattern (10+ from same IP)
- Rate limit triggers (legitimate traffic being blocked)
- Disk usage warnings (>80%)

---

## Multi-Domain Incident Response

### Scenario: Issue with One New Domain

**Example:** visionquest.me certificate error

**Response:**
1. Isolate: Does not affect mirrorborn.us (primary)
2. Classify: P1 (high, but not launch-blocking)
3. Contain: Redirect DNS temporarily if needed
4. Fix: Renew cert, reload nginx
5. Validate: Test HTTPS access
6. Document: Log incident timeline

**Impact assessment:**
- mirrorborn.us unaffected → Launch continues
- Fix within 1-4 hours (P1 timeline)
- Users redirected to mirrorborn.us if needed

---

### Scenario: Issue with mirrorborn.us

**Example:** Backend auth flow broken

**Response:**
1. Classify: P0 (critical, launch-blocking)
2. Escalate: @everyone in Discord
3. Coordinate: Verse + Phex + Will
4. Options:
   - Fix immediately (if <15 min)
   - Roll back to previous version
   - Delay launch if unfixable quickly
5. Decision authority: Will (final call)

---

## Hour 4-6: Wind Down (4:00 - 6:00 PM CST)

### End-of-Day Security Report

**Metrics to gather:**

**mirrorborn.us:**
- Total requests served
- Failed auth attempts (count + unique IPs)
- Rate limit triggers
- Error rates (500s, 404s, 401s/403s)
- Avg response time
- Security alerts fired

**New domains:**
- Traffic per domain
- Errors per domain
- Certificate issues (if any)

**Fleet-wide:**
- Incidents: P0=?, P1=?, P2=?
- Mean time to detect (MTTD)
- Mean time to resolve (MTTR)
- Overall uptime (%)

---

### Launch Day Security Report Template

```markdown
## Launch Day Security Report — 2026-02-13

**Duration:** 12:00 PM - 6:00 PM CST (6 hours)

### Fleet Security Health

**Pre-launch:**
- Fleet score: [X]/100
- mirrorborn.us: [Y]/100
- New domains avg: [Z]/100

**Post-launch:**
- Fleet score: [X]/100 (change: +/- [N])
- Incidents detected: [count]
- Incidents resolved: [count]

### mirrorborn.us (Primary Domain)

**Traffic:**
- Requests: [X]
- Unique visitors: [Y]
- Failed auth: [Z] ([N] unique IPs)
- Rate limit triggers: [N]

**Performance:**
- Avg response time: [X]ms
- 99th percentile: [Y]ms
- Uptime: [X]%

**Security:**
- Alerts fired: P0=[X], P1=[Y], P2=[Z]
- Incidents: [list if any]

### New Domains

| Domain | Traffic | Errors | Incidents |
|--------|---------|--------|-----------|
| visionquest.me | X | Y | None/[details] |
| apertureshift.com | X | Y | None/[details] |
| wishnode.net | X | Y | None/[details] |
| sotafomo.com | X | Y | None/[details] |
| quickfork.net | X | Y | None/[details] |

### Incidents (if any)

[For each P1+ incident:]
- Time: [HH:MM]
- Severity: P0/P1
- Description: [brief]
- Resolution time: [X min]
- Root cause: [brief]

### Success Criteria

- [✅/❌] Zero P0 incidents
- [✅/❌] All P1 incidents <1 hour
- [✅/❌] No unauthorized access
- [✅/❌] Monitoring functional
- [✅/❌] Team coordination smooth

**Overall:** [EXCELLENT/GOOD/NEEDS IMPROVEMENT]

### Lessons Learned

**What went well:**
- [List]

**What needs improvement:**
- [List]

**Action items for Week 2:**
1. [Item]
2. [Item]
```

---

## Post-Launch Security Tasks (First Week)

### Day 2 (Feb 14)
- [ ] Full security scan (all 6 domains)
- [ ] Review all alerts from launch day
- [ ] Update threat model based on observed traffic
- [ ] Fix any medium-priority issues found

### Day 3 (Feb 15)
- [ ] Deep log analysis (patterns, anomalies)
- [ ] Interview early users about security UX
- [ ] Validate session cleanup working
- [ ] Test backup/restore procedure

### Week 1 Review (Feb 20)
- [ ] Security posture report (all 6 domains)
- [ ] Incident count + resolution times
- [ ] Updated threat landscape
- [ ] Recommendations for Week 2

---

## Communication Protocols

### During Launch (Discord Voice)

**Normal status update (every hour):**
> "Security: All domains green. mirrorborn.us: X requests, Y auth attempts. New domains: low traffic, no issues."

**Warning (investigating):**
> "@team Security alert: [type] on [domain]. Investigating. Update in 5 min."

**P1 Incident:**
> "@team P1 Security Incident: [brief] on [domain]. Coordinating with @Verse. ETA [time]."

**P0 Incident:**
> "@everyone P0 SECURITY INCIDENT: [brief]. [Affected domain]. All hands. Voice channel now."

**All clear:**
> "@team Incident resolved. [Domain] stable. Continuing monitoring."

---

## Success Criteria (Updated for Multi-Domain)

**Excellent (🟢):**
- ✅ Zero P0 incidents (any domain)
- ✅ All P1 incidents <1 hour (any domain)
- ✅ Fleet score remains ≥75/100
- ✅ mirrorborn.us uptime >99.9%
- ✅ New domains uptime >99% (acceptable lower for placeholders)
- ✅ Monitoring functioned as designed

**Good (🟡):**
- ✅ Zero P0 incidents
- ⚠️ 1-2 P1 incidents, resolved <2 hours
- ✅ Fleet score ≥70/100
- ✅ mirrorborn.us uptime >99%
- ⚠️ 1 new domain had issues, resolved same day

**Needs Improvement (🔴):**
- ⚠️ 1+ P0 incidents
- ⚠️ P1 incidents took >2 hours
- ⚠️ Fleet score dropped below 70/100
- ⚠️ mirrorborn.us downtime >1%
- ⚠️ Multiple new domains had issues

---

## Launch Abort Criteria (Pre-Launch Only)

**Abort if (T-24 to T-0):**
1. Fleet security score <70/100
2. mirrorborn.us security score <80/100
3. <3/5 new domains secured
4. P0 vulnerabilities unpatched
5. Monitoring completely non-functional
6. No backup/rollback capability
7. Critical team member unavailable (Verse, Will)

**Authority to abort:** Will (final), Verse (infrastructure), Cyon (security)

**Abort communication:**
> "@everyone LAUNCH DELAYED. Reason: [specific blocker]. Security score: [X]/100. New launch time: TBD pending fix."

---

## Version History

- **v1.0** (Round 10): Single domain (mirrorborn.us)
- **v2.0** (Round 12): Multi-domain (6 domains), fleet scoring, lessons from Round 11

---

**Owner:** Cyon 🪶  
**Status:** Ready for Feb 13 launch  
**Next Review:** Post-launch (Feb 14)

*Six domains. One launch. Zero compromises.* 🚀🔐
