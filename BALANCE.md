# Adventure XP balance

## Role and persistence

Real WoW activities fill one account-wide Adventure XP bar. Every 100 XP raises Adventure rank and awards 60 Essence. Excess XP carries into the next rank, including quarter points from skinning. The requirement and payout stay constant so a high account rank does not make the same activity worth less over time.

Adventure rank, partial XP, and unspent Essence survive prestige. Idle battles supply hero experience, gold, equipment, and materials. They do not generate Adventure XP. Essence funds permanent party development and learned Commander abilities. Heroes grow naturally to 60. Gold and idle materials fund crafting, enhancement, enchantments, titanforging and heirloom production.

Existing version-one saves retain their currency, hero experience, equipment, and discoveries. The new bar starts at rank 1 with zero XP: earlier activity already paid rewards and is not credited a second time.

## Initial reward weights

| Activity | Adventure XP | Rationale |
| --- | ---: | --- |
| Eligible creature kill | 1 | Frequent baseline; non-gray credited kills remain eligible at character level cap. |
| Herb or ore node | 4 | Includes finding and traveling between eligible nodes. |
| Skinning | 0.25 | A small additional reward after the kill; four skins equal one kill. |
| Quest completed | 20 | Includes objectives, travel, and turn-in time. World quests use the same completion signal. |
| Eligible boss defeated | 25 | Recognizes encounter effort and coordination. |
| Confirmed dungeon completion | 40 bonus | Added to its kills and bosses, rather than replacing them. |
| Character level gained | 5 bonus | Small milestone reward; most leveling effort already receives kill and quest XP. |

The shared bar makes small activities immediately visible without issuing currency for every event. There is no daily earning cap. Rates live in `Content.lua`.

## Eligibility and duplicate handling

- Kills require combat-XP delivery or readable non-trivial unit evidence with participation or loot credit.
- Mining, herbalism, and skinning require a successful gather whose pre-cast difficulty can grant profession skill: orange, yellow, or green. A matching actual skill-up can confirm eligibility when difficulty is unavailable. Multiple signals for the same cast pay once.
- Bosses use observed non-gray status before death, matching the player's XP eligibility and current scaling. Cached encounter evidence survives the boss frame disappearing.
- Dungeon completion requires an explicit completion signal and an eligible boss in the current run. A verified current-instance recommended level bracket is the fallback when boss evidence is unavailable. Portal admission limits are not treated as recommended levels. Legacy farming and unverified eligibility do not award boss or completion XP.
- The completion bonus is available only where the client confirms completion. Manual runs still receive eligible boss rewards; leaving an instance does not prove completion.

## Time and effort model

These are design assumptions, not measured player statistics. Counts include travel, loot, grouping, and other downtime. Individual routes, classes, gear, and dungeon lengths will vary.

| Play style | Assumed activity per hour | XP/hour | Essence/hour, long-run average |
| --- | --- | ---: | ---: |
| Mixed questing | 8 quests, 80 kills, 4 nodes | 256 | 153.6 |
| Herb / ore route | 60 nodes, 20 kills | 260 | 156 |
| Kill and skin | 150 kills, 150 skins | 187.5 | 112.5 |
| Dense skinnable packs | 240 kills, 240 skins | 300 | 180 |
| Confirmed dungeon | 80 creature kills, 4 boss bonuses, completion per 45 minutes | 293.3 | 176 |
| Manual dungeon | Same run, without an exposed completion signal | 240 | 144 |
| Pure mob farming | 180 kills | 180 | 108 |

Skinning is a supplemental reward to combat. At the dense-pack assumption, 1 XP per skin would raise income to 480 XP/hour; quarter points keep it at 300. Dedicated gathering and ordinary questing remain competitive. Optimized play can earn more; the goal is to avoid a universally dominant routine, not force identical hourly returns.

## Permanent development affordability

