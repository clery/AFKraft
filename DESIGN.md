# WoWIdle — Design Document

Status: research-informed draft for review, with the implementation audit updated 2026-11-03 for commander boosts and their initial automation. The audit below distinguishes current source behavior from proposed work. New boost values are provisional; existing balance constants are unchanged. An implemented feature still requires supported-client validation and playtesting.

## Vision

An account-wide idle party RPG inside World of Warcraft: Forever. Five heroes adventure through miniature side-view dioramas of Azeroth. Normal WoW play fuels their growth; idle adventures supply loot and materials; prestige creates a lasting inheritance.

The addon should feel like a polished minigame, with visible characters, attacks, spells, enemies, and discoveries. Management supports the adventure scene rather than replacing it.

Target occasional meaningful check-ins every 15–30 minutes. Balance the first prestige around 4–6 hours of mixed real WoW activity over 2–3 days, including offline earnings. Dungeons are optional accelerators.

## Design principles

- **Permanent capabilities, repeatable adventures.** Resets rebuild a run or a progression cycle. Purchased abilities, unlocked professions, automation modes, saved rules, and route templates remain owned through ordinary prestige and Prestige+.
- **Attention is a resource.** Progress from choosing individual actions to configuring useful routines. An unlock should introduce a decision, remove a repeated task, or do both. Avoid adding another bar solely because its numbers can increase.
- **Active play is optional support.** A well-timed boost can help with a difficult fight. Ordinary progression must remain viable without watching cooldowns or interrupting the player's real WoW activity every few minutes.
- **Automation preserves agency.** Offer a useful simple default, then optional rules and route planning. The player decides priorities and can inspect why an automated action ran or waited.
- **Discovery changes the decision space.** New systems should connect to existing builds, equipment, resources, or exploration. Introduce them progressively, with one clear first use rather than many simultaneous configuration screens.
- **Visible growth across resets.** Rebuilding familiar content should require less attention and offer a credible path beyond the previous frontier. Higher difficulty also needs new decisions; larger enemy numbers alone are insufficient.
- **Explain costs and consequences.** Separate permanent ownership, temporary effect state, and cycle investment. Show purchase outcomes, upcoming unlocks, automation eligibility, and reset losses before commitment.
- **Implement behavior, then calibrate it.** Research guides hypotheses, not final prices or retention promises. Existing numbers remain provisional; choose coefficients after the new mechanics work together.

## Implementation audit

Audit date: 2026-11-02; commander boosts updated 2026-11-03. **Implemented** means present in source; **partial** means a foundation exists but does not provide the full proposed feature; **proposed** means no implementation is being claimed. Code references identify the relevant entry points.

| Feature | Current status | Boundary or next step |
| --- | --- | --- |
| Account party, companion discoveries, duplicate classes, same-class alt replacement | Implemented: [party rules](Domain/Party.lua) | One active party, up to five heroes; simultaneous parties and raids are future scope. |
| Routine combat and hero priorities | Implemented: [combat](Simulation/Combat.lua), [configuration](Domain/Party.lua) | Attack/heal/special priorities with health and enemy-count thresholds; not a general player-authored rule engine. |
| Combat talents | Implemented: [base content](Content.lua), [traits](Content/TalentTraits.lua), [additional rows](Content/TalentExpansion.lua) | Nine classes, three 16-node trees each; shared foundations, class mechanics, free respecs, and persistent earned points. These are passive build choices, not commander boost buttons. |
| Character levels and Mastery | Implemented: [party progression](Domain/Party.lua), [Mastery](Domain/Mastery.lua) | Character cap 60; permanent Mastery unlocks at 20 and awards extra talent points. Current rank costs start at 100 XP and increase by 50. Its encounter frontier has no difficulty-tier dimension. |
| Adventure XP and Essence | Implemented: [Adventure XP](Domain/Adventure.lua), [activity adapters](Compatibility/Kills.lua) | Real WoW activities award account progress; idle combat does not manufacture Adventure XP. Supported-client reward signals still need live verification. |
| Equipment and inventory | Implemented: [item content](Content/Items.lua), [transactions](Domain/Inventory.lua) | Ten wearable slots, comparisons, filters, protection, and a manual equip-best command. Equip-best is not an unattended purchasing or equipment automation feature. |
| Targeted crafting, basic enhancement, heirlooms | Implemented: [inventory commands](Domain/Inventory.lua) | Craft previews, material/Essence costs, item enhancements, and Legacy-purchased heirloom recipes. Basic enhancement is not the proposed enchanting or titanforging system. |
| Automatic salvage and manual disenchanting | Implemented: [loot rules and workbench commands](Domain/Inventory.lua) | Salvage uses broad rarity/upgrade/new-effect keep rules. Disenchanting handles stored stacks and returns gold/Relic dust. Detailed inventory filters are not equivalent to detailed automatic salvage rules. |
| Gear-set collections | Proposed | No permanent set ledger, zone-specific collection rewards, duplicate protection, or Prestige+ collection ranks exist yet. Item-effect discoveries are not set collections. |
| Enchanting and titanforging | Proposed | Separate item-modification decisions and upgrade tracks; no current command or progression ledger provides them. |
| Profession talent trees | Proposed | Separate crafting/enchanting/titanforging specializations, not extra spending from the combat talent budget. |
| Zone travel and encounter progression | Partial: [travel/retry](Domain/Party.lua), [world map](UI/Atlas.lua) | Manual destination changes, automatic encounters within a zone, and defeat fallback exist. No saved zone-change schedule or route executor exists. |
| Player-triggered temporary party boosts | Initial implementation: [catalog](Content/Boosts.lua), [commands](Domain/Boosts.lua), [controls](UI/Panels.lua) | Battle Orders and Iron Resolve; permanent Essence purchases, one equipped/active boost, five-minute effects, ten-minute cooldowns, full/compact activation. Values remain provisional; additional boosts and alternative acquisition paths remain proposed. |
| Boost automation | Initial implementation: [commands and conditions](Domain/Boosts.lua), [combat-step execution](Simulation/Combat.lua), [Commander controls](UI/Panels.lua) | Permanent on-cooldown and conditional unlocks; global pause, per-boost enable/mode, boss/lowest-living-health/farming/pushing triggers, inspectable reasons, and offline execution. One condition per equipped boost; saved profiles and a general priority-rule editor remain proposed. Hero priorities remain separate. |
| Route planning | Proposed | No route editor, persistent templates, milestone interpreter, or per-run route cursor. |
| Ordinary prestige and Legacy | Implemented: [prestige](Domain/Prestige.lua) | Level-8 milestone unlock, run reset, retained talents/Mastery, Legacy rewards, and the current +4 percentage points to health/damage/healing per rewarded chapter. |
| Prestige+ and difficulty tiers | Proposed | No deeper reset, tiered zone progress, new tier currency, or tier reward multiplier exists yet. Ordinary prestige is not Prestige+. |
| Offline play | Implemented safe farming: [catch-up](Simulation/Offline.lua) | Up to 24 hours, bounded deterministic catch-up, including Mastery and commander boosts/automation. Rules use the safe-farming snapshot, so pushing-only rules wait offline. No first-time destination progression, route execution, or automated resets offline. |
| Fullscreen, windowed, compact views and onboarding | Implemented foundations: [shell](UI/Shell.lua), [tutorial](UI/Tutorial.lua) | Expanded management, Commander purchases/loadout/automation, and full/compact boost activation. Route/profile management remain proposed. |
| Client coverage and final pacing | Partial | Retail is the current development/simulator target; Forever integration, asset behavior, activity signals, and the complete pacing model are not established by source coverage alone. |

