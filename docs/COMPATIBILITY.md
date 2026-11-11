# Compatibility findings

Research date: 11 November 2026. No WoW executable or client data files are available in Codex Cloud. The exact client build **has not been independently verified**. This is a capability-based implementation, not a declaration that every modern Retail API works on Forever.

## Evidence and sources

Two independent community Forever projects use `## Interface: 16001`. Roleplaying Helper explicitly describes Forever **1.60.1**, modern API ancestry and the absence of the traditional combat-log event stream. These are community reports, not measurements of the user's client:

1. [Roleplaying Helper README](https://github.com/XalZul/RoleplayingHelper-WoWForever/blob/33e9bde73d535392d3efc74126654b35129abbb3/README.md) and [manifest](https://github.com/XalZul/RoleplayingHelper-WoWForever/blob/33e9bde73d535392d3efc74126654b35129abbb3/RoleplayingHelper.toc).
2. [OpenMap manifest](https://github.com/fitzforge/wowforever-openmap/blob/849bac460b6ebcb110ef80fc27a6b08565069c74/OpenMap/OpenMap.toc). This repository describes itself as an unofficial mirror, so it is corroboration, not an authoritative client specification.
3. Blizzard UI source mirror, Classic beta family, inspected at `4d9399a664eb65f2c8d5e96d7a6bf5e234414239`:
   - [SecureTemplates_Shared.lua](https://github.com/Gethe/wow-ui-source/blob/4d9399a664eb65f2c8d5e96d7a6bf5e234414239/Interface/AddOns/Blizzard_FrameXML/Classic/SecureTemplates_Shared.lua): secure `type=action`, `ActionButton_CalculateAction`, modifier handling and native `UseAction` invocation.
   - [ActionButton.lua](https://github.com/Gethe/wow-ui-source/blob/4d9399a664eb65f2c8d5e96d7a6bf5e234414239/Interface/AddOns/Blizzard_ActionBar/Classic/ActionButton.lua): ID zero selects the explicit `action` attribute; tuple-form action cooldowns; `AnyUp` registration.
   - [Spell API documentation](https://github.com/Gethe/wow-ui-source/blob/4d9399a664eb65f2c8d5e96d7a6bf5e234414239/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua): namespaced spell information and cooldown access.
4. [Historical 3.3.5 Blizzard UI mirror](https://github.com/tekkub/wow-ui-source/tree/3.3.5/FrameXML), inspected for legacy fallback behavior: SecureTemplates, ActionButton, Bindings and MultiActionBars. This is **not evidence that Forever is a Wrath client**.
5. [Lua upstream 5.1.1 source](https://github.com/lua/lua/tree/98194db4295726069137d13b8d24fca8cbf892b6), built locally without changing the addon repository's dependencies or disabling verification.

The guessed official domains `wowforever.com` and `www.wowforever.com` could not be queried: Cloud's destination policy returned CONNECT 403. Their ownership/content was not established. No assertion in this report relies on those sites. GitHub source pages and raw source access succeeded.

## API decisions

| Area | Implementation | Confidence / required client check |
| --- | --- | --- |
| Version / TOC | `16001`, based on the two community manifests | Reported 1.60.1; exact build unknown. Settings panel displays runtime `GetBuildInfo()` and `_VERSION`. |
| Lua | Lua 5.1 syntax, no `goto`, bit operators, `table.unpack`, Retail-only mixins or dependencies | WoW uses a modified Lua runtime; actual Forever `_VERSION` still requires observation. Cloud checks use upstream 5.1.1. |
| Secure actions | `SecureActionButtonTemplate` plus `SecureHandlerStateTemplate`, `type=action`, ID zero, explicit native slot | Supported by inspected Classic-family source. Real clicks, protected attributes and taint must be tested on Forever. No insecure casting wrapper. |
| Native slots | Primary 1–12, standard Rogue stealth page 73–84 via `[bonusbar:1] 7; 1`; secondary 61–72 | Standard Blizzard convention; client/server overrides, stealth and learned higher ranks require live checks. No arbitrary primary paging. |
| Bindings | Existing ACTIONBUTTON and MULTIACTIONBAR1BUTTON keys use temporary `SetOverrideBindingClick`; 24 optional direct CLICK definitions | Applied out of combat. Both keys returned by `GetBindingKey` are routed. No SetBinding/SaveBindings calls. |
| Dragging | Out-of-combat `PickupAction` / `PlaceAction`, native cursor semantics | Live testing required for spellbook → button, swap, replacement and drag-off removal. Native placements persist through WoW. |
| Health | `UnitHealth` / `UnitHealthMax` | Player units only. Secret values are not inspected or used in arithmetic; unavailable values produce an empty bar/optional `?`, not guessed health. |
| Energy | `UnitPower` / `UnitPowerMax`, energy enum or numeric 3; frequent unit power events | No assumption about 100 maximum or energy tick rate. |
| Combo points | Player combo power (enum or numeric 4) when the client reports a positive combo-power maximum; `GetComboPoints(player,target)` fallback otherwise | Target-change events refresh both paths. Five defaults; automatic limit from player max power, capped at ten drawable segments; target-specific Forever semantics require testing. |
| Cooldowns | Modern C_Spell record API when available, legacy spell tuple fallback; native action tuple API, optional namespaced action adapter | Guard secret numbers before math; normalize boolean or 0/1 enabled flags. GCD-only values ≤1.5s are omitted from tracker, not functional bars. No inferred cooldowns. |
| Swing timing | `UnitAttackSpeed` plus public player SWING_DAMAGE/SWING_MISSED events, if delivered; only distinguish hands with an explicit boolean flag | Forever community reports the log stream is absent. Registration alone does not prove delivery. Blank is the expected fallback. |
| Reset / haste | Equipment, death, world transition, combat exit and successful player casts invalidate estimates; speed-change events preserve fractional progress | Fractional haste adjustment is an estimate. Hidden parry haste, server-specific resets and missing off-hand flags cannot be inferred. No fabricated repeating swings. |
| Lockdown | Keyed deferred out-of-combat operations for layouts, buttons, visibility and bindings; secure stealth state driver handles page changes | Mock tests reject protected geometry mutations in combat. Only the real engine can establish taint safety. |
| Settings | Modern canvas category registration or legacy InterfaceOptions category | No Retail Settings mixin dependency; actual panel registration/scrolling still needs a live check. |

If required secure/native functions are absent, action bars are disabled with a chat message; the resources/settings modules still load. Unsupported event registration is guarded. If numerical information is secret, its derived display is withheld rather than bypassing restrictions. The addon neither unlocks protected APIs nor intercepts packet/combat data.

Default tracked spell IDs are Classic Rogue candidates: Kick `1766`, Stealth `1784`, Evasion `5277`, Sprint `2983`, Vanish `1856`. Names/icons and learned ranks are resolved by the running client, never painted as permanent placeholder icons. Unlearned or missing spells are hidden; users can replace every ID. Forever-specific spell replacements remain a live validation item.
