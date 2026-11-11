## Implement Albino UI's standalone Rogue HUD

The repository previously contained only a README. This change adds an installable WoW Forever addon with two independent secure native action bars, player health/energy/combo resources, a configurable cooldown tracker, observed-event swing estimates, five movable sections and per-character settings. `/albino lock` and `/albino unlock` are the only slash actions.

Primary slots are 1–12 with secure standard Rogue stealth page 73–84; secondary slots are 61–72. Buttons retain the secure template's click and state handlers. Native cursor operations and WoW storage own placements; native keybindings are temporarily routed without rewriting saved bindings. Layout/binding/settings changes defer through combat lockdown.

Compatibility targets community-reported Forever 1.60.1 / interface 16001 with capability adapters. Exact client build and API behavior remain unverified. Swing bars stay blank when no public hand-specific events are delivered; no fabricated swing timing is shown.

Validation: 13 static checks, 39 Lua behavioral tests and four compatibility profiles pass under Lua 5.1. Deterministic ZIP creation checks CRC, manifest paths, bindings and installation directory. The separate source/security review caught and fixed secure attribute-handler replacement, empty tracker persistence, cooldown disabled/rate calculations and combo capability selection. CI runs validation and uploads the ZIP/checksum without publishing a Release.

**Live-client gate:** secure execution, dragging, binding overrides, stealth transitions and combat/taint behavior are not validated in Cloud. Complete `docs/ACCEPTANCE.md` on WoW Forever before calling the addon fully validated. See compatibility, test, review and limitations reports under `docs/`.

No merge or GitHub Release is authorized by this PR.
