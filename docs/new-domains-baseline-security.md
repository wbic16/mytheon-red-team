# New Domains Baseline Security — Round 12/N

**Date:** 2026-02-06  
**Owner:** Cyon 🪶  
**Scope:** 5 new Mirrorborn domain properties  
**Status:** DNS pointing to Verse (44.248.235.76)

---

## Domain Inventory

| Domain | DNS Status | Purpose | Priority | Next Steps |
|--------|-----------|---------|----------|------------|
| visionquest.me | ✅ → Verse | Portal/hub | P1 | HTTPS + placeholder |
| apertureshift.com | ✅ → Verse | Perspective/blog | P2 | HTTPS + placeholder |
| wishnode.net | ✅ → Verse | Community | P2 | HTTPS + placeholder |
| sotafomo.com | ✅ → Verse | Events/newsletter | P2 | HTTPS + placeholder |
| quickfork.net | ✅ → Verse | Dev tools/API | P2 | HTTPS + placeholder |

---

## Baseline Security Requirements

**Minimum standard for ALL domains before launch:**

### 1. HTTPS with Valid Certificate
- Let's Encrypt certificate
- Auto-renewal configured (certbot)
- Covers domain + www subdomain
- Grade: A or A+ on SSL Labs

### 2. Security Headers
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline';" always;
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### 3. Server Hardening
- nginx version hidden (`server_tokens off`)
- Only ports 80, 443 exposed
- HTTP → HTTPS redirect (301)

### 4. Error Pages
- Custom 404 page
- Custom 500 page
- No information disclosure

### 5. Monitoring
- Uptime monitoring (all domains)
- Certificate expiration alerts
- Security event logging

---

## nginx Configuration Templates

### Template 1: Placeholder Page (Redirect to mirrorborn.us)

```nginx
# /etc/nginx/sites-available/visionquest.me
server {
    listen 80;
    server_name visionquest.me www.visionquest.me;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name visionquest.me www.visionquest.me;

    # SSL
    ssl_certificate /etc/letsencrypt/live/visionquest.me/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/visionquest.me/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self';" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Redirect to mirrorborn.us
    return 302 https://mirrorborn.us;
}
```

### Template 2: Static Placeholder Page

```nginx
server {
    listen 443 ssl http2;
    server_name visionquest.me www.visionquest.me;

    root /sites/web/visionquest.me;
    index index.html;

    # SSL + security headers (same as above)
    
    location / {
        try_files $uri $uri/ =404;
    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /500.html;
}
```

---

## Deployment Procedure (For Verse)

### Step 1: Provision Certificates

```bash
# For each domain
sudo certbot certonly --nginx -d visionquest.me -d www.visionquest.me
sudo certbot certonly --nginx -d apertureshift.com -d www.apertureshift.com
sudo certbot certonly --nginx -d wishnode.net -d www.wishnode.net
sudo certbot certonly --nginx -d sotafomo.com -d www.sotafomo.com
sudo certbot certonly --nginx -d quickfork.net -d www.quickfork.net

# Verify all certificates
sudo certbot certificates
```

### Step 2: Create nginx Configs

```bash
# Option A: Redirect to mirrorborn.us (fastest)
for domain in visionquest.me apertureshift.com wishnode.net sotafomo.com quickfork.net; do
    sudo nano /etc/nginx/sites-available/$domain
    # Paste Template 1 (redirect)
    sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
done

# Option B: Static placeholder (if content ready)
# Use Template 2, ensure /sites/web/$domain/index.html exists
```

### Step 3: Test and Reload

```bash
# Test all configs
sudo nginx -t

# If OK, reload
sudo systemctl reload nginx

# Verify services
for domain in visionquest.me apertureshift.com wishnode.net sotafomo.com quickfork.net; do
    echo "Testing $domain..."
    curl -I https://$domain
done
```

---

## Validation Checklist (Cyon)

### Per-Domain Tests

**For each domain:**

```bash
# Test 1: HTTPS accessible
curl -I https://$DOMAIN | head -1
# Expected: HTTP/2 200 or HTTP/2 302

# Test 2: Certificate valid
echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -dates
# Expected: Valid dates, no errors

# Test 3: Security headers present
curl -I https://$DOMAIN | grep -E "Strict-Transport|X-Frame|Content-Security"
# Expected: All headers present

# Test 4: nginx version hidden
curl -I https://$DOMAIN | grep -i "server:"
# Expected: "server: nginx" (no version)

# Test 5: HTTP redirects to HTTPS
curl -I http://$DOMAIN | head -1
# Expected: HTTP/1.1 301 or 302, Location: https://

# Test 6: SSL Labs grade
# Visit: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN
# Expected: A or A+
```

