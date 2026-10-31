# Adventure XP balance

## Role and persistence

Real WoW activities fill one account-wide Adventure XP bar. Every 100 XP raises Adventure rank and awards 60 Essence. Excess XP carries into the next rank, including quarter points from skinning. The requirement and payout stay constant so a high account rank does not make the same activity worth less over time.

Adventure rank, partial XP, and unspent Essence survive prestige. Idle battles supply hero experience, gold, equipment, and materials. They do not generate Adventure XP. Essence funds meaningful upgrades such as raising a hero's idle level cap, targeted crafting, equipment improvements, and heirlooms.

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

## Upgrade affordability

The first level-cap increase costs 120 Essence, requiring two rank rewards, or 200 Adventure XP. At 200–300 XP/hour this takes 40–60 minutes.

A representative first-party investment costs 740 Essence:

- Five first level-cap increases: 600 Essence.
- Ten first item improvements on separate items: 80 Essence.
- Five ordinary level-4 crafts: 60 Essence.

Whole-rank payouts require 1,300 XP to afford this bundle. The modeled questing, gathering, and dungeon profiles reach it in approximately 4.4–5.4 hours. The estimate covers Essence only; gold, materials, hero progression, and actual combat success still matter. It does not establish the final first-prestige timing.

## Reproducible checks and tuning

Run `lua scripts/balance_activity.lua`. It reads the live reward and upgrade-cost definitions, projects 100 hours, and samples 5,000 efficiency variations per profile at 75–125% of the assumed rates. It also reports how many party-wide training tiers the projected income can fund after the initial bundle. These results are a sensitivity model, not a substitute for playtesting.

Adventure progress stores per-source activity counts and XP totals. Use timed playtests to compare those totals against the assumptions, including dense pack farms, fast quest turn-ins, repeated quests, level scaling, and long manual dungeon runs. Keep these weights provisional until observed rates support them. Do not infer extra rewards from signals the client cannot verify.
