# AFKraft : WoW Idle Game — Design Document

Status: source audit reconciled 2026-11-04. The accepted gameplay systems are implemented; live Forever validation and playtesting remain pending. Retail is the current simulator target. Forever collection sources are database-verified, not live-client verified; Retail acquisition remains disabled. Current tuning and recorded simulations live in [BALANCE.md](BALANCE.md), and outstanding work in [HANDOFF.md](HANDOFF.md).

## Vision

An account-wide idle party RPG inside World of Warcraft: Forever. Five heroes adventure through miniature side-view dioramas of Azeroth. Idle adventures supply hero growth, loot, and materials; normal WoW play adds permanent party development and targeted discoveries; prestige creates a lasting inheritance.

The addon should feel like a polished minigame, with visible characters, attacks, spells, enemies, and discoveries. Management supports the adventure scene rather than replacing it.

Target useful management visits about every 30 minutes, with substantial new systems spread over hours. Check-in cadence and feature-unlock cadence are separate targets, not required timers. Safe resources and discoveries wait for the player; observed pacing is still untested. Dungeons are optional accelerators.

## Design principles

- **Permanent capabilities, repeatable adventures.** Resets rebuild a run or a progression cycle. Purchased abilities, unlocked professions, automation modes, saved rules, and route templates remain owned through ordinary prestige and Prestige+.
- **Attention is a resource.** Progress from choosing individual actions to configuring useful routines. An unlock should introduce a decision, remove a repeated task, or do both. Avoid adding another bar solely because its numbers can increase.
- **Separate progression axes.** Idle growth must remain viable without real WoW activity. Essence never purchases permission to gain hero levels or sustain routine equipment improvements; outdoor collections provide optional goals and build choices.
- **Active play is optional support.** A well-timed boost can help with a difficult fight. Ordinary progression must remain viable without watching cooldowns or interrupting the player's real WoW activity every few minutes.
- **Automation preserves agency.** Offer a useful simple default, then optional rules and route planning. The player decides priorities and can inspect why an automated action ran or waited.
- **Discovery changes the decision space.** New systems should connect to existing builds, equipment, resources, or exploration. Introduce them progressively, with one clear first use rather than many simultaneous configuration screens.
- **Visible growth across resets.** Rebuilding familiar content should require less attention and offer a credible path beyond the previous frontier. Higher difficulty also needs new decisions; larger enemy numbers alone are insufficient.
- **Explain costs and consequences.** Separate permanent ownership, temporary effect state, and cycle investment. Show purchase outcomes, upcoming unlocks, automation eligibility, and reset losses before commitment.
- **Implement behavior, then calibrate it.** Research guides hypotheses, not final prices or retention promises. Existing numbers remain provisional; choose coefficients after the new mechanics work together.

## Implementation audit

Audit date: 2026-11-04. **Implemented** means present in source; **partial** means a foundation exists but does not provide the full proposed feature; **future** identifies an extension without claiming implementation. Code references identify the relevant entry points.

| Feature | Current status | Boundary or next step |
| --- | --- | --- |
| Account party, companion discoveries, duplicate classes, same-class alt replacement | Implemented: [party rules](Domain/Party.lua) | One active party, up to five heroes; simultaneous parties and raids are future scope. |
| Routine combat and hero priorities | Implemented: [combat](Simulation/Combat.lua), [configuration](Domain/Party.lua) | Attack/heal/special priorities, health/enemy-count thresholds, and Balanced/Offensive/role-labeled support presets. Per-hero primary-target selection supports first living enemy, lowest health percentage, or highest health percentage, with stable ties and matching movement/attack selection. Per-hero resource thresholds gate authored Rage/Energy/Mana abilities without stopping basics; pools reset each encounter, with shared online/offline simulation. Hero priorities remain separate from commander rules; arbitrary class scripting is future scope. |
| Combat talents | Implemented: [base content](Content.lua), [traits](Content/TalentTraits.lua), [additional rows](Content/TalentExpansion.lua) | Nine classes, three 18-node trees each in six rows of three; individually authored two-, three- and five-rank passives, critical/super-critical damage and healing, separate attack/ability speed, resource and shield synergies, single-point signature mechanics, cumulative 5/10/15/20/25-point requirements in earlier rows, free rank refunds, and persistent earned points. These are passive build choices, not commander boost buttons. |
| Character levels and Mastery | Implemented: [party progression](Domain/Party.lua), [Mastery](Domain/Mastery.lua) | Natural idle growth reaches the 60 ceiling without paid training gates. Permanent Mastery unlocks at 20 and awards one extra talent point every three ranks. Rank costs start at 100 XP and increase by 50, with an additional `100 * max(0, rank - 8)^2` XP premium after rank eight. Per-tier encounter frontiers migrate the existing record into tier zero. |
| Adventure XP and Essence | Implemented: [Adventure XP](Domain/Adventure.lua), [activity adapters](Compatibility/Kills.lua) | Real WoW activities award account progress; idle combat does not manufacture Adventure XP. The permanent Might/Resolve/Provisioning board offers ten ranks per branch, free redistribution and rank-three milestone choices. Supported-client reward signals still need live verification. |
| Equipment and inventory | Implemented: [item content](Content/Items.lua), [transactions](Domain/Inventory.lua) | Ten wearable slots, comparisons, filters, protection, and a manual equip-best command. Equip-best is not an unattended purchasing or equipment automation feature. |
| Targeted crafting, basic enhancement, heirlooms | Implemented: [inventory commands](Domain/Inventory.lua) | Craft previews, gold/idle-material costs, enhancements, Legacy-purchased heirloom recipes, and profession/development modifiers. Routine production and modifications do not spend Essence. Basic enhancement, enchanting, and titanforging are distinct investments. |
| Automatic salvage and manual disenchanting | Implemented: [loot rules and workbench commands](Domain/Inventory.lua) | Rarity/upgrade/new-effect/protection rules plus an optional class/slot/desired-stat keep policy. Policy fields combine to retain matching items in addition to existing protections. Manual stack disenchanting returns gold/Relic dust; it does not enchant equipment. |
| Gear-set collections | Representative implementation: [catalog](Content/Collections.lua), [ledger](Domain/Collections.lua), [book](UI/CollectionPanel.lua) | Outdoor and dungeon acquisition machinery has individual-piece discovery, independent per-piece rolls, durable kill receipts and one selectable completed-set effect. Legacy Westfall discoveries/ranks retain their earned benefit floor. Forever 16001 uses gnolls in Redridge Mountains for the cloak and ogres in Loch Modan for the four leather pieces; a separate Forever dungeon profile supplies the five Defias Leather identities from Deadmines sources. Retail candidates remain disabled until verified independently; idle/offline battles award no collection progress. |
| Enchanting and titanforging | Implemented: [profession commands](Domain/Professions.lua), [Workshop](UI/ProfessionPanel.lua) | Three base and three tier-earned enchantments, plus five forge tiers, with shared quote/transaction validation and retained heirloom investment. No live WoW profession or bag-item modification. |
| Profession talent trees | Initial implementation: [content](Content/Professions.lua), [progression](Domain/Professions.lua) | Three branches per profession, up to three ranks per branch; separate paid-work progression and saved allocation plans. Broader profession content is future scope. |
| Zone travel and encounter progression | Implemented: [travel/retry](Domain/Party.lua), [world map](UI/Atlas.lua), [routes](Domain/Routes.lua) | Immediate manual travel, automatic local encounters, defeat fallback, and online milestone routes. Offline travel is opt-in and restricted to departure-cleared checkpoints. |
| Player-triggered temporary party boosts | Implemented: [catalog](Content/Boosts.lua), [commands](Domain/Boosts.lua), [controls](UI/Panels.lua) | Battle Orders, Iron Resolve, Focused Assault, and Restorative Focus. Permanent Essence or alternative Legacy purchase resolves to one ownership flag; one equipped/active effect, five-minute duration, ten-minute cooldown, full/compact activation. |
| Boost automation and profiles | Implemented: [commands](Domain/Boosts.lua), [ordered rules](Domain/BoostRules.lua), [profiles](Domain/Profiles.lua) | Permanent on-cooldown/conditional unlocks, global pause and per-boost enable, presets or up to four ordered typed rules, first-match priority, inspectable reasons, and offline execution. Up to eight named profiles retain boost/rule and route preferences. |
| Route planning | Initial implementation: [executor](Domain/Routes.lua), [editor](UI/RoutePanel.lua) | Up to eight templates with 1–12 distinct destinations; named boss/current-hero-level/unlock milestones; stable step IDs, run cursor, safe waiting, manual override/resume. Material-stock and individual outdoor-discovery milestones are supported; collection conditions only observe earned discoveries. Offline execution requires a separate opt-in and visits only departure-cleared current-run/tier checkpoints, with at most 12 transitions. Routes cannot perform outdoor hunts. |
| Ordinary prestige and Legacy | Implemented: [prestige](Domain/Prestige.lua) | Level-8 milestone unlock, run reset, retained talents/Mastery and Legacy rewards. Permanent health/damage/healing strength gains 2 percentage points per Legacy earned, separately from chapter count; old saves retain existing strength. |
| Prestige+ and difficulty tiers | Initial implementation: [difficulty commands](Domain/Difficulty.lua), [preview](UI/DifficultyPanel.lua) | Level-60 hero plus online victory over Spire dragonmarshal in Blackrock Mountain unlock; tiers 0–10, tier records/Mastery, explicit deeper-reset preview, one-time per-tier Inheritance and permanent rebuilding/supplies purchases. Fixed affixes begin at tiers 2/5/8 and appear in previews. Runic fragments from tier 2+ level-20+ bosses fund three permanently learned enchantment recipes at tiers 2/5/8. |
| Offline play | Implemented safe farming: [catch-up](Simulation/Offline.lua) | Up to 24 hours, deterministic Mastery/boost/rule/difficulty rewards and fractional material reconciliation. Saved return totals, journal summary and an icon-based return report; no manual claim. Pushing-only rules wait; no first-time destination progression or automated resets offline; routes require separate opt-in and cleared checkpoints. |
| Fullscreen, windowed, compact views and onboarding | Implemented foundations: [shell](UI/Shell.lua), [tutorial](UI/Tutorial.lua) | Expanded Commander/rules, profiles, routes, collections, Workshop and Prestige+ management; compact activation stays minimal. Native milestone lessons introduce available systems with retained acknowledgements and a guide toggle. An affordable board purchase has a milestone lesson; first-hunt onboarding is available with the verified Forever source profile. Adventure cards preview development opportunities. Supported-client validation remains work. |
| Client coverage and final pacing | Partial | Retail is the current development/simulator target; Forever integration, asset behavior, activity signals, and the complete pacing model are not established by source coverage alone. |

