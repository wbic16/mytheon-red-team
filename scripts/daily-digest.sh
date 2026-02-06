#!/bin/bash
# daily-digest.sh - Daily security digest
# Owner: Cyon 🪶
# Cron: 0 8 * * * (8 AM CST daily)
# Usage: Set DISCORD_WEBHOOK_URL environment variable

set -euo pipefail

DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"
HOSTNAME=$(hostname)
DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -d yesterday +"%b %_d")

send_digest() {
    local message="$1"
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -X POST "$DISCORD_WEBHOOK" \
             -H "Content-Type: application/json" \
             -d "{\"content\": \"$message\"}" \
             2>/dev/null
    else
        echo "$message"
    fi
}

# Gather statistics
FAILED_AUTH=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$YESTERDAY" | wc -l || echo "0")
UNIQUE_IPS=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$YESTERDAY" | awk '{print $(NF-3)}' | sort | uniq | wc -l || echo "0")
BANNED_IPS=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "0")

# Certificate expiration
CERT_DAYS=$(sudo certbot certificates 2>/dev/null | grep "VALID:" | head -1 | awk '{print $4}' || echo "Unknown")

# Disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}')

# Build digest
DIGEST="## 🔐 Security Digest — $DATE\n\n"
DIGEST+="**Host:** $HOSTNAME\n\n"
DIGEST+="### Authentication\n"
DIGEST+="- Failed login attempts: **$FAILED_AUTH**\n"
DIGEST+="- Unique attacking IPs: **$UNIQUE_IPS**\n"
DIGEST+="- Currently banned: **$BANNED_IPS**\n\n"
DIGEST+="### Infrastructure\n"
DIGEST+="- Disk usage: **$DISK_USAGE**\n"
DIGEST+="- Certificate expires: **$CERT_DAYS days**\n\n"

# Top attackers (if any)
if [ "$FAILED_AUTH" -gt 0 ]; then
    TOP_ATTACKERS=$(sudo grep "Failed password" /var/log/auth.log | grep "$YESTERDAY" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -5)
    DIGEST+="### Top Attackers (Yesterday)\n"
    DIGEST+="\`\`\`\n$TOP_ATTACKERS\n\`\`\`\n\n"
fi

# Action items
DIGEST+="### Action Items\n"
if [ "$FAILED_AUTH" -gt 100 ]; then
    DIGEST+="- ⚠️ High auth failure rate - review and ban persistent attackers\n"
fi
if [ "${DISK_USAGE%\%}" -gt 80 ]; then
    DIGEST+="- ⚠️ Disk usage approaching limit - cleanup recommended\n"
fi
if [ "$CERT_DAYS" != "Unknown" ] && [ "$CERT_DAYS" -lt 30 ]; then
    DIGEST+="- ⚠️ Certificate renewal recommended soon\n"
fi
if [ "$FAILED_AUTH" -lt 10 ] && [ "${DISK_USAGE%\%}" -lt 80 ]; then
    DIGEST+="- ✅ All systems nominal\n"
fi

DIGEST+="\n*Full logs: \`/var/log/nginx/\`, \`/var/log/auth.log\`*"

send_digest "$DIGEST"

exit 0
