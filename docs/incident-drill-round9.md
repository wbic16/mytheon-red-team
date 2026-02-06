# Incident Response Drill — Round 9/N

**Date:** 2026-02-06  
**Owner:** Cyon 🪶  
**Scenario:** P1 Brute Force Attack  
**Duration:** 1-2 hours  
**Participants:** Cyon, Verse, Phex (coordinator)

---

## Objectives

1. **Validate runbook procedures** — Test incident response runbook in practice
2. **Measure response time** — P1 target: <1 hour from detection to containment
3. **Identify gaps** — Find missing steps, unclear procedures, tooling issues
4. **Build muscle memory** — Practice makes perfect

---

## Scenario: P1 Brute Force Attack

### Simulated Attack

**Attacker Profile:**
- Source: 5 attacking IPs (simulated)
- Target: SSH port 22
- Method: Automated password guessing
- Rate: 50 attempts/minute per IP
- Duration: 10 minutes

**Detection Trigger:**
- 250+ failed login attempts in 10 minutes
- Multiple IPs targeting same account
- High alert fires via automated script

---

## Drill Timeline

### T-15 minutes: Preparation

**Cyon:**
- [ ] Announce drill start time in Discord #general
- [ ] Prepare simulated attack IPs (use test VPS or local VMs)
- [ ] Verify monitoring scripts are running
- [ ] Confirm Verse + Phex are available

**Verse:**
- [ ] Ensure SSH access to mirrorborn.us
- [ ] Have fail2ban commands ready
- [ ] iptables knowledge refreshed

**Phex:**
- [ ] Ready to coordinate between Cyon + Verse
- [ ] Timer ready to measure response

---

### T+0: Attack Begins

**Cyon's Actions:**
1. Start simulated brute force attack
   ```bash
   # From test IPs (5x)
   for i in {1..50}; do
       ssh -o ConnectTimeout=1 testuser@mirrorborn.us 2>&1 | grep "denied" &
       sleep 1
   done
   ```

2. Wait for automated alert to fire (should be <5 minutes)

---

### T+5: Detection (Expected)

**Automated Alert Fires:**
```
⚠️ HIGH: Suspicious authentication pattern

Time: 2026-02-06 XX:XX:XX CST
Host: mirrorborn.us
Suspicious IPs (attempts, IP):
   52 192.0.2.1
   51 192.0.2.2
   50 192.0.2.3
   ...

Action: Monitor, consider banning if persistent

@Cyon
```

**Cyon's Response:**
- [ ] Acknowledge alert in Discord
- [ ] Classify severity (P1 — brute force in progress)
- [ ] Escalate to Verse: "@Verse P1 incident - brute force attack, 250+ attempts"

---

### T+10: Assessment

**Verse's Actions:**
1. Confirm attack is real (check auth logs)
   ```bash
   sudo tail -100 /var/log/auth.log | grep "Failed password"
   ```

2. Identify attacking IPs
   ```bash
   sudo grep "Failed password" /var/log/auth.log | grep "$(date +"%b %_d %H:")" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
   ```

3. Report findings in Discord:
   "Confirmed: 5 IPs attacking, 250+ attempts in 10 min. Proceeding with containment."

---

### T+15: Containment

**Verse's Actions:**
1. Ban attacking IPs via fail2ban
   ```bash
   for ip in 192.0.2.{1..5}; do
       sudo fail2ban-client set sshd banip $ip
   done
   ```

2. Verify bans
   ```bash
   sudo fail2ban-client status sshd | grep "Currently banned"
   ```

3. Optional: Add permanent iptables rules
   ```bash
   for ip in 192.0.2.{1..5}; do
       sudo iptables -A INPUT -s $ip -j DROP
   done
   sudo iptables-save > /etc/iptables/rules.v4
   ```

4. Report containment:
   "Containment complete. 5 IPs banned. Attack stopped."

---

### T+20: Investigation

**Cyon's Actions:**
1. Analyze attack pattern
   - Were all IPs from same network?
   - What accounts were targeted?
   - Any successful logins?

2. Check for persistence
   - Are attackers still trying?
   - Did they gain access elsewhere?

3. Document findings
   ```markdown
   ## Incident Analysis
   - Attack started: [time]
   - Detection: [time] (X minutes)
   - Containment: [time] (Y minutes)
   - Total failed attempts: 250+
   - Targeted accounts: root, ubuntu, admin
   - Successful logins: 0
   - Attack vector: SSH brute force
   - Attacker IPs: [list]
   ```

---

### T+30: Remediation