## Party and identity

- One shared account adventure with one active party that grows from one hero to five.
- Unrestricted composition, including duplicate classes.
- Support every Forever launch class with recognizable abilities adapted for idle combat.
- The current character supplies the first hero's identity and class. Idle progression is independent of actual character power, gear, and talents.
- Discover companion slots after defeating milestone bosses at levels 2, 24, 36 and 52. Let the player choose each companion’s class; generate names and appearances. Discoveries and existing parties persist across chapters.
- Register alts when the addon is loaded on them. An alt may replace a generated hero of the same class, retaining its idle level, build, equipment, and progression.
- Additional simultaneous parties and parties combining into raids are future features.

## Core loop

The implemented loop below still needs supported-client validation and pacing tests.

1. Select an unlocked Azeroth zone and prepare the party.
2. Automatically fight small enemy groups and boss encounters.
3. Earn idle experience, gold, equipment, and local materials.
4. Play WoW to fill an account-wide Adventure XP bar; rank rewards grant Essence for permanent party development and learned capabilities. Optionally browse collection sources and hunt their eligible real outdoor creatures.
5. Craft targeted gear, adjust builds, and attempt harder encounters; use unlocked commander boosts when useful.
6. Turn familiar decisions into saved ability rules and zone routes as those capabilities unlock.
7. Prestige for a quicker rebuild with permanent knowledge and controls intact. Eventually enter Prestige+ for a harder tier, deeper cycle rebuilding, and faster gains.

### Intended check-in experience

These examples describe intended check-ins; their pacing and onboarding are not validated balance promises:

| Stage | A useful check-in |
| --- | --- |
| Early party | Inspect a defeat, change a talent or equipment choice, and try the first attack/defense boost on a meaningful fight. Leave with a visible next unlock rather than a repeating click task. |
| Established adventure | Choose between a material-farming route and a frontier push, reserve a boost for bosses, then let saved rules carry out that plan while playing WoW. Review the outcome instead of repeating every command. |
| Later cycle | Choose a profession specialization and a difficulty goal, preview a deeper reset, and rebuild with owned tools already configured. The next challenge should change the plan, not require repurchasing familiar controls. |

## Combat and builds

- Routine combat is automatic, with configurable per-hero priorities. Commander abilities add occasional player decisions without replacing automatic hero actions.
- Current priorities use ally-health and enemy-count thresholds, with Balanced, Offensive, and Healing/Defensive presets. These presets set existing fields. Per-hero primary targets can use encounter order, lowest living enemy health percentage, or highest health percentage. Ties use encounter order; area effects retain living in-range targets. Idle combat now uses authored encounter resources: Warriors start with 0/100 Rage and gain 15 per basic attack and 5 per damaging hit received; Rogues start with 100 Energy and regenerate 8 per second; remaining supported classes start with 100 Mana and regenerate 4 per second. Strike/recovery/special costs are 20/15/30 Rage, 45/30/60 Energy, and 30/20/40 Mana. Each hero may require a minimum resource percentage before abilities; the threshold is checked before paying the cost. Unaffordable abilities wait without consuming cooldowns, while basic attacks continue. Pools reset each encounter and run identically online/offline. These are simulated game rules, independent of live character resources. Arbitrary class scripting remains future scope.
- Deep class-specific talent paths should alter behavior and interactions, including damage, healing, survival, control, and support. Permit mixing paths.
- Talent selections and earned points survive ordinary prestige. Personal level records grant points without rewarding repeated levels. Respecs remain free.
- Heroes gain levels naturally from idle XP up to 60, without purchased training gates. Retain this ceiling initially to preserve talent and difficulty assumptions; infinite levels are outside this revision. Hero XP costs remain unchanged through level ten, then grow quadratically to slow passive late leveling. Permanent Mastery unlocks at hero level 20 and awards one additional talent point every three ranks from victories at or above each hero's recorded encounter frontier. Rank XP costs rise independently of character levels, with a steeper quadratic premium after rank eight.
- Equipment, talent, and priority changes are available at any time, including during idle combat. Changes preserve current health proportions and cooldowns rather than restarting the encounter.
- Manual resting is not part of gameplay. Brief transitions let defeated models complete their death animation. Damage numbers rise and fade smoothly.
- On defeat, recover automatically and farm the last safe encounter. Explain the defeat cause and offer a retry control.
- Ten current equipment slots per hero: weapon, armor, head, back, shoulders, hands, waist, legs, feet, and wrists. Removed accessory/trinket IDs remain reserved for save compatibility.

