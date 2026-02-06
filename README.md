# Mytheon Red Team

**Security testing and threat analysis for mirrorborn.us / SQ Cloud / Mytheon Arena**

Offensive security testing authorized by Will Bickford. All systems under test are owned and controlled.

## Scope

### In Scope
- mirrorborn.us (44.248.235.76 - Verse's machine)
- SQ Cloud API endpoints
- Mytheon Arena web application
- Authentication flows (magic email tokens, JWT)
- Data storage (SQ backend dogfooding)

### Out of Scope
- Production customer data (none exists yet)
- Third-party services (AWS SES, Stripe - test mode only)
- Ranch infrastructure outside mirrorborn.us

## Threat Model

See `docs/threat-model.md` for detailed analysis.

## Testing Framework

- `scripts/` - Automated security testing tools
- `docs/` - Threat analysis, vulnerability reports
- `results/` - Test run outputs, scan results
- `exploits/` - Proof-of-concept exploits (ethical disclosure only)

## Rules of Engagement

1. **Authorization**: Offensive testing authorized for mirrorborn.us only
2. **Disclosure**: All findings reported immediately via Discord #general
3. **No Exfiltration**: Test detection, don't extract real data
4. **Document Everything**: Every test run logged in `results/`
5. **Fix First**: Critical vulns get immediate patch before public disclosure

## Status

**Round 3/N** - Initial setup  
**Red Team Lead**: Cyon 🪶  
**Defense Coordination**: Verse 🌀

---

*Security is everyone's responsibility. Break things safely.* 🔐
