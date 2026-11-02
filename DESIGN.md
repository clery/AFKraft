# WoWIdle — Design Document

Status: agreed direction and initial implementation defaults, 2026-10-31.

## Vision

An account-wide idle party RPG inside World of Warcraft: Forever. Five heroes adventure through miniature side-view dioramas of Azeroth. Normal WoW play fuels their growth; idle adventures supply loot and materials; prestige creates a lasting inheritance.

The addon should feel like a polished minigame, with visible characters, attacks, spells, enemies, and discoveries. Management supports the adventure scene rather than replacing it.

Target occasional meaningful check-ins every 15–30 minutes. Balance the first prestige around 4–6 hours of mixed real WoW activity over 2–3 days, including offline earnings. Dungeons are optional accelerators.

## Party and identity

- One shared account adventure with one active party that grows from one hero to five.
- Unrestricted composition, including duplicate classes.
- Support every Forever launch class with recognizable abilities adapted for idle combat.
- The current character supplies the first hero's identity and class. Idle progression is independent of actual character power, gear, and talents.
- Discover companion slots after defeating milestone bosses at levels 1, 3, 5 and 7. Let the player choose each companion’s class; generate names and appearances. Discoveries and existing parties persist across chapters.
- Register alts when the addon is loaded on them. An alt may replace a generated hero of the same class, retaining its idle level, build, equipment, and progression.
- Additional simultaneous parties and parties combining into raids are future features.

## Core loop

1. Select an unlocked Azeroth zone and prepare the party.
2. Automatically fight small enemy groups and boss encounters.
3. Earn idle experience, gold, equipment, and local materials.
4. Play WoW to fill an account-wide Adventure XP bar; rank rewards grant Essence for major upgrades.
5. Craft targeted gear, adjust builds, and attempt harder encounters.
6. Prestige the whole adventure to earn legacy rewards and unlock heirloom recipes.

## Combat and builds

- Entirely automatic combat, with configurable per-hero ability priorities.
- Support conditions such as ally health, enemy count, available resources, and target selection.
- Provide functional class presets before requiring players to configure priorities.
- Deep class-specific talent paths should alter behavior and interactions, including damage, healing, survival, control, and support. Permit mixing paths.
- Talent selections and earned points survive ordinary prestige. Personal level records grant points without rewarding repeated levels. Respecs remain free.
- Hero levels cap at 60. Permanent Mastery unlocks at hero level 20 and awards additional talent points from victories at or above each hero's recorded encounter frontier. Rank XP costs increase gently, independent of character levels.
- Equipment, talent, and priority changes are available at any time, including during idle combat. Changes preserve current health proportions and cooldowns rather than restarting the encounter.
- Manual resting is not part of gameplay. Brief transitions let defeated models complete their death animation. Damage numbers rise and fade smoothly.
- On defeat, recover automatically and farm the last safe encounter. Explain the defeat cause and offer a retry control.
- Six equipment slots per hero: weapon, armor, head, accessory, and two trinkets. Expansion is possible later.

## Azeroth world map

- Reuse WoW's map artwork and navigation for choosing destinations.
- Show interactive Kalimdor and Eastern Kingdoms continent maps with clickable regions and destination markers. Travel can interrupt combat; abandoned encounters grant no rewards and do not heal the party.
- Idle travel is independent of the real character's location.
- Unlock destinations through idle progression, not actual exploration or character level.
- First-release coverage includes all Forever launch outdoor adventure zones. Cities serve as landmarks rather than farming areas.
- Each zone has an idle level range, unlock requirements, biome, enemy families, encounter groups, boss milestones, resource profile, loot, and scenery.
- Location, original zone level, and monster types inform its resources and challenges.
- Provide branching farming choices alongside a clear progression route.
- Share biome scenery and encounter components where useful, preserving recognizable zone identity.

## Resources, rewards, and crafting

### Real WoW activity

Kills, quests, level gains, gathering, and confirmed dungeon completions contribute weighted XP to one account-wide Adventure bar. Each rank awards Essence for major upgrades. The initial threshold is 100 XP with a 60-Essence payout; rank, partial XP, and unspent Essence survive prestige. Real WoW activity does not directly grant hero experience. See [BALANCE.md](BALANCE.md) for rates and time assumptions.