## Party and identity

- One shared account adventure with one active party that grows from one hero to five.
- Unrestricted composition, including duplicate classes.
- Support every Forever launch class with recognizable abilities adapted for idle combat.
- The current character supplies the first hero's identity and class. Idle progression is independent of actual character power, gear, and talents.
- Discover companion slots after defeating milestone bosses at levels 1, 3, 5 and 7. Let the player choose each companion’s class; generate names and appearances. Discoveries and existing parties persist across chapters.
- Register alts when the addon is loaded on them. An alt may replace a generated hero of the same class, retaining its idle level, build, equipment, and progression.
- Additional simultaneous parties and parties combining into raids are future features.

## Core loop

The complete loop below includes proposed layers; implementation status is defined by the audit.

1. Select an unlocked Azeroth zone and prepare the party.
2. Automatically fight small enemy groups and boss encounters.
3. Earn idle experience, gold, equipment, and local materials.
4. Play WoW to fill an account-wide Adventure XP bar; rank rewards grant Essence for major upgrades.
5. Craft targeted gear, adjust builds, and attempt harder encounters; use unlocked commander boosts when useful.
6. Turn familiar decisions into saved ability rules and zone routes as those capabilities unlock.
7. Prestige for a quicker rebuild with permanent knowledge and controls intact. Eventually enter Prestige+ for a harder tier, deeper cycle rebuilding, and faster gains.

### Intended check-in experience

These examples describe the proposed complete game, not additional implemented features:

| Stage | A useful check-in |
| --- | --- |
| Early party | Inspect a defeat, change a talent or equipment choice, and try the first attack/defense boost on a meaningful fight. Leave with a visible next unlock rather than a repeating click task. |
| Established adventure | Choose between a material-farming route and a frontier push, reserve a boost for bosses, then let saved rules carry out that plan while playing WoW. Review the outcome instead of repeating every command. |
| Later cycle | Choose a profession specialization and a difficulty goal, preview a deeper reset, and rebuild with owned tools already configured. The next challenge should change the plan, not require repurchasing familiar controls. |

## Combat and builds

- Routine combat is automatic, with configurable per-hero priorities. Proposed commander abilities add occasional player decisions without replacing automatic hero actions.
- Current priorities use ally-health and enemy-count thresholds. Richer resource/target conditions and selectable class presets are proposed extensions; supply useful defaults before requiring rule configuration.
- Deep class-specific talent paths should alter behavior and interactions, including damage, healing, survival, control, and support. Permit mixing paths.
- Talent selections and earned points survive ordinary prestige. Personal level records grant points without rewarding repeated levels. Respecs remain free.
- Hero levels cap at 60. Permanent Mastery unlocks at hero level 20 and awards additional talent points from victories at or above each hero's recorded encounter frontier. Rank XP costs increase gently, independent of character levels.
- Equipment, talent, and priority changes are available at any time, including during idle combat. Changes preserve current health proportions and cooldowns rather than restarting the encounter.
- Manual resting is not part of gameplay. Brief transitions let defeated models complete their death animation. Damage numbers rise and fade smoothly.
- On defeat, recover automatically and farm the last safe encounter. Explain the defeat cause and offer a retry control.
- Ten current equipment slots per hero: weapon, armor, head, back, shoulders, hands, waist, legs, feet, and wrists. Removed accessory/trinket IDs remain reserved for save compatibility.