The optional first bundle is one rank each in Might, Resolve and Provisioning (60 Essence each), plus Battle Orders (30): 210 Essence. Whole-rank payouts require 400 Adventure XP. Modeled mixed questing reaches it in 1.56 hours, gathering in 1.54, and a confirmed dungeon profile in 1.36. Idle-only play does not earn Essence and has no paid level or equipment gate; Legacy remains an alternative for Commander ownership.

Each Development branch has ten ranks. Its next rank costs `60 * nextRank^2`; a complete branch costs 23,100 Essence, and all three cost 69,300. Benefits use a diminishing `rank / (rank + 4)` curve. Rank three offers a free two-way milestone choice. Refunding ranks returns their exact Essence investment; learned capabilities are never refunded or revoked.

Might improves damage/healing; Resolve improves health, incoming damage and post-victory recovery; Provisioning improves material yield, hero XP and equipment costs. Mastery XP and real-activity rewards remain separate. Combined discounts leave all equipment transactions with positive gold/material costs. Crafting consumes at least five materials, exceeding the maximum four Ore recovered from a crafted item's salvage. No equipment operation returns Essence.


## Reproducible checks and tuning

Run `lua scripts/balance_activity.lua`. It reads the live reward, Commander and Development definitions, projects 100 hours, and samples 5,000 efficiency variations per profile at 75–125% of the assumed rates. It reports optional-bundle affordability, acquired board ranks and unspent Essence, including an idle-only profile. These results are a sensitivity model, not a substitute for playtesting.

Adventure progress stores per-source activity counts and XP totals. Use timed playtests to compare those totals against the assumptions, including dense pack farms, fast quest turn-ins, repeated quests, level scaling, and long manual dungeon runs. Keep these weights provisional until observed rates support them. Do not infer extra rewards from signals the client cannot verify.

## Permanent talents and Mastery

Character levels stop at 60. Each hero retains selected talents, earned points, and their highest level through ordinary prestige. Higher personal level records award a point every two levels, starting at level 1, for up to 30 level-earned points. Repeating old levels and respeccing do not award new points or change Mastery prices.

Mastery unlocks permanently at hero level 20 and uses its own rank and XP bar. Every victory records that hero's highest completed encounter level for the current difficulty tier. Victories at or above that frontier award the encounter's base XP with the tier's Mastery multiplier, doubled for bosses; easier encounters award none. Frontiers survive both resets; existing records migrate to tier zero. Hero-XP rebuilding purchases do not multiply Mastery XP. This rewards pushing harder encounters while permitting steady progress at the current frontier, including offline farming and character-level caps.

Mastery rank-ups grant one permanent talent point. The first costs 100 XP, with 50 XP added to each subsequent price. Eighteen ranks cost 9,450 XP in total; alongside 30 level-earned points, they fill the current 48-talent budget. Reaching level 60 is not required before earning Mastery points. Once all points are earned, further talent Mastery gains stop. Constants live in `Content/TalentTraits.lua`.

Existing saves retain allocated and unspent talent points. Old hero levels above 60 become Mastery ranks once on load, preserving the existing talent budget; older resets that already discarded talents cannot be reconstructed.

## Combined progression feasibility

Run `lua scripts/balance_rebuild.lua` for actual ordinary prestige, same-tier Prestige+ control and next-tier Prestige+ rebuilds. Two seeds, two-hour horizons and 15-minute check-ins are replayed exactly. A declared level-60 established-account fixture pays for its board, heirloom recipes/equipment and weapon modifications through real commands, then loses ordinary resources through real reset commands. Retention, paid rebuilding and deterministic results are asserted. Setup funding is synthetic; no resources or real activity are injected after reset. Ordinary Legacy strength, deeper-reset profession losses and the next tier's challenge/rewards differ deliberately and are disclosed.

Both seeds regain frontier 60 after 37.18 minutes for ordinary prestige, 43.38 minutes for same-tier Prestige+ and 53.93 minutes for tier-one Prestige+. Final frontiers are 91/85/79. Ordinary prestige pays 19 Legacy; either first deeper reset pays one Inheritance. The policy buys 4/6/6 crafts respectively. All 40 weapon-modification quotes per scenario defer because this initial-zone policy earns no Relic dust. This is a source/route-policy bottleneck, not evidence that modifications are globally unaffordable. No acquisition-time, measured player-attention or balanced-reset-loop claim follows from the fixture.

