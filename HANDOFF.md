# AFKraft : WoW Idle Game — development status

Updated 2026-11-04. Accepted gameplay systems are implemented in source. Retail is the development/simulator target; Forever remains the product target. Neither source coverage nor simulator results establish live Forever behavior.

## Current implementation

- One account party, up to five heroes and nine classes; three 18-talent trees per class, natural levels to 60, permanent Mastery and configurable priorities/resources.
- Gold/material equipment economy, ten wearable slots, class-aware power scoring and weapon/armor proficiencies, crafting, enchanting, titanforging and profession plans.
- Permanent Growth investment with exact free refunds; four Commander boosts, reusable cooldowns, automation, ordered rules and profiles.
- Manual chapters and Transcendence, retained capabilities, difficulty tiers, Inheritance and Runic recipes.
- Source-specific outdoor/dungeon collections, independent rolls, durable receipts, one selected set effect and separate session totals.
- Fullscreen/windowed/compact views, progressive menu discovery, onboarding and automatic return reports.
- Optional offline routes limited to departure-cleared current-run/tier checkpoints and 12 transitions per absence.

## Remaining work

### 1. Forever integration and live validation — pending client access

Update the Forever simulator version and test setup together before using it. Confirm build detection and TOC metadata. Package a separate map-art/geometry profile using the [port checklist](MAPS.md#forever-port-checklist); the current geometry targets Retail. Native spell effects are disabled on Forever until assets and visual APIs are verified together. Exact offline alt appearance remains unfinished.

When client testing becomes available, back up the save and record build, action, expected/actual result and errors:

1. Login/reload and switch characters: retain identities, settings and earned progress; initialize and pay rewards once.
2. Real activities: verify participation/loot credit, gray kills, gathering difficulty/success, quests, levels, bosses and confirmed dungeon completion. Leaving an instance must never count as completion.
3. Collections: verify eligible real outdoor and instance kills, including trivial collection kills; reject wrong contexts and duplicate signals. Check discovery without bag/equipment drops, session totals, reload and profile restoration.
4. Both resets: compare preview and actual losses/retention. Owned automation must work at level one without repurchase; cooldowns must remain.
5. Offline catch-up: interrupt/reload, deliver live activity/discoveries during reconciliation, and check the 24-hour cap and cleared-route limits. No duplicate earnings or transitions.
6. Visuals/input: model loading/fallbacks, equipment, attack/death/spell animations, camera framing, text bounds, all window modes and lock/unlock. Check normal WoW combat/input and performance. Reproduce any native HelpTip error before attributing it to the addon.

### 2. Pacing and management effort

Use [BALANCE.md](BALANCE.md) as the source for tuning, fixture assumptions and recorded outcomes. The current target is **45–60 minutes to first prestige access**, replacing the earlier 4–6-hour hypothesis. Check-ins remain a provisional 15–30 minutes; choosing to reset is separate from unlocking it.

- Current-code profile rechecks reach first access in 43–46 minutes. Observe actual new-player pacing before tuning again.
- The 96-case build fixture has 80 wins and 16 timeouts. Its synthetic retained-power budget does not prove acquisition time or broad build parity.
- The current two-hour reset fixture stops at frontiers 50/48/47; none regains the previous frontier of 60. Relic-dust availability still limits modifications under its initial-zone policy. Compare material-aware routes before drawing a global affordability conclusion.
- Earlier 100-hour journeys reached tier eight; one endpoint intervention required 900 paid modifications. Those results predate the class-stat correction and need rerunning before further tuning. Measure actual management effort, not domain-command counts. Tier-nine/ten acquisition remains unproven.
- Measure live hunting rates, travel, source availability and unlucky-streak tails. Independent collection rolls never guarantee a discovery.

### 3. UI and text

Player-facing text uses effects, costs and actions first. Keep exact values in the relevant preview/tooltip; avoid repeating formulas and implementation details in panel help. Preserve destructive-action consequences and reset retention. Broad navigation/layout redesign remains deferred until feature validation.

## Explicitly deferred

Automated resets; simultaneous parties/raids; larger boost loadouts; arbitrary class scripting; broader profession content. Retail collection acquisition remains disabled pending independent source verification. Additional collection content is optional scope, not a substitute for validating the current catalog. Public source labels use monster families grouped by zone; exact creature IDs/names remain internal provenance.

## Verification and resuming

The text/documentation pass reruns domain and isolated Retail simulator tests, formatting, Lua syntax and LuaLS diagnostics. It also rechecks builds, six-hour profiles and actual-reset scenarios; see BALANCE.md for refreshed results. No live Forever validation has been performed. Simulator screenshots verify layout only, not native particles or protected client behavior.

Before editing, inspect Git status and HEAD, preserve unrelated work, and read the affected module's documentation. Use committed scenario scripts. Keep gameplay tuning separate from copy changes, and do not push or release without instruction.