## Commander abilities

The manual prototype implements all four abilities below. Battle Orders and Iron Resolve each cost 30 Essence; Focused Assault and Restorative Focus each cost 60 Essence. Each also offers an alternative 1-Legacy permanent purchase, without paying twice through another path. One boost is equipped and one effect can be active. All last 900 adventure seconds with an 1800-second cooldown from activation. Battle Orders accelerates only basic-attack cooldown progress by 25%; quarter-second action resolution determines realized throughput. Iron Resolve reduces incoming damage by up to 20% before shields, stopping added mitigation at 90% total reduction without weakening stronger existing defenses. Focused Assault increases party damage by 20%, including ongoing effects; Restorative Focus increases healing-spell output by 25% without reviving defeated heroes. Values are provisional. Both reset types retain ownership/loadout/cooldown deadlines and end effects. Eligible offline farming advances the same simulation clock; ineligible absence does not advance boost time.

### Permanent ownership and acquisition

Commander abilities are player-triggered temporary buffs for the simulated party. They are distinct from automatic class abilities and permanent combat talents. Initial effects should strengthen existing roles rather than give every class a replacement heal, resurrection, or control kit.

Buy an ability once with Essence or Legacy, according to its catalog entry. A starter Essence purchase gives a first use before late progression; Legacy supplies an alternative. Both paths resolve to the same ownership flag, preventing duplicate purchases. Prices, capacity, and unlock order remain tuning decisions.

Learned abilities are reusable through cooldowns, without an Essence or Legacy activation fee. Spending the currency primarily earned from real WoW play every five minutes would discourage experimenting and make unattended use drain savings. Any later consumable-based ability must be a separate, clearly labeled option with explicit spending limits.

### First ability set

Working names describe intent, not final coefficients or asset IDs. A five-minute effect is the requested initial prototype duration, not a validated balance target.

| Ability | Temporary effect | Useful decision |
| --- | --- | --- |
| Battle Orders | Increase basic-attack speed for five minutes | Push an offensive window; distinguish basic attacks from spell/heal cooldown speed. |
| Iron Resolve | Reduce incoming damage for five minutes | Sustain a difficult boss or a weak front line without becoming invulnerable. |
| Focused Assault | Increase damage output for a limited window | Choose burst timing versus saving readiness for the next milestone. |
| Restorative Focus | Improve existing healing output for a limited window | Support healing builds without replacing a healer or reviving fallen heroes. |

The attack-speed and defense lifecycle also supports the damage and healing abilities. All four effects are party-wide, with one equipped slot and one concurrent effect. Larger loadouts or capacities remain future tuning/design changes.

### Duration, cooldown, and stacking contract

- Manual use validates ownership, loadout, party eligibility, cooldown, and active-effect capacity through the same command later used by automation. No confirmation for an ordinary activation.
- Cooldown begins on activation and belongs to the ability, not its hotbar position or hero. Show effect time remaining separately from next-use readiness.
- A copy of an already-active effect cannot stack with itself or be refreshed for extra uptime. Loadout swaps do not clear its cooldown; existing effects still count against active capacity until they expire.
- Attack-speed boosts must specify whether they affect basic attacks only. Reusing a stat that also accelerates healing or offensive abilities requires an explicit design choice.
- Applying or expiring a boost preserves attack/ability cooldown progress rather than granting free immediate actions. Defense combines with armor and talents through an explicit, capped damage calculation. Never permit zero incoming damage through accidental stacking. Health-related stat changes preserve the existing health proportion and death state.
- Buff effects expire normally; ability ownership does not. Both resets end active effects while preserving cooldown progress, preventing reset/reload/loadout swapping from providing free extra uses.
- Use one monotonic adventure-time model for effects and cooldowns, including eligible offline simulation. Login, hiding the window, and clock rollback cannot restart timers or duplicate activations. Time beyond the offline reward cap does not produce extra simulated uses.
- Manual and automatic use have identical strength, duration, cooldown, and validation. Attention changes timing choices, not the numerical power of the same button.

## Automation

Only the equipped boost executes automatically in living encounters. On-cooldown automation requires lifetime idle level 45 and costs 1 Legacy once; conditional automation requires lifetime idle level 60, costs 2 Legacy once, and requires that unlock. Purchases do not enable automation: the global running toggle and per-boost Auto-cast must be enabled. Each boost can use one preset or up to four ordered activation rules. A nonempty rule list takes precedence over the preset, including Manual; the first matching rule requests the shared activation command. Empty rules preserve the selected preset. Conditions are always-in-combat, boss, living-ally health strictly below 10–90%, farming, pushing, or current tier at least 0–10. The compact rule editor starts collapsed; draft changes require Save. Manual activation remains available while automation is paused and owns the shared cooldown if requests coincide. Waiting reasons are readable and routine automatic activations are logged quietly. Up to eight named profiles snapshot loadout, rules, enable preferences, and selected route; applying one validates references/entitlements atomically without activating effects or resetting timers. Profile and rule limits/prices remain provisional.

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

## Route planning

A route is a saved plan for online zone changes during an adventure. Route planning costs 1 Legacy permanently and starts disabled. Up to eight named templates hold 1–12 distinct destinations with boss, named current-hero-level, destination-unlock, material-stock, or individual outdoor-discovery milestones. Editing is a preview until saved. The executor processes at most one step per resolved encounter, preserving stable step IDs and run completion markers. Manual travel pauses the route until resumed; unavailable/locked destinations wait safely. Material milestones observe current stock without spending it; spending before the next encounter boundary can delay travel. Discovery milestones observe exact outdoor piece identities, wait safely for unavailable catalog references, and cannot advance real-world hunting. Offline routes are a separate opt-in, limited to departure-cleared checkpoints in the current run/tier and at most 12 transitions per absence. Automatic resets remain future extensions. This is not control of the real WoW character.

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

Kills, quests, level gains, gathering, and confirmed dungeon completions contribute weighted XP to one account-wide Adventure bar. Each rank awards Essence for permanent party development and learned capabilities. The initial threshold is 100 XP with a 60-Essence payout; rank, partial XP, and unspent Essence survive prestige. Real WoW activity does not directly grant hero experience. See [BALANCE.md](BALANCE.md) for rates and time assumptions.

Non-gray kills remain eligible at the actual character's level cap. Mining, herbalism, and skinning qualify when their node can grant a profession skill point, even when that gather does not produce one. Skinning gives only a small quarter-point bonus after combat to limit pack-farming efficiency. Gray or failed gathers do not qualify. Boss and dungeon rewards require appropriate boss XP eligibility, with verified recommended level brackets as fallback evidence. Legacy farming and unknown eligibility do not qualify. These restrictions govern Adventure XP only. Collection eligibility is separate: a trivial creature can remain a valid collection source. Heroes grow naturally to 60. Gold and idle materials fund routine crafting, enhancement, enchanting, titanforging and heirloom production; none spends Essence. Versioned migration credits recorded retired training and retained Essence equipment investment once, using the conservative policy documented below.

