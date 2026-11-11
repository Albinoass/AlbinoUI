# Automated test report

Run date: 11 November 2026. Environment: Codex Cloud Linux, Python 3, upstream Lua **5.1.1** built at `98194db4295726069137d13b8d24fca8cbf892b6`. No WoW client was installed or run.

## Commands and outcomes

```sh
LUA=/workspace/albino-tools/lua51/lua python3 tools/check.py
python3 tools/package.py
```

- **13 static checks passed:** manifest order, interface, SavedVariables declaration, file existence, duplicate detection, Lua syntax for all shipping/test files, 24 binding definitions, no binding execution bodies, single slash root, no insecure action execution/persistent binding rewrites, secure OnClick/attribute-handler preservation and storage separation.
- **39 behavioral tests passed:** initialization/idempotence, secure template/slot configuration, both native binding keys, disjoint normal/stealth/secondary slots, state snippet arithmetic, spellbook drop, replacement, move/swap/removal cursor calls, dragging while locked, combat rejection, deferred count/size/bindings/lock, five independently saved positions, scale coordinates, health/energy/combos, target changes, client maxima, secret data, cooldown rates/expiry/disabled state, tracker visibility/native icons/GCD filtering, usable/range states, observed swing expiry, modern log hand selection, ignored/missing events, speed changes, reset invalidation, fading, corrupt/empty/custom SavedVariables, transactional settings validation/persistence, legacy spell fallback, event-driven query behavior stealth-slot dragging and inherited secure state-handler preservation and target-combo fallback without player combo power.
- **4 separate compatibility profiles passed:** legacy spell/settings APIs, unsupported secure APIs plus absent combat-log event, login during combat followed by deferred initialization, and namespaced action API fallback.
- **Package validation passed:** CRC, top-level `AlbinoUI/`, complete TOC references, Bindings.xml inclusion, no repository/tests inside the addon and deterministic rebuild. `dist/SHA256SUMS` contains the actual archive checksum.
- `git diff --check`: passed before commit.

**Failures:** none in the completed automated suites. **Skipped tests:** none in these suites. **Live-client tests:** all unrun, not counted as passes. Native swing-event delivery is unavailable for Cloud validation.

The harness models protected geometry mutation errors and native cursor storage operations. It cannot verify the actual client's secure execution, taint, binding registration, cursor placement semantics, spell rank resolution, rendered layout or event availability. A passing mock of a secure snippet is not proof of combat-safe native execution.

The validation script exits nonzero on any failed assertion or Lua test, preserving subprocess failure status. CI runs the same scripts; a remote CI run is not claimed until GitHub reports it. See [ACCEPTANCE.md](ACCEPTANCE.md) for the pending real-client gate and [REVIEW.md](REVIEW.md) for review fixes.