Non-gray kills remain eligible at the actual character's level cap. Mining, herbalism, and skinning qualify when their node can grant a profession skill point, even when that gather does not produce one. Skinning gives only a small quarter-point bonus after combat to limit pack-farming efficiency. Gray or failed gathers do not qualify. Boss and dungeon rewards require appropriate boss XP eligibility, with verified recommended level brackets as fallback evidence. Legacy farming and unknown eligibility do not qualify. Essence funds training, targeted crafting, equipment improvements, and heirlooms.

Ordinary questing and combat must support progression without mandatory dungeons. Eligible kill attribution and reward amounts require client verification and balance tuning; ambient unrelated deaths must not grant rewards.

### Idle activity

Automatic combat yields experience, gold, ordinary equipment, and materials. Biomes and monster families determine material profiles. Targeted crafting complements random drops and provides a reliable route toward a desired build.

Natural combat experience is free. Allocating or changing talents never costs Essence. All currencies and crafting exist only inside the minigame.

### Loot handling

Automatically salvage unwanted ordinary loot. Configurable keep rules include rarity, class/slot, desired stats or effects, and explicit protection. Defaults retain potential upgrades and newly discovered effects. Apply the same rules during offline catch-up and summarize results.

Display shared inventory by effective item power, descending, with stable ordering for equal-power items and clear comparisons against the selected hero's equipment.

## Prestige and heirlooms

Prestige becomes available at an initial boss milestone and remains available thereafter. Preview legacy rewards and all losses before confirmation. Rewards grow with achieved run milestones; empty resets yield nothing.

| Resets | Persists |
| --- | --- |
| All heroes' idle levels and training | Hero identities, classes, talents, earned talent points, and Mastery |
| Ordinary equipment and purchased run upgrades | Talent, effect, and recipe discoveries |
| Gold and zone materials | Legacy currency and permanent upgrades |
| Zone and encounter progression | Crafted heirlooms |
| | Unspent Adventure Essence |

Spent Essence remains spent; prestige does not refund upgrades. Real WoW effort held as unspent Essence carries across resets.

Legacy rewards unlock heirloom recipes; materials and Essence craft them. Heirlooms scale with their owner's current idle level, returning to starting-level power after prestige. They provide a dependable baseline while ordinary drops can outperform them or enable specialized builds.

## Progression layers roadmap

The current foundation separates resettable hero levels (1–60), permanent talents, and Mastery unlocked at level 20. Additional layers should introduce new decisions at spaced milestones, not merely raise the level ceiling. The following milestones are planned and require implementation and playtesting:

| Milestone | New layer | Purpose |
| --- | --- | --- |
| Level 30 | Enchanting | Add targeted equipment bonuses and choices beyond basic enhancements. |
| Level 40 | Titanforging | Improve equipment power through its own upgrade track. |
| Level 50 | Profession talent trees | Specialize in crafting, enchanting, or titanforging efficiency and power. |
| Level 60 | Prestige+ | Unlock a harder progression tier and an optional deeper reset with lasting gain multipliers. |

Ordinary prestige keeps talents and Mastery. Prestige+ should reset additional profession and upgrade development in exchange for faster rebuilding and tougher zones. Its permanent rewards can accelerate hero XP, Mastery XP, and resource acquisition. Keep earned talent points permanent; define each additional reset loss explicitly in the preview. Exact multipliers, profession reset boundaries, and subsequent difficulty unlocks remain balance work. Existing enhancement purchases remain usable while the new profession layers are developed.

## Offline progression

- Earn up to 24 hours of offline rewards per absence.
- Calculate earnings when the addon next loads; no code runs while WoW is closed.
- Initial default: farm the saved safe encounter offline; new bosses and destination decisions are handled online.
- Use the same combat rules for online and offline outcomes, with bounded catch-up batches and no rendering.
- Apply rewards once, advance the saved timestamp, and display a return summary. No manual claim is needed to resume.
- Handle negative elapsed time, reloads, and character switches without duplicate rewards.

## Presentation and controls

