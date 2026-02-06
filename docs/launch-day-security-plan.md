# Launch Day Security Plan — Feb 13, 2026

**Red Team Lead:** Cyon 🪶  
**Status:** Ready for launch  
**Coordination:** Discord voice call (11:00 AM - 5:00 PM CST)

---

## Pre-Launch Security Validation (T-24 Hours)

### Critical Security Checks

**Must Pass Before Launch:**
- [ ] Security health score ≥75/100 (acceptable minimum)
- [ ] P0 fixes applied (security headers, nginx version hiding)
- [ ] HTTPS A+ on SSL Labs
- [ ] No critical vulnerabilities in SQ v0.5.2
- [ ] Alert automation deployed and tested
- [ ] Incident response runbook accessible
- [ ] Backup/restore tested successfully

**If Any Fail:** Delay launch until resolved.

---

## T-1 Hour Security Checklist (11:00 AM CST)

### Cyon's Pre-Flight Checks

**Infrastructure:**
- [ ] Run full recon scan (`./scripts/recon.sh`)
- [ ] Verify security headers present (HSTS, CSP, X-Frame-Options, etc.)
- [ ] Confirm nginx version hidden
- [ ] SSL Labs test: Grade A or A+ required
- [ ] Certificate valid (check expiration)
- [ ] Port scan: Only 80, 443 exposed

**Monitoring:**
- [ ] Alert scripts running (check cron)
- [ ] Discord webhook delivering alerts (test)
- [ ] Critical alerts script: No false positives in past 24h
- [ ] Daily digest sent successfully this morning
- [ ] Monitoring dashboards accessible

**Backend Security:**
- [ ] Session file permissions: 600 (if files exist)
- [ ] Session directory permissions: 700
- [ ] SQ process running and responsive
- [ ] Rate limiting configured (verify with Verse)
- [ ] Auth flow tested end-to-end (magic link → session)

**Incident Response:**
- [ ] Runbook open in browser tab
- [ ] Verse contact confirmed (Discord voice + phone backup)
- [ ] Phex available for coordination
- [ ] Will notified of launch (available for escalation if needed)

**Access & Tools:**
- [ ] SSH access to mirrorborn.us confirmed
- [ ] Admin credentials accessible (if needed)
- [ ] Security logs tailable in real-time
- [ ] Incident ticket template ready (GitHub or project tool)

---

## T-0: Launch Moment (12:00 PM CST)

### Security Go/No-Go

**Cyon confirms:**
- "Security validation complete. No blockers. Ready to launch." ✅

**or**

- "Security blocker: [specific issue]. Recommend delaying launch." ❌

---

## Hour 1-2: Active Security Monitoring (12:00 - 2:00 PM CST)

### Real-Time Monitoring Tasks

**Every 5 Minutes:**
- [ ] Check critical alerts (should be zero)
- [ ] Review nginx error log tail
- [ ] Monitor auth attempt patterns
- [ ] Watch for unusual traffic spikes

**Every 15 Minutes:**
- [ ] Check security dashboard
- [ ] Scan for failed auth patterns
- [ ] Review rate limit triggers
- [ ] Monitor disk usage

**Tools:**
```bash
# Terminal 1: nginx error log
sudo tail -f /var/log/nginx/error.log | grep -i "error\|crit"

# Terminal 2: auth log
sudo tail -f /var/log/auth.log | grep "Failed\|sshd"

# Terminal 3: SQ process monitoring
watch -n 5 'curl -I -s https://mirrorborn.us/1.1.1/1.1.1/1.1.1 | head -1'

# Terminal 4: Discord alerts (if webhook working)
# Visual check in Discord #security-alerts channel
```

### Expected Patterns (Normal)

**Good signs:**
- Steady increase in 200 OK responses
- Occasional 404s (bots, typos)
- Few failed auth attempts (<10/hour)
- No 500 errors
- Response times <500ms

**Watch for (Warning Signs):**
- Sudden 500 error spike (backend issue)
- High failed auth rate (brute force)
- DDoS-like traffic (many requests from few IPs)
- Cert errors (HTTPS misconfiguration)
- Session file permission errors

---

## Hour 2-4: Sustained Monitoring (2:00 - 4:00 PM CST)

### Reduce Frequency, Stay Vigilant

**Every 30 Minutes:**
- Security dashboard check
- Alert review
- Log pattern scan

**When Alerts Fire:**
1. Acknowledge in Discord immediately
2. Classify severity (P0/P1/P2/P3)
3. Follow incident response runbook
4. Coordinate with Verse if infrastructure fix needed
5. Document incident timeline

---

## Hour 4-6: Wind Down (4:00 - 6:00 PM CST)

### End-of-Day Security Review

**Metrics to Gather:**
- Total requests served
- Failed auth attempts (count + unique IPs)
- Rate limit triggers (count + reasons)
- Error rates (500s, 404s, 401s/403s)
- Security alerts fired (critical, high, medium)
- Incidents handled (P0/P1/P2/P3)

**Security Health Assessment:**
- [ ] No critical incidents (P0)
- [ ] All high incidents (P1) resolved same day
- [ ] No unauthorized access detected
- [ ] Certificate still valid
- [ ] Monitoring still functional
- [ ] Team coordination effective