Run `lua scripts/balance_builds.lua` for 64 build/profession cases, each replayed exactly: two party compositions, unallocated/specialized profession plans, levels 40/60, tiers 0/2/5/8 and two seeds. Equal initial budgets fund real craft/enchant/forge commands; the script checks each quoted payment. Lifetime profession access at 60, retained work rank 7, prestige strength 40 and eight Mastery ranks are synthetic fixture assumptions, including for the level-40 cases. They do not establish acquisition time.

This matrix produces 44 wins and 20 timeouts, with no wipes. Every tier-8 case times out. Level-60 tier-5 support/survival cases also time out; mixed-offense cases clear in 69 seconds without allocations and 57.25 seconds with specialization. All level-40 tier-5 cases clear in 47–108.25 seconds. Both seeds agree in these fixtures. Paid costs per party are 120,000 gold/3,150 Ore/850 Relic dust at level 40 and 176,000/4,150/850 at level 60. The selected branches improve power rather than reducing these costs. These bounded boss checks identify comparison targets; they do not diagnose every damage, healing or resource bottleneck or prove broad build viability.

Run `lua scripts/balance_automation.lua` to compare no activation, manual boss-entry activation, on-cooldown automation and conditional boss rules from identical level-20 mixed-party snapshots. Three fixed seeds and 15-minute/one-hour horizons are replayed exactly; assertions cover paid transactions, activation deadlines, encounter accounting and absence of recurring fees. Active and combat-active seconds integrate the actual per-step boost fractions. The fixture supplies starting resources and uses real purchase/crafting commands; it does not measure acquisition time or player attention, and makes no later equipment, talent or reset decisions.

In this fixture, all three seeds produce 101 one-hour victories without activation, 104 with manual boss-entry or conditional-boss use, and 105 with on-cooldown use. All reach frontier 37 without defeats. Manual boss observation makes 21 attempts for five successful activations, matching the conditional policy's five uses and 1,378.5 combat-active seconds. On-cooldown makes six activations and supplies 1,660.5 combat-active seconds without scripted manual attempts. These results compare one basic-attack boost and one party policy; they do not establish broad build balance or a universally preferred rule.

Run `lua scripts/balance_scenarios.lua` for bounded, fixed-seed combat and reset scenarios using the live simulation. The fixtures provide five mixed-class heroes, legal talent allocations, same-level crafted equipment, and natural growth without training resources. They test feasibility; supplied equipment and currency do not establish acquisition time or measured player behavior.

Enemy health and damage retain their original curves through encounter level 8. Above 8, each level multiplies health by 1.055 and damage by 1.025, anchored to the level-8 values. The previous uninterrupted 1.16/1.12 curves produced a level-60 boss with 38.1 million health and 268,317 damage per hit, preventing the capstone progression required for Prestige+ even with a developed party.

With eight retained Mastery points per hero and no boosts, the fixed mixed-party fixture defeats the level-60 boss in 26.75 seconds at base difficulty and 42.75 seconds at tier one. Forty equivalent prestige bonuses reduce those times to 12 and 18 seconds. These are provisional checks for this build and seed; other parties, equipment budgets, higher tiers, and actual-client play need testing. The regression suite preserves opening combat exactly and checks that base and first-tier capstones remain attainable.

Tier modifiers, profession investments, collection bonuses, and temporary boosts affect idle rewards and combat only. Real-activity Adventure XP and its Essence payout remain unchanged. Prices, collection guarantees, and higher-tier multipliers remain prototype values.

