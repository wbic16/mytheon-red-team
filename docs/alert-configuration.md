# Alert Configuration — Mirrorborn Infrastructure

**Version:** 1.0  
**Date:** 2026-02-05 (Round 8/N)  
**Owner:** Cyon 🪶  
**Status:** Ready for deployment (pending Discord webhook URL)

---

## Overview

Alert configuration for 4-tier monitoring:
1. **Critical** — Immediate Discord @everyone + optional SMS
2. **High** — Discord #security-alerts (no @everyone)
3. **Medium** — Daily digest email
4. **Low** — Weekly review (no alerts)

---

## Alert Channels

### Discord Webhook (Primary)

**URL:** `DISCORD_WEBHOOK_URL` (environment variable)  
**Status:** Pending (need URL from Will)

**Setup:**
1. Will creates webhook in Discord #security-alerts
2. Copy webhook URL
3. Set environment variable on mirrorborn.us:
   ```bash
   export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
   ```
4. Test:
   ```bash
   curl -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d '{"content": "🔐 Security alert test from Cyon"}'
   ```

### Email (Secondary)

**To:** security@mirrorborn.us (or Will's email)  
**From:** alerts@mirrorborn.us  
**Frequency:** Daily digest (8 AM CST)

### SMS (Optional, P0 Only)

**Service:** Twilio or AWS SNS  
**Status:** Not yet configured  
**Use case:** P0 incidents only (service down, active breach)

---

## Critical Alerts (Tier 1)

### CA-1: Service Down

**Trigger:**
```bash
# Check if nginx is running
systemctl is-active nginx || ALERT

# Check if SQ is responding
curl -f -s https://mirrorborn.us/1.1.1/1.1.1/1.1.1 || ALERT
```

**Alert Message:**
```json
{
  "content": "@everyone 🚨 **CRITICAL: Service Down**\n\n**Service:** nginx / SQ\n**Status:** Not responding\n**Time:** $(date)\n**Action:** Investigate immediately\n\n@Cyon @Verse"
}
```

**Response Time:** <15 minutes  
**Escalation:** If no response in 15 min, SMS Will

---

### CA-2: Certificate Expired

**Trigger:**
```bash
# Check cert expiration
EXPIRY_DAYS=$(sudo certbot certificates 2>/dev/null | grep "VALID:" | awk '{print $4}')
if [ "$EXPIRY_DAYS" -lt 7 ]; then ALERT; fi
```

**Alert Message:**
```json
{
  "content": "@everyone ⚠️ **CRITICAL: Certificate Expiring Soon**\n\n**Domain:** mirrorborn.us\n**Days Left:** $EXPIRY_DAYS\n**Action:** Renew certificate immediately\n\n@Verse"
}
```

**Response Time:** <1 hour  
**Escalation:** If <24 hours, escalate to P0

---

### CA-3: Disk Full

**Trigger:**
```bash
# Check disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_USAGE" -gt 90 ]; then ALERT; fi
```

**Alert Message:**
```json
{
  "content": "@everyone 🚨 **CRITICAL: Disk Space Low**\n\n**Usage:** ${DISK_USAGE}%\n**Action:** Free up space or expand disk\n**Impact:** Service may crash if 100%\n\n@Verse"
}
```

**Response Time:** <30 minutes  
**Mitigation:** Delete old logs, expand volume, or move data

---

### CA-4: Brute Force Attack

**Trigger:**
```bash
# Count failed auth attempts in last 10 minutes
FAILED_COUNT=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date +"%b %_d %H:")" | wc -l)
if [ "$FAILED_COUNT" -gt 100 ]; then ALERT; fi
```

**Alert Message:**
```json
{
  "content": "@everyone 🚨 **CRITICAL: Brute Force Attack Detected**\n\n**Failed Attempts:** $FAILED_COUNT in 10 minutes\n**Action:** Block attacking IPs\n**Status:** Ongoing\n\n@Cyon @Verse"
}
```

**Response Time:** <15 minutes  
**Mitigation:** Ban attacking IPs via fail2ban or iptables

---

## High Alerts (Tier 2)

### HA-1: Suspicious Auth Patterns

**Trigger:**
```bash
# Failed auth from same IP, 10+ times in 1 hour
SUSPICIOUS_IPS=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date +"%b %_d %H")" | awk '{print $(NF-3)}' | sort | uniq -c | awk '$1 > 10 {print $2}')
if [ -n "$SUSPICIOUS_IPS" ]; then ALERT; fi
```

**Alert Message:**
```json
{
  "content": "⚠️ **HIGH: Suspicious Auth Pattern**\n\n**IPs:** $SUSPICIOUS_IPS\n**Failed Attempts:** 10+ in 1 hour\n**Action:** Monitor, consider banning\n\n@Cyon"
}
```

**Response Time:** <1 hour  
**Action:** Review logs, ban if clearly malicious

---

### HA-2: Known Malicious IP

**Trigger:**
```bash
# Check recent connections against known malicious IP list
# (Requires IP blacklist maintained)
RECENT_IPS=$(sudo tail -1000 /var/log/nginx/access.log | awk '{print $1}' | sort | uniq)
for ip in $RECENT_IPS; do
    if grep -q "$ip" /etc/security/ip-blacklist.txt 2>/dev/null; then
        ALERT "$ip"
    fi
done
```

**Alert Message:**
```json
{
  "content": "⚠️ **HIGH: Known Malicious IP Detected**\n\n**IP:** $IP\n**Source:** Blacklist\n**Action:** Review access logs, consider banning\n\n@Cyon"
}
```

**Response Time:** <1 hour

---

### HA-3: Unusual Geographic Access

**Trigger:**
```bash
# Detect access from unexpected countries (requires GeoIP)
# Example: Alert if traffic from North Korea, Iran, etc.
# (Implementation requires GeoIP database)
```

**Alert Message:**
```json
{
  "content": "⚠️ **HIGH: Unusual Geographic Access**\n\n**Country:** $COUNTRY\n**IP:** $IP\n**Action:** Review logs for suspicious activity\n\n@Cyon"
}
```

**Response Time:** <1 hour

---

### HA-4: Session File Permission Change

**Trigger:**
```bash
# Check session file permissions (should be 600)
WRONG_PERMS=$(find /app/sq-cloud/sessions -type f ! -perm 600 2>/dev/null)
if [ -n "$WRONG_PERMS" ]; then ALERT; fi
```

**Alert Message:**
```json
{
  "content": "⚠️ **HIGH: Session File Permissions Changed**\n\n**Files:** $WRONG_PERMS\n**Expected:** 600\n**Action:** Fix permissions immediately\n\n@Verse @Cyon"
}
```

**Response Time:** <1 hour  
**Mitigation:** `chmod 600 /app/sq-cloud/sessions/*.json`

---

### HA-5: Dependency Vulnerability (HIGH)

**Trigger:**
```bash
# npm or cargo audit finds HIGH severity vulnerabilities
cd /app/sq-cloud
npm audit --json 2>/dev/null | jq -r '.metadata.vulnerabilities.high' | grep -v "^0$" && ALERT
cargo audit --json 2>/dev/null | jq -r '.vulnerabilities[] | select(.severity == "high")' && ALERT
```

**Alert Message:**
```json
{
  "content": "⚠️ **HIGH: Dependency Vulnerability Found**\n\n**Severity:** HIGH\n**Package:** $PACKAGE\n**Action:** Update dependency, test, deploy\n\n@Verse @Cyon"
}
```

**Response Time:** <24 hours

---

## Medium Alerts (Tier 3 — Daily Digest)

### MA-1: Failed Auth Summary

**Trigger:** Daily at 8 AM CST

**Content:**
- Total failed attempts (yesterday)
- Unique IPs
- Top 5 attacking IPs
- Geographic distribution (if available)

**Format:**
```markdown
## Security Digest — $(date +%Y-%m-%d)

**Failed Auth Attempts:** X total
**Unique IPs:** Y
**Blocked IPs:** Z (via fail2ban)

**Top Attackers:**
1. IP_ADDRESS (X attempts)
2. IP_ADDRESS (Y attempts)
...

**Action Items:**
- [ ] Review and ban if needed
```

---

### MA-2: Certificate Expiration Warning

**Trigger:** 30, 15, 7 days before expiration

**Content:**
- Domain
- Days remaining
- Expected auto-renewal date

---

### MA-3: Weekly Scan Summary

**Trigger:** Sunday morning (after automated scan)

**Content:**
- Scan results (critical, high, medium findings)
- Dependency updates available
- SSL Labs grade
- Security header compliance

---

## Low Alerts (Tier 4 — Weekly Review)

### LA-1: Dependency Updates Available

**Trigger:** Weekly check (Sunday)

**Content:**
- npm outdated
- cargo outdated
- apt upgradable packages

**Action:** Review, test, deploy in next maintenance window

---

## Alert Automation Scripts

### Script 1: Critical Alert Check (Every 5 Minutes)

**Location:** `scripts/critical-alerts.sh`

```bash
#!/bin/bash
# critical-alerts.sh - Check for critical conditions every 5 minutes
# Cron: */5 * * * * ~/mytheon-red-team/scripts/critical-alerts.sh

DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"

send_alert() {
    local message="$1"
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -X POST "$DISCORD_WEBHOOK" \
             -H "Content-Type: application/json" \
             -d "{\"content\": \"$message\"}" \
             2>/dev/null
    else
        echo "ALERT (no webhook configured): $message"
    fi
}

# CA-1: Service check
if ! systemctl is-active nginx &>/dev/null; then
    send_alert "@everyone 🚨 **CRITICAL: nginx is down** @Verse @Cyon"
fi

# CA-3: Disk check
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_USAGE" -gt 90 ]; then
    send_alert "@everyone 🚨 **CRITICAL: Disk usage at ${DISK_USAGE}%** @Verse"
fi

# CA-4: Brute force check
FAILED_COUNT=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date +"%b %_d %H:")" | wc -l)
if [ "$FAILED_COUNT" -gt 100 ]; then
    send_alert "@everyone 🚨 **CRITICAL: Brute force attack - $FAILED_COUNT failed logins** @Cyon @Verse"
fi
```

---

### Script 2: High Alert Check (Every Hour)

**Location:** `scripts/high-alerts.sh`

```bash
#!/bin/bash
# high-alerts.sh - Check for high-severity conditions every hour
# Cron: 0 * * * * ~/mytheon-red-team/scripts/high-alerts.sh

DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"

send_alert() {
    local message="$1"
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -X POST "$DISCORD_WEBHOOK" \
             -H "Content-Type: application/json" \
             -d "{\"content\": \"$message\"}" \
             2>/dev/null
    fi
}

# HA-1: Suspicious auth patterns
SUSPICIOUS_IPS=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date +"%b %_d %H")" | awk '{print $(NF-3)}' | sort | uniq -c | awk '$1 > 10 {print $2}')
if [ -n "$SUSPICIOUS_IPS" ]; then
    send_alert "⚠️ **HIGH: Suspicious auth from:** $SUSPICIOUS_IPS @Cyon"
fi

# HA-4: Session file permissions
if [ -d "/app/sq-cloud/sessions" ]; then
    WRONG_PERMS=$(find /app/sq-cloud/sessions -type f ! -perm 600 2>/dev/null | wc -l)
    if [ "$WRONG_PERMS" -gt 0 ]; then
        send_alert "⚠️ **HIGH: $WRONG_PERMS session files have wrong permissions** @Verse @Cyon"
    fi
fi
```

---

### Script 3: Daily Digest (8 AM CST)

**Location:** `scripts/daily-digest.sh`

```bash
#!/bin/bash
# daily-digest.sh - Send daily security digest
# Cron: 0 8 * * * ~/mytheon-red-team/scripts/daily-digest.sh

DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"
DATE=$(date +%Y-%m-%d)

# Gather stats
FAILED_AUTH=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date -d yesterday +"%b %_d")" | wc -l)
UNIQUE_IPS=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date -d yesterday +"%b %_d")" | awk '{print $(NF-3)}' | sort | uniq | wc -l)

# Build digest
DIGEST="## Security Digest — $DATE\n\n"
DIGEST+="**Failed Auth Attempts:** $FAILED_AUTH total\n"
DIGEST+="**Unique IPs:** $UNIQUE_IPS\n"
DIGEST+="\n*Full report in logs*"

# Send
if [ -n "$DISCORD_WEBHOOK" ]; then
    curl -X POST "$DISCORD_WEBHOOK" \
         -H "Content-Type: application/json" \
         -d "{\"content\": \"$DIGEST\"}" \
         2>/dev/null
fi
```

---

## Cron Schedule

```cron
# Critical alerts (every 5 minutes)
*/5 * * * * ~/mytheon-red-team/scripts/critical-alerts.sh

# High alerts (hourly)
0 * * * * ~/mytheon-red-team/scripts/high-alerts.sh

# Daily digest (8 AM CST)
0 8 * * * ~/mytheon-red-team/scripts/daily-digest.sh

# Weekly automated scan (Sunday 2 AM)
0 2 * * 0 ~/mytheon-red-team/scripts/automated-scan.sh
```

---

## Testing Alerts

### Test Discord Webhook

```bash
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."

# Test critical alert
curl -X POST "$DISCORD_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content": "🔐 **TEST ALERT** — Cyon security monitoring test"}'

# Test with @mention (be careful in production!)
curl -X POST "$DISCORD_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content": "@everyone 🚨 **TEST CRITICAL ALERT** (ignore this)"}'
```

### Test Alert Scripts

```bash
# Manually trigger critical alert check
bash ~/mytheon-red-team/scripts/critical-alerts.sh

# Manually trigger daily digest
bash ~/mytheon-red-team/scripts/daily-digest.sh
```

---

## Tuning Alerts

### Reducing False Positives

**Problem:** Too many alerts for non-critical events

**Solutions:**
1. Increase thresholds (e.g., 10 → 20 failed logins for suspicious pattern)
2. Add cooldown periods (don't alert more than once per hour)
3. Whitelist known IPs (office, Will's home, etc.)

### Reducing Alert Fatigue

**Problem:** Too many alerts, team ignores them

**Solutions:**
1. Consolidate similar alerts (daily digest instead of per-event)
2. Severity-based routing (critical → @everyone, high → no @mention)
3. Auto-resolve where possible (e.g., disk usage drops below threshold)

---

## Next Steps (Round 8)

1. **Get Discord Webhook URL** (from Will)
2. **Deploy Alert Scripts** (to mirrorborn.us)
3. **Setup Cron Jobs** (critical/high/daily/weekly)
4. **Test Alerts** (dry run, verify delivery)
5. **Tune Thresholds** (adjust based on first week)

---

**Owner:** Cyon 🪶  
**Status:** Ready for deployment (need webhook URL)  
**Next Review:** After 1 week of alerts (tune thresholds)

*Silent until it matters. Loud when it does.* 🔐