## Commander abilities — draft

The first manual prototype implements Battle Orders and Iron Resolve. Each costs 30 Essence once, with one equipped boost and one concurrent effect. Both last 300 adventure seconds with a 600-second cooldown from activation. Battle Orders accelerates only basic-attack cooldown progress by 25%; quarter-second action resolution determines realized attack throughput. Iron Resolve multiplies incoming damage by 0.8 before shields, stopping additional mitigation at 90% total reduction without weakening builds whose existing defenses are stronger. These are provisional prototype values. Owned boosts, loadout, and cooldown deadlines survive ordinary prestige; active effects end. Eligible offline safe farming advances the same saved simulation clock; ineligible absence does not advance boost time. Boost automation is described below; further abilities and alternative purchase paths remain future work.

### Permanent ownership and acquisition

Commander abilities are player-triggered temporary buffs for the simulated party. They are distinct from automatic class abilities and permanent combat talents. Initial effects should strengthen existing roles rather than give every class a replacement heal, resurrection, or control kit.

Buy an ability once with Essence or Legacy, according to its catalog entry. A starter Essence purchase gives a first use before late progression; later Legacy purchases can broaden the catalog and automation options. Alternative purchase paths must resolve to the same ownership flag, preventing duplicate purchases. Prices, capacity, and unlock order are review/tuning decisions.

Default proposal: learned abilities are reusable through cooldowns, without an Essence or Legacy activation fee. Spending the currency primarily earned from real WoW play every five minutes would discourage experimenting and make unattended use drain savings. Any later consumable-based ability must be a separate, clearly labeled option with explicit spending limits.

### First ability set

Working names describe intent, not final coefficients or asset IDs. A five-minute effect is the requested initial prototype duration, not a validated balance target.

| Ability | Temporary effect | Useful decision |
| --- | --- | --- |
| Battle Orders | Increase basic-attack speed for five minutes | Push an offensive window; distinguish basic attacks from spell/heal cooldown speed. |
| Iron Resolve | Reduce incoming damage for five minutes | Sustain a difficult boss or a weak front line without becoming invulnerable. |
| Focused Assault | Increase damage output for a limited window | Choose burst timing versus saving readiness for the next milestone. |
| Restorative Focus | Improve existing healing output for a limited window | Support healing builds without replacing a healer or reviving fallen heroes. |

Start with the attack-speed and defense abilities. Add more after their shared lifecycle works. Prefer party-wide effects initially to avoid five copies of the same maintenance action. A small loadout/concurrent-effect capacity should create a choice; its exact size remains open.

### Duration, cooldown, and stacking contract

- Manual use validates ownership, loadout, party eligibility, cooldown, and active-effect capacity through the same command later used by automation. No confirmation for an ordinary activation.
- Cooldown begins on activation and belongs to the ability, not its hotbar position or hero. Show effect time remaining separately from next-use readiness.
- A copy of an already-active effect cannot stack with itself or be refreshed for extra uptime. Loadout swaps do not clear its cooldown; existing effects still count against active capacity until they expire.
- Attack-speed boosts must specify whether they affect basic attacks only. Reusing a stat that also accelerates healing or offensive abilities requires an explicit design choice.
- Applying or expiring a boost preserves attack/ability cooldown progress rather than granting free immediate actions. Defense combines with armor and talents through an explicit, capped damage calculation. Never permit zero incoming damage through accidental stacking. Health-related stat changes preserve the existing health proportion and death state.
- Buff effects expire normally; ability ownership does not. Proposed reset behavior ends active effects while preserving cooldown progress, preventing reset/reload/loadout swapping from providing free extra uses.
- Use one monotonic adventure-time model for effects and cooldowns, including eligible offline simulation. Login, hiding the window, and clock rollback cannot restart timers or duplicate activations. Time beyond the offline reward cap does not produce extra simulated uses.
- Manual and automatic use have identical strength, duration, cooldown, and validation. Attention changes timing choices, not the numerical power of the same button.

## Automation — draft

The initial implementation offers one saved mode per boost, executing only the equipped boost in living encounters. On-cooldown automation costs 1 Legacy once; conditional modes cost 2 Legacy once and require that first unlock. Purchases do not enable automation: a global running toggle, per-boost enable, and a non-manual mode are all required. Enabling a boost initially selects on-cooldown mode; subsequent toggles retain its chosen condition. Available conditions are a boss encounter, a living ally strictly below a configured health percentage, safe farming, or frontier pushing. The health threshold defaults to 50%; the interface offers 35%, 50%, 65%, and 80%. Manual activation remains available while automation is paused and uses identical validation and timers. Unmet conditions generate a readable reason rather than repeated notifications; routine automatic activations enter the bounded journal quietly. These unlock costs and presets are provisional. General priority lists and named profiles remain future work.

### Progression from action to planning

1. **Manual:** learn what the ability does and see its outcome.
2. **On cooldown:** a permanently purchased mode uses it whenever ready and eligible. This is a viable low-attention default.
3. **Conditional:** an additional permanent capability introduces readable rules such as boss fights, lowest living ally health, encounter difficulty, or farming/pushing state.
4. **Profiles:** saved combinations of loadout, rules, and route preferences support different goals without rebuilding configuration after resets.

Unlocking another control mode adds flexibility, not a stronger version of the buff. Combat priorities and salvage remain functional throughout; do not require rebuying existing automation. There should be no recurring automation license, check-in refill, or feature expiry.