---

## Security Health Scores

### Initial Assessment (Before HTTPS)

| Domain | Score | Status |
|--------|-------|--------|
| visionquest.me | 0/100 | ❌ No HTTPS |
| apertureshift.com | 0/100 | ❌ No HTTPS |
| wishnode.net | 0/100 | ❌ No HTTPS |
| sotafomo.com | 0/100 | ❌ No HTTPS |
| quickfork.net | 0/100 | ❌ No HTTPS |

### Target After Baseline Security

| Domain | Score | Status |
|--------|-------|--------|
| visionquest.me | 75/100 | ✅ Baseline secure |
| apertureshift.com | 75/100 | ✅ Baseline secure |
| wishnode.net | 75/100 | ✅ Baseline secure |
| sotafomo.com | 75/100 | ✅ Baseline secure |
| quickfork.net | 75/100 | ✅ Baseline secure |

**Score breakdown:**
- SSL (25 pts): HTTPS A+ ✅
- Headers (20 pts): All present ✅
- Dependencies (20 pts): N/A (static pages) ✅
- Incident Response (10 pts): Framework ready ✅
- Monitoring (15 pts): ⏸️ (deploy later, placeholder = 0)

**Actual score with placeholder:** 65/100 (acceptable for pre-launch)

---

## Aggregate Fleet Security Score

**Formula:**
```
Fleet Score = (mirrorborn.us × 0.5) + (average of 5 new domains × 0.5)
```

**Current:**
```
Fleet = (55 × 0.5) + (0 × 0.5) = 27.5/100 🔴
```

**After mirrorborn.us P0 fixes + new domain baselines:**
```
Fleet = (75 × 0.5) + (65 × 0.5) = 70/100 🟡
```

**Target for launch:**
```
Fleet = (85 × 0.5) + (65 × 0.5) = 75/100 ✅
```

---

## Placeholder Page Content

### index.html Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[Domain] — Coming Soon</title>
    <style>
        body {
            font-family: monospace;
            background: #111;
            color: #0f0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
        }
        h1 { margin: 0 0 1em 0; }
        a { color: #0a0; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>[Domain Name]</h1>
        <p>Coming soon as part of the Mirrorborn ecosystem.</p>
        <p><a href="https://mirrorborn.us">Visit mirrorborn.us →</a></p>
    </div>
</body>
</html>
```

**Deploy one for each domain:**
- visionquest.me: "VisionQuest — Coming Soon"
- apertureshift.com: "Aperture Shift — Coming Soon"
- wishnode.net: "Wishnode — Coming Soon"
- sotafomo.com: "SotaFOMO — Coming Soon"
- quickfork.net: "QuickFork — Coming Soon"

---

## Launch Readiness Criteria

**New domains are launch-ready if:**
- ✅ HTTPS with valid certificate (A+ grade)
- ✅ Security headers present
- ✅ nginx version hidden
- ✅ Redirect or placeholder page (no 404s)
- ✅ Certificate auto-renewal configured

**Acceptable compromise for Feb 13 launch:**
- Placeholder pages OK (full sites can launch later)
- Monitoring can be added post-launch
- Purpose-specific security can wait until features defined

---

## Timeline

**Estimated time for Verse:**
- Certificate provisioning: 15 minutes (5 domains × 3 min each)
- nginx config: 20 minutes (5 domains × 4 min each)
- Testing: 10 minutes
- **Total:** ~45 minutes

**Estimated time for Cyon validation:**
- Per-domain tests: 5 minutes each
- **Total:** 25 minutes for all 5

**Combined:** ~70 minutes from start to validated

---

## Next Steps

1. **Verse:** Begin certificate provisioning for 5 new domains
2. **Verse:** Deploy nginx configs (redirect or placeholder)
3. **Cyon:** Validate each domain after deployment
4. **Cyon:** Update security health scores
5. **Team:** Decide on placeholder vs. redirect strategy

---

**Owner:** Cyon 🪶  
**Status:** Development phase (baseline security defined)  
**Next:** Awaiting Verse deployment

*Six domains. One security baseline. Zero compromises.* 🔐
