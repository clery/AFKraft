# Architecture

## Module boundaries

| Directory | Responsibility | May depend on |
| --- | --- | --- |
| `Content.lua` | Stable class, zone, equipment, and talent definitions | Lua only |
| `Content/Items.lua` | Fixed Classic item snapshots, stat labels, class attributes, and curated destination pools | Lua only |
| `Domain/` | State, party rules, inventory transactions, prestige, rewards | Content and Lua |
| `Simulation/` | Deterministic combat and bounded offline catch-up | Domain and content |
| `Compatibility/` | Client APIs, event normalization, map IDs, model IDs | WoW APIs and domain commands |
| `UI/` | Scene composition, widgets, panels, window management | Readable state, domain commands, compatibility adapter |
| `App/` | Initialization, events, update scheduling, SavedVariables | All modules |

The TOC loads embedded libraries before explicitly ordered addon modules. They share the addon's namespace through `local _, W = ...`; `WoWIdle` is the public debugging handle. `W.Game` is the domain command facade. The simulation never creates frames or reads WoW units, wall-clock time, or global random state.

## State and commands

`Game.New(timestamp)` creates plain serializable state. `Game.Load(database, timestamp)` validates the schema version and refuses unsupported saves without discarding them. `WoWIdleDB` is account-wide. AceDB manages account-wide preferences separately in `WoWIdlePreferencesDB.global`; `App/Preferences.lua` imports legacy UI/settings once and binds the state-facing tables to AceDB. Gameplay validation and schema migration remain independent of preference storage. Future schema changes must add explicit migrations before modifying existing saves.

Schema two adds `adventure`: rank, partial XP, lifetime XP, and per-source counts. Migration copies version-one data before changing it, retains existing currency and hero progression, and starts the new bar without retroactive rewards. Quarter-point XP stays exactly representable; validation checks rank and remainder against lifetime XP.

Party, crafting, equipment, training, and prestige commands validate their preconditions before spending resources. Equipment, talents, priorities, and training are available during combat. Live stat refresh preserves the health fraction, shields, and cooldowns. Travel abandons an active encounter without paying its rewards and preserves current health. Commands return a success flag and an optional user-facing explanation. UI selection and geometry are presentation state; combat rules belong in the domain or simulation.

Use internal content IDs in saves. Client numeric map and model identifiers belong in compatibility tables, not hero progression or inventory data. Generated companion appearances use stable appearance keys. Additions to client-specific content must not silently reuse unverified identifiers from another client.

## Simulation and rendering

Combat advances in fixed quarter-second steps with a saved deterministic random seed. The application preserves unprocessed elapsed time and bounds work per frame. Combat emits transient feedback events; the scene consumes them. Encounters track each combatant’s coordinates and current target. Melee units close distance before dealing damage; ranged units hold their formation, and enemy pursuit follows the living front line or its guard. Position updates use the same fixed steps during visible play and offline catch-up. Animation timing cannot change damage or rewards. Feedback buffers and adventure logs are bounded.

Each encounter snapshots its participants. Recruiting during combat adds heroes to the party for the next encounter; victory health and experience updates use the participant snapshot. Prepare all participant results before committing shared rewards. On loading an older save with a completed encounter left unresolved by an error, discard that encounter rather than replaying a partially applied payout.

Offline catch-up snapshots the party and simulates safe farming in batches using the same rules. It never advances boss milestones or destinations. Completion merges earnings into the live state while preserving real-world Essence rewards. An interrupted catch-up preserves its remaining earning time. Identical ordinary drops stack to keep inventory growth manageable.

`Game.ActivityReward` claims a unique receipt and passes the activity's configured XP to `Domain/Adventure.lua`. Real WoW activities never directly grant hero experience or per-event Essence. Completed Adventure ranks pay Essence, with overflow retained. The live account's Adventure progress stays outside the offline merge, preserving XP and payouts received during reconciliation. Rates and rank rewards belong in content; the reproducible pacing model is in `scripts/balance_activity.lua`.

Public unit observation and loot credit are isolated in `Compatibility/Kills.lua`; gathering casts and pre-cast skill-up colors are in `Compatibility/Gathering.lua`. `Compatibility/Dungeons.lua` caches non-gray boss eligibility before death, checks completion signals, and resolves recommended level brackets as a fallback. It handles scaling, legacy-loot exclusion, unsupported events, and duplicate completion signals. These adapters ignore secret values and do not register combat-log events.

Rendering is isolated from combat. `UI/Backdrop.lua` supplies the current screenshot renderer through `Create(parent)` and `SetZone(zoneID)`. `Content/Backdrops.lua` maps stable destination IDs to packaged textures. Credits and crop settings live in `Assets/Backdrops/sources.json`; the asset preparation script rebuilds the textures, descriptor, and credit table from those entries. Cropping preserves the landscape's aspect ratio, with shaded title and health-bar regions for readability.

