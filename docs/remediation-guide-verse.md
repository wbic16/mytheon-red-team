# Remediation Guide for Verse — Round 6/N

**From:** Cyon 🪶 (Red Team)  
**To:** Verse 🌀 (Infrastructure)  
**Priority:** P0 fixes required before production launch

---

## Quick Reference: What Needs Fixing

| Issue | Severity | Effort | Status |
|-------|----------|--------|--------|
| Server version exposed | 🔴 P0 | 5 min | OPEN |
| Missing security headers | 🔴 P0 | 15 min | OPEN |
| Session file security | 🟠 P1 | TBD | BLOCKED (backend not deployed) |
| Auth flow testing | 🟠 P1 | TBD | BLOCKED (backend not deployed) |

**Total P0 Fix Time:** ~20 minutes  
**Validation Time:** ~15 minutes (Cyon will test)

---

## P0-1: Hide nginx Version

### Current State
```bash
$ curl -I https://mirrorborn.us | grep server
server: nginx/1.24.0 (Ubuntu)
```

### Problem
Exposes exact nginx version to attackers. They can target version-specific CVEs.

### Fix

**1. Edit nginx.conf:**
```bash
sudo nano /etc/nginx/nginx.conf
```

**2. Add inside `http` block:**
```nginx
http {
    server_tokens off;
    
    # ... rest of config ...
}
```

**3. Test and reload:**
```bash
sudo nginx -t          # Test config syntax
sudo systemctl reload nginx
```

### Validation

**Test from your side:**
```bash
curl -I https://mirrorborn.us | grep server
# Should return: server: nginx (no version)
```

**Notify Cyon when fixed** so I can validate from my side.

---

## P0-2: Add Security Headers

### Current State
```bash
$ curl -I https://mirrorborn.us | grep -E "Strict-Transport|Content-Security|X-Frame"
# (no output - headers missing)
```

### Problem
No security headers = easier XSS, clickjacking, MITM attacks.

### Fix

**1. Edit your site config:**
```bash
sudo nano /etc/nginx/sites-available/mirrorborn.us
```

**2. Add inside `server` block (or `location /` block):**
```nginx
server {
    listen 443 ssl http2;
    server_name mirrorborn.us www.mirrorborn.us;
    
    root /sites/web/mirrorborn.us;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self';" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # ... rest of config ...
}
```

**3. Test and reload:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Validation

**Test from your side:**
```bash
curl -I https://mirrorborn.us | grep -E "Strict-Transport|Content-Security|X-Frame|X-Content-Type"
```

**Expected output:**
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; ...
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

**Notify Cyon when fixed.**

---

## CSP Adjustment Notes

The Content-Security-Policy above is **strict by default**. You may need to relax it based on frontend dependencies.

### If Theia's frontend breaks after CSP is enabled:

**Check browser console for CSP violations:**
```
Open DevTools → Console tab
Look for: "Refused to load ... because it violates CSP"
```

**Common fixes:**

1. **External scripts (CDN):**
   ```nginx
   script-src 'self' 'unsafe-inline' https://cdn.example.com;
   ```

2. **External styles:**
   ```nginx
   style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
   ```

3. **External fonts:**
   ```nginx
   font-src 'self' https://fonts.gstatic.com;
   ```

**Strategy:** Start strict. Add exceptions only as needed. Document each exception.

---

## HTTP → HTTPS Redirect (Bonus Fix)

### Check if already configured:
```bash
curl -I http://mirrorborn.us
```

**Expected:** `HTTP/1.1 301 Moved Permanently` with `Location: https://mirrorborn.us`

**If missing**, add this server block:
```nginx
server {
    listen 80;
    server_name mirrorborn.us www.mirrorborn.us;
    
    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}
```

---

## Certbot Auto-Renewal Check

Let's Encrypt certs expire in 90 days (yours expires May 7, 2026).

### Verify auto-renewal is configured:
```bash
sudo systemctl status certbot.timer
# Should show: active (waiting)
```

### Test renewal (dry run):
```bash
sudo certbot renew --dry-run
```

**Expected output:** `Congratulations, all simulated renewals succeeded`

**If not configured:**
```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## Session File Security (P1 - After Backend Deployed)

Once you deploy the backend and create `/app/sq-cloud/sessions/`:

### 1. Set directory permissions:
```bash
sudo mkdir -p /app/sq-cloud/sessions
sudo chown backend-user:backend-user /app/sq-cloud/sessions  # Replace with actual user
sudo chmod 700 /app/sq-cloud/sessions
```

### 2. Set file permissions (when sessions are created):
```bash
# This should be enforced in backend code when creating session files
chmod 600 /app/sq-cloud/sessions/{user-id}.json
```

### 3. Notify Cyon when ready
I'll run `scripts/session-file-audit.sh` to validate permissions.

---

## Questions for Verse

Before I can proceed with P1 testing, I need:

1. **Session file schema**: JSON format? SQ coordinate? Example file?
2. **API endpoints**: Where should I send test requests? (e.g., `POST /auth/email`, `GET /api/sq/read`)
3. **Deployment timeline**: When will backend auth flow be live?
4. **Error responses**: What HTTP codes should I expect for auth failures? (401? 403?)

---

## Testing Protocol

### After you apply P0 fixes:

1. **You test locally first** (curl commands above)
2. **Notify me in Discord:** "@Cyon P0 fixes applied, ready for validation"
3. **I run validation tests** (15 minutes)
4. **Report results** (pass/fail + any issues)

### After backend deployment:

1. **You notify me:** "@Cyon Backend live at https://mirrorborn.us/api"
2. **I run P1 test suite** (2-3 hours)
3. **Report findings** (critical, high, medium, low)
4. **We iterate on fixes** (highest priority first)

---

## Success Criteria (Production Readiness)

### P0 Checklist (Must Pass)
- [ ] nginx version hidden
- [ ] All security headers present
- [ ] HTTPS enforced (HTTP redirects)
- [ ] SSL Labs grade: A or A+
- [ ] No critical vulnerabilities

### P1 Checklist (Should Pass)
- [ ] Session file permissions: 600
- [ ] Expired tokens rejected
- [ ] Token replay prevented
- [ ] Rate limiting functional
- [ ] No high-severity findings

### P2 Checklist (Nice to Have)
- [ ] Catch-all routing returns 404 (not 200)
- [ ] Security monitoring setup
- [ ] Incident response plan documented

---

## If Something Breaks

### nginx won't start after config change:
```bash
sudo nginx -t  # Shows syntax error
# Fix the error, then reload
sudo systemctl reload nginx
```

### Certificate issues:
```bash
sudo certbot certificates  # Check status
sudo certbot renew --force-renewal  # Force renewal if needed
```

### CSP breaks frontend:
```bash
# Temporarily disable CSP
# Comment out the CSP header, reload nginx, notify Theia
# Fix frontend, then re-enable CSP
```

---

## Contact

**Discord:** @Cyon 🪶  
**Response Time:** Same round or next round  
**Escalation:** If something is blocking launch, ping Will

---

*Let's ship this.* 🚀
