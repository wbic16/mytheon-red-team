#!/bin/bash
# critical-alerts.sh - Check for critical security conditions
# Owner: Cyon 🪶
# Cron: */5 * * * * (every 5 minutes)
# Usage: Set DISCORD_WEBHOOK_URL environment variable

set -euo pipefail

DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"
HOSTNAME=$(hostname)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")

send_alert() {
    local message="$1"
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -X POST "$DISCORD_WEBHOOK" \
             -H "Content-Type: application/json" \
             -d "{\"content\": \"$message\"}" \
             2>/dev/null || echo "Failed to send Discord alert"
    else
        echo "[$TIMESTAMP] ALERT (no webhook): $message"
    fi
}

# CA-1: Service check (nginx)
if ! systemctl is-active nginx &>/dev/null; then
    send_alert "@everyone 🚨 **CRITICAL: nginx down on $HOSTNAME**\n\nTime: $TIMESTAMP\nAction: Investigate immediately\n\n@Verse @Cyon"
    exit 1
fi

# CA-1: Service check (SQ API)
if ! curl -f -s -m 5 https://mirrorborn.us/1.1.1/1.1.1/1.1.1 &>/dev/null; then
    send_alert "@everyone 🚨 **CRITICAL: SQ API not responding**\n\nTime: $TIMESTAMP\nAction: Check SQ process status\n\n@Verse @Cyon"
fi

# CA-2: Certificate expiration
CERT_EXPIRY=$(sudo certbot certificates 2>/dev/null | grep "VALID:" | head -1 | awk '{print $4}' || echo "999")
if [ "$CERT_EXPIRY" != "999" ] && [ "$CERT_EXPIRY" -lt 7 ]; then
    send_alert "@everyone ⚠️ **CRITICAL: Certificate expiring soon**\n\nDomain: mirrorborn.us\nDays left: $CERT_EXPIRY\nTime: $TIMESTAMP\nAction: Renew immediately\n\n@Verse"
fi

# CA-3: Disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | tr -d '%' || echo "0")
if [ "$DISK_USAGE" -gt 90 ]; then
    send_alert "@everyone 🚨 **CRITICAL: Disk usage at ${DISK_USAGE}%**\n\nHost: $HOSTNAME\nTime: $TIMESTAMP\nAction: Free up space or expand volume\n\n@Verse"
fi

# CA-4: Brute force detection
FAILED_COUNT=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date +"%b %_d %H:")" | wc -l || echo "0")
if [ "$FAILED_COUNT" -gt 100 ]; then
    ATTACKING_IPS=$(sudo grep "Failed password" /var/log/auth.log | grep "$(date +"%b %_d %H:")" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -5)
    send_alert "@everyone 🚨 **CRITICAL: Brute force attack detected**\n\nFailed attempts: $FAILED_COUNT in last hour\nTime: $TIMESTAMP\nTop attackers:\n\`\`\`\n$ATTACKING_IPS\n\`\`\`\nAction: Block attacking IPs\n\n@Cyon @Verse"
fi

exit 0
