# Architecture

## Module boundaries

| Directory | Responsibility | May depend on |
| --- | --- | --- |
| `Content.lua` | Stable class, zone, equipment, and talent definitions | Lua only |
| `Content/Encounters.lua` | Additional regional creatures, families, and frontier unlocks through level 60 | Content and Lua |
| `Content/Items.lua` | Fixed Classic item snapshots, stat labels, class attributes, and curated destination pools | Lua only |
| `Content/Boosts.lua`, `Content/Collections.lua`, `Content/Professions.lua` | Boost catalog/unlocks, curated collection catalog and drop tuning, profession/enchantment definitions | Content and Lua |
| `Domain/` | State, party/inventory transactions, boosts/rules/profiles, routes, collections, professions, difficulty/reset rules and rewards | Content and Lua |
| `Simulation/` | Deterministic combat and bounded offline catch-up | Domain and content |
| `Compatibility/` | Client APIs, event normalization, map IDs, model IDs | WoW APIs and domain commands |
| `UI/` | Scene composition, widgets, panels, window management | Readable state, domain commands, compatibility adapter |
| `App/` | Initialization, events, update scheduling, SavedVariables | All modules |

The TOC loads embedded libraries before explicitly ordered addon modules. They share the addon's namespace through `local _, W = ...`; `WoWIdle` is the public debugging handle. `W.Game` is the domain command facade. The simulation never creates frames or reads WoW units, wall-clock time, or global random state.

## State and commands

`Game.New(timestamp)` creates plain serializable state. `Game.Load(database, timestamp)` validates the schema version and refuses unsupported saves without discarding them. `WoWIdleDB` is account-wide. AceDB manages account-wide preferences separately in `WoWIdlePreferencesDB.global`; `App/Preferences.lua` imports legacy UI/settings once and binds the state-facing tables to AceDB. Gameplay validation and schema migration remain independent of preference storage. Future schema changes must add explicit migrations before modifying existing saves.

Schema two adds `adventure`: rank, partial XP, lifetime XP, and per-source counts. Migration copies version-one data before changing it, retains existing currency and hero progression, and starts the new bar without retroactive rewards. Quarter-point XP stays exactly representable; validation checks rank and remainder against lifetime XP.

Party, crafting, equipment, Development and prestige commands validate their preconditions before spending resources. Equipment, talents, priorities and Development changes are available during combat. Live stat refresh preserves the health fraction, shields, and cooldowns. Travel abandons an active encounter without paying its rewards and preserves current health. Commands return a success flag and an optional user-facing explanation. UI selection and geometry are presentation state; combat rules belong in the domain or simulation.

New ledgers are additive schema-two defaults with nested validation: `boosts` holds ownership, equipment, deadlines and automation; `boostProfiles` stores named configuration snapshots; `routes` separates persistent templates from its run cursor; `collectionBook` stores archived tier records and receipts; `outdoorCollections`/`dungeonCollections` hold discovered pieces, kill receipts, counters and the mutually exclusive selected set effect; `professions` separates ownership/saved allocations from cycle work ranks/XP; `tier`/`difficulty` hold current challenge, permanent records and Inheritance. `materialRemainders` retains fractional collection/difficulty yields until a whole material is earned. A future collection receipt watermark is rejected rather than silently blocking rewards.

`prestigeStrength` separates permanent party power from the number of rewarded chapters. Missing older values migrate from `prestiges`, preserving prior stats. A rewarded ordinary prestige adds half its Legacy reward to this ledger; the existing 4%-per-strength stat multiplier therefore adds 2 percentage points per Legacy earned. Empty and deeper resets add no ordinary-prestige strength.

`Domain/Prestige.lua` centralizes run rebuilding in `ResetAdventure`. Ordinary prestige retains profession work; Prestige+ also clears its ranks/XP. Both retain permanent abilities, rules/profiles, route templates/preferences, collection discoveries, Mastery, Adventure progress and heirloom modifications. Active boost effects end while cooldown deadlines remain. Routes restart with a fresh run cursor. `Domain/Difficulty.lua` owns current-cycle level-60 completion, explicit deeper-reset previews, tier selection, one-time tier Inheritance rewards and bounded permanent purchases. Difficulty never changes real WoW Adventure XP. `Domain/Mastery.lua` migrates the old frontier into tier zero and maintains independent frontiers per tier without removing earned talent points.

Use internal content IDs in saves. Client numeric map and model identifiers belong in compatibility tables, not hero progression or inventory data. Generated companion appearances use stable appearance keys. Additions to client-specific content must not silently reuse unverified identifiers from another client.

## Simulation and rendering

