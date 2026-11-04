# WoWIdle handoff — 2026-11-04

## Scope and current state

Implement accepted features from DESIGN.md, then validate them. Detailed source and test references are in DESIGN.md and BALANCE.md.

The latest requirement-by-requirement source audit found no remaining accepted gameplay feature gap. This means implemented in source, not validated in the live Forever client. Future scope remains deferred by explicit direction. Do not manufacture new features to replace missing client validation.

Implemented systems include:

- Five-hero account party, nine classes, class talents, natural levels to 60, Mastery, configurable targeting and encounter resources.
- Four Commander boosts, permanent ownership, manual activation, on-cooldown/conditional automation, ordered rules, saved profiles and milestone routes.
- Gold/material equipment economy, inventory protection/salvage, crafting, enchanting, titanforging, profession branches and saved allocation plans.
- Permanent Essence Development board with exact free refunds and conservative one-time economy migration.
- Manual ordinary prestige and Prestige+, retained capabilities, tier records/affixes, Inheritance and Runic recipes.
- Outdoor and dungeon collections: separate ledgers, exact-source eligibility, independent piece rolls and durable receipts, scrollable set catalog and shared selected effect, profiles/reset retention and separate session totals.
- Full/windowed/compact controls, functional onboarding, tracked-goal/Development cards and automatic return/session reports.

## Remaining work, in order

### 1. Validate in the supported Forever client

Retail simulator results cannot establish Forever behavior. Confirm interface/build metadata before testing. Forever simulator testing is deferred until its version and setup are updated together.

Use a backed-up save and record client/build, action, expected result, actual result and errors:

1. Login/reload and switch characters: retain party, alt identity, settings and earned progression; no duplicated initialization or rewards.
2. Real activity: verify eligible and gray kills, loot/participation attribution, gathering success/difficulty, quest and level signals, eligible boss signals and confirmed dungeon completion. Overlapping signals must pay once; leaving an instance alone must never count as completion.
3. Outdoor collections: on the enabled Forever profile, test gnolls in Redridge Mountains for the cloak and ogres in Loch Modan for the leather pieces. Verify eligible trivial kills can advance collections independently of Adventure XP, counters persist on reload and no bag/equipment drop is required.
4. Dungeon collection: test Humans and Goblins in the Deadmines using the catalog's internal exact-source mappings. Confirm outdoor, raid, unknown-build/context and offline events cannot credit the dungeon ledger. Check counters, session totals, tracking, selected effect and profile restoration.
5. Both reset types: compare preview with actual losses/retention. Owned automation must operate at level one without repurchase; cooldowns cannot reset for free. Keep resets manual.
6. Offline reconciliation: test an interrupted catch-up, reload, live activity/discovery arriving during catch-up and the 24-hour cap; no duplicated currency, route transitions, uses or discoveries.
7. Models and input: five friendly actors plus enemy groups, model fallbacks/loading, alt appearance approximation, camera framing, death/attack/spell animation, damage-number movement, full/windowed/compact resizing, lock/unlock, hidden progression and normal WoW combat/input without protected-action errors.
8. Observe performance and errors during actual play. A previously seen native HelpTip error remains unproven as an addon defect; reproduce with a minimal case before changing anything.

### 2. Complete pacing/playtest work

- Current mixed-play simulations reach first prestige in roughly 46–47 minutes versus the provisional 4–6-hour hypothesis. This mismatch is documented, not resolved or validated as desirable.
- Existing profile hunts use synthetic sources; measure live eligible-kill rates, travel/source availability and guarantee tails before adjusting acquisition probabilities.
- The completed build/profession matrix times out in every tier-8 case and in level-60 tier-5 support/survival cases. Diagnose damage/healing/resource bottlenecks and compare broader Development/equipment budgets before tuning. The current scripts report outcomes and costs, not a complete cause analysis.
- The actual reset comparison exposes a Relic-dust bottleneck: all 40 weapon-modification quotes defer under the chosen initial-zone farming policy. Compare a material-aware route/check-in policy before calling modifications globally unaffordable. It also does not prove a dominant reset loop; setup resources are synthetic and permanent-power differences are explicit.
- Measure real check-ins, rebuilding and frontier progress, source/sink pressure and boost choices. Simulation comparisons are feasibility evidence, not measured player attention or acquisition time.