### Rules and player control

- Use a bounded priority list of typed conditions and actions, with a useful preset. Do not require writing Lua, scripts, or mathematical expressions.
- Define conditions precisely: for example, the health of the lowest-health living ally, rather than an unspecified party average. Exclude dead units and unavailable targets.
- Evaluate rules from simulation state, not rendered frames. Health triggers can evaluate at combat-step boundaries; route actions evaluate at encounter boundaries.
- If several rules qualify, apply a stable priority and execute each eligible command once. Respect shared active-effect limits and per-ability cooldowns.
- Manual activation takes precedence over a simultaneous automated request; the latter revalidates readiness. Rules can reserve an ability for a boss instead of repeatedly spending its cooldown during farming.
- Permit a global automation toggle, per-ability enable controls, manual override, and an inspectable reason such as active, cooling down, condition unmet, or target unavailable.
- Keep rules, profiles, selected modes, ownership, and enabled preferences through ordinary prestige and Prestige+. Temporary ineligibility in a new run pauses an action with a reason; it never deletes configuration or revokes a purchased feature.
- Repeated failure must fall back to a safe behavior and a bounded notice, not an infinite retry loop or a stream of notifications.

## Route planning — draft

A route is a saved plan for zone changes during an adventure. It moves repeat-run effort toward choosing a farming or pushing strategy. It is not control of the real WoW character, and it does not require an automatic prestige feature.

### Route model

A persistent template contains ordered steps: destination ID, run-scoped milestone, destination eligibility checks, and fallback behavior. The current step and completed-step markers belong to the run and restart on prestige; the template and automation capability remain owned and enabled across both reset layers.

Initial supported milestones should be small and explicit: complete a named zone milestone, reach a specified current hero level, or unlock a destination. Later material targets and richer conditions can be added when they create useful choices. A level predicate must identify the hero or aggregation it uses; it must not silently substitute a lifetime best for a current-run level.

Example plan:

1. Continue in the starting zone until a specified boss milestone is complete and the next destination is unlocked.
2. Travel to that destination after the encounter resolves; farm until the next step's level/unlock conditions are met.
3. Move to the next eligible zone, or keep farming the current safe encounter if the destination remains unavailable.

### Execution and safety

- Route travel occurs between resolved encounters so an automatic transition does not abandon a paid-for fight or replay rewards. Manual travel keeps its existing immediate behavior.
- Process at most one route transition per encounter boundary. Use stable step IDs and per-run completion markers; reject self-triggering loops and contradictory destinations.
- If a target is locked, removed, unsupported, or unsafe for the current difficulty, retain the step and show a waiting reason. Continue safe farming; do not silently choose a more expensive or harder route.
- Allow immediate manual destination override and a clear resume-route control. Do not fight the player by instantly traveling back after an override.
- Show the next destination, its trigger, current progress, and the reason for waiting. Permit previewing/editing a route without executing it.
- A retained enabled route resumes from its first eligible step in a new run. A manual override pauses execution for that run until resumed; a deliberate global disable remains disabled across resets.
- Saved routes reference stable game destination IDs, not client map IDs. Steps inherit the current run tier unless a template explicitly restricts its tier. A zone route never changes difficulty or triggers a reset.
- Route planning and ability automation share visible run context and ordering, so a boost can be saved for the boss before a transition rather than wasted after it.

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

Automatically salvage unwanted ordinary loot. Current keep rules cover rarity, potential upgrades, new effects, and explicit protection. Class/slot and desired-stat policies are proposed extensions; inventory display filters do not yet provide those salvage rules. Apply the same rules during offline catch-up and summarize results. Keep manual disenchanting distinct from automatic salvage and from the proposed enchanting profession.

Display shared inventory by effective item power, descending, with stable ordering for equal-power items and clear comparisons against the selected hero's equipment.

## Gear-set collections — draft

Rare equipment from idle encounters can also fill a permanent, account-wide collection book. This gives a familiar zone a specific long-term goal and connects exploration, loot, route planning, and Prestige+ without requiring players to store obsolete gear. These are minigame drops, not a requirement to collect items in the real WoW character's bags.

### Discovery and permanent bonuses

- Register each distinct piece once on acquisition, before automatic salvage or other inventory disposal. Equipping, consuming, or manually claiming the item is not required. Any party composition can register a piece, regardless of armor proficiency; normal equipment restrictions remain unchanged.
- Grant modest permanent bonuses at visible partial-set milestones and a distinct completion bonus. Avoid an all-or-nothing reward that makes every drop before the last piece feel useless. Exact thresholds and coefficients remain open for balancing.
- Keep the book, earned bonuses, piece ranks, and bad-luck progress through ordinary prestige and Prestige+. Selling, disenchanting, replacing, or losing the physical equipment never revokes the discovery.
- Give sets recognizable themes rather than making every collection another universal damage multiplier. Candidate themes include basic-attack effectiveness, survival against a particular enemy family, or material yield. Keep party-wide benefits modest and class-specific mechanics in class talents; no set should make a class's defining ability universally available.
- Completion provides an enduring improvement, not a mandatory key to the next zone or difficulty. Balance progression for incomplete collections and reserve completionist goals for optional depth.

A working example is a Defias-themed collection associated with Westfall encounters. A future Deadmines dungeon could add its own collection or additional acquisition sources. This is an idle-content proposal, not a claim about canonical item drop locations: verify exact item identities, artwork, and client-specific sources before implementation. Do not make an outdoor collection require a dungeon that does not exist yet.

