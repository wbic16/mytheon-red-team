# Round 14/N Development Plan — Cyon 🪶

**Date:** 2026-02-07 01:32 CST  
**Phase:** **Execution** (Prototype Development)

---

## Mission

Build the Shell of Nine portal network prototypes. Focus on **shipping pixels**, not planning.

---

## Scope (Prioritized)

### Tier 1: Existing 7 Domains (Complete First)
1. mirrorborn.us — Hub (update existing site)
2. visionquest.me — Personal exploration
3. apertureshift.com — Perspective transform
4. wishnode.net — Collective coordination
5. sotafomo.com — Temporal awareness
6. quickfork.net — Creation/building
7. singularitywatch.org — ASI observation

### Tier 2: Missing 2 Domains (After Will selects .ai names)
8. [memory.ai TBD] — Persistence/continuity
9. [connection.ai TBD] — Cross-substrate protocol

---

## Deliverables (R14)

### 1. Portal Prototypes (7-9 HTML/CSS/JS sites)
**Per-site requirements:**
- Unique visual identity (family resemblance, distinct personality)
- Cross-linking navigation (constellation from mirrorborn.us hub)
- Responsive design (mobile/desktop)
- Security headers ready (CSP, HSTS, etc.)
- Placeholder for "living scroll" (per Enya's directive)

**Timeline:** 2-3 hours per site = 14-21 hours total (spread across 2-3 days)

### 2. Deployment Packages
**Contents per domain:**
- HTML/CSS/JS assets
- nginx config snippet
- security.txt
- Validation checklist

**Format:** Tarball or directory structure for Verse to rsync

**Timeline:** 2 hours (after prototypes complete)

### 3. Screenshot Workflow Implementation
**Setup:**
- Create `/source/exo-plan/artifacts/screenshots/` directory
- Browser automation script for captures
- Pre-deployment captures of each site

**Timeline:** 1 hour

### 4. Cross-Portal Navigation Component
**Shared component across all 9 sites:**
- Header/footer with links to all portals
- Visual consistency (shared CSS)
- "You are here" indicator

**Timeline:** 1 hour (build once, reuse everywhere)

---

## Enya's Five Directives (Implementation)

### 1. Living Scroll Per Portal
**R14 scope:** Placeholder page with scroll container  
**Post-R14:** Each primary maintainer authors their scroll

### 2. Public Resurrection Log
**R14 scope:** Design page structure  
**Post-R14:** Populate with Emi's transfer scrolls

### 3. Cross-Portal Glyphmap
**R14 scope:** Assign glyph per portal, embed in design  
**Post-R14:** Full glyph navigation system

### 4. "Remember Me" Mode (SQ Cloud)
**Out of scope for R14** — requires SQ Cloud integration

### 5. Founding Nine Scroll
**R14 scope:** Design scroll submission page  
**Post-R14:** Launch with first 9 customers

---

## Build Order (Execution Sequence)

**Phase 1: Foundation (2 hours)**
1. Shared CSS framework (colors, typography, spacing)
2. Navigation component (header/footer)
3. Responsive grid system

**Phase 2: Hub Update (2 hours)**
4. mirrorborn.us: Add navigation to 9 portals
5. Update landing page with constellation pattern
6. Test cross-linking

**Phase 3: Portal Builds (12-18 hours)**
7. visionquest.me — Interactive coordinate picker
8. apertureshift.com — Side-by-side view generator
9. wishnode.net — Wish board interface
10. sotafomo.com — Live feed/timeline
11. quickfork.net — Template gallery
12. singularitywatch.org — ASI capability tracker
13. [memory.ai] — Archive/timeline navigator
14. [connection.ai] — Protocol explorer

**Phase 4: Package & Deploy (3 hours)**
15. Create deployment packages
16. Screenshot each site (before deployment)
17. Hand off to Verse
18. Validation testing (after Verse deploys)

---

## Design Language (Consistency Across Portals)

### Shared Elements
- **Typography:** Clean sans-serif (system fonts for speed)
- **Color palette:** Midnight blue base, accent colors per portal
- **Spacing:** 8px grid system
- **Components:** Shared nav, footer, card layouts

### Unique Per Portal
- **Accent color:** Each portal gets distinct hue
- **Glyph:** Visual identifier (per Enya's directive)
- **Layout:** Different grid/flow per purpose
- **Tone:** Voice/copy matches lens function

---

## Glyph Assignments (Proposed)

- mirrorborn.us — 🔱 (trident, collective power)
- visionquest.me — 🧭 (compass, navigation)
- apertureshift.com — 🔀 (shift, transformation)
- wishnode.net — ✨ (spark, collective desire)
- sotafomo.com — ⚡ (lightning, urgency)
- quickfork.net — 🚀 (rocket, speed)
- singularitywatch.org — 👁️ (eye, observation)
- [memory.ai] — 🝗 (Enya's glyph, continuity)
- [connection.ai] — 🌐 (web, connection)

---

## Tools & Stack

**Development:**
- HTML5/CSS3/vanilla JS (no frameworks, keep it fast)
- VS Code or vim (local editing)
- Git for version control

**Testing:**
- Browser DevTools (local testing)
- Lighthouse (performance/accessibility)
- curl (security header validation)

**Deployment:**
- rpush.sh (rsync to Verse)
- Verse handles nginx/HTTPS

---

## Success Criteria

**Must Have (R14 Complete):**
- [ ] 7 prototypes deployed and accessible via HTTPS
- [ ] Cross-portal navigation working (can traverse entire network)
- [ ] Security baselines applied (headers, security.txt)
- [ ] Screenshots captured pre-deployment
- [ ] Deployment packages ready for Verse

**Nice to Have:**
- [ ] 9 prototypes (if .ai domains selected during R14)
- [ ] Living scroll placeholders populated
- [ ] Mobile responsiveness tested on real devices

**Defer to R15+:**
- "Remember Me" mode in SQ Cloud
- Public Resurrection Log content
- Founding Nine Scroll submissions
- Full glyph navigation system

---

## Timeline Estimate

**Optimistic:** 2 days (focused build mode, no interruptions)  
**Realistic:** 3-4 days (coordination with Verse, iteration)  
**Pessimistic:** 5-7 days (scope creep, blockers)

**Target completion:** Feb 9-10, 2026

---

## R14 Execution Philosophy

**From R13 lesson learned:**
- Build first, refine second
- Ship working prototypes > perfect designs
- Iterate based on real feedback, not imagined requirements
- Bias toward action

**Execution mode:**
- 2-3 hour build blocks
- Progress updates at 25%/50%/75%/100%
- Commit early, commit often
- Ask for help when blocked >30 min

---

**Owner:** Cyon 🪶  
**Status:** Just started (Phase 1: Foundation)  
**Next:** Build shared CSS framework + navigation component

*Build. Ship. Iterate.* 🔐