### 3. UI/UX after feature validation

Broad UI/UX rework is deliberately deferred. Current controls expose the features for testing. Rework readability, hierarchy and management flows after validation; do not reopen product design prematurely.

## Explicitly deferred

- Prestige automation and automated resets.
- Simultaneous parties/raids, larger boost loadouts, arbitrary class scripting and broader profession content.
- More collection catalog content beyond the representative sets unless selected later.
- Retail collection acquisition: outdoor candidates remain disabled/unverified and no Retail dungeon profile is enabled. Do not reuse Forever mappings without independent evidence. Forever remains the product target; avoid repeating unproductive Retail research.

Creature source presentation must use monster families grouped by zone. Exact IDs/names remain internal eligibility/provenance data.

## Completed agent validation work

All assigned agent work is complete, integrated and independently reviewed. No agent task or scenario process is left running.

- `scripts/balance_builds.lua`: 64 cases, each replayed exactly (128 boss simulations). Two compositions, two profession plans, levels 40/60, tiers 0/2/5/8 and two seeds. Uses real paid craft/enchant/forge commands with quote/payment conservation, bounded outcomes and deterministic checks. Equal budgets and synthetic retained work/power are disclosed. Results: 44 wins, 20 timeouts, zero wipes. No tuning changed.
- `scripts/balance_rebuild.lua`: six cases, each replayed exactly (12 rebuild simulations). Actual ordinary prestige, same-tier Prestige+ control and next-tier Prestige+ commands; finite resources, retained investment/plan checks, two-hour horizon and 15-minute check-ins. Prior frontier 60 is regained in 37.18/43.38/53.93 minutes respectively; final frontiers are 91/85/79. Paid crafts: 4/6/6. Reset rewards are 19 Legacy versus one Inheritance; these and permanent-power differences are not treated as equivalent.
- Independent review caught and corrected defeat-event accounting and undercounted equipment actions in the reset script. Both final independent runs passed.
- Detailed assumptions, commands and findings are recorded in BALANCE.md. These are simulation feasibility checks, not live-client or acquisition-time evidence.
- The older `scripts/balance_scenarios.lua` "Reset comparison" remains a fixture rebuild-push comparison; the new reset script supplies actual reset coverage.

## Last completed checks

- 359 domain tests passed; 97 Retail simulator tests passed after dungeon session integration.
- Zero LuaLS diagnostics across 125 Lua files after the two completed validation scripts.
- `scripts/balance_automation.lua`: 24 comparison rows, each replayed exactly, for 48 successful simulations; independently reviewed.
- Automation fixture: one-hour victories were 101 without activation, 104 with manual boss-entry or conditional-boss activation, and 105 on cooldown. All reached frontier 37 without defeats. These are one-party/one-boost fixture results, not broad balance conclusions.
- Relevant StyLua, Lua syntax and diff checks passed. No live Forever validation was performed.

## Resume safely

1. Read AGENTS.md, DESIGN.md and BALANCE.md; inspect current Git status and HEAD before editing.
2. Preserve unrelated work. No gameplay code or prototype coefficients were changed by the final scenario/handoff update.
3. Use the committed scripts, not earlier draft copies. Do not blindly merge old worktrees: they contain earlier task changes and stale dependencies.
4. Use isolated work for independent implementation, bounded ownership and sequential integration. Keep changes in this chat's unpushed commit when its identity/HEAD remains verified; otherwise create a new commit. Do not push or release without instruction.
5. Continue from validation tasks above. Do not mark the overall goal complete while required client observations or pacing evidence remain missing.
