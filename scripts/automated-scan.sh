#!/bin/bash
# automated-scan.sh - Weekly security scanning for Mirrorborn infrastructure
# Owner: Cyon 🪶
# Cron: 0 2 * * 0 (Every Sunday at 2 AM CST)

set -euo pipefail

# Configuration
RESULTS_DIR="$HOME/mytheon-red-team/results/automated-scans"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$RESULTS_DIR/scan-$TIMESTAMP.txt"
DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"  # Set in environment

# Domains to scan
DOMAINS=(
    "mirrorborn.us"
    "visionquest.me"
    "apertureshift.com"
    "wishnode.net"
    "sotafomo.com"
    "quickfork.net"
)

# Ensure results directory exists
mkdir -p "$RESULTS_DIR"

# Start report
{
    echo "============================================="
    echo "  Mirrorborn Security Scan — Automated"
    echo "============================================="
    echo "Timestamp: $(date)"
    echo "Domains: ${DOMAINS[*]}"
    echo "Report: $REPORT"
    echo "============================================="
    echo ""

    # === Port Scan ===
    echo "=== PORT SCAN (nmap) ==="
    echo "Scanning common web ports (80, 443, 22, 8080, 3000)..."
    echo ""
    
    for domain in "${DOMAINS[@]}"; do
        echo "Domain: $domain"
        if command -v nmap &> /dev/null; then
            nmap -Pn -p 80,443,22,8080,3000 "$domain" 2>&1 || echo "  Scan failed for $domain"
        else
            echo "  ERROR: nmap not installed"
        fi
        echo ""
    done

    # === TLS/SSL Check ===
    echo "=== TLS/SSL AUDIT ==="
    echo "Checking certificate validity and TLS configuration..."
    echo ""
    
    for domain in "${DOMAINS[@]}"; do
        echo "Domain: $domain"
        
        # Certificate expiration
        if command -v openssl &> /dev/null; then
            CERT_INFO=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
            if [ -n "$CERT_INFO" ]; then
                echo "$CERT_INFO"
                
                # Check if cert expires within 30 days
                EXPIRY=$(echo "$CERT_INFO" | grep "notAfter" | cut -d= -f2)
                EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo "0")
                NOW_EPOCH=$(date +%s)
                DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
                
                echo "Days until expiration: $DAYS_LEFT"
                
                if [ "$DAYS_LEFT" -lt 30 ]; then
                    echo "⚠️  WARNING: Certificate expires in less than 30 days!"
                fi
            else
                echo "  No HTTPS certificate found (or not configured yet)"
            fi
        else
            echo "  ERROR: openssl not installed"
        fi
        echo ""
    done

    # === Security Headers Check ===
    echo "=== SECURITY HEADERS AUDIT ==="
    echo "Checking for HSTS, CSP, X-Frame-Options, etc..."
    echo ""
    
    for domain in "${DOMAINS[@]}"; do
        echo "Domain: $domain"
        if command -v curl &> /dev/null; then
            HEADERS=$(curl -I -s "https://$domain" 2>/dev/null || echo "")
            
            if [ -n "$HEADERS" ]; then
                # Check for critical headers
                echo "$HEADERS" | grep -i "strict-transport-security" || echo "  ❌ HSTS missing"
                echo "$HEADERS" | grep -i "content-security-policy" || echo "  ❌ CSP missing"
                echo "$HEADERS" | grep -i "x-frame-options" || echo "  ❌ X-Frame-Options missing"
                echo "$HEADERS" | grep -i "x-content-type-options" || echo "  ❌ X-Content-Type-Options missing"
                
                # Check for version disclosure
                if echo "$HEADERS" | grep -i "server:" | grep -qE "[0-9]+\.[0-9]+"; then
                    echo "  ⚠️  Server version exposed: $(echo "$HEADERS" | grep -i "server:")"
                fi
            else
                echo "  No response (HTTPS may not be configured)"
            fi
        else
            echo "  ERROR: curl not installed"
        fi
        echo ""
    done

    # === Dependency Audit (if applicable) ===
    echo "=== DEPENDENCY AUDIT ==="
    echo "Checking for known vulnerabilities in dependencies..."
    echo ""
    
    # Check if backend directory exists
    if [ -d "/app/sq-cloud" ]; then
        cd /app/sq-cloud
        
        # npm audit (if Node.js project)
        if [ -f "package.json" ] && command -v npm &> /dev/null; then
            echo "Running npm audit..."
            npm audit --json > npm-audit-$TIMESTAMP.json 2>&1 || true
            npm audit 2>&1 | head -50 || echo "npm audit completed"
            echo ""
        fi
        
        # cargo audit (if Rust project)
        if [ -f "Cargo.toml" ] && command -v cargo &> /dev/null; then
            echo "Running cargo audit..."
            cargo audit --json > cargo-audit-$TIMESTAMP.json 2>&1 || true
            cargo audit 2>&1 | head -50 || echo "cargo audit completed"
            echo ""
        fi
    else
        echo "Backend directory /app/sq-cloud not found (may not be deployed yet)"
        echo ""
    fi

    # === DNS Check ===
    echo "=== DNS VALIDATION ==="
    echo "Checking DNS records..."
    echo ""
    
    for domain in "${DOMAINS[@]}"; do
        echo "Domain: $domain"
        dig +short "$domain" A || echo "  No A record"
        dig +short "$domain" AAAA || echo "  No AAAA record (IPv6)"
        echo ""
    done

    # === Summary ===
    echo "============================================="
    echo "  SCAN SUMMARY"
    echo "============================================="
    
    # Count critical findings
    CRITICAL_COUNT=$(grep -c "CRITICAL\|⚠️" "$REPORT" 2>/dev/null || echo "0")
    WARNING_COUNT=$(grep -c "WARNING\|❌" "$REPORT" 2>/dev/null || echo "0")
    
    echo "Critical findings: $CRITICAL_COUNT"
    echo "Warnings: $WARNING_COUNT"
    echo ""
    
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo "🚨 CRITICAL ISSUES FOUND — Review immediately!"
    elif [ "$WARNING_COUNT" -gt 5 ]; then
        echo "⚠️  Multiple warnings detected — Review recommended"
    else
        echo "✅ No critical issues detected"
    fi
    
    echo ""
    echo "Full report: $REPORT"
    echo "============================================="

} | tee "$REPORT"

# Send Discord alert if critical findings
if [ "$CRITICAL_COUNT" -gt 0 ] && [ -n "$DISCORD_WEBHOOK" ]; then
    curl -X POST "$DISCORD_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"🚨 **Security Scan Alert**\n\nCritical findings: $CRITICAL_COUNT\nWarnings: $WARNING_COUNT\n\nReport: \`$REPORT\`\n\n@Cyon @Verse\"}" \
        2>/dev/null || echo "Failed to send Discord alert"
fi

# Cleanup old scans (keep last 30 days)
find "$RESULTS_DIR" -name "scan-*.txt" -mtime +30 -delete 2>/dev/null || true

echo ""
echo "✅ Automated scan complete"
echo "Next scan: $(date -d 'next Sunday 2:00' '+%Y-%m-%d %H:%M %Z')"

exit 0