**Verse's Actions:**
1. Verify fail2ban is properly configured
   ```bash
   sudo fail2ban-client status
   ```

2. Check if rate limiting is sufficient
   - Current: ban after 5 failed attempts in 10 min
   - Adjust if needed

3. Consider additional hardening
   - SSH key-only auth (disable password auth)
   - Change SSH port from 22
   - Install additional monitoring (OSSEC, Wazuh)

---

### T+45: Recovery

**Verify Services:**
1. SSH still accessible (for legitimate users)
2. fail2ban didn't ban legitimate IPs
3. No service disruption

**Post-Incident Actions:**
- [ ] Update IP blacklist with attacking IPs
- [ ] Review SSH access logs for patterns
- [ ] Check if same IPs attacked other services

---

### T+60: Review (Post-Mortem)

**All Participants:**

**What Went Well:**
- [ ] Detection time: [X minutes] (target: <5 min)
- [ ] Communication: [clear/unclear]
- [ ] Containment time: [Y minutes] (target: <15 min)
- [ ] Coordination: [effective/needs work]

**What Went Poorly:**
- [ ] Delays: [where did we slow down?]
- [ ] Confusion: [what was unclear in runbook?]
- [ ] Tools: [what didn't work as expected?]
- [ ] Communication: [what information was missing?]

**Action Items:**
1. [ ] Update runbook with clarifications
2. [ ] Fix tooling issues discovered
3. [ ] Improve monitoring if detection was slow
4. [ ] Train on any gaps found

**Metrics:**
- Total incident duration: [X minutes]
- MTTD (Mean Time To Detect): [Y minutes]
- MTTR (Mean Time To Resolve): [Z minutes]
- Target met: [Yes/No]

---

## Success Criteria

### Must Pass
- ✅ Attack detected within 5 minutes
- ✅ Incident classified correctly (P1)
- ✅ Containment within 15 minutes
- ✅ No false positive bans
- ✅ Services remain operational

### Should Pass
- ✅ Communication clear and timely
- ✅ Runbook followed without confusion
- ✅ All participants know their roles
- ✅ Post-mortem completed same day

### Nice to Have
- ✅ Total incident <30 minutes
- ✅ Automated response (no manual intervention)
- ✅ Lessons learned documented

---

## Drill Variations (Future Rounds)

### Drill 2: P0 Service Outage
- Simulate nginx crash
- Test service restart procedures
- Measure downtime

### Drill 3: P0 Data Breach
- Simulate session file leak
- Test containment + investigation
- Measure response to data exposure

### Drill 4: P1 DDoS Attack
- Simulate traffic flood
- Test rate limiting + DDoS mitigation
- Measure service degradation

### Drill 5: P2 Certificate Expiration
- Simulate expired cert (staging)
- Test renewal procedures
- Measure user impact

---

## Preparation Checklist

### Before Drill Day

**Cyon:**
- [ ] Confirm drill date/time with team (48 hours notice)
- [ ] Prepare test attack infrastructure
- [ ] Verify monitoring scripts running
- [ ] Have timer/stopwatch ready

**Verse:**
- [ ] Ensure admin access to mirrorborn.us
- [ ] Review fail2ban commands
- [ ] Have incident response runbook open
- [ ] Clear calendar for drill window

**Phex:**
- [ ] Coordinate timing
- [ ] Prepare to log timeline
- [ ] Ready to observe + provide feedback

**Will (optional):**
- [ ] Notified of drill (avoid false alarm)
- [ ] Available for escalation if drill reveals real issues

---

## Safety Precautions

1. **No production data at risk** — attacking test accounts only
2. **Reversible actions** — all bans can be undone
3. **Monitoring disabled** — no real alerts sent to Will during drill
4. **Announcement** — all participants know it's a drill
5. **Abort procedure** — if real incident occurs, abort drill immediately

---

## Post-Drill Deliverables

1. **Incident report** — Complete post-mortem (markdown)
2. **Runbook updates** — Fix any gaps found
3. **Metrics summary** — MTTD, MTTR, total duration
4. **Lessons learned** — What to improve for Drill 2

---

## Scheduled Date

**Proposed:** Round 9/N (after P0 fixes applied, monitoring deployed)

**Date:** TBD (coordinate with Verse + Phex)

**Time:** Weekday, off-peak hours (avoid Friday evenings)

**Duration:** 1-2 hours (including post-mortem)

---

**Owner:** Cyon 🪶  
**Status:** Drill plan ready, awaiting schedule confirmation  
**Next:** Coordinate with team, pick date, execute

*Practice makes perfect. Drills save lives.* 🔐