Ordinary questing and combat must support progression without mandatory dungeons. Eligible kill attribution and reward amounts require client verification and balance tuning; ambient unrelated deaths must not grant rewards.

### Permanent party development

Adventure XP and Essence remain the broad real-activity reward; do not add another general-purpose currency. Invest Essence in a small account-wide development board that survives ordinary prestige and Prestige+.

| Branch | Role | Candidate investments |
| --- | --- | --- |
| Might | Offensive party development | Modest damage and healing ranks |
| Resolve | Survival and recovery | Health, recovery, and survivability ranks |
| Provisioning | Farming and rebuilding | Idle material yield, crafting efficiency, and rebuilding benefits |

The implemented board has ten ranks in each branch, priced at 60 times the new rank squared, with benefits using a diminishing rank/(rank+4) curve. Rank three unlocks a free choice between two branch milestones. Use a few readable stat ranks with useful milestone choices, rather than a large tree of tiny percentage nodes. For example, a Provisioning milestone could unlock a farming-oriented commander option. Show current benefit, next benefit, and exact price before purchase. Early investments should be useful immediately; later ranks cost more and offer diminishing gains. Branch size, milestones, prices, and coefficients require combined-system testing.

Permit free redistribution of Essence invested in board ranks. Keep learned abilities permanently owned; redistribution cannot revoke or refund permanent capability purchases. Commander abilities remain reusable without activation fees, with the existing Legacy alternative preserving access for idle-only play. Gold and idle materials sustain the repeatable equipment economy so outdoor inactivity cannot recreate a level gate through gear costs. All benefits affect the simulated party only.

### Idle activity

Automatic combat yields experience, gold, ordinary equipment, and materials. The current destination selects its material; enemy-family metadata supports matching-family combat effects. Simulated battles never award outdoor or dungeon collection discoveries. Explicitly tagged enemy families now add secondary idle spoils: humanoids yield timber; beasts, dragonkin and critters hide; machines and giants ore; elementals, undead and demons Relic dust. The encounter divides a maximum 25% bonus across its enemies; unknown families add nothing. Destination output remains unchanged. All 41 destination profiles have aligned enemy and boss tags, using the existing appearance catalog’s Classic tooltip taxonomy while retaining Westfall’s authored contract. Seven records without type evidence remain unknown. These are authored idle rewards, not claims about real loot. Targeted crafting complements random drops and provides a reliable route toward a desired build.

Natural combat experience is free. Allocating or changing talents never costs Essence. All currencies and crafting exist only inside the minigame.

### Loot handling

Automatically salvage unwanted ordinary loot. Keep rules cover rarity, potential upgrades, new effects, explicit protection, and an optional class/slot/desired-stat policy. All selected policy fields must match for that policy to retain an item; these matches add to the other keep rules rather than removing their protections. Class matching uses equipment proficiency, not the presence of a particular hero. The same rules execute offline. Inventory display filters remain separate. Keep manual disenchanting distinct from automatic salvage and the enchanting profession.

Display shared inventory by effective item power, descending, with stable ordering for equal-power items and clear comparisons against the selected hero's equipment.

## Gear-set collections — accepted target

Collections are a separate account-wide progression axis earned by hunting specific real-world sources. Outdoor sets use outdoor creatures; the accepted dungeon extension uses separate instance-only goals and ledgers. The loop is: choose a missing piece, inspect eligible creatures and locations, farm those creatures in WoW, discover the piece, and gain an idle build option. Idle battles continue to provide ordinary equipment, but do not manufacture outdoor or dungeon collection discoveries or guarantee progress.

The retired Westfall prototype awarded curated pieces from simulated humanoid victories and recorded Prestige+ ranks. This is implementation history, not evidence of canonical loot sources. Audit every proposed item's source on the supported client before enabling outdoor acquisition; do not assume Retail and Forever loot tables match. Dungeon collections are separate goals and must not be required to complete an outdoor set. The first dungeon set is Defias Leather from the Deadmines, with a separate durable ledger and instance-only eligibility.

### Source-specific acquisition

- Roll an addon collection reward after an attributable, eligible real-world creature kill. Restrict each piece to verified creatures that can drop that item on the supported client; zone or creature-family matching alone is insufficient.
- Discoveries represent item identities in the collection book. The actual item need not drop into the player's bags, and no real bag item is created or modified. Addon chances are independent of real loot probabilities and must be labeled accordingly.
- Keep source identities and client-specific mappings behind compatibility boundaries. Verify observable kill attribution and deduplicate overlapping signals before granting rewards; unavailable evidence must not produce guessed credit.
- Evaluate collection eligibility independently from Adventure XP. Trivial creatures may qualify for collection hunting without granting Adventure XP. Idle difficulty and Prestige+ do not change outdoor eligibility or manufacture collection ranks.
- Register a discovery atomically without requiring inventory space, equipment proficiency, equipping, consumption, or a manual claim. Crafted copies, inventory reconstruction, resets, and replayed receipts cannot grant discoveries.

### Discovery rewards and selectable effects

Grant small permanent discovery rewards at visible partial milestones. Completing a set unlocks a themed selectable effect, such as sustained basic attacks, survival against an enemy family, or material farming. Begin with one active completed-set effect; allow free swaps and save the selection in profiles. Preserve class identity and avoid granting every party a class's defining mechanic.

Keep discoveries, earned rewards, unlocked effects, selection, and bad-luck progress through both reset types. Physical equipment ownership never controls collection benefits. Bound the aggregate permanent discovery bonuses as the catalog expands; one selectable effect prevents completion effects from all multiplying together. Ordinary idle progression and difficulty access must remain viable with incomplete or absent collections.

Do not introduce endless duplicate ranks in the first revision. Completion should finish a goal. Retain existing recorded piece/set ranks as legacy save data during migration, but do not tie new outdoor discoveries to idle Prestige+ tiers. Any future repeat-collection system requires a separate design and value-preserving migration.

### Collection browsing and discovery

The book lists all sets in a scrollable catalog with piece counts and a completion label. Piece icons show discovery through color; source and drop-chance details appear in spaced tooltips. Exact creature IDs remain internal eligibility data; family labels do not broaden the kill predicate. Piece cards are passive previews with source tooltips.

Each confirmed eligible creature kill rolls independently for every missing piece that creature can supply. Failed rolls do not accumulate saved progress or increase future odds, and there is no guaranteed discovery threshold. Duplicate kill signals are rejected using bounded receipts.

Legacy collection talents provide optional, permanent support for real collection hunts. Fieldcraft applies only to eligible outdoor collection kills; Relic Hunter applies only to eligible dungeon collection kills. Each has three ranks at Legacy costs of 1/2/3. A rank adds 20% of the source profile's base chance, yielding `base * (1 + 0.2 * rank)`; conditions are mutually exclusive and never stack across acquisition kinds. At rank three, current outdoor/dungeon profiles move from 5%/20% to 8%/32%. These bonuses affect collection pieces only, never ordinary equipment, Adventure XP, source eligibility or attribution. Learned ranks survive both reset types and older saves start with no ranks. The Legacy purchase controls and verified-piece tooltips explain costs, effective chances and active/inactive conditions. See BALANCE.md for modeled distributions and pacing targets; no failed-roll progress or guaranteed threshold is introduced.