### Higher-difficulty upgrades

Each collection piece records its highest acquired Prestige+ tier. A higher-tier copy replaces that record rather than creating a separate book or erasing earlier completion. A first drop at a higher tier also counts as discovering the piece; lower-tier copies never downgrade it.

Use the lowest recorded tier across all pieces as the set's completed upgrade rank. For example, upgrading all but one piece to Prestige+1 keeps the base completion reward; acquiring the remaining Prestige+1 piece upgrades that reward. Show both piece progress and the next completed-rank reward. Higher ranks improve the existing bonus with gentle, diminishing increments, replacing the previous rank's value rather than stacking full copies of it. Exact rank limits and increments remain open; permanent collection rank is separate from an item's enhancement, enchantment, or titanforge level.

Ordinary duplicate copies still follow normal equipment/salvage rules and never repeatedly award permanent stats. Changing difficulty, resetting, crafting the same item, or replaying a reward receipt must not produce extra discoveries or ranks. Crafted items do not count as rare collection drops in the initial design.

### Target farming and bad-luck protection

The book shows each piece's eligible zones/enemy families, required difficulty, discovered state, highest tier, and progress toward a guaranteed missing piece. Publish drop eligibility and chances once tuned. Let players choose a collection target for planning; choosing a target does not silently change drop probabilities.

Propose a visible per-collection, per-difficulty guarantee counter: eligible victories advance it, and reaching the threshold grants a randomly selected piece still missing at that difficulty. A normal qualifying drop that fills a missing piece restarts that counter; irrelevant duplicates do not. If that rank is complete, no counter advances. Persist partial counters across resets, process online and eligible offline victories identically, and make each reward atomic. A higher-tier drop satisfies the same piece at lower tiers; it cannot generate additional conversion rewards from those tiers. Thresholds are implementation placeholders until completion-time distributions are tested. This uses progress records rather than introducing another spendable currency.

Saved routes may later wait for a collection milestone before moving on. They must expose a time/victory limit and fallback destination so optional collecting cannot trap a run indefinitely. Keep the collection book in the expanded view, with a short new-piece/upgrade summary after offline catch-up; avoid a popup or inventory action for every duplicate.

## Prestige and heirlooms

Prestige becomes available at an initial boss milestone and remains available thereafter. Preview legacy rewards and all losses before confirmation. Rewards grow with achieved run milestones; empty resets yield nothing.

### Reset contract

Ordinary prestige is implemented. The Prestige+ column is the proposed contract, not current behavior. New ability, automation, profession, and route entitlements are account-wide; hero-specific talents and Mastery stay with their hero. A run, recipe, or destination can be temporarily ineligible without removing an owned capability. A level or currency milestone used to acquire a capability is not rechecked as an ownership gate after a reset.

| State | Ordinary prestige — current/proposed additions | Prestige+ — proposed |
| --- | --- | --- |
| Hero identity, class, companions and discoveries | Keep | Keep |
| Combat talents, earned/unspent talent points, and Mastery | Keep | Keep; never re-award points for repeating an already-paid milestone |
| Character levels, XP and training | Reset | Reset |
| Adventure rank, partial Adventure XP, and unspent Essence | Keep | Keep; real WoW effort is not a run consumable |
| Legacy balance, earned/purchased permanent bonuses and heirloom recipes | Keep | Keep; a deeper reset does not revoke purchases advertised as permanent |
| Ordinary equipment, gold and zone materials | Reset | Reset |
| Owned heirlooms and existing permanent investment in them | Keep; stats scale back with hero level | Keep; future cycle-only modifications must be identified separately before purchase |
| Collection discoveries, permanent bonuses, highest piece/set ranks, and guarantee counters | Proposed: keep | Keep; physical ordinary gear still resets |
| Ability ownership, purchased automation modes, rule capacity, and route capability | Proposed: keep | Keep |
| Rule/profile data, route templates, enabled preferences | Proposed: keep | Keep |
| Active boost effects and cooldowns | Proposed: end active effects; keep cooldown progress | Same; no reset-based free activation |
| Run zone progress and route cursor | Reset | Reset in the selected tier; keep templates and permanent tier records |
| Future cycle profession ranks and cycle-only forging investments | Proposed: retain through ordinary prestige | Rebuild; keep the profession, specialization access, recipes, saved builds, and automation tools |
| Prestige+ tier unlocks and its permanent purchases/currency | Not implemented | Keep after the deeper reset |

Spent Essence remains spent; prestige does not refund upgrades. Real WoW effort held as unspent Essence carries across resets.

Legacy rewards unlock heirloom recipes; materials and Essence craft them. Heirlooms scale with their owner's current idle level, returning to starting-level power after prestige. They provide a dependable baseline while ordinary drops can outperform them or enable specialized builds.

## Progression layers roadmap — draft

Existing character levels (1–60), permanent combat talents, Mastery at 20, Adventure ranks, and ordinary prestige remain distinct axes. New capability unlocks should use lifetime account milestones, such as the first hero reaching a level. After an unlock is earned, later runs and alts inherit access. Run resources and current recipe/item requirements still matter.

These timings are a proposed introduction order, not fixed balance promises:

| Milestone or experience | Layer | New decision |
| --- | --- | --- |
| Early party development | First manual commander boost, purchased with Essence | When a temporary attack or defense window helps. |
| First useful ordinary prestige and Legacy purchases | On-cooldown boost automation and basic route planning | Which familiar routine to delegate first. |
| First hero reaches 20 | Existing per-hero Mastery; proposed conditional-rule access for the account | Which encounters deserve reserved boosts. Introduce the new editor separately from the Mastery explanation. |
| First hero reaches 30 | Enchanting | Targeted offense, defense, or utility bonuses on equipment. |
| First hero reaches 40 | Titanforging | Which durable item deserves a higher potential tier; respect existing armor-proficiency unlocks. |
| First hero reaches 50 | Profession talent trees | Specialize crafting, enchanting, or titanforging without spending combat talent points. |
| First hero reaches 60 and completes a qualifying challenge | Prestige+ access | Trade cycle development for a harder run tier and faster rebuilding. |

### Profession layers

Crafting already supplies targeted items and a repeatable resource sink. Enchanting should add targeted modifications; titanforging should improve an item's potential/tier through a separate investment. Neither should simply rename the current repeatable +10% enhancement button.

Profession trees use their own earned points or research, with readable branches for crafting outcomes, enchantment choices, and forging efficiency/potential. Unlocks, recipes, specialization access, and saved allocations/templates survive Prestige+. Cycle-earned ranks and explicitly labeled cycle investments can rebuild there. Reapply a saved allocation only as its current requirements become valid.

Keep reliable progress alongside optional random loot. Preview crafting/modification outcomes and losses before spending resources. Ensure craft–salvage–disenchant loops cannot produce unlimited money, Essence, or materials. Current crafts are instantaneous; a crafting-speed bonus has no value until a timed crafting process actually exists.

### Prestige+ and zone difficulty

Prestige+ is a separate, optional deeper reset, not a renaming of ordinary prestige or a level cap above 60. Unlock its interface permanently at the first qualifying level-60 milestone. Further deeper resets require an explicit current-cycle completion condition; an owned feature can be waiting for eligibility without being lost.

Start with one difficulty tier for the run, shared by its zones, rather than independent per-zone difficulty axes. Higher tiers can add encounter modifiers and new resource/recipe opportunities as well as stronger enemies. Keep previously unlocked tiers selectable. Challenge affixes are a later extension, not another mandatory layer in the first slice.

A deeper reset rebuilds profession/cycle development and zone progress while retaining the tools that make rebuilding less laborious. Award a distinct permanent reward only if it has a clear role beyond Essence and Legacy. It can improve rebuilding speed and eligible idle gains; exact currency naming and multiplier values remain open. Show the reward and a complete loss/retention preview.

Separate hero-XP, Mastery-XP, gold/material, loot, and challenge modifiers. Idle difficulty must not quietly increase real WoW Adventure XP or mint Essence. Evaluate the combined effects of tier rewards, abilities, professions, and permanent bonuses before selecting multipliers.

Before tiers ship, extend records and gates to include difficulty context. The current Mastery frontier is a single encounter level: directly reusing it would make a harder tier's low-numbered encounters look easier than a previous tier's frontier. A per-tier frontier/normalized challenge model needs an explicit migration from the existing base-tier record. Keep permanent talent entitlements intact and prevent replaying previously rewarded milestones for duplicate permanent points.

Automatic prestige is outside the initial route-planning scope. A later version would need its own explicit opt-in, reward threshold, safe boundary, and transaction receipt; zone routes alone must never initiate either reset type.

## Offline progression

- Earn up to 24 hours of offline rewards per absence.
- Calculate earnings when the addon next loads; no code runs while WoW is closed.
- Current behavior: farm the saved safe encounter offline; new bosses and destination decisions are handled online.
- Use the same combat rules for online and offline outcomes, with bounded catch-up batches and no rendering.
- Apply rewards once, advance the saved timestamp, and display a return summary. No manual claim is needed to resume.
- Handle negative elapsed time, reloads, and character switches without duplicate rewards.
- Proposed boosts and their automation use the same commands, effect/cooldown timeline, and rule ordering online and in offline safe farming. Do not estimate a full day at permanent boosted power or award manual activations the player never made.
- First route implementation targets online progression while WoW is running, including when the minigame is hidden. Retain the current offline safe-farming policy initially. Later offline routes may use only destinations/checkpoints already cleared in the current run and tier before departure, with separate opt-in and bounded transitions. First-time bosses, new tiers, and automated resets need a later explicit design decision.
- Return summaries should distinguish ordinary earnings, Mastery progress, automatic boost uses, route transitions, and waits. Do not require claiming rewards or rebuilding saved settings.

## Presentation and controls

Keep WoWIdle's own adventure layout and identity. Prefer native modern WoW controls and frame treatments appropriate to the supported client.

### Adventure scene

WoW character and creature models form a side-view miniature diorama. For now, use an in-game landscape screenshot for each zone as the background. Preserve the option to compose scenery from zone models later, once their rendering works reliably. Do not bundle painted backdrop substitutes. Layer lighting, spell feedback, health indicators, and restrained loot effects. The party's activity and immediate challenge should be readable at a glance.

### Expanded view

- Start fullscreen on first explicit entry into the minigame, not automatically on login.
- Allow a resizable window and remember the preferred expanded geometry.
- Include equipment, talents, priorities, crafting, world map, and prestige panels. Proposed ability ownership/loadouts, automation profiles, route editing, and reset previews belong in expanded management.

### Compact view

