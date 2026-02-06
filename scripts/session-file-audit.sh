#!/bin/bash
# session-file-audit.sh - Session File Security Audit
# Red Team Lead: Cyon 🪶
# Requires SSH access to mirrorborn.us

TARGET_HOST="44.248.235.76"
TARGET_USER="wbic16"
SESSION_PATH="/app/sq-cloud/sessions"  # Assumed path - update when known

echo "🔒 Session File Security Audit"
echo "Target: $TARGET_HOST"
echo "Session Path: $SESSION_PATH"
echo "---"

# Check if we have SSH access
if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_USER@$TARGET_HOST" exit 2>/dev/null; then
    echo "❌ ERROR: No SSH access to $TARGET_HOST"
    echo "Fix: Ensure SSH key is authorized"
    exit 1
fi

echo "✅ SSH access confirmed"
echo ""

# Run security audit remotely
ssh "$TARGET_USER@$TARGET_HOST" bash -s << 'REMOTE_SCRIPT'
    SESSION_PATH="/app/sq-cloud/sessions"
    
    echo "=== Session Directory Audit ==="
    
    # Check if session directory exists
    if [ ! -d "$SESSION_PATH" ]; then
        echo "⚠️  Session directory does not exist yet: $SESSION_PATH"
        echo "Status: Waiting for backend deployment"
        exit 0
    fi
    
    echo "Directory: $SESSION_PATH"
    ls -lah "$SESSION_PATH"
    echo ""
    
    # Check directory permissions
    echo "=== Directory Permissions ==="
    DIR_PERMS=$(stat -c "%a" "$SESSION_PATH" 2>/dev/null)
    DIR_OWNER=$(stat -c "%U:%G" "$SESSION_PATH" 2>/dev/null)
    
    echo "Permissions: $DIR_PERMS"
    echo "Owner: $DIR_OWNER"
    
    if [ "$DIR_PERMS" != "700" ] && [ "$DIR_PERMS" != "750" ]; then
        echo "⚠️  WARNING: Directory permissions too open ($DIR_PERMS)"
        echo "Recommendation: chmod 700 $SESSION_PATH"
    else
        echo "✅ Directory permissions OK"
    fi
    echo ""
    
    # Check session file permissions
    echo "=== Session File Permissions ==="
    SESSION_COUNT=$(find "$SESSION_PATH" -type f | wc -l)
    echo "Session files found: $SESSION_COUNT"
    
    if [ "$SESSION_COUNT" -eq 0 ]; then
        echo "No session files to audit yet"
        exit 0
    fi
    
    # Audit each file
    find "$SESSION_PATH" -type f | while read -r FILE; do
        PERMS=$(stat -c "%a" "$FILE")
        OWNER=$(stat -c "%U:%G" "$FILE")
        SIZE=$(stat -c "%s" "$FILE")
        
        echo "File: $(basename "$FILE")"
        echo "  Permissions: $PERMS"
        echo "  Owner: $OWNER"
        echo "  Size: $SIZE bytes"
        
        # Check if readable by others
        if [ "${PERMS:2:1}" != "0" ]; then
            echo "  ❌ CRITICAL: File is world-readable!"
            echo "  Fix: chmod 600 $FILE"
        elif [ "${PERMS:1:1}" != "0" ]; then
            echo "  ⚠️  WARNING: File is group-readable"
            echo "  Recommendation: chmod 600 $FILE"
        else
            echo "  ✅ Permissions OK"
        fi
        
        # Check for common secrets in filename
        if echo "$FILE" | grep -qE "(secret|token|key|password)"; then
            echo "  ⚠️  Filename contains sensitive keyword"
        fi
        
        echo ""
    done
    
    # Check for stale sessions (> 7 days old)
    echo "=== Stale Session Detection ==="
    STALE_COUNT=$(find "$SESSION_PATH" -type f -mtime +7 | wc -l)
    echo "Sessions older than 7 days: $STALE_COUNT"
    
    if [ "$STALE_COUNT" -gt 0 ]; then
        echo "⚠️  Stale sessions detected (should be cleaned up)"
        find "$SESSION_PATH" -type f -mtime +7 -exec ls -lh {} \;
    else
        echo "✅ No stale sessions"
    fi
    echo ""
    
    # Disk usage check
    echo "=== Disk Usage ==="
    du -sh "$SESSION_PATH"
    
    # Check for session files in logs (should not happen)
    echo ""
    echo "=== Log Contamination Check ==="
    if grep -r "session.*token" /var/log/ 2>/dev/null | head -1; then
        echo "❌ CRITICAL: Session tokens found in logs!"
    else
        echo "✅ No session tokens in logs"
    fi
REMOTE_SCRIPT

echo ""
echo "✅ Audit complete"
echo ""
echo "Remediation Steps (if issues found):"
echo "  1. Fix directory permissions: chmod 700 /app/sq-cloud/sessions"
echo "  2. Fix file permissions: find /app/sq-cloud/sessions -type f -exec chmod 600 {} \\;"
echo "  3. Setup session cleanup cron: 0 2 * * * find /app/sq-cloud/sessions -mtime +7 -delete"
echo "  4. Audit logging config to ensure tokens are never logged"