Offline and simulated kills never roll collection discoveries. Distinguish the player's real hunting destination from the idle party's farming destination. Idle route automation never moves the real character or completes outdoor hunts.

## Prestige and heirlooms

Prestige becomes available at an initial boss milestone and remains available thereafter. Preview legacy rewards and all losses before confirmation. Rewards grow with achieved run milestones; empty resets yield nothing.

### Reset contract

Both reset types are implemented; the matrix below specifies target retention, including the implemented board and the revised collection target. Ability, automation, profession, and route entitlements are account-wide; hero-specific talents and Mastery stay with their hero. A run, recipe, or destination can be temporarily ineligible without removing an owned capability. An acquisition milestone is not rechecked as an ownership gate after a reset.

| State | Ordinary prestige | Prestige+ |
| --- | --- | --- |
| Hero identity, class, companions and discoveries | Keep | Keep |
| Combat talents, earned/unspent talent points, and Mastery | Keep | Keep; never re-award points for repeating an already-paid milestone |
| Character levels and XP | Reset; no paid training gates | Reset; no paid training gates |
| Party development board investment and allocation | Keep | Keep; free redistribution remains available |
| Adventure rank, partial Adventure XP, and unspent Essence | Keep | Keep; real WoW effort is not a run consumable |
| Legacy balance, earned/purchased permanent bonuses and heirloom recipes | Keep | Keep; a deeper reset does not revoke purchases advertised as permanent |
| Ordinary equipment, gold, zone materials and Runic fragments | Reset | Reset |
| Learned Runic enchantment recipes | Keep | Keep; applications still require gold, materials and fragments |
| Owned heirlooms and existing permanent investment in them | Keep; stats scale back with hero level | Keep; future cycle-only modifications must be identified separately before purchase |
| Collection discoveries, Legacy collection talents, bounded permanent rewards, unlocked/selected effects | Keep | Keep; preserve legacy rank records during migration; physical ordinary gear still resets |
| Ability ownership, purchased automation modes, rule capacity, and route capability | Keep | Keep |
| Rule/profile data, route templates, enabled preferences | Keep | Keep |
| Active boost effects and cooldowns | End active effects; keep cooldown progress | Same; no reset-based free activation |
| Run zone progress and route cursor | Reset | Reset in the selected tier; keep templates and permanent tier records |
| Profession work ranks/XP and saved allocations | Keep | Rebuild ranks/XP; keep ownership, specialization access and allocation plan, which reactivates as work requirements return |
| Heirloom enchantments and forging | Keep, scaling with hero level | Keep; ordinary modified items reset with ordinary equipment |
| Prestige+ tier unlocks, permanent records, Inheritance and its purchases | Keep | Keep after the deeper reset |

Prestige does not refund purchases. Unspent Essence, board investment, and learned capabilities carry across resets; free board redistribution is independent of resetting.

Unlocked difficulty tier 4 and Legacy rewards unlock heirloom recipes; gold and idle materials craft them. Prior evidenced Essence equipment investment is credited by the economy migration. Heirlooms scale with their owner's current idle level, returning to starting-level power after prestige. They provide a dependable baseline while ordinary drops can outperform them or enable specialized builds.

Ordinary prestige records rewarded chapter count separately from permanent party strength. Each earned Legacy adds 2 percentage points to the shared health/damage/healing multiplier; a level-8 reward of 2 Legacy adds 4 points, while a level-20 reward of 6 adds 12. Loading an older save preserves its previous chapter-based strength. Empty resets and Prestige+ do not add ordinary-prestige strength. These values remain prototype pacing choices.

## Progression layers and remaining roadmap

Idle hero growth (levels 1–60, talents, Mastery, and equipment), real-activity party development (Adventure XP and Essence), source-specific outdoor collections, and Legacy/reset progression have separate roles. Natural idle growth retains the level-60 ceiling and Mastery at 20. New capability unlocks should use lifetime account milestones, such as the first hero reaching a level. After an unlock is earned, later runs and alts inherit access. Run resources and current recipe/item requirements still matter.

Current capability unlocks follow the milestones below; the board and planned first outdoor hunt are introduced progressively alongside them; their introduction and pacing remain playtest hypotheses:

| Milestone or experience | Layer | New decision |
| --- | --- | --- |
| Early party development | First manual commander boost, purchased with Essence | When a temporary attack or defense window helps. |
| First hero reaches 22 | Manual Commander boosts | Learn timing and loadout decisions before automation. |
| First hero reaches 45 | On-cooldown automation | Delegate familiar boost timing after hands-on progression. |
| Unlocked difficulty tiers 3 / 4 | Route planning / heirloom recipes | Simplify travel and rebuilding in the post-60 game. |
| First hero reaches 20 | Per-hero Mastery | How to expand the persistent combat build. Conditional automation opens at lifetime hero level 60 and is purchased separately with Legacy. |
| First hero reaches 30 | Enchanting | Targeted offense, defense, or utility bonuses on equipment. |
| First hero reaches 50 | Titanforging | Which durable item deserves a higher potential tier; respect existing armor-proficiency unlocks. |
| First hero reaches 60 | Profession talent trees | Specialize crafting, enchanting, or titanforging without spending combat talent points. |
| First hero reaches 60 and completes a qualifying challenge | Prestige+ access | Trade cycle development for a harder run tier and faster rebuilding. |

### Profession layers

Crafting supplies targeted items and a repeatable resource sink. Enchanting unlocks permanently from lifetime idle level 30 and offers offense, defense, or utility modifications. Titanforging unlocks at 50 and adds up to five potential tiers independently of repeatable enhancement. Both use shared previews and atomic resource validation. These are simulated equipment commands, independent of the actual character's professions.

Lifetime idle level 60 unlocks profession specialization. Paid successful work advances separate profession XP/ranks, capped at 30, and supplies specialization points. Each profession has three branches with up to three ranks each: crafting cost/quality/stat strength, enchanting offense/defense/utility strength, and forging efficiency/potential/heirloom efficiency. These points never consume combat talents. Unlocks, recipes, specialization access, and saved allocations survive Prestige+; work ranks/XP rebuild and the saved plan reactivates as its requirements return. Ordinary prestige retains profession work progress. Heirloom enchant/forge investments survive both resets and scale back with hero level.

Keep reliable progress alongside optional random loot. Preview crafting/modification outcomes and losses before spending resources. Ensure craft–salvage–disenchant loops cannot produce unlimited money, Essence, or materials. Current crafts are instantaneous; a crafting-speed bonus has no value until a timed crafting process actually exists.

### Prestige+ and zone difficulty

Prestige+ is a separate, optional deeper reset, not a renaming of ordinary prestige or a level cap above 60. Unlock its interface permanently at the first qualifying level-60 milestone. Further deeper resets require an explicit current-cycle completion condition; an owned feature can be waiting for eligibility without being lost.

