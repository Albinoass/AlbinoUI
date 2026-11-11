# Albino UI

A standalone, borderless Rogue HUD for **WoW Forever**, with two functional native action bars. No dependencies, recommendations, automatic casting, or hard-coded button abilities.

**Status:** cloud implementation and mocked API tests complete; **not yet validated in WoW Forever**. Community Forever addons report client **1.60.1 / interface 16001**. The installed client build, secure actions, dragging, keybindings, and combat behavior still require the acceptance test below.

The default stack is cooldown icons → green health → yellow energy → five combo segments → main/off-hand swing estimates → main action row. A second action row sits below it. Each section moves independently. Native spell textures, transparent dark backgrounds, compact spacing, configurable dimensions and scale suit 1080p and 1440p layouts.

## Install

1. Download `AlbinoUI.zip` from the prepared build or the pull request's **Validate and package** workflow artifact. No GitHub Release is required.
2. Close WoW. Back up your `WTF` folder: these bars edit **native action slots**, including slots already used by Blizzard's bars.
3. Extract the ZIP into `World of Warcraft\_forever_\Interface\AddOns\`.
4. Confirm the final path is `World of Warcraft\_forever_\Interface\AddOns\AlbinoUI\AlbinoUI.toc`. Avoid `AlbinoUI\AlbinoUI\AlbinoUI.toc`.
5. Enable **Albino UI** at character selection. If the client flags it out of date, check its build against [the compatibility report](docs/COMPATIBILITY.md) before choosing “Load out of date AddOns”.
6. Log into a Rogue and follow [the acceptance checklist](docs/ACCEPTANCE.md). Start with other action-bar addons disabled.

To install from a source checkout, copy the **inner `AlbinoUI` folder**, not the whole repository, into AddOns.

## Use

The only slash actions are:

- `/albino unlock` — show subtle drag handles for all five independent sections.
- `/albino lock` — hide handles and save positions.

Drag the **handle above** an element to move it. Locking never locks spell placement. Out of combat, drag spells from the spellbook onto any button; drag an assigned ability to another button to move or swap it, or drop it away from the bars to remove it using the game's cursor behavior. Protected layout, binding and visibility changes wait until combat ends. Native spell rearrangement is rejected during combat.

Open **Game Menu → Options → AddOns → Albino UI** (older clients: Interface → AddOns). Set counts (1–12), size, spacing, visibility and mouseover fading independently for both bars; resource dimensions and numbers; combo dimensions and limit; tracked spell IDs and ready visibility; swing dimensions; and UI scale (0.5–2). Click **Apply settings**. Unknown or unlearned tracked spells stay hidden. An empty tracked list disables all tracker icons. Layout and settings are saved per character in `AlbinoUIDB`.

The main bar displays **native slots 1–12**, switching securely to **73–84** on the standard Rogue stealth bonus page. Secondary slots are **61–72**, the standard bottom-left bar. They never overlap. Changing button count hides slots without deleting them. Action placements are saved by WoW, not serialized into addon settings.

Existing **Action Button 1–12** bindings control the main row. Existing **Bottom Left Action Button 1–12** bindings control the secondary row. Alternatively assign the 24 direct buttons under **Key Bindings → Albino UI**. Both native keys per action are supported. Bindings are temporarily routed with override bindings; the addon never rewrites your saved keybinding set. Hidden or truncated bars stop overriding native bindings, so a native binding may still execute its underlying action. Direct `CLICK` bindings belong to the named button and are separate from visibility preferences.

Blizzard's bars are retained; Albino UI does not hide or reparent Blizzard's protected UI. Hide redundant stock bars through supported game settings if desired. Disable competing bar addons when testing. Primary manual page cycling and vehicle/possess/override bars are outside this Rogue HUD's scope; do not rely on these overrides in special vehicle content.

Swing bars are **estimates from observed player swing events**, never a clock started merely by entering combat. Forever community documentation reports no traditional combat-log stream; if so, these bars remain blank. Tooltip details and [limitations](docs/LIMITATIONS.md) explain resets and haste estimates.

## Develop, test and package

Use this checkout directly; a separate repository or worktree is unnecessary. Requires Python 3 and Lua 5.1, with no runtime addon dependencies.

```sh
# Debian/Ubuntu development machine:
sudo apt-get install lua5.1
python3 tools/check.py
python3 tools/package.py
```

For a nonstandard Lua installation, use `LUA=/path/to/lua5.1 python3 tools/check.py`. The test double exercises module loading, persistence, combat deferral, slots, bindings, cursor operations, resources, timers and compatibility profiles. It does not reproduce WoW's native secure executor or taint system. CI runs the same checks and uploads the ZIP and checksum. Packaging is deterministic and validates its archive paths and manifest.

Outputs: `dist/AlbinoUI.zip` and `dist/SHA256SUMS`. Packaging and CI **do not publish a GitHub Release**.

- [Compatibility and research sources](docs/COMPATIBILITY.md)
- [Automated test report](docs/TEST_REPORT.md)
- [In-game acceptance checklist](docs/ACCEPTANCE.md)
- [Known limitations](docs/LIMITATIONS.md)
- [Architecture and review findings](docs/REVIEW.md)