Combat advances in fixed quarter-second steps with a saved deterministic random seed. The application preserves unprocessed elapsed time and bounds work per frame. Combat emits transient feedback events; the scene consumes them. Encounters track each combatant’s coordinates and current target. Melee units close distance before dealing damage; ranged units hold their formation, and enemy pursuit follows the living front line or its guard. Position updates use the same fixed steps during visible play and offline catch-up. Animation timing cannot change damage or rewards. Feedback buffers and adventure logs are bounded.

Each encounter snapshots its participants. Recruiting during combat adds heroes to the party for the next encounter; victory health and experience updates use the participant snapshot. Prepare all participant results before committing shared rewards. On loading an older save with a completed encounter left unresolved by an error, discard that encounter rather than replaying a partially applied payout.

Offline catch-up snapshots the party and simulates safe farming in batches using the same combat, boost/rule, collection and difficulty reward rules. It never unlocks first-time boss milestones, completes a new Prestige+ cycle, or resets an adventure. Opt-in offline routes visit only checkpoints cleared in the current run and tier before departure, with at most 12 transitions per absence. Completion merges earnings, simulation clock, boost ledger, collection book, fractional materials, difficulty records and the global encounter serial while preserving live real-world Adventure progress/Essence. Keeping the encounter serial and collection watermark together prevents later online receipts from being discarded or replayed. An interrupted catch-up preserves remaining earning time. Identical ordinary drops stack to keep inventory growth manageable.

`lastOfflineSummary` records processed/remaining time, interruption status, retained hero XP/levels, ordinary earnings/material deltas, kept equipment units, salvage, Mastery XP/ranks, automatic boost uses, route transitions and final route status. Legacy collection-total fields remain readable in older reports; current offline battles award no discoveries. `UI/OfflinePanel.lua` presents these totals from the Adventure return-report button without a manual claim; older reports show missing totals explicitly. A finished catch-up job cannot be applied or advanced again.

`UI/Tutorial.lua` introduces available Commander, automation, profile, route, collection, Mastery, profession and Prestige+ capabilities through native HelpTips. Starter actions take priority; unavailable or already-used layers are skipped. Per-lesson acknowledgements live in `guide` and survive both resets. Menu names and icons stay hidden until their system is discovered; discovery persists across resets. Global dismissal and the client's hidden-HelpTips preference are respected; Adventure offers a guide toggle when a lesson is pending.

`Game.ActivityReward` claims a unique receipt and passes the activity's configured XP to `Domain/Adventure.lua`. Real WoW activities never directly grant hero experience or per-event Essence. Completed Adventure ranks pay Essence, with overflow retained. The live account's Adventure progress stays outside the offline merge, preserving XP and payouts received during reconciliation. Rates and rank rewards belong in content; the reproducible pacing model is in `scripts/balance_activity.lua`.

Public unit observation and loot credit are isolated in `Compatibility/Kills.lua`; gathering casts and pre-cast skill-up colors are in `Compatibility/Gathering.lua`. `Compatibility/Dungeons.lua` caches non-gray boss eligibility before death, checks completion signals, and resolves recommended level brackets as a fallback. It handles scaling, legacy-loot exclusion, unsupported events, and duplicate completion signals. These adapters ignore secret values and do not register combat-log events.

Rendering is isolated from combat. `UI/Backdrop.lua` supplies the current screenshot renderer through `Create(parent)` and `SetZone(zoneID)`. `Content/Backdrops.lua` maps stable destination IDs to packaged textures. Credits and crop settings live in `Assets/Backdrops/sources.json`; the asset preparation script rebuilds the textures, descriptor, and credit table from those entries. Cropping preserves the landscape's aspect ratio, with shaded title and health-bar regions for readability.

`Compatibility/SceneryAssets.lua` maps destinations to candidate in-game model IDs. The experimental `UI/Scenery.lua` renderer retains reusable scenery actors and a side-view camera for later development. `UI/Scene.lua` owns party/enemy models and feedback. Verify asset visibility, scale, lighting, and camera placement in the client before enabling model-based scenery again.

`Compatibility/Models.lua` contains companion NPC appearances and per-enemy creature IDs. The client adapter resolves these through `PlayerModel:SetCreature`; bare race display IDs lack the composite textures needed for dressed characters. The active WoW character uses `SetUnit("player")`. Scene model keys include the actual creature, and loading events reapply framing after asynchronous model creation. Visible icons cover unavailable or pending models without overlapping loaded characters.

The scene retains the completed battle through its short transition so defeated models can finish their death animation instead of disappearing. Damage numbers rise and fade in a frame-rate presentation update; simulation and state synchronization retain their bounded update cadence.

## Interface lifecycle