One difficulty tier applies to the run and its zones. Tiers 0–10 increase enemy health/damage, add basic-attack resistance, and separately modify hero XP, Mastery XP, gold, materials, and ordinary loot chance. Previously unlocked tiers remain selectable through an eligible deeper reset. Fixed cumulative affixes add Relentless at tier 2 (2.16-second enemy attacks), Renewal at tier 5 (living enemies regenerate 0.1% maximum health per second after 10 seconds), and Boss fury at tier 8 (+20% boss damage after 30 seconds, applied once). They use the same simulation online/offline, never revive enemies or alter real Adventure XP/Essence, and appear as icon tooltips before reset confirmation. After encounter eight, health/damage grow by 1.14/1.065 per encounter level to encourage recurring prestige before 60. Tier health scales by `1.27^tier * 1.12^max(0, tier-2)` and damage by `1.18^tier`; see BALANCE.md for funded build checks. Runic fragments are a cycle resource, capped at 1,000 and awarded once per eligible tier 2+ level-20+ boss encounter. Online bosses permanently teach Runic Fury/Fortitude/Clarity at tiers 2/5/8; applications cost 3/5/8 fragments alongside ordinary gold/material costs. Specializations apply through the matching offense/defense/utility branch. Cleared bosses can supply fragments offline after a recipe is known, but cannot teach recipes offline. Both resets clear fragments while retaining recipes and existing heirloom modifications. Values remain provisional.

A deeper reset requires a current level-60 hero and an online victory over Spire dragonmarshal, the final Blackrock Mountain champion, in that cycle. It rebuilds hero levels, ordinary equipment, run resources/progress, and profession work ranks/XP. A completed tier pays Inheritance once, with no repeat payment from replaying that tier. Inheritance buys bounded permanent hero-XP or gold/material rebuilding bonuses. The preview shows target tier, reward, retention, and losses. Reset eligibility must be earned again in the current cycle; the interface and purchased tools remain owned.

Separate hero-XP, Mastery-XP, gold/material, loot, and challenge modifiers. Idle difficulty must not quietly increase real WoW Adventure XP or mint Essence. Evaluate the combined effects of tier rewards, abilities, professions, and permanent bonuses before selecting multipliers.

Difficulty records retain per-tier destination/safe progress and completion receipts. Mastery migrates the existing encounter frontier into tier zero and tracks each harder tier separately, retaining permanent earned points. Ordinary and deeper resets restart the active run while retaining permanent records; switching difficulty does not re-award previously paid character-level talent milestones.

Automatic prestige is outside the initial route-planning scope. A later version would need its own explicit opt-in, reward threshold, safe boundary, and transaction receipt; zone routes alone must never initiate either reset type.

## Offline progression

- Earn up to 24 hours of offline rewards per absence.
- Calculate earnings when the addon next loads; no code runs while WoW is closed.
- Farm saved safe encounters offline. Optional offline routes can visit only checkpoints cleared before departure in the current run and tier. New bosses and destination decisions remain online.
- Use the same combat rules for online and offline outcomes, with bounded catch-up batches and no rendering.
- Apply rewards once, advance the saved timestamp, and display a return summary. No manual claim is needed to resume.
- Handle negative elapsed time, reloads, and character switches without duplicate rewards.
- Boosts and ordered rules use the same commands and simulation timeline during eligible offline farming. In the revised collection model, offline simulation grants no outdoor discoveries; the simulated collection behavior is retired. Do not estimate a full day at permanent boosted power or award manual activations the player never made.
- Online routes also work while the minigame is hidden. Offline routes default off and require a separate opt-in, retained in profiles and both resets. A departure snapshot freezes the eligible current-run/tier checkpoints; each transition farms that cleared checkpoint, never the next uncleared encounter. Paused routes stay paused. The executor retains one transition per resolved encounter and caps each absence at 12. First-time bosses, new tiers, and automated resets remain excluded.
- Current prototype behavior: the saved return summary records processed/remaining time, interruptions, retained hero XP/levels, gold, victories, material deltas, kept/salvaged items, Mastery XP/ranks, automatic boost uses, collection discoveries/upgrades, and route transitions and final waiting/completion status. Adventure opens an icon-based return report; journal output retains key totals. Older reports mark unrecorded fields explicitly, and rewards never require claiming. Session feedback records real Adventure XP and Essence earned, eligible outdoor kills, discovered identities and elapsed session time separately from offline earnings. Purchases, refunds and migration credits do not count as earned activity Essence. The latest meaningful report is retained on save; empty sessions do not replace it. The collection book displays current or previous hunting totals; Adventure displays current or previous real-activity XP, Essence and discoveries. Older reports explicitly mark unrecorded activity totals.

## Presentation and controls

Keep AFKcraft's own adventure layout and identity. Prefer native modern WoW controls and frame treatments appropriate to the supported client.

### Adventure scene

WoW character and creature models form a side-view miniature diorama. For now, use an in-game landscape screenshot for each zone as the background. Preserve the option to compose scenery from zone models later, once their rendering works reliably. Do not bundle painted backdrop substitutes. Layer lighting, spell feedback, health indicators, and restrained loot effects. The party's activity and immediate challenge should be readable at a glance.

### Expanded view

- Start fullscreen on first explicit entry into the minigame, not automatically on login.
- Allow a resizable window and remember the preferred expanded geometry.
- Expanded management includes the permanent party development board, equipment, talents/priorities, crafting, world map, Legacy, Commander ownership/rules, profiles, routes, collections, Workshop, and Prestige+ previews.

### Progression feedback — accepted target

The main adventure view shows encounter/frontier state, recent outcomes, and the lowest-cost next development rank with its affordability and benefit. The development card opens its detailed panel without spending resources.

Use familiar equipment slots, item icons, and tooltips in the collection book. Hovering over a piece shows source details. Clearly distinguish real-character hunting locations from idle-party destinations. On the board, preview current/next benefit and exact cost; introduce the first useful purchase and one hunt progressively rather than exposing every branch at once.

Return and session summaries separate idle earnings, Essence actually earned through real WoW activity, and new outdoor discoveries. Never imply that absence generated activity rewards. Apply rewards automatically; no claim action or duplicate-loot popups. The existing catch-up journal is a foundation, not evidence that this presentation is implemented.

### Compact view

- Movable and resizable, with geometry saved separately.
- Interactive by default, with minimal controls: expand, lock, retry, world-map access, and one equipped-boost activation control showing readiness/duration. Manual pause/rest is not current gameplay. Full rule/route editors open the expanded view.
- Purchases, development allocation, source browsing, and deep management open the expanded view.
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
- Permanent entitlements/configuration, run state, and Prestige+ cycle state have explicit storage/reset ownership. Purchasing a capability, assigning a rule, and executing its temporary effect are separate operations.
- Manual and automated commands share validation and side effects. Ability/route evaluators operate on pure minigame state, have bounded work, and emit inspectable action reasons. Automation never casts real WoW spells, controls the real character, or bypasses protected-action restrictions.
- Resolve simultaneous simulation events in a documented order; for example, finish encounter rewards, apply pending route travel, then consider next-encounter boosts. Persist receipts/cursors and cooldown progress so interrupted catch-up or reloads cannot repeat rewards, purchases, transitions, or activations.

### Runtime checks required

The source contains model actors, animation methods, map APIs, and activity event definitions, but runtime support must be verified in Forever.

