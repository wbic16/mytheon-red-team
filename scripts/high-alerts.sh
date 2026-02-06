#!/bin/bash
# high-alerts.sh - Check for high-severity security conditions  
# Owner: Cyon 🪶
# Cron: 0 * * * * (hourly)
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
             2>/dev/null
    else
        echo "[$TIMESTAMP] HIGH ALERT: $message"
    fi
}

# HA-1: Suspicious auth patterns (10+ failed logins from same IP in 1 hour)
SUSPICIOUS_IPS=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date +"%b %_d %H")" | awk '{print $(NF-3)}' | sort | uniq -c | awk '$1 >= 10 {print $1, $2}' || echo "")

if [ -n "$SUSPICIOUS_IPS" ]; then
    send_alert "⚠️ **HIGH: Suspicious authentication pattern**\n\nTime: $TIMESTAMP\nHost: $HOSTNAME\nSuspicious IPs (attempts, IP):\n\`\`\`\n$SUSPICIOUS_IPS\n\`\`\`\nAction: Monitor, consider banning if persistent\n\n@Cyon"
fi

# HA-4: Session file permission check (if session directory exists)
if [ -d "/app/sq-cloud/sessions" ]; then
    WRONG_PERMS=$(find /app/sq-cloud/sessions -type f ! -perm 600 2>/dev/null || echo "")
    if [ -n "$WRONG_PERMS" ]; then
        WRONG_COUNT=$(echo "$WRONG_PERMS" | wc -l)
        send_alert "⚠️ **HIGH: Session file permissions incorrect**\n\nTime: $TIMESTAMP\nFiles with wrong perms: $WRONG_COUNT\nExpected: 600 (rw-------)\nAction: Fix immediately\nCommand: \`chmod 600 /app/sq-cloud/sessions/*.json\`\n\n@Verse @Cyon"
    fi
fi

# HA-5: Dependency vulnerabilities (npm/cargo audit)
if [ -d "/app/sq-cloud" ]; then
    cd /app/sq-cloud
    
    # npm audit (if package.json exists)
    if [ -f "package.json" ] && command -v npm &>/dev/null; then
        HIGH_VULNS=$(npm audit --json 2>/dev/null | jq -r '.metadata.vulnerabilities.high // 0')
        CRITICAL_VULNS=$(npm audit --json 2>/dev/null | jq -r '.metadata.vulnerabilities.critical // 0')
        
        if [ "$HIGH_VULNS" -gt 0 ] || [ "$CRITICAL_VULNS" -gt 0 ]; then
            send_alert "⚠️ **HIGH: Dependency vulnerabilities found (npm)**\n\nTime: $TIMESTAMP\nCritical: $CRITICAL_VULNS\nHigh: $HIGH_VULNS\nAction: Run \`npm audit fix\` and test\n\n@Verse @Cyon"
        fi
    fi
    
    # cargo audit (if Cargo.toml exists)
    if [ -f "Cargo.toml" ] && command -v cargo-audit &>/dev/null; then
        CARGO_VULNS=$(cargo audit --json 2>/dev/null | jq -r '.vulnerabilities[] | select(.severity == "high" or .severity == "critical") | .package' || echo "")
        
        if [ -n "$CARGO_VULNS" ]; then
            send_alert "⚠️ **HIGH: Dependency vulnerabilities found (cargo)**\n\nTime: $TIMESTAMP\nAffected packages:\n\`\`\`\n$CARGO_VULNS\n\`\`\`\nAction: Update dependencies and test\n\n@Verse @Cyon"
        fi
    fi
fi

exit 0
