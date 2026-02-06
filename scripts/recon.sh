#!/bin/bash
# recon.sh - Phase 1 reconnaissance for mirrorborn.us
# Red Team Lead: Cyon 🪶

TARGET="mirrorborn.us"
TARGET_IP="44.248.235.76"
RESULTS_DIR="../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$RESULTS_DIR/recon-$TIMESTAMP.txt"

echo "🔍 Mytheon Red Team - Reconnaissance Phase"
echo "Target: $TARGET ($TARGET_IP)"
echo "Report: $REPORT"
echo "---"

mkdir -p "$RESULTS_DIR"

{
    echo "=== Mytheon Red Team - Reconnaissance Report ==="
    echo "Target: $TARGET ($TARGET_IP)"
    echo "Timestamp: $(date)"
    echo "Red Team Lead: Cyon 🪶"
    echo ""

    # DNS Enumeration
    echo "=== DNS Records ==="
    dig +short $TARGET A
    dig +short $TARGET AAAA
    dig +short $TARGET MX
    dig +short $TARGET TXT
    echo ""

    # Port Scan (common web ports)
    echo "=== Port Scan (nmap) ==="
    if command -v nmap &> /dev/null; then
        nmap -Pn -p 80,443,8080,8443,22,3000,5000 $TARGET_IP
    else
        echo "nmap not installed - skipping port scan"
    fi
    echo ""

    # HTTP/HTTPS Check
    echo "=== HTTP Response ==="
    curl -I -s http://$TARGET || echo "HTTP failed"
    echo ""

    echo "=== HTTPS Response ==="
    curl -I -s https://$TARGET || echo "HTTPS failed"
    echo ""

    # TLS/SSL Check
    echo "=== TLS Certificate Info ==="
    if command -v openssl &> /dev/null; then
        echo | openssl s_client -connect $TARGET:443 -servername $TARGET 2>/dev/null | \
            openssl x509 -noout -subject -issuer -dates 2>/dev/null || echo "No HTTPS cert found"
    else
        echo "openssl not installed - skipping cert check"
    fi
    echo ""

    # Technology Detection
    echo "=== Server Headers ==="
    curl -s -I https://$TARGET 2>/dev/null | grep -E "^Server:|^X-Powered-By:" || echo "No headers exposed"
    echo ""

    # Common Paths
    echo "=== Common Path Probe ==="
    for path in /robots.txt /.well-known/security.txt /sitemap.xml /.git/config /admin /api; do
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$TARGET$path 2>/dev/null)
        echo "$path - HTTP $STATUS"
    done
    echo ""

    echo "=== End of Recon Report ==="
} | tee "$REPORT"

echo ""
echo "✅ Reconnaissance complete. Report saved to: $REPORT"
echo ""
echo "Next steps:"
echo "  - Review findings"
echo "  - Identify exposed services"
echo "  - Plan Phase 2 (Authentication testing)"