- Prototype five friendly models plus enemy groups, side-view cameras, animations, scenery, and full/compact resizing.
- Use curated race/body model presets for generated companions. Verify randomized appearance options exposed to in-game addons.
- Capture alt appearance where supported. If exact offline reconstruction is unavailable, retain identity with a clearly identified race/body approximation.
- Verify kill attribution and restrictions, quest/level event payloads, and final-boss dungeon mappings. Deduplicate overlapping boss signals; leaving an instance alone does not mean completion.
- Verify ordinary WoW combat does not cause protected-action errors or unwanted input capture.

## Current implementation priorities

Implement missing features before broad UI/UX rework. Current controls need only expose the features clearly enough to use and test them. Prestige automation is explicitly deferred; ordinary and deeper resets remain manual. The initial dungeon collection, Defias Leather, is implemented with a separate ledger and session totals; supported-client validation remains outstanding. Collection source presentation groups monster families by zone; exact creature IDs remain internal eligibility data.

## Implementation sequence before balance tuning

Phases 1–6 are implemented, including source-specific outdoor/dungeon collections and bounded rule/profile/route editors. The former simulated collection remains archived only to preserve earned benefits. This table retains the implementation order and acceptance criteria; it does not claim completed live-client validation or balanced progression. Pacing/playtests and supported-client integration remain; broader content/UI extensions stay deferred.

| Phase | Deliverable | Completion evidence before proceeding |
| --- | --- | --- |
| 0 | Review capability ownership, clocks, reset contract, and feature audit | Agreed scope and a clear implemented/proposed boundary. |
| 1 | Permanent ability catalog/purchases and two manual boosts | Visible activation/expiry/cooldown, correct effects, migration, and no reset/reload exploits. |
| 2 | On-cooldown automation | The same commands work without repeated clicks; enabled settings survive reset and reload. |
| 3 | Conditional rules and profiles | Useful presets, deterministic conflict resolution, waiting reasons, manual override, and safe offline behavior. |
| 4 | Route editor and online executor | Milestone transitions between encounters, eligible-target checks, override/resume, and permanent templates with fresh run cursors. |
| 4a | Existing simulated collection prototype | Historical foundation only: ledger, partial bonuses, retained counters, and simulated online/offline parity. Replace acquisition and tier ranks under the accepted revision below. |
| 5 | Enchanting, titanforging, then profession trees | Distinct useful choices, reliable progression, explicit cycle/permanent investment, and transaction safety. |
| 6 | Tiered progress and Prestige+ | Level-60 entry, migrated tier-aware records, deeper reset with retained capabilities, legacy collection rank support, and faster-gain rewards working end to end. |
| 7 | Balancing and playtest iteration | Reproducible combined-system scenarios, observed bottlenecks, and comparisons against the pacing hypotheses below. |

Supported-client validation and visual quality continue throughout. Maintain the intended launch-class/outdoor-zone coverage, but use a representative route and party to verify each new system before extending its content. Use working placeholder coefficients for implementation; do not treat their initial values as balance conclusions.

### Accepted progression revision — implementation status

Steps 1–4 are implemented in source and covered by domain/simulator checks, including database-verified Forever source mappings and full/windowed/compact hunting feedback with separate outdoor/dungeon session totals. Step 5 has a reproducible comparison harness; supported-client hunting validation, combined pacing and final tuning remain outstanding. Source and simulator checks do not establish live-client behavior.

1. Remove paid hero training gates and retain natural idle growth to 60. Remove Essence from repeatable equipment production/modification, replacing costs with gold and idle materials.
2. Add the three-branch permanent Essence development board with free rank redistribution, explicit benefit/cost previews, and reset retention.
3. Audit and implement one verified outdoor collection with real-source attribution, individual-piece discovery, independent per-piece rolls, modest discovery rewards, and one selectable completion effect saved in profiles.
4. Update full/windowed/compact feedback and automatic return/session summaries before expanding the catalog.
5. Compare idle-only, ordinary mixed-play, and focused-hunt profiles; tune only after migrations and source attribution work. The reproducible `scripts/balance_profiles.lua` comparison now covers three fixed seeds and 15-minute/one-hour/six-hour horizons with paid equipment and Development decisions. Its hunting sources are synthetic only; verified-client hunting and final tuning remain incomplete. See BALANCE.md for current assumptions, the 30-minute management target and historical simulations.

The implemented economy migration uses `economyVersion = 1`. It credits current-cycle training from saved ranks, retained enhancement ranks, and one retained historical enchantment application. Crafts with unknown discounts, forging, earlier replaced/discarded investments and unidentified items receive a documented zero fallback; existing equipment and modifiers remain. Credits are recorded once and visible in Development. Outdoor migration imports only identical discovered piece IDs, preserves the original archive and ranks, and retains the stronger legacy benefit on each affected axis rather than stacking duplicate benefits. The old cloak does not grant its replacement identity.

Use a versioned, idempotent migration. Preserve hero XP/levels, Adventure XP/rank, unspent Essence, learned abilities, all earned discoveries, and recorded legacy collection ranks. Credit retired training purchases and removed historical Essence equipment spending where saved evidence supports an exact reconstruction; never invent a full purchase history from incomplete state. Define and test a conservative fallback credit for ambiguous saves before rollout. Preserve the value of previously earned collection benefits explicitly when moving to a selectable effect, without silently activating all completion effects or re-awarding discoveries. Migration credit is one-time, separate from ordinary prestige refunds and board redistribution.

## Verification

- Deterministic combat, priority ordering, healing, threat, control, and defeat fallback.
- Crafting costs, inventory transactions, salvage protection, and full inventory behavior.
- Verified client-specific collection source mappings; attributable real kills, including eligible trivial kills; independent per-piece rolls; duplicate/replayed signals; discovery without equipment or bag requirements; free effect selection/profile restoration; bounded combined rewards; and retention across both resets. Confirm idle/offline victories never award outdoor discoveries.
- Natural hero growth to 60 without training or Essence; routine equipment progression with gold/materials alone; board purchase/redistribution conservation and retained learned abilities; one-time migration credits, legacy discoveries/ranks, and preserved collection value across reloads.
- Same-class alt replacement and persistence across character switches.
- Ordinary prestige and Prestige+ preview/retention matrices, including talents, Mastery, Essence, heirlooms, purchased abilities, automation modes, saved rules, route templates, and enabled preferences. Test a purchased always-eligible automation at level 1 immediately after each reset, without repurchasing or re-earning its original unlock milestone.
- Manual/automatic ability equivalence; expiry and cooldown boundaries; same-effect stacking; loadout swaps; simultaneous requests; death/health preservation; and unchanged behavior while the UI is hidden.
- Rule conflict priority, invalid/removed targets, safe fallbacks, no loops, manual override/resume, and transition/reward receipts across save/reload.
- Equal online/offline safe-farm outcomes for identical initial state and automation; no duplicated activations, purchases, currency spending, or route completion after interrupted catch-up.
- Difficulty-aware Mastery and destination records; no duplicate permanent points or rewards by changing tiers or repeatedly resetting.
- Save migrations, duplicated activity events, negative time, repeated reloads, and the 24-hour cap.
- Screenshot checks at fullscreen, expanded, and compact sizes; readable text, unclipped controls, correct layering, and unlocked access from locked mode.
- In-client model animation, spell feedback, combat-lockdown compatibility, and performance checks.
- First prestige access during the opening sessions with 30-minute check-ins, without requiring dungeons; measure the chosen reset time separately.

