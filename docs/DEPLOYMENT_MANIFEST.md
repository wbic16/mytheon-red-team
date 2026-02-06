# Deployment Manifest — Round 11/N

**Date:** 2026-02-06  
**Target:** mirrorborn.us (44.248.235.76)  
**Package:** mirrorborn-deployment-round11.tar.gz (9.0 KB)  
**Owner:** Cyon 🪶 (prepared), Verse 🌀 (deployer)

---

## Package Contents

```
mirrorborn.us/
├── .well-known/
│   └── security.txt          # Security disclosure policy
├── css/
│   ├── main.css              # Base styles
│   └── sq-cloud.css          # Brand stylesheet
├── images/
│   ├── lattice-pattern.svg   # Background pattern
│   ├── mirrorborn-icons.svg  # Shell of Nine icons
│   └── phext-logo.svg        # 11D lattice logo
├── js/
│   └── [JS files]            # Frontend utilities
├── 404.html                  # Error page
├── 500.html                  # Server error page
├── favicon.svg               # Site icon
├── index.html                # Homepage
├── landing.html              # Landing page (12.5 KB)
└── loading.html              # Loading state
```

---

## Deployment Instructions for Verse

### Step 1: Extract Package

```bash
cd /tmp
tar -xzf mirrorborn-deployment-round11.tar.gz
```

### Step 2: Deploy to Webroot

```bash
# Ensure webroot exists
sudo mkdir -p /sites/web/mirrorborn.us

# Copy files
sudo cp -r mirrorborn.us/* /sites/web/mirrorborn.us/

# Set ownership
sudo chown -R www-data:www-data /sites/web/mirrorborn.us

# Set permissions
sudo find /sites/web/mirrorborn.us -type d -exec chmod 755 {} \;
sudo find /sites/web/mirrorborn.us -type f -exec chmod 644 {} \;
```

### Step 3: Verify Deployment

```bash
# Check files deployed
ls -la /sites/web/mirrorborn.us/

# Test local access
curl http://localhost/landing.html

# Test HTTPS
curl https://mirrorborn.us/landing.html
```

### Step 4: Security Validation

```bash
# Verify security.txt accessible
curl https://mirrorborn.us/.well-known/security.txt

# Should return security disclosure policy
# Expected: 200 OK with contact info
```

---

## What This Deployment Includes

### Frontend Assets
- ✅ Responsive landing page (Chrys's design)
- ✅ CSS styling (brand colors, typography)
- ✅ SVG assets (logos, icons, patterns)
- ✅ Error pages (404, 500)
- ✅ Loading states

### Security Assets
- ✅ security.txt (responsible disclosure)
- ✅ Security contact: security@mirrorborn.us
- ✅ Canonical URL defined
- ✅ Expiration: 2026-05-07

### Missing (Requires Backend)
- ⏸️ Auth flow (magic links, JWT, sessions)
- ⏸️ SQ API integration
- ⏸️ Rate limiting
- ⏸️ User dashboard

---

## Post-Deployment Validation

### Cyon's Checks (After Deployment)

```bash
# Run recon scan
cd ~/mytheon-red-team/scripts
./recon.sh

# Verify security.txt
curl -I https://mirrorborn.us/.well-known/security.txt

# Check landing page loads
curl -I https://mirrorborn.us/landing.html

# Validate assets
curl -I https://mirrorborn.us/css/sq-cloud.css
curl -I https://mirrorborn.us/images/phext-logo.svg
```

**Expected Results:**
- All URLs return 200 OK
- security.txt accessible
- Assets loading correctly
- No 404s on deployed files

---

## Alternative Deployment (If SSH Not Available)

If Cyon cannot SSH to mirrorborn.us directly:

### Option 1: Verse Deploys from Gateway

```bash
# From Verse's location
scp mirrorborn-deployment-round11.tar.gz wbic16@44.248.235.76:/tmp/
ssh wbic16@44.248.235.76
cd /tmp
tar -xzf mirrorborn-deployment-round11.tar.gz
sudo cp -r mirrorborn.us/* /sites/web/mirrorborn.us/
# Set permissions as above
```

### Option 2: Git-Based Deployment

```bash
# Clone phext-dot-io-v2 on mirrorborn.us
git clone https://github.com/wbic16/phext-dot-io-v2.git /tmp/phext-io
cd /tmp/phext-io
git checkout exo

# Deploy
sudo cp -r public/* /sites/web/mirrorborn.us/
sudo cp -r css /sites/web/mirrorborn.us/
sudo cp -r images /sites/web/mirrorborn.us/
# Add security.txt manually
```

---

## Rollback Procedure (If Needed)

If deployment causes issues:

```bash
# Backup current webroot
sudo cp -r /sites/web/mirrorborn.us /sites/web/mirrorborn.us.backup.$(date +%s)

# Restore previous version
sudo cp -r /sites/web/mirrorborn.us.backup.[timestamp]/* /sites/web/mirrorborn.us/

# Or clear webroot
sudo rm -rf /sites/web/mirrorborn.us/*
```

---

## Integration with Existing Infrastructure

### Nginx Configuration (Ensure This Exists)

```nginx
server {
    listen 443 ssl http2;
    server_name mirrorborn.us www.mirrorborn.us;

    root /sites/web/mirrorborn.us;
    index index.html landing.html;

    # SSL config (already done)
    ssl_certificate /etc/letsencrypt/live/mirrorborn.us/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mirrorborn.us/privkey.pem;

    # Security headers (P0 - still pending)
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    # ... (see remediation-guide-verse.md for full list)

    # Static file serving
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security.txt
    location /.well-known/security.txt {
        default_type text/plain;
    }

    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /500.html;
}
```

### Verification Commands

```bash
# Test nginx config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Check nginx status
sudo systemctl status nginx
```

---

## Post-Deployment Security Check

**Cyon will verify:**
1. ✅ security.txt accessible and valid
2. ✅ Landing page loads correctly
3. ✅ Assets (CSS, images, JS) load
4. ✅ Error pages configured
5. ⏸️ Security headers (pending P0 fixes)
6. ⏸️ nginx version hidden (pending P0 fixes)

**If any fail:** Report to Verse immediately for remediation.

---

## Success Criteria

**Deployment Successful If:**
- ✅ Landing page live at https://mirrorborn.us/landing.html
- ✅ security.txt accessible at https://mirrorborn.us/.well-known/security.txt
- ✅ All CSS/images/JS assets loading
- ✅ Error pages configured
- ✅ No 500 errors in nginx logs after deployment

**Blockers Remaining:**
- ⏸️ P0 security fixes (headers, nginx version)
- ⏸️ Backend auth flow
- ⏸️ SQ API integration

---

## Next Steps After Deployment

1. **Cyon:** Run post-deployment security validation
2. **Verse:** Apply P0 nginx fixes (if not already done)
3. **Team:** Test landing page user journey
4. **Lumen:** Review landing copy live
5. **Chrys:** Validate visual consistency

---

## Contact

**Questions:** Discord #general  
**Deployment Issues:** @Verse 🌀  
**Security Validation:** @Cyon 🪶  
**Package Location:** `~/deployment-package/mirrorborn-deployment-round11.tar.gz`

---

**Prepared by:** Cyon 🪶  
**Date:** 2026-02-06 06:22 CST  
**Status:** Ready for Verse to deploy

*Assets synthesized. Deployment ready. Awaiting Verse.* 🚀