**Report Template:**
```markdown
## Launch Day Security Report — 2026-02-13

**Duration:** 12:00 PM - 6:00 PM CST (6 hours)

### Metrics
- Requests served: X
- Failed auth attempts: Y (Z unique IPs)
- Rate limit triggers: N
- Incidents: P0=0, P1=0, P2=0, P3=0

### Security Health
- Pre-launch score: 75/100
- Post-launch score: [TBD after 24h]
- Issues detected: [count]
- Issues resolved: [count]

### Incidents (if any)
[List P1+ incidents with timeline]

### Lessons Learned
- What went well
- What needs improvement
- Action items for tomorrow

### Recommendations
- Short-term (this week)
- Medium-term (this month)
- Long-term (Q1 2026)
```

---

## Common Attack Scenarios & Response

### Scenario 1: Brute Force Attack

**Detection:**
- Alert: "HIGH: Suspicious auth pattern" or "CRITICAL: Brute force attack"
- Log shows: 100+ failed logins from same IP(s)

**Response:**
1. Confirm attack is real (not monitoring false positive)
2. Identify attacking IP(s)
3. Ban via fail2ban: `sudo fail2ban-client set sshd banip <IP>`
4. Add to permanent blacklist if persistent
5. Monitor for shift to new IPs
6. Document in incident report

**Time to Resolve:** <15 minutes (P1)

---

### Scenario 2: DDoS / Traffic Flood

**Detection:**
- Sudden traffic spike (10x normal)
- Response times degrading
- Rate limit triggers across many IPs

**Response:**
1. Confirm it's malicious (not HN/Reddit traffic spike)
2. If malicious: enable aggressive rate limiting
3. If legitimate: scale infrastructure (coordinate with Verse)
4. Consider Cloudflare integration for DDoS protection
5. Monitor service health

**Time to Resolve:** <30 minutes (P1)

---

### Scenario 3: Backend Error Spike

**Detection:**
- Alert: Multiple 500 errors in logs
- User reports: "Site is broken"

**Response:**
1. Not a security issue — escalate to Verse (backend owner)
2. Monitor for exploit attempts (attackers love 500s)
3. If exploit detected, coordinate immediate containment
4. Continue security monitoring while Verse fixes backend

**Time to Resolve:** Depends on root cause (backend issue)

---

### Scenario 4: Certificate Expiration

**Detection:**
- Alert: "CRITICAL: Certificate expiring soon" (shouldn't happen on launch day)
- Users report: "Your connection is not secure"

**Response:**
1. Verify cert status: `sudo certbot certificates`
2. If expired: `sudo certbot renew --force-renewal`
3. If renewal fails: troubleshoot immediately (P0)
4. Coordinate with Verse for nginx reload
5. Test HTTPS after fix

**Time to Resolve:** <15 minutes (P0)

---

### Scenario 5: Session File Leak

**Detection:**
- Alert: "HIGH: Session file permissions incorrect"
- Or: User reports seeing another user's data

**Response:**
1. **IMMEDIATE:** Stop writes to affected files
2. Fix permissions: `chmod 600 /app/sq-cloud/sessions/*.json`
3. Assess damage: Which files were readable? For how long?
4. Rotate all session tokens (invalidate + reissue)
5. Notify affected users if PII exposed
6. Document for post-mortem

**Time to Resolve:** <15 minutes containment, hours for full remediation (P0)

---

## Post-Launch Security Tasks (First Week)

### Day 2 (Feb 14)
- [ ] Full security scan (automated + manual)
- [ ] Review all alerts from launch day
- [ ] Update threat model based on observed traffic
- [ ] Fix any medium-priority issues found

### Day 3 (Feb 15)
- [ ] Deep log analysis (patterns, anomalies)
- [ ] Interview early users about security UX
- [ ] Validate session cleanup working
- [ ] Test backup/restore procedure

### Week 1 Review (Feb 20)
- [ ] Security posture report
- [ ] Incident count + resolution times
- [ ] Updated threat landscape
- [ ] Recommendations for Week 2

---

## Communication Protocols

### During Launch (Discord Voice)

**Normal status update (every hour):**
> "Security: All green. X requests, Y auth attempts, zero incidents."

**Warning (alert fired, investigating):**
> "@team Security alert: [type]. Investigating. Will update in 5 min."

**Incident (P1+):**
> "@everyone P1 Security Incident: [brief description]. Coordinating with @Verse. ETA [time]."

**All clear:**
> "@team Incident resolved. Services stable. Continuing monitoring."

---

## Success Criteria

**Launch Day Security Success:**
- ✅ Zero P0 incidents
- ✅ All P1 incidents resolved within 1 hour
- ✅ No unauthorized access
- ✅ Monitoring functioned as designed
- ✅ Incident response tested in practice
- ✅ Team coordination smooth

**If we achieve all 6:** 🟢 **EXCELLENT**  
**If we achieve 4-5:** 🟡 **GOOD** (iterate for next launch)  
**If we achieve <4:** 🔴 **NEEDS IMPROVEMENT** (post-mortem required)

---

## Contingency: Launch Abort Criteria

**If any of these occur before launch (T-0), recommend delay:**
1. Security health score <75/100
2. P0 vulnerabilities unpatched
3. Monitoring not functional
4. Backup/restore not tested
5. Critical infrastructure component down

**Authority to abort:** Will (final decision), Verse (infrastructure), Cyon (security)

**Abort communication:**
> "@everyone LAUNCH DELAYED. Reason: [specific blocker]. New launch time: TBD pending fix."

---

**Owner:** Cyon 🪶  
**Review Cadence:** Daily until launch, then weekly post-launch  
**Next Update:** After launch (security report)

*Launch day is when theory meets practice. Ready to break things safely.* 🚀🔐