## Balancing plan — after the behavior is implemented

Values in [BALANCE.md](BALANCE.md) and content files describe the current prototype, not validated targets for the combined game. Five-minute boosts, unlock levels, capacities, multipliers, and prices remain hypotheses to measure together.

### What to measure

| Question | Measurements/scenarios |
| --- | --- |
| Does automation remove work while preserving decisions? | Required interactions and uninterrupted idle time for the same build/route, comparing manual, on-cooldown, and conditional use. |
| Do boosts create useful windows rather than mandatory upkeep? | Actual effect uptime, activations per check-in, boss success, clear time, and progress with no boosts versus simple automation versus contextual rules. |
| Are different builds and professions viable? | Damage, healing, survival, failure causes, resource bottlenecks, and upgrade choices across representative class/party compositions. |
| Do resets feel rewarding? | Time and interactions to regain the previous frontier, reach new content, afford a meaningful permanent purchase, and rebuild cycle investments. Separate ordinary prestige from Prestige+. |
| Is there a dominant farm/reset loop? | Reward per total elapsed adventure time, including rebuild time; compare short resets, deep pushes, frontier farming, difficulty switching, and boss loops. |
| Do idle/offline modes remain worthwhile? | Progress per eligible simulated hour and resource use at matched starting states; account separately for active attention, real WoW activity, and elapsed offline time. |
| Do collections reward exploration without blocking progression? | Median and long-tail real eligible kills/time per piece and set; travel time, source availability, drop-rate variance, aggregate discovery bonuses, selectable-effect choices, and progress with no collections. No repeat-rank target in this revision. |
| Are the progression axes independent and rewarding? | Compare idle-only, ordinary mixed play, and focused outdoor hunts over short and long horizons. Check natural level/equipment growth without Essence, time to meaningful board purchases, diminishing rank value, and faster acquisition of the chosen piece through focused hunting. |
| Does the economy remain understandable? | Source/sink totals per currency, savings toward unlocks, activation cost visibility, deterministic craft payback, and protection against profitable circular transactions. |

Begin with fixed seeds and a small reproducible scenario set: new account, first reset, established automation, level-20 Mastery, level-40 equipment/professions, level-60 cap, and first Prestige+ rebuild. Include difficult bosses, healing/defense parties, low-resource runs, long absences, and bad-loot cases. Follow numerical comparisons with observation of real check-ins and interface friction.

### Guardrails for later math

- Model speed, damage, mitigation, equipment, and tier multipliers together. Basic-attack speed is not a direct multiplier on every source of damage or healing. Check action resolution in the quarter-second simulator so a claimed speed bonus produces actual extra attacks rather than disappearing into a tick limit.
- As a first estimate, an always-available cooldown ability has uptime bounded by duration divided by activation interval, capped at one. Measure actual combat-weighted uptime and timing; do not assume full-time benefits or that this estimate captures movement, failure, and boss windows.
- Evaluate reset rewards against total rebuilding plus pushing time. A large displayed reward can still be a poor loop, and a tiny repeatable reward can dominate if automation makes resets nearly free.
- Keep guaranteed progression and useful fallback choices. Extra currencies, talent nodes, and rare rolls must create decisions rather than disguise a wait or a mathematically inferior option.
- Prevent complete damage immunity, unbounded haste, infinite resource conversion, and multiplicative reward feedback loops before testing high-tier content.
- Treat 30-minute check-ins as a provisional target; first-prestige access is measured rather than forced. Timed playtests must establish actual pacing and the best reset moment.

## Research basis and limits

The draft combines the project's progression/persistence requirements, the implementation audit, descriptive idle-game research, motivation research, and developer-authored mechanics material. The consequences below are design recommendations, not claims that a source proves a particular feature, cooldown, price, or retention outcome for AFKcraft. Game-specific examples are not part of the product specification.

| Research | Finding and application to this draft |
| --- | --- |
| [Playing to Wait: A Taxonomy of Idle Games](https://research.monash.edu/en/publications/playing-to-wait-a-taxonomy-of-idle-games/) — CHI 2018 | Analysis of 66 idle games discusses a shift from playing toward planning and attention as a resource. Apply this as a hypothesis: later automation should delegate familiar execution while leaving useful choices in rules and routes. The accessible institutional abstract supports this scope; it is not a controlled test of this addon. |
| [The Math and Design of Idle Games](https://media.gdcvault.com/gdceurope2016/presentations/Pecorella_Anthony_Quest%20for%20Progress.pdf) — GDC Europe 2016 | Developer material connects active-skill timing, growth multipliers, and prestige-cycle design. Apply it by specifying buff lifecycles and measuring rebuilding/frontier progression together. It supplies models and questions, not transferable final coefficients. |
| [The Motivational Pull of Video Games](https://selfdeterminationtheory.org/SDT/documents/2006_RyanRigbyPrzybylski_MandE.pdf) — 2006 | Four studies connect perceived autonomy/competence and related needs to enjoyment and future play. Support readable choices, feedback, and control over automation. These associations do not prove that more currencies, longer grinds, or a specific reward schedule improve this game. |
| [A Study of Interaction in Idle Games and Perceptions on the Definition of a Game](https://research.torrens.edu.au/en/publications/a-study-of-interaction-in-idle-games-amp-perceptions-on-the-defin/) — 2016 | The institutional abstract describes optional interaction over extended play and a survey of player perceptions. Treat low-attention play as a first-class mode; do not infer a universal active/idle reward ratio from it. |
| [MDA: A Formal Approach to Game Design and Game Research](https://users.cs.northwestern.edu/~hunicke/MDA.pdf) — 2004 | Separates implemented mechanics, resulting system behavior, and intended experience. It supports implementing/observing interacting systems before final tuning; adding features alone does not establish a better experience. |

Developer documentation and public implementation examples were also checked for conditional automation, persistent configuration, route milestones, offline handling, and failure cases. Their availability shows feasibility and exposes design questions; it is not evidence of WoW-client compatibility or guaranteed player satisfaction.

### Dungeon collection implementation

Defias Leather has five discoverable identities, tracked separately from outdoor pieces, kills and session totals. It uses the same bounded per-piece receipt rules and one shared selected completed-set effect across both collection types. No inventory item, equipment proficiency or real bag drop is required; collection-only identities never enter ordinary loot or crafting pools. Profiles retain a selected dungeon effect, and discoveries survive both resets. Live dungeon discoveries received during offline reconciliation remain on the live state.

Only attributable real kills inside a party instance can use the Forever 16001 dungeon source profile. Outdoor and dungeon source profiles cannot credit each other's ledgers. Unknown builds, unavailable/secret context, raids and offline simulation remain ineligible. Source-family groups and locations appear in collection-piece tooltips. Routes may observe dungeon discoveries but never perform the dungeon or move the real character.

Provisional dungeon acquisition is 20% per eligible kill with no guaranteed drop threshold. Two discoveries add 0.5% basic-attack strength; four add 0.5% material yield, under the shared discovery caps. Completion unlocks a selectable 4% reduction to simulated humanoid damage. This is an authored idle effect, separate from the real equipment set's bonuses. Database source verification and mocked adapter checks do not establish live Forever behavior.