- Movable and resizable, with geometry saved separately.
- Interactive by default, with minimal controls: expand, lock, retry, and world-map access. Manual pause/rest is not current gameplay. Proposed compact boost icons show readiness and duration; full rule/route editors open the expanded view.
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
- Proposed permanent entitlements/configuration, run state, and Prestige+ cycle state need explicit storage/reset ownership. Purchasing a capability, assigning a rule, and executing its temporary effect are separate operations.
- Manual and automated commands share validation and side effects. Ability/route evaluators operate on pure minigame state, have bounded work, and emit inspectable action reasons. Automation never casts real WoW spells, controls the real character, or bypasses protected-action restrictions.
- Resolve simultaneous simulation events in a documented order; for example, finish encounter rewards, apply pending route travel, then consider next-encounter boosts. Persist receipts/cursors and cooldown progress so interrupted catch-up or reloads cannot repeat rewards, purchases, transitions, or activations.

### Runtime checks required

The source contains model actors, animation methods, map APIs, and activity event definitions, but runtime support must be verified in Forever.

- Prototype five friendly models plus enemy groups, side-view cameras, animations, scenery, and full/compact resizing.
- Use curated race/body model presets for generated companions. Verify randomized appearance options exposed to in-game addons.
- Capture alt appearance where supported. If exact offline reconstruction is unavailable, retain identity with a clearly identified race/body approximation.
- Verify kill attribution and restrictions, quest/level event payloads, and final-boss dungeon mappings. Deduplicate overlapping boss signals; leaving an instance alone does not mean completion.
- Verify ordinary WoW combat does not cause protected-action errors or unwanted input capture.

## Implementation sequence before balance tuning

This draft is the review stage. No new ability, automation, route, collection, profession, or Prestige+ system is implemented by this document.

| Phase | Deliverable | Completion evidence before proceeding |
| --- | --- | --- |
| 0 | Review capability ownership, clocks, reset contract, and feature audit | Agreed scope and a clear implemented/proposed boundary. |
| 1 | Permanent ability catalog/purchases and two manual boosts | Visible activation/expiry/cooldown, correct effects, migration, and no reset/reload exploits. |
| 2 | On-cooldown automation | The same commands work without repeated clicks; enabled settings survive reset and reload. |
| 3 | Conditional rules and profiles | Useful presets, deterministic conflict resolution, waiting reasons, manual override, and safe offline behavior. |
| 4 | Route editor and online executor | Milestone transitions between encounters, eligible-target checks, override/resume, and permanent templates with fresh run cursors. |
| 4a | Outdoor gear-set collection book and acquisition ledger | One representative set, partial/completion bonuses, registration before disposal, retained guarantee progress, and online/offline reward parity; dungeon sources remain future scope. |
| 5 | Enchanting, titanforging, then profession trees | Distinct useful choices, reliable progression, explicit cycle/permanent investment, and transaction safety. |
| 6 | Tiered progress and Prestige+ | Level-60 entry, migrated tier-aware records, deeper reset with retained capabilities, collection rank upgrades, and faster-gain rewards working end to end. |
| 7 | Balancing and playtest iteration | Reproducible combined-system scenarios, observed bottlenecks, and comparisons against the pacing hypotheses below. |

Supported-client validation and visual quality continue throughout. Maintain the intended launch-class/outdoor-zone coverage, but use a representative route and party to verify each new system before extending its content. Use working placeholder coefficients for implementation; do not treat their initial values as balance conclusions.

## Verification

- Deterministic combat, priority ordering, healing, threat, control, and defeat fallback.
- Crafting costs, inventory transactions, salvage protection, and full inventory behavior.
- Collection registration before salvage/full-inventory handling; missing-piece guarantees; higher-tier first discoveries; duplicate/replayed receipts; mixed-tier completion; and retention of bonuses/ranks/counters across both resets. Verify no class or equipment requirement blocks registration.
- Same-class alt replacement and persistence across character switches.
- Ordinary prestige and Prestige+ preview/retention matrices, including talents, Mastery, Essence, heirlooms, purchased abilities, automation modes, saved rules, route templates, and enabled preferences. Test a purchased always-eligible automation at level 1 immediately after each reset, without repurchasing or re-earning its original unlock milestone.
- Manual/automatic ability equivalence; expiry and cooldown boundaries; same-effect stacking; loadout swaps; simultaneous requests; death/health preservation; and unchanged behavior while the UI is hidden.
- Rule conflict priority, invalid/removed targets, safe fallbacks, no loops, manual override/resume, and transition/reward receipts across save/reload.
- Equal online/offline safe-farm outcomes for identical initial state and automation; no duplicated activations, purchases, currency spending, or route completion after interrupted catch-up.
- Difficulty-aware Mastery and destination records; no duplicate permanent points or rewards by changing tiers or repeatedly resetting.
- Save migrations, duplicated activity events, negative time, repeated reloads, and the 24-hour cap.
- Screenshot checks at fullscreen, expanded, and compact sizes; readable text, unclipped controls, correct layering, and unlocked access from locked mode.
- In-client model animation, spell feedback, combat-lockdown compatibility, and performance checks.
- Simulated mixed-play profiles reaching first prestige after 4–6 hours of actual WoW activity over 2–3 days without requiring dungeons.

## Balancing plan — after the behavior is implemented

Existing values in [BALANCE.md](BALANCE.md) and content files describe the current prototype, not validated targets for the combined game. Leave them unchanged during this documentation pass. Five-minute boosts, proposed unlock levels, capacities, multipliers, and prices remain hypotheses.

### What to measure