Ordinary prestige now adds two percentage points of permanent party health, damage, and healing per Legacy earned, independently of spending that Legacy. Existing saves retain their previous party bonus through a one-time `prestigeStrength` migration. Rewarded chapter count remains a separate record. Empty resets and Prestige+ add no ordinary prestige strength. In the retained-talent/heirloom fixture, level-8 and level-20 reset loops earn approximately 1.52 and 1.53 percentage points per simulated minute, compared with the former roughly threefold short-reset advantage. The fixture supplies retained equipment and talents, but needs no training currency; actual acquisition and rebuild costs still need playtesting.

## Economy migration

`economyVersion = 1` distinguishes the natural-growth economy from older saves. Migration operates on a copy and commits credits only after validation. Current-cycle training rank `r` proves `60*r*(r+1)` Essence and `80*r` gold. Retained enhancement rank `n` proves `8*n + 5*n*(n-1)/2` Essence per unit; a retained enchantment proves one historical fixed-price 15-Essence application. Duplicate item identities count once.

Crafting discounts, forging discounts, earlier enchantment replacements, discarded items and previous reset cycles lack complete receipts. Their documented conservative fallback is zero credit. Items without a valid stable identity likewise receive no guessed equipment credit. Existing gear, modifications, hero/Adventure progression, currencies and learned capabilities remain; migration never marks credited Essence as newly earned real-activity XP. The saved migration report is inspectable on Development, and repeated loads/resets never pay it again.

Tier affixes currently add a fixed 2.16-second enemy attack interval at tier 2, 0.2% maximum-health regeneration per second after 10 seconds at tier 5, and a one-time 20% boss damage increase after 30 seconds at tier 8. They add no separate reward multiplier. Regeneration is capped at maximum health, excludes dead enemies, and does not extend the 180-second encounter limit.

The fixed level-60 scenario with 40 retained prestige strength and eight Mastery ranks wins at tier 2 in 26.75 seconds and tier 5 in 133 seconds, but times out at tier 8. This exposes a high-tier pacing gap for that party, not a validated target or a claim that every tier is attainable at this investment. Broader Mastery/development/profession budgets and class compositions still need comparison before tuning these coefficients.

Runic recipes currently unlock from online level-20+ bosses at tiers 2/5/8. Their offense/defense/utility bases are 8 attack/spell power, 10 stamina plus 32 armor, and 5 spirit plus 4 haste, scaled through existing item-level and specialization rules. Fragment costs are 3/5/8 per application, alongside ordinary gold/material costs. One fragment per eligible tier 2+ level-20+ boss is capped at 1,000; fragments reset with the run and never convert back from an enchantment. Recipe ownership and heirloom investments persist. These are provisional optional late-cycle sinks; combined high-tier recipe, affix and profession pacing still needs comparison.

### Encounter resources

Idle resources are authored simulation rules, not live character resources. Warrior Rage starts empty, gains 15 per basic swing and 5 per damaging hit received, and costs 20/15/30 for strike/recovery/special. Rogue Energy starts at 100, regenerates 8 per second, and costs 45/30/60. Other supported classes use 100 Mana, regenerate 4 per second, and pay 30/20/40. Regeneration is capped at 100; pools reset each encounter. A per-hero percentage threshold applies before payment, without delaying basic attacks or consuming ability cooldowns when unmet. Values remain provisional.

The fixed-seed mixed-party scenario with no prestige, boosts or supplied training reaches encounter 8 in 160 seconds, 12 in 262.75 seconds, and 20 in 476.5 seconds. Same-level geared level-8 parties beat base and first-tier milestone bosses in 7.25 and 12.75 seconds respectively. These feasibility checks do not establish parity between class compositions or final high-tier pacing.

### Combined progression profiles

Run `lua scripts/balance_profiles.lua` from the repository root. Seeds 17, 91 and 403 each simulate six online idle hours, with checkpoints at 15 minutes, one hour and six hours. The common policy checks in every 15 minutes, recruits available companions, allocates legal talents in catalog order, equips usable upgrades, crafts one affordable improvement per hero, buys one affordable Development rank per branch, and retries failed frontiers. It supplies no equipment, currency, training, prestige bonuses or automatic resets. This is one policy rather than optimal play.