Keep WoWIdle's own adventure layout and identity. Prefer native modern WoW controls and frame treatments appropriate to the supported client.

### Adventure scene

WoW character and creature models form a side-view miniature diorama. For now, use an in-game landscape screenshot for each zone as the background. Preserve the option to compose scenery from zone models later, once their rendering works reliably. Do not bundle painted backdrop substitutes. Layer lighting, spell feedback, health indicators, and restrained loot effects. The party's activity and immediate challenge should be readable at a glance.

### Expanded view

- Start fullscreen on first explicit entry into the minigame, not automatically on login.
- Allow a resizable window and remember the preferred expanded geometry.
- Include equipment, talents, priorities, crafting, world map, and prestige panels.

### Compact view

- Movable and resizable, with geometry saved separately.
- Interactive by default, with minimal controls: pause, expand, lock, and retry.
- Deep management opens the expanded view.
- Optional lock prevents dragging and scene interaction; an accessible unlock control remains.
- Switching views never interrupts combat. Hide rendering when the scene is hidden while retaining progression.

## Technical foundation

Target World of Warcraft: Forever, with Retail used for initial development and visual testing. Keep client-specific APIs and asset identifiers behind compatibility adapters. Confirm interface metadata against each supported client build.

- Use account-wide, versioned `WoWIdleDB` SavedVariables for heroes, inventory, currencies, discoveries, run state, random seed, timestamps, and preferences.
- Account-wide means the local WoW account installation; cross-computer synchronization is outside the first release.
- Separate pure Lua simulation, data-driven content, WoW event adapters, persistence, and rendering.
- Normalize WoW activity into one reward interface with source identifiers and duplicate suppression.
- Emit combat and reward events for the renderer; animation never determines simulation results.
- Define classes, abilities, talents, items, recipes, zones, and encounters as validated content data.
- Keep logs bounded and avoid saving transient model objects or frame references.

### Runtime checks required

The source contains model actors, animation methods, map APIs, and activity event definitions, but runtime support must be verified in Forever.

- Prototype five friendly models plus enemy groups, side-view cameras, animations, scenery, and full/compact resizing.
- Use curated race/body model presets for generated companions. Verify randomized appearance options exposed to in-game addons.
- Capture alt appearance where supported. If exact offline reconstruction is unavailable, retain identity with a clearly identified race/body approximation.
- Verify kill attribution and restrictions, quest/level event payloads, and final-boss dungeon mappings. Deduplicate overlapping boss signals; leaving an instance alone does not mean completion.
- Verify ordinary WoW combat does not cause protected-action errors or unwanted input capture.

## Delivery milestones

1. **Compatibility and visual proof:** validate Forever rendering, appearances, event adapters, persistence, and offline timing. Establish simulator screenshots and real-client checks.
2. **Complete gameplay slice:** party setup, representative zone, combat, gear, crafting, Essence, offline catch-up, prestige, and heirlooms.
3. **Full content coverage:** every launch class and outdoor zone using the validated systems. The slice is an implementation milestone, not a reduction of first-release scope.
4. **Polish and balance:** zone scenery, class feedback, compact usability, salvage configuration, and 2–3-day first-prestige pacing.

## Verification

- Deterministic combat, priority ordering, healing, threat, control, and defeat fallback.
- Crafting costs, inventory transactions, salvage protection, and full inventory behavior.
- Same-class alt replacement and persistence across character switches.
- Prestige preview and exact retention/reset behavior, especially Essence and heirlooms.
- Save migrations, duplicated activity events, negative time, repeated reloads, and the 24-hour cap.
- Screenshot checks at fullscreen, expanded, and compact sizes; readable text, unclipped controls, correct layering, and unlocked access from locked mode.
- In-client model animation, spell feedback, combat-lockdown compatibility, and performance checks.
- Simulated mixed-play profiles reaching first prestige after 4–6 hours of actual WoW activity over 2–3 days without requiring dungeons.

## Balance values still to tune

Exact ability coefficients, talent counts, zone encounter tables, resource amounts, recipe costs, prestige formulas, and reward rates are implementation and playtest work. Keep these in content/balance tables rather than hardcoding them into UI or event handlers. The pacing and retention rules above are the design constraints.
