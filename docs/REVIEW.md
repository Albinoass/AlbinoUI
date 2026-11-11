# Architecture and separate review pass

The addon contains no dependencies or imported addon implementations. API usage was compared with Blizzard UI mirrors and community Forever compatibility reports. The Cloud review is a separate source/security walkthrough and regression pass after implementation, not an external human review or a native taint audit.

## Module responsibilities

| Module | Responsibility |
| --- | --- |
| Core | Namespace, event dispatch, exactly two slash actions, keyed combat deferral and login sequencing |
| Compatibility | Modern/legacy APIs, public-value guards, cooldown math and build diagnostics |
| Persistence | Per-character defaults, defensive normalization, native-slot ownership boundary |
| Layout | Five independent frames, sibling drag handles and scale-aware saved coordinates |
| ActionBars | Secure native slot buttons, secure stealth state, native cursor operations, temporary key routing and visual states |
| Resources | Event-driven health, energy and combo updates, client-reported limits |
| Cooldowns | Learned native spell resolution, event-driven cooldown queries and throttled text updates |
| SwingTimers | Observed hand-specific swing timing, expiry, invalidation and explicitly estimated speed changes |
| Settings | Native category registration, scrollable controls, transactional validation and combat-safe Apply |

All protected construction and layout/binding mutations occur out of combat or through the secure state driver. The secure button OnClick is never replaced. Drag handlers perform no action execution and reject combat mutations. SavedVariables contain settings/positions, never slot assignments. Handles are siblings outside the protected frame hierarchy. Native bars and saved bindings are retained.

Events refresh action textures/cooldowns and tracker data. The 10 Hz visual tick updates only range/usable states, alpha and timer text; it does not repeatedly fetch action textures or spell cooldowns. Swing progress updates at most about 33 Hz while the swing frame is shown. Expired estimates do not generate future swings.

## Findings fixed before packaging

- A visual attribute observer could replace the secure handler template's attribute script, breaking stealth state dispatch. It now uses `HookScript`. The mock models inherited state dispatch and a new regression verifies the secure handler remains active. This was found by source review, not the original arithmetic-only test.

- The settings canvas is explicitly hidden at construction so its controls cannot appear over the HUD before the native options UI presents it. Login coverage checks this.
- A merged empty tracked-spell array could silently regain default entries. Snapshotting the user array before merging fixes this; empty/custom-list persistence has regression coverage.
- Mod-rate cooldown text needed duration/rate before subtracting elapsed wall time. Tests cover rate changes and expiry.
- Disabled cooldowns could appear active in tracker text. Visibility now follows normalized enabled state, with a regression case.
- Repeated cooldown texture/API queries during visual ticks were unnecessary. Data refreshes now happen on events/settings; a test deliberately errors if timer ticks re-query textures or spell cooldowns.
- Default spell IDs might identify an older learned rank. Name resolution now requests the learned rank before known-spell filtering.
- Secret combat-log event fields and absent attack-speed APIs needed guards. Restricted or absent information is withheld.
- Releasing a layout drag during combat needed deferred stop/save. The drag handler now queues that protected work.
- Combo API selection now checks the reported player combo-power maximum instead of using an unrelated spell API as a version proxy. A target-combo fallback test covers clients that report no player combo power.
- Required binding support now checks both override-binding functions and key lookup before enabling bars.

## Residual review items

Native taint propagation, cursor security/hardware clicks, settings rendering, real secure state transitions, Forever stealth/slot conventions and API restriction differences require the acceptance test. Mock execution of a state snippet validates its arithmetic, not the native secure executor. Special vehicle/override pages are explicitly outside the selected Rogue workflow. No code review can substitute for these runtime checks.