Boost automation stores permanent capability ownership, a global running preference, and per-boost enable/preset/health configuration under `boosts.automation`. Optional `rules` are dense lists of at most four `{condition, threshold?, action="activate"}` entries. `Domain/BoostRules.lua` validates typed conditions and evaluates them in saved order against living combatants/current run state; first match wins. Nonempty lists take precedence over the preset, while empty/missing lists preserve it. `G.Step` evaluates the equipped boost before advancing combat time, sharing `ActivateBoost` with manual use. Rest and completed encounters cannot spend readiness. The same step executes during eligible offline farming; the clock and ledger reconcile together. Existing saves gain disabled defaults, and both resets retain capabilities/configuration.

Commander boost content lives in `Content/Boosts.lua`; `Domain/Boosts.lua` owns the shared Essence/Legacy ownership flag, single equipped slot, activation validation, and effect/cooldown deadlines. All deadlines use `state.clock`, advanced only by simulated adventure time. Combat applies Battle Orders to basic-attack cooldown recovery, Iron Resolve before shield absorption without weakening stronger defenses, Focused Assault to party damage including ongoing effects, and Restorative Focus to healing-spell output without reviving heroes. Applying/expiring boosts does not rewrite health or reset action progress. Full/compact Adventure controls share activation and show separate effect/readiness timers.

Commander uses a wrapped icon catalog and one selected-boost editor. `UI/BoostRulePanel.lua` keeps rule changes in a draft until explicitly saved; the editor starts collapsed. `Domain/Profiles.lua` and `UI/ProfilePanel.lua` support eight named snapshots of loadout, automation/rules, route preferences and selected collection effect. Application validates stale references and entitlements before changing configuration, preserves boost timers/effects, and resets the route cursor only when changing its selected template. UI refresh displays waiting reasons without executing rules.

`Domain/Routes.lua` owns permanent route planning, eight bounded templates, stable step IDs and run completion markers. The editor in `UI/RoutePanel.lua` previews boss, current-hero-level, destination-unlock, material-stock and collection-discovery milestones before saving. `RouteBoundary` runs after resolved victory/defeat rewards and processes at most one transition per encounter; boost evaluation for the next encounter happens afterward. Unavailable destinations retain the step and fall back to safe farming, while an unfinished current-zone boss milestone can continue advancing. Immediate manual travel pauses execution until Resume. Offline execution defaults off; an opted-in snapshot freezes departure-cleared checkpoints and retains the same boundary rules with a 12-transition cap. Material-stock and collection-discovery milestones observe current state without spending materials or performing hunts. Profiles reference template IDs rather than copying or executing a route.

`Domain/Collections.lua` awards outdoor and dungeon discoveries through `CollectionKill`, using attributed real kills and client/build-specific source profiles. Separate ledgers store discovered identities, counters and bounded kill receipts; dungeon eligibility also requires the matching instance context. Each missing piece rolls independently, without failed-roll progress or a guarantee. Idle/offline victories, crafting and bag contents never award discoveries. The retired `collectionBook` preserves legacy tier records and their earned benefit floor; it no longer acquires pieces. Passive discovery bonuses and one selected completed-set effect feed pure combat/material queries. Profiles retain the selected effect; targeting a piece never changes its chance.

`Content/Collections.lua` defines provisional Legacy collection talents, rank costs and relative bonuses. `Domain/Collections.lua` validates `state.collectionTalents`, owns atomic Legacy purchases, and computes the effective per-kill chance shared by acquisition and source tooltips. Rolls use basis points so fractional-percent bonuses work. Missing ranks default to zero on load; both resets retain learned ranks. Outdoor and dungeon conditions use the verified profile's acquisition kind, without adding client API queries. They affect collection discoveries only and do not change source eligibility or duplicate-kill handling. The Legacy panel owns purchase controls; the collection panel previews effective odds and active/inactive conditions.

`Domain/Professions.lua` shares quote and payment validation for enchantments/forge tiers, awards work progression only after successful paid commands, and derives active specialization ranks from saved allocations/current work requirements. `UI/ProfessionPanel.lua` presents previews and independent profession points. Item enhancement, enchantment and titanforge potential remain distinct tracks. Ordinary items lose modifications when reset; heirlooms retain their investments and scale with hero level. Craft/salvage recovery is bounded below paid costs. Loot class/slot/stat keep policies are separate from inventory display filters; role-labeled hero presets configure existing priority fields without changing commander rules.

The shell owns fullscreen, windowed, and compact layouts. A labeled navigation rail groups Journey, Company, Strategy and Progression features. Adventure emphasizes the stage and derives a next action from existing onboarding and progression opportunities. Management hides the stage and uses the full workspace; hero-specific pages retain a company selector. Inventory derives its page size from the workspace height, and talent trees scroll independently above combat priorities. Forge shares one local navigation row for crafting and the profession views while preserving the existing saved tab IDs and commands. Pooled help buttons and control tooltips hold longer explanations; the panels retain headings, actionable states, costs and reset reviews. `UI/PartyPanel.lua` owns recruitment, equipment selection, inventory comparisons, and purchase previews. Equipment quotes come from the same domain cost functions used by the transactions. Hero growth is natural to 60; Party opens the permanent Development board instead of a training purchase.