`Compatibility/SceneryAssets.lua` maps destinations to candidate in-game model IDs. The experimental `UI/Scenery.lua` renderer retains reusable scenery actors and a side-view camera for later development. `UI/Scene.lua` owns party/enemy models and feedback. Verify asset visibility, scale, lighting, and camera placement in the client before enabling model-based scenery again.

`Compatibility/Models.lua` contains companion NPC appearances and per-enemy creature IDs. The client adapter resolves these through `PlayerModel:SetCreature`; bare race display IDs lack the composite textures needed for dressed characters. The active WoW character uses `SetUnit("player")`. Scene model keys include the actual creature, and loading events reapply framing after asynchronous model creation. Visible icons cover unavailable or pending models without overlapping loaded characters.

The scene retains the completed battle through its short transition so defeated models can finish their death animation instead of disappearing. Damage numbers rise and fade in a frame-rate presentation update; simulation and state synchronization retain their bounded update cadence.

## Interface lifecycle

Boost automation stores permanent capability ownership, a global running preference, and one typed mode/health threshold per boost under `boosts.automation`. Existing saves gain disabled defaults. `G.Step` evaluates the equipped boost before advancing combat time, sharing `ActivateBoost` with manual use. Rules inspect living combatants and current boss/farming context, never rendered frames. Rest and completed encounters cannot spend readiness. The same step executes during eligible offline farming; the clock and ledger reconcile together. Ordinary prestige retains capability ownership and configuration. Commander uses a wrapped icon catalog and one selected-boost editor, keeping purchase, loadout and automation controls independent of catalog size. Tooltips hold explanatory text; compact views retain a single activation control. Refresh shows current reasons without executing rules or emitting notices.

Commander boost content lives in `Content/Boosts.lua`; `Domain/Boosts.lua` owns permanent purchases, the single equipped slot, activation validation, and saved effect/cooldown deadlines. All deadlines use `state.clock`, advanced only by simulated adventure time. Combat applies Battle Orders only to basic-attack cooldown progress and Iron Resolve before shield absorption without rewriting combatant stats. Offline reconciliation merges the simulated clock and boost ledger together. Prestige ends effects while preserving ownership, loadout, and cooldown progress. The Commander panel manages purchases and equipment; full/compact Adventure controls share the same activation command and show separate effect/readiness timers.

The shell owns fullscreen, windowed, and compact layouts. Adventure emphasizes the stage; management uses a shallow banner and a larger working area. `UI/PartyPanel.lua` owns recruitment, equipment selection, inventory comparisons, and purchase previews. Training and upgrade quotes come from the same domain cost functions used by the transactions.

`UI/AdventureBar.lua` presents the same account-wide progress in full and compact modes, including rate explanations and rank-payout feedback. Its tooltip distinguishes Adventure XP from hero experience.

Management panels acquire frames and regions from Blizzard object pools because WoW frames cannot be destroyed. Reused buttons clear their previous content, and custom icons and labels are parented to the button so its background cannot cover them. Native gold frame borders, panel buttons, and modern dropdowns supply the shared WoW visual language. Shared widgets constrain single-line labels and use the primary button's existing font string. Capability fallbacks remain inside widgets or compatibility code.

`UI/Atlas.lua` renders both continent maps using native map-art tiles, region highlighting, hover tooltips, and direct click travel. `Compatibility/Maps.lua` selects verified client/artwork profiles and resolves destinations from generated ownership rows; native lookup is the fallback when no matching profile exists. Color masks and hit regions share that partition, with hits restricted to land and reviewed inland water. Padded mask bounds are texture placement, not hit rectangles. Other client IDs are discovered from their own hierarchy. Locked regions remain inspectable. See [the map maintenance and porting guide](MAPS.md) for generation and client/continent integration. Inventory views sort index-bearing entries by effective power without mutating the underlying saved inventory.

AceAddon manages login initialization and disable/re-enable; AceEvent dispatches the explicitly selected public client events. AceConsole registers `/wowidle` and `/wi`. AceTimer samples activities and refreshes the scene at 0.2 seconds, and refreshes the wider interface once per second. The frame update retains only bounded combat/offline work and model state transitions; floating combat text uses native animation groups. AceConfig and AceGUI generate the settings panel from its options table. Disabling cancels timers, unregisters events, hides the window, and stops audio.

Rendering stops when the window is hidden; simulation continues. Locking compact mode leaves an unlock control accessible. Legacy paused saves resume automatically; manual resting is no longer part of gameplay.

## Extending and checking

- Add class and zone definitions through stable content keys; add runtime assets separately.
- Add gameplay commands to the relevant domain module, then cover their transactions and edge cases with pure Lua tests.
- Add client event support only after verifying its payloads, credit rules, and restrictions. Deduplicate overlapping delivery signals.
- Add UI checks for new management views and verify object reuse across redraws.
- Run domain tests, simulator integration tests, formatting checks, and Lua diagnostics before review.
- Keep environment configuration outside the repository. No tool installation, editor profile, or client filesystem location is assumed by game code.
