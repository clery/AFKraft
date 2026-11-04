# Progression and economy balance

## Design intent

WoWIdle is a companion idle RPG: short management visits should produce useful decisions, while battles and safe offline farming supply the resources between visits. Real WoW play accelerates permanent development without buying permission to level, equip, or prestige. A new feature should create another useful investment, not make the older investments irrelevant.

This pass follows the production/cost comparison and reset-loop modeling described in Anthony Pecorella’s [The Math of Idle Games, Part I](https://www.kongregate.com/en/pages/the-math-of-idle-games-part-i) and [Part III](https://www.kongregate.com/en/pages/the-math-of-idle-games-part-iii). These sources explain modeling methods, not universal timings. The targets below are this project's design choices. All reported results are simulations or analytical models, not observed player behavior or in-client validation.

## Evidence freshness

The long-horizon journey, matrix and intervention figures below record the balance pass before the later class-stat scoring correction. They remain useful scenario evidence, but are not current-code or live-client guarantees. Rerun the relevant scenario before tuning from those figures; the 100-hour journey and tier-nine/ten acquisition have not been revalidated in this text pass.

Current-code rechecks on 2026-11-04:

| Scenario | Result |
| --- | --- |
| `balance_builds.lua` | 96 cases, each replayed: 80 wins, 16 timeouts, no wipes. |
| `balance_profiles.lua` | Nine six-hour no-reset profiles. First prestige access at 43–46 minutes; hero levels 27–31 and frontiers 37–42 after six hours. Mixed-play access is slightly earlier than the provisional 45–60-minute target. Hunt sources are synthetic. |
| `balance_rebuild.lua` | Six actual-reset cases, each replayed. At two hours, ordinary/tier-zero-deep/tier-one-deep frontiers are 50/48/47; none regains the prior frontier of 60. Each case buys 10 crafts and 2 forge steps, with 38 deferred modification quotes under its initial-zone policy. |

These results replace the older handoff's 64-case build matrix and faster rebuild timings. Different reset rewards and retained power remain explicit; the reset fixture does not prove a dominant loop or globally unaffordable upgrades.

## Feature roles and targets

| System | Role and balance decision |
| --- | --- |
| Opening, recruitment and destinations | Preserve the first eight encounter levels, existing companion discoveries and all 41 destination unlocks. Aim for a useful first session and first prestige access in roughly 45–60 minutes with 15-minute check-ins. Access is optional; it is not a forced reset. |
| Hero levels, talents and class resources | Keep natural growth to 60, level-earned permanent points, free respecs and encounter resource pools. Never charge Essence for levels. Class priorities and party composition should affect throughput and survival. |
| Mastery | Keep level-20 unlock, per-tier highest-encounter eligibility, 100 initial XP plus 50 per rank through rank eight, a quadratic late-rank premium, and double boss XP. Repeated easy resets cannot generate new level points or bypass the Mastery frontier. |
| Equipment loot and crafting | Loot supplies incidental upgrades; crafting fills specific gaps. Reduce normal craft materials to `max(5, ceil((4 + ceil(level/4)) * discounts))`, from `4 + level`. At level 60 an undiscounted replacement costs 19 materials instead of 64. Gold remains `8 * level`. |
| Enhancement | Keep +10% base stats per purchase and the existing Ore price. Gold becomes `16 + 10*r + 6*r^2`, where `r` is prior upgrades. Early enhancement remains cheap; repeated enhancement eventually competes with enchanting and forging rather than dominating them indefinitely. Already earned stats are unchanged. |
| Enchanting and titanforging | Unlock at 30/50 and paid-work specialization at 60. Gold becomes `(24 + 6*itemLevel) * nextRank`; Relic dust is `2 + nextRank`; forging also costs `4 + 2*nextRank` Ore, before discounts. Enchanting uses rank one. A level-60 first modification costs 384 gold and 3 dust rather than 760 and 5. |
| Profession plans and heirlooms | Retain work XP, branch ranks, forge power, recipes and heirloom scaling. New heirloom access requires unlocked tier 4, then 1 Heritage per slot. Basic heirloom craft remains 30 gold/12 materials before discounts. Profession plans and item investments make later rebuilds faster. Salvage/disenchant returns remain below paid inputs. |
| Adventure and Development | Retain activity rates and exact investment receipts; increase permanent branch benefits instead of changing prices under existing saves. First-rank purchases should produce a visible combat or rebuilding benefit. |
| Commander and automation | Retain single equipped ability, 300-second effects/600-second cooldowns and permanent 30/60 Essence or 1 Legacy ownership. Manual boosts require lifetime hero level 22; automation requires 45/60 and costs 1/2 Legacy once, never per activation. Aim for a useful convenience/throughput benefit without mandatory clicking. |
| Routes and profiles | Require unlocked tier 3 for 1 Legacy route ownership; retain eight templates/profiles and existing safe offline travel rules. These reduce management friction; they do not create income independently. |
| Collections and hunt talents | Preserve verified sources, eligibility, independent rolls and earned bonuses. Double the relative chance bonus per talent rank to 20%, at unchanged 1/2/3 Legacy prices. Hunting remains optional permanent progression. No failure counters or guaranteed discovery. |
| Ordinary prestige | Keep `floor((runBest - 1)/3)` Legacy and two percentage points of permanent party power per Legacy earned. Existing strength is preserved. Short and deeper rebuilds should have comparable power per minute, so resetting at the earliest opportunity is not universally best. |
| Transcendence and Inheritance | Require online defeat of Spire dragonmarshal in Blackrock Mountain with a current level-60 hero; retain, one-time `tier + 1` Inheritance, tier cap 10, permanent purchases and profession-work reset. Higher tiers should be attainable with investment, not a blanket timeout. |
| Offline farming | Keep 24-hour catch-up, quarter-second combat and the same yields, resource/boost rules and safe-route constraints as online. No offline Adventure XP, live collection kills, frontier unlocks or newly learned Runic recipes. |

All prices and chances used in previews still come from the same domain/content functions used by transactions. No new currencies, dependencies, telemetry, daily caps or reset losses are introduced.

## Feature pacing: hands-on play before convenience

Aim for a substantial new layer roughly every 4–6 adventure hours after the opening. This is a pacing target, not a clock gate: levels and unlocked difficulty tiers control access. Early party building, crafting, talents, Growth, collections and ordinary prestige remain available. Manual Commander play precedes automation; route planning and heirlooms are post-60 rewards. Existing purchases, profession ownership, recipes and discovered menu names are retained; no migration removes access.

Before the final-boss requirement replaced any level-60 boss, two fresh 40-hour `balance_journey.lua deep` runs (seeds 17/73, 15-minute check-ins, assumed 8 quests/80 eligible kills/4 nodes per hour) produced:

| Layer | Permanent milestone | Observed adventure hours |
| --- | --- | --- |
| Mastery | Hero 20 | 1.0 |
| Manual Commander boosts | Hero 22 | 6.5 |
| Enchanting | Hero 30 | 10.25–11.0 |
| On-cooldown automation and profiles | Hero 45, then learn automation | 14.0–16.0 |
| Titanforging | Hero 50 | 18.25–19.0 |
| Specializations / conditional automation | Hero 60 | 21.0–21.75 |
| First Transcendence | Current hero 60 and Blackrock final champion | 21.75–22.75 |
| Route planning | Unlock tier 3 | 25.0–26.0 |
| Heirloom recipes | Unlock tier 4 | 27.25–28.25 |

The opening is deliberately denser. The later cadence is still uneven: forging, capstone features and the first tier unlocks sometimes arrive 2–3 hours apart. These runs establish the ordering and remove first-hour convenience purchases; they do not establish a universal 4–6-hour interval. Active play, reset decisions, drops, party composition and Forever collections require playtest calibration. Both runs reached tier 6 by hour 40 with repeated ordinary resets; gates do not make pre-heirloom progression impossible.

The journey logs unlocks and targets Blackrock Mountain once encounter 60 is accessible instead of repeatedly resetting just before the final boss. The times above predate this new endpoint and must be remeasured. All rewards and transactions remain earned; the simulation does not grant unlock entitlements.

## Challenge curve and recurring prestige

The first eight encounter levels are unchanged, preserving recruitment and the level-eight prestige unlock. After eight, health grows by **1.14 per encounter level** and damage by **1.065**, replacing 1.055/1.025. Prestige is intended during the climb, not just after reaching 60. The original balance pass recorded first prestige access around 46–47 minutes; the current-code recheck above records 43–46 minutes. In that original pass, the regular-reset model first chose it at 75 minutes, then completed six chapters by hour six. This is a policy observation, not a forced schedule or unlock delay.

A naked same-level party fails at 20/40/60. At 20, crafted gear plus legal talents clears in 49.75 seconds, while either alone fails. At 40 and 60, crafted gear plus the level-earned talent budget also fails: retained talents, Mastery, heirlooms, Development, modifications and ordinary-prestige power become necessary investments. No new level-training fee, timer gate, combat restriction or reset loss is added.

Difficulty tiers add `1.27^tier * 1.12^max(0,tier-2)` health and `1.18^tier` damage. The extra health slope begins after tier two, leaving early ascensions gentler while preserving later walls. Relentless starts at tier two (2.16-second attacks); Renewal at tier five heals 0.1% maximum health/second after ten seconds; Boss fury at tier eight adds 20% damage after 30 seconds, once. Basic resistance, reward multipliers and Runic tier 2/5/8 requirements remain unchanged.

Mastery cost at current rank `r` is `100 + 50*r + 100*max(0,r-8)^2`. The first eight ranks retain their old prices. Filling all 24 extra level-60 points now costs 140,200 XP rather than 16,200. This preserves early build development while slowing the passive acquisition of every late-tree choice. Existing earned points, selected talents, ranks and partial XP are retained. Offline summaries sum actual prices across rank-ups, including the late premium.

`scripts/balance_matrix.lua walls` checks progression at 20/40/60 and every tier 0–10. Its cumulative funded comparisons show that board rank three alone cannot erase the late wall. Full Mastery, weapon enhancement five, board rank three and 1,000 synthetic prestige strength clear through tier six; additional tested strength of 3,000 clears tiers seven–nine. Tier ten clears at 10,000 synthetic strength with Focused Assault. These large fixture budgets establish a finite tested escape, **not** reasonable acquisition time. The earned journey reaches tier eight in 100 hours; tier-nine/ten acquisition remains an aspirational pacing question for playtests.

`scripts/balance_builds.lua` now explicitly supplies 1,000 prestige strength, eight Mastery ranks, paid equipment and retained work access, across 96 class-composition/profession/level/tier cases. It produces 80 wins and 16 timeouts. Tests require funded baseline/early tiers to remain viable; later timeouts are deliberate walls rather than a reason to flatten the curve again. These fixtures do not establish broad build parity or earned affordability.

## Adventure XP and permanent development

Every 100 account-wide Adventure XP pays 60 Essence. Rank, partial XP, lifetime XP and unspent Essence survive both resets. Idle battles never generate Adventure XP. Rewards remain:

| Activity | XP |
| --- | ---: |
| Eligible creature kill | 1 |
| Skill-eligible herb/ore node | 4 |
| Skill-eligible skin | 0.25 |
| Quest/world quest completion | 20 |
| Eligible boss | 25 |
| Confirmed eligible dungeon completion, in addition to kills/bosses | 40 |
| Character level gained | 5 |

Keep non-gray participation/loot attribution, skill-eligible gathering evidence, per-cast deduplication and explicit dungeon-completion checks. Legacy farming and uncertain eligibility never gain guessed rewards. These rules belong to compatibility adapters; this balance pass does not change their client behavior.

The optional first bundle (one rank in each branch plus Battle Orders) still costs 210 Essence, requiring 400 XP in whole payouts. Modeled affordability is 1.56 hours mixed questing, 1.54 gathering, 1.36 confirmed dungeon play, and 2.13 kill-and-skin play. Counts include assumed travel/downtime; actual rates vary. The activity sensitivity model samples 5,000 variations at 75–125% efficiency. At 100 hours it buys board ranks 5–6 per branch across the active profiles; idle-only earns no Essence and can still progress naturally.

Prices remain `60 * nextRank^2`, ten ranks per branch, 23,100 Essence per branch and 69,300 total. Exact refunds, free milestone switching and investment validation are unchanged. With `f = rank/(rank+4)`, benefits now are:

| Branch | Benefits before unchanged rank-three choices |
| --- | --- |
| Might | `1 + 0.4*f` damage/healing (rank one +8%, rank ten +28.57%) |
| Resolve | `1 + 0.4*f` health, `0.03*f` victory recovery, `1 - 0.15*f` incoming damage |
| Provisioning | `1 + 0.6*f` materials, `1 + 0.5*f` hero XP, unchanged `1 - 0.25*f` equipment cost |

Might previously gave +5% at rank one. New Resolve starts at +8% health/0.6% recovery/3% less damage; Provisioning starts at +12% materials/+10% hero XP. Mastery XP and real activity rewards do not receive these multipliers. Material-family secondary yields remain capped at 25% before shared multipliers, with fractional remainders preserved.

## Collection investment and variance

Collection talent costs stay 1/2/3 Legacy, six per completed talent. Outdoor and dungeon conditions do not overlap. At rank three the source chance becomes `base * 1.6`: 5% → 8% outdoors and 20% → 32% in dungeons. Expected eligible kills per piece fall by 37.5%. Legacy spending never subtracts already earned prestige strength.

`scripts/balance_activity.lua` additionally samples 5,000 five-piece sets per kind/rank using the live purchase and effective-chance functions. This is an independent geometric model with distinct sequential sources; it excludes travel, overlapping sources, dungeon boss availability and repeat visits. It never enables client acquisition profiles.

| Model | Expected kills/piece | Set kills p50/p90/p99 |
| --- | ---: | --- |
| Outdoor, untrained | 20 | 95 / 158 / 230 |
| Outdoor, rank three | 12.5 | 59 / 98 / 143 |
| Dungeon, untrained | 5 | 24 / 38 / 55 |
| Dungeon, rank three | 3.125 | 15 / 23 / 33 |

These are sample quantiles, not guarantees or equal elapsed-time targets for outdoor/dungeon play. Arbitrarily long dry streaks remain possible. Existing collection bonuses, targeting behavior and source verification are unchanged.

## Integrated earned progression and attention

`scripts/balance_journey.lua` starts with one level-one Warrior and zero gold, items, permanent power or talent grants. Recruitment, talent purchases, crafting, enhancement, enchanting, forging, specialization, Commander ownership/automation, heirloom recipes, collections talents, ordinary prestige, ascensions and Inheritance use real domain commands. Every check-in validates a loadable save. Resource income comes from actual fights; optional real activity assumes eight quests, 80 kills and four nodes/hour through the live XP command. No collection kills are fabricated in this model.

Policies compare unmanaged play, investment without resets, early resets, regular deep progression, hourly management, idle-resource-only management and a daily return. The regular policy chooses progressively deeper reset targets (12 plus three per rewarded chapter, capped at 60), or resets after a stalled check-in. It waits for a qualifying online boss when a current level-60 hero is ready, and never repeats a zero-reward ascension just to satisfy a script. These are illustrative policies, not optimal bots or measured player preferences.

| Model | Observed outcome |
| --- | --- |
| Regular, 15-minute visits, seed 17 | First reset at 1.25 hours, frontier 15/hero 20; six ordinary prestiges by six hours, with reset hero levels 15–21. Eighteen by 24 hours. First ascension at 30.75 hours. |
| Same regular model, 100 hours | 29 ordinary prestiges, eight ascensions, tier eight, 438 Legacy and 36 Inheritance earned. Paid 899 crafts, 860 enhancements, 624 enchants and 484 forge steps. About 37.76 hours spent farming at walls. |
| Hourly regular visits, seed 91, 24 hours | 16 ordinary prestiges, 208 Legacy, no ascension yet. Reset observations include hero levels 19–48 long before cap. |
| Idle-resource-only management, seed 17, 24 hours | No Adventure XP/Essence injection; 16 prestiges, 175 Legacy, frontier 61 and hero level 49 at the endpoint. Legacy buys Commander ownership when Essence is unavailable. |
| Investing without prestige, seed 17, 24 hours | Caps hero levels but reaches only frontier 54 under the bounded purchasing policy. Waiting and routine purchases do not bypass the prestige curve. |
| Daily return | One hour online plus 23 hours of actual catch-up farms an already safe encounter. Hero levels can grow offline, but new frontiers and ascension completion still require online play. |

The 100-hour policy still accumulates substantial gold (981,140 in seed 17; 918,631 in seed 91) because its purchases stop at enhancement five/forge two and it does not optimize every material route. Seed 91 independently reaches tier eight with 33 ordinary prestiges/eight ascensions and 517 Legacy/36 Inheritance earned. A separate endpoint intervention spends that **same account's** available stock toward enhancement twenty/forge five: 900 paid modifications consume 862,278 gold and turn its failed tier-eight level-60 encounter (180-second timeout) into a 102-second victory. This establishes an earned, non-waiting escape from that wall. It does not establish acceptable management effort: 900 modifications would be substantial player input, and the model does not simulate a human performing them. The 24-hour no-prestige account has no affordable modification at its wall despite surplus gold, identifying a material-route bottleneck instead. Neither accumulation nor one intervention proves every endgame sink is balanced. Commands count successful domain calls, including repeated configuration, rather than observed clicks. Real management burden and the best reset moment remain playtest questions.

The current no-reset `balance_profiles.lua` policy reaches hero levels 27–31 and frontiers 37–42 after six hours, across idle-only/mixed/hunting profiles and three seeds. Its easy-talent ordering and infrequent purchases are deliberately distinct from the integrated strategy. Earlier results reaching level 60 in six hours used the flatter curve and no longer describe this build.

## Class, profession, Commander and destination comparisons

- **Classes/resources:** `balance_matrix.lua builds` covers all nine classes, three initial talent-path orders, levels 20/40/60, tiers 0/5 and resource thresholds 0/50/90: 486 cases. The declared 1,000-strength/eight-Mastery funded budget wins all 243 base-tier cases and 162/243 tier-five cases. Candidate damage/healing rates expose role tradeoffs; tank/healing paths should not be judged solely by DPS. The matrix is not an exhaustive search of mixed talent allocations or party permutations.
- **Professions:** `balance_matrix.lua professions` compares all 27 combinations of crafting branch, forge branch and enchant type at declared late-game power. Eighteen clear tier eight; nine defense-enchant choices time out in this offensive fixture. Efficiency lowers expenditure, precision/quality improve power, utility improves cadence, and defense trades damage for survival. The heirloom branch intentionally offers no discount to ordinary items; its retained-item discount and reset behavior are covered by the existing profession/reset tests. No branch is made universally equal in one task.
- **Commander:** `balance_matrix.lua boosts` compares all four abilities, both offensive/support parties, tiers 0/5/8/10 and none/on-cooldown/boss/low-health policies: 128 half-hour runs. It starts from declared cleared encounters instead of allowing a failed high-tier case to fall back to an unearned level-one benchmark. Ownership/automation costs are paid once and recurring fees are asserted absent. Offense boosts improve throughput; defensive boosts need incoming-damage pressure to have value. These results do not establish a single best trigger or equal performance for every ability.
- **Destinations:** `balance_matrix.lua zones` compares all 41 destinations for ten simulated minutes, with common level-60 gear/power and the same absolute starting encounter level. It reports gold, primary/secondary material rates, upgrade drops and defeats. Gold/combat curves are shared; material-family output and curated item pools differentiate routes. No map geometry or client artwork changes are involved. The equipped late-game fixture has no useful low-level loot upgrades; this does not prove that early-zone loot is irrelevant to leveling heroes.
- **Collections:** `balance_hunts.lua` uses the actual Forever piece-to-NPC overlap, real `CollectionKill` transactions and all catalog sets at ranks zero/three, 1,000 samples each. It models outdoor kills at 120/hour plus ten minutes per source-zone visit; dungeon sources appear once per assumed 45-minute run. Outdoor shared sources can roll several missing pieces per kill. For Redridge, median completion is 55/35 kills and 0.96/0.79 hours untrained/trained; Defias is 37/21 listed-source kills and 7.5/4.5 hours. Travel, source availability and dungeon cadence are assumptions, not client measurements. Full collection passive bonuses cap at 5% each; only one completed-set effect is active. Every selectable effect is checked against matching-family defense/basic/material bounds. Retail source profiles remain disabled; these hunts cannot be validated through Retail drops.

The one-time tier-zero-through-ten Inheritance supply is 66; both five-rank permanent branches cost 30 total. The remaining 36 is finite completion surplus, not a growing faucet or a new mandatory sink. Short resets intentionally yield Legacy without earning high-tier recipes or Inheritance. Their time/attention opportunity cost remains visible in the journey comparisons; no reset cooldown was added.

## Persistence and verification

No save schema or purchase receipt changes are required. Mastery prices change only future requirements; earned ranks and partial XP are preserved. Existing Development investment/refunds, collection talent ranks, prestige strength, forgePower, enhancements, profession work and heirloom modifications remain intact. New benefits apply to existing ownership; new prices apply only to future purchases. The historical economy migration remains unchanged: only evidenced retired training/enhancement/enchantment purchases receive credits, with zero guessed fallback. No retroactive refund is issued for prior gold/material purchases.

Run from the repository root:

```sh
lua scripts/test.lua
lua scripts/balance_activity.lua
lua scripts/balance_builds.lua
lua scripts/balance_profiles.lua
lua scripts/balance_profiles.lua 100 3600 17
lua scripts/balance_scenarios.lua
lua scripts/balance_rebuild.lua
lua scripts/balance_automation.lua
lua scripts/balance_journey.lua 100 deep 17
lua scripts/balance_journey.lua 24 casual 91
lua scripts/balance_journey.lua 24 builder 17
lua scripts/balance_journey.lua 24 returning 17
lua scripts/balance_matrix.lua walls
lua scripts/balance_matrix.lua builds
lua scripts/balance_matrix.lua professions
lua scripts/balance_matrix.lua boosts
lua scripts/balance_matrix.lua zones
lua scripts/balance_hunts.lua 1000
```

The profile arguments are horizon hours (1–100), check-in seconds (60–86400), and optional single seed. Longer runs expose savings/stalls under a policy that never resets; they are not an optimal endgame strategy. The activity model projects 100 hours of real-activity income independently of combat policy. Compare results before changing coefficients again.

For a few-hour Retail session, record first prestige unlock, first chosen reset, reset frontier/hero levels, and how soon the next wall arrives. Try one blocked boss after an equipment/build change, then compare a prestige rebuild. Review prestige should open the existing review without spending or resetting. Check a fresh party through recruitment and prestige, compare craft/enchant/forge quotes against actual deductions, buy/refund a Development rank during combat, reload an existing invested save, and compare visible/offline safe-farm rewards. Exercise tier-five Renewal and a tier-eight boss with both offensive and defensive parties. Simulator tests cannot validate live activity attribution, 3D rendering or actual player pacing. Forever simulator/client validation remains deferred until its testing setup is updated.

Final-boss recheck: a fresh 40-hour deep journey with seed 17 reached first Transcendence at 22.75 hours, routes at 26.5 hours, heirlooms at 29.75 hours, and tier 6 by hour 40. This is one simulation seed, not live-client evidence. Readiness now requires the designated Blackrock final champion; older saves retain their earned tiers and purchases but must defeat that boss to earn current-cycle readiness again.