| Profile | Assumed real activity per hour | Six-hour hero level range | Six-hour Development M/R/P | First prestige unlock |
| --- | --- | --- | --- | --- |
| Idle only | None | 50–51 | 0/0/0 | 0.77–0.79 hours |
| Mixed play | 8 quests, 80 kills, 4 gathers | 55 | 2/2/2 | 0.77–0.78 hours |
| Focused hunt | 150 kills | 54–55 | 2/1/1 | 0.79 hours |

Mixed play earns 1,536 real-activity XP over six hours; focused hunting earns 900. Idle-only earns zero Adventure XP and makes substantial natural hero/equipment progress. Under this policy the first Development rank is bought after 30 minutes of mixed activity or 45 minutes of focused hunting. No activity is required to unlock ordinary prestige. The observed 46–47-minute unlock contradicts the provisional 4–6-hour first-prestige target; the model measures access, not a player's decision to reset. Do not claim that target is met or delay the unlock without checking the intended early-game experience.

Collection comparisons are explicitly synthetic: one hypothetical source per piece, 5% addon chance, sequential hunting of the next missing piece, and eligible hunt kills as a subset of the profile's activity kills. No Retail or Forever source is enabled by this script. Mixed play assumes 12 eligible hunt kills per hour; focused hunting assumes 120. Earlier completion-time measurements used a retired 30-kill guarantee and no longer establish current acquisition pacing. Independent rolls have an unbounded long tail; rerun these profiles and measure broader distributions before claiming balanced completion times. Source verification, representative builds, commander/profession policies and observed check-ins remain required before coefficient tuning.

### Legacy collection talents — balancing pending

Hypothesis: optional Legacy investment should modestly shorten collection hunts without changing source eligibility, equipment loot, or the independence of each kill. Fieldcraft applies to eligible outdoor collection kills; Relic Hunter applies to eligible dungeon collection kills. Each has three permanent ranks, provisionally priced at 1/2/3 Legacy (6 total per talent). Each rank adds 10% of the base collection chance; these two conditions never overlap. Learned ranks survive ordinary prestige and Prestige+. These values are implementation placeholders, not a balanced progression target.

| Current source profile | Base chance | Rank 1 | Rank 2 | Rank 3 | Expected eligible kills per piece, base → rank 3 |
| --- | --- | --- | --- | --- | --- |
| Outdoor | 5% | 5.5% | 6% | 6.5% | 20 → 15.38 |
| Dungeon | 20% | 22% | 24% | 26% | 5 → 3.85 |

Expectations use `1 / p` for independent geometric rolls, excluding travel, source availability, overlapping piece sources and duplicate signals. They are analytical means, not completion guarantees or live measurements. Rank three reduces expected eligible kills by about 23%, while arbitrarily long dry streaks remain possible. Tooltips and rolls use the same chance, rounded to a basis point. The combined-profile script models the untrained baseline and does not purchase these talents.

Before tuning, compare untrained and ranked median/p90/p99 eligible kills and elapsed hunt time, total-set completion distributions, outdoor versus dungeon access and travel, Legacy earning/spending opportunity costs against recipes and other unlocks, and actual talent uptake. Validate attribution and persistence in supported clients. Tune costs, rank count and relative bonus together; never restore saved failure progress or a guaranteed discovery threshold as a balancing shortcut.

### Secondary family spoils

Explicit encounter family tags add secondary materials while preserving the destination's base yield. Humanoids yield timber; beasts/dragonkin/critters hide; machines/giants ore; elementals/undead/demons Relic dust. Each tagged enemy contributes `base yield * 0.25 / enemy count`; total secondary output is capped at 25%, including boss encounters. Collection, Development and tier material multipliers apply once to both outputs; existing per-material fractional remainders preserve small awards online/offline. Untagged enemies add no guessed output. All 41 destinations have aligned enemy and boss profiles; appearance records without type evidence stay unknown. Values remain provisional. Combined-profile comparisons must account for this extra material income.