`UI/AdventureBar.lua` presents the same account-wide progress in full and compact modes, including rate explanations and rank-payout feedback. Its tooltip distinguishes Adventure XP from hero experience.

Shared controls in `UI/Widgets.lua` follow the same roles across panels:

| Purpose | Component |
| --- | --- |
| Perform a command | `Button`: native panel button; gold for the main commit action |
| Switch peer views | `Tab`: native top tabs, as used by Forge |
| Select a row, card, or small set of choices | `SelectButton` with `Selected` for one shared selection treatment |
| Enable a preference or protect an item | Native `Checkbox` |
| Choose from a longer list | `Choice`: native radio dropdown |
| Display a report or affix without an action | `Card`: a passive frame with optional tooltip |
| Explain a system | `Help`: one native information icon and paragraph-spaced tooltip |
| Enter a route or profile name | `Input`: native edit box with shared focus and sizing behavior |
| Show health, XP, or progress | `Bar`: native status bar; combat nameplates retain client styling |

Keep models, maps, talent nodes, and AceConfig settings specialized. Shared widgets own template fallbacks, pooled state reset, and tooltip lifecycle; panels own the commands and selected values.

Management panels acquire frames and regions from Blizzard object pools because WoW frames cannot be destroyed. Reused buttons clear their previous content, and custom icons and labels are parented to the button so its background cannot cover them. Native gold frame borders, panel buttons, and modern dropdowns supply the shared WoW visual language. Shared widgets constrain single-line labels and use the primary button's existing font string. Capability fallbacks remain inside widgets or compatibility code.

`UI/Atlas.lua` renders both continent maps using native map-art tiles, region highlighting, hover tooltips, and direct click travel. `Compatibility/Maps.lua` selects verified client/artwork profiles and resolves destinations from generated ownership rows; native lookup is the fallback when no matching profile exists. Color masks and hit regions share that partition, with hits restricted to land and reviewed inland water. Padded mask bounds are texture placement, not hit rectangles. Other client IDs are discovered from their own hierarchy. Locked regions remain inspectable. See [the map maintenance and porting guide](MAPS.md) for generation and client/continent integration. Inventory views sort index-bearing entries by effective power without mutating the underlying saved inventory.

AceAddon manages login initialization and disable/re-enable; AceEvent dispatches the explicitly selected public client events. AceConsole registers `/afkcraft`, `/wowidle` and `/wi`. AceTimer samples activities and refreshes the scene at 0.2 seconds, and refreshes the wider interface once per second. The frame update retains only bounded combat/offline work and model state transitions; floating combat text uses native animation groups. AceConfig and AceGUI generate the settings panel from its options table. Disabling cancels timers, unregisters events, hides the window, and stops audio.

Rendering stops when the window is hidden; simulation continues. Locking compact mode leaves an unlock control accessible. Legacy paused saves resume automatically; manual resting is no longer part of gameplay.

## Extending and checking

- Add class and zone definitions through stable content keys; add runtime assets separately.
- Add gameplay commands to the relevant domain module, then cover their transactions and edge cases with pure Lua tests.
- Add client event support only after verifying its payloads, credit rules, and restrictions. Deduplicate overlapping delivery signals.
- Add UI checks for new management views and verify object reuse across redraws.
- Run domain tests, simulator integration tests, formatting checks, and Lua diagnostics before review.
- Keep environment configuration outside the repository. No tool installation, editor profile, or client filesystem location is assumed by game code.

## Natural growth and permanent development

`Domain/Economy.lua` applies the versioned natural-growth migration after save validation, on a detached copy of older state. It credits recorded current-cycle training, retained enhancement ranks and one retained enchantment application; ambiguous spending has an explicit zero fallback. The marker/report make credits idempotent and visible. `G.LevelCap` is always the character ceiling; retired training commands cannot spend currency.

`Content/Development.lua` defines Might, Resolve and Provisioning. `Domain/Development.lua` validates the exact rank/investment ledger, quotes current/next modifiers, purchases ranks, refunds exact costs and retains dormant milestone choices. The account owns this ledger through both resets. Live refresh preserves health fractions and action deadlines. Combat applies separate damage/healing/health/defense/recovery, hero-XP and material multipliers; Mastery and real-activity XP are unchanged. Equipment prices combine profession and board discounts, with positive gold/material floors and no Essence costs. Offline snapshots use the same modifiers while live Essence and board ownership remain outside the earnings merge.