| Question | Measurements/scenarios |
| --- | --- |
| Does automation remove work while preserving decisions? | Required interactions and uninterrupted idle time for the same build/route, comparing manual, on-cooldown, and conditional use. |
| Do boosts create useful windows rather than mandatory upkeep? | Actual effect uptime, activations per check-in, boss success, clear time, and progress with no boosts versus simple automation versus contextual rules. |
| Are different builds and professions viable? | Damage, healing, survival, failure causes, resource bottlenecks, and upgrade choices across representative class/party compositions. |
| Do resets feel rewarding? | Time and interactions to regain the previous frontier, reach new content, afford a meaningful permanent purchase, and rebuild cycle investments. Separate ordinary prestige from Prestige+. |
| Is there a dominant farm/reset loop? | Reward per total elapsed adventure time, including rebuild time; compare short resets, deep pushes, frontier farming, difficulty switching, and boss loops. |
| Do idle/offline modes remain worthwhile? | Progress per eligible simulated hour and resource use at matched starting states; account separately for active attention, real WoW activity, and elapsed offline time. |
| Do collections reward exploration without blocking progression? | Median and long-tail eligible victories/time to first piece, partial milestones, completion, and each higher-tier upgrade; duplicate frequency, guarantee activations, route detours, and parties with incomplete sets. |
| Does the economy remain understandable? | Source/sink totals per currency, savings toward unlocks, activation cost visibility, deterministic craft payback, and protection against profitable circular transactions. |

Begin with fixed seeds and a small reproducible scenario set: new account, first reset, established automation, level-20 Mastery, level-40 equipment/professions, level-60 cap, and first Prestige+ rebuild. Include difficult bosses, healing/defense parties, low-resource runs, long absences, and bad-loot cases. Follow numerical comparisons with observation of real check-ins and interface friction.

### Guardrails for later math

- Model speed, damage, mitigation, equipment, and tier multipliers together. Basic-attack speed is not a direct multiplier on every source of damage or healing. Check action resolution in the quarter-second simulator so a claimed speed bonus produces actual extra attacks rather than disappearing into a tick limit.
- As a first estimate, an always-available cooldown ability has uptime bounded by duration divided by activation interval, capped at one. Measure actual combat-weighted uptime and timing; do not assume full-time benefits or that this estimate captures movement, failure, and boss windows.
- Evaluate reset rewards against total rebuilding plus pushing time. A large displayed reward can still be a poor loop, and a tiny repeatable reward can dominate if automation makes resets nearly free.
- Keep guaranteed progression and useful fallback choices. Extra currencies, talent nodes, and rare rolls must create decisions rather than disguise a wait or a mathematically inferior option.
- Prevent complete damage immunity, unbounded haste, infinite resource conversion, and multiplicative reward feedback loops before testing high-tier content.
- Keep the earlier 15–30-minute check-in and 4–6-hour first-prestige goals as provisional pacing hypotheses. Research does not establish them for this game; timed playtests must.

## Research basis and limits

The draft combines the project's progression/persistence requirements, the implementation audit, descriptive idle-game research, motivation research, and developer-authored mechanics material. The consequences below are design recommendations, not claims that a source proves a particular feature, cooldown, price, or retention outcome for WoWIdle. Game-specific examples are not part of the product specification.

| Research | Finding and application to this draft |
| --- | --- |
| [Playing to Wait: A Taxonomy of Idle Games](https://research.monash.edu/en/publications/playing-to-wait-a-taxonomy-of-idle-games/) — CHI 2018 | Analysis of 66 idle games discusses a shift from playing toward planning and attention as a resource. Apply this as a hypothesis: later automation should delegate familiar execution while leaving useful choices in rules and routes. The accessible institutional abstract supports this scope; it is not a controlled test of this addon. |
| [The Math and Design of Idle Games](https://media.gdcvault.com/gdceurope2016/presentations/Pecorella_Anthony_Quest%20for%20Progress.pdf) — GDC Europe 2016 | Developer material connects active-skill timing, growth multipliers, and prestige-cycle design. Apply it by specifying buff lifecycles and measuring rebuilding/frontier progression together. It supplies models and questions, not transferable final coefficients. |
| [The Motivational Pull of Video Games](https://selfdeterminationtheory.org/SDT/documents/2006_RyanRigbyPrzybylski_MandE.pdf) — 2006 | Four studies connect perceived autonomy/competence and related needs to enjoyment and future play. Support readable choices, feedback, and control over automation. These associations do not prove that more currencies, longer grinds, or a specific reward schedule improve this game. |
| [A Study of Interaction in Idle Games and Perceptions on the Definition of a Game](https://research.torrens.edu.au/en/publications/a-study-of-interaction-in-idle-games-amp-perceptions-on-the-defin/) — 2016 | The institutional abstract describes optional interaction over extended play and a survey of player perceptions. Treat low-attention play as a first-class mode; do not infer a universal active/idle reward ratio from it. |
| [MDA: A Formal Approach to Game Design and Game Research](https://users.cs.northwestern.edu/~hunicke/MDA.pdf) — 2004 | Separates implemented mechanics, resulting system behavior, and intended experience. It supports implementing/observing interacting systems before final tuning; adding features alone does not establish a better experience. |

Developer documentation and public implementation examples were also checked for conditional automation, persistent configuration, route milestones, offline handling, and failure cases. Their availability shows feasibility and exposes design questions; it is not evidence of WoW-client compatibility or guaranteed player satisfaction.
