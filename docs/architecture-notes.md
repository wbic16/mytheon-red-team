# Architecture Notes — Round 4/N

**Source**: Will's directives in Discord #general  
**Updated**: 2026-02-05 Round 4

---

## File Structure

```
/sites/web/mirrorborn.us/          # Webroot (non-standard path - good)
/app/sq-cloud/                      # SQ Cloud app install
/app/mytheon-arena/                 # Mytheon Arena app install
```

**Security Note**: Non-default webroot reduces automated scanner effectiveness. Good practice.

---

## Authentication Flow (Updated)

### Magic Email Token Flow
1. User submits email via frontend
2. Backend generates ephemeral token (JWT)
3. AWS SES sends email with magic link
4. User clicks link → token validated
5. Backend creates server-side session token
6. Session token stored in **separate auth file per user** (filesystem-based)
7. Session token returned to client (cookie)

### Token Lifetimes
- **Magic link token:** 5 minutes (tight window, good)
- **Session token:** 1 week (need revocation mechanism)

### SQ Access Control
- SQ sessions authenticated **only after email verification**
- Must verify session → user → email confirmed before allowing SQ operations

---

## Session Storage Design

**Server-side session tokens keyed by user account**

Implications:
- Filesystem-based session store (likely `/app/sq-cloud/sessions/{user-id}.json` or similar)
- Each user gets separate auth file
- Need to test:
  - File permissions (must be 600, owned by app user)
  - Race conditions (concurrent session creation/validation)
  - Revocation (delete file or mark as revoked inside)
  - Cleanup (expired sessions not garbage collected?)

**Threat:** If file permissions are wrong (world-readable), all session tokens leak.

**Test:** Try to read other users' session files from within app context.

---

## AWS SES Integration

Will handling SES config. We receive:
- SMTP credentials or API keys (environment variables)
- Verified sender domain (mirrorborn.us)
- Email template location (Chrys delivering)

**Security Tests:**
- Verify SPF/DKIM/DMARC records
- Test email spoofing resistance
- Validate rate limiting (prevent email bombing)
- Check for credential leakage in logs/errors

---

## Open Questions

1. **Session file format?** JSON? SQ coordinate? Need schema to test parsing bugs.
2. **Revocation mechanism?** Delete file? Add `revoked: true` field? Need to know for testing.
3. **Concurrent session limit?** Can one user have 10 active sessions? DoS vector?
4. **Session cleanup?** Cron job? Manual? Expired sessions accumulate = disk fill?
5. **File locking?** Concurrent read/write to session file could corrupt data.

---

## Security Priorities (Round 4)

### P0 - Critical Gaps
1. **HTTPS setup** (blocks all auth testing)
2. **File permission validation** (session files must be locked down)
3. **Session revocation design** (1 week is long, need kill switch)

### P1 - High Priority
4. **Email spoofing tests** (SPF/DKIM/DMARC validation)
5. **Concurrent session handling** (race condition testing)
6. **Token validation bypass attempts** (expired, malformed, replayed)

### P2 - Medium Priority
7. **Rate limiting** (email send, session creation, SQ API)
8. **Session cleanup automation** (disk exhaustion prevention)
9. **Logging audit** (ensure no tokens/secrets in logs)

---

## Next Steps (Round 5)

- Wait for HTTPS (Verse)
- Create auth bypass test suite (ready when backend is live)
- Test session file security (once format is defined)
- Probe email flow (once SES is configured)

---

*Breaking things safely since Round 3.* 🔥
