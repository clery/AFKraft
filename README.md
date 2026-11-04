# WoWIdle

**Your adventures. Their growing legend.**

An account-wide idle party RPG inside World of Warcraft. Build a company of five heroes, fight through Azeroth, and improve their equipment and builds while playing your own character.

**Early playable prototype.** Retail is the current development and simulator client. Forever is the intended content target; its maps, visuals and live activity signals still need integration and testing.

## Distribution

Forever is the only planned release target. Retail remains a development client;
no Retail distribution is published. Packaging does not establish Forever readiness.
See [packaging and release checks](TOOLING.md#packaging) before preparing a release.

## Getting started

1. Put the `WoWIdle` folder in your client's `Interface/AddOns` directory, with `WoWIdle.toc` directly inside it.
2. Enable the addon and log in. Restart WoW if you installed it while the game was running.
3. Enter `/wowidle` or `/wi` to open the adventure. Follow the dismissible starter guide.

Libraries are bundled. Your characters share one saved adventure; idle hero levels, equipment and currencies are separate from your real WoW character.

## Party and battles

Start with one hero. Defeat milestone bosses at encounter levels **1, 3, 5 and 7** to discover companions, then choose their classes in **Party**. All nine original classes are available, including duplicates. Companion discoveries and recruited heroes survive resets. Loading the addon on an alt lets that character replace a generated companion of the same class.

Combat is automatic. Equipment, talents, targeting and ability priorities shape each hero's role. Change them during battle without resetting health proportions or cooldowns. Heroes gain levels naturally to **60**; no Essence or paid training is required. Each class has three **18-talent** trees, with free respecs and permanent earned points.

**Mastery** unlocks permanently at hero level **20**. Victories at or above that hero's hardest completed encounter in the current difficulty earn Mastery XP; bosses award double. Each rank adds a permanent talent point, up to the tree's 54-point total. Easier rebuild encounters cannot farm Mastery points. The Talents bar shows current XP and the next rank cost.

Choose among **41 outdoor destinations** on the Kalimdor and Eastern Kingdoms maps. Destinations differ in scenery, enemies, equipment pools and materials. Cities, dungeons and raids are not idle destinations. Travel abandons the current encounter without rewards and preserves health. After a defeat, the party farms a safe encounter; improve its build and use **Retry frontier** to push again.

## Real WoW activity and Essence

Every **100 Adventure XP** awards **60 Essence**. Spend Essence on permanent party bonuses in **Growth** or learn abilities in **Commander**. Growth ranks can be refunded for their exact Essence cost.

| Eligible activity | Adventure XP |
| --- | ---: |
| Creature kill | 1 |
| Herb or ore node | 4 |
| Skinning | 0.25 |
| Quest completion | 20 |
| Boss | 25 |
| Confirmed dungeon completion | 40 bonus |
| Character level gained | 5 bonus |

Kills and bosses must be within your XP range; gathering must be skill-up eligible. Gray kills, legacy boss farming and unconfirmed completions award no XP. Credit depends on client evidence and still needs live validation. Hero XP comes from idle battles instead.

## Equipment and Forge

Each hero has **10 wearable slots**. Drops have fixed Classic item stats; class proficiencies and idle level requirements apply. **Power** estimates item value for the selected class, not damage per second. Compare items, equip individual upgrades, or use **Equip best power** in Party.

**Forge** crafts targeted equipment with gold and idle materials. Enhancement adds **10% of base stats per purchase**. Enchanting unlocks when a hero first reaches **30**, titanforging at **50**, and profession specializations at **60**. Enchanting replaces the current enchantment; titanforging has five potential tiers. Previews show outcomes and costs before purchase. Heirloom recipes open at difficulty tier **4** for **1 Heritage per slot**. Heirloom investments survive both resets.

Every zone has its own **boss trophy**: each idle boss victory guarantees one. Enchantments and titanforging consume specific trophies in addition to their existing costs. Forge previews show the source and your stock; **Farm** repeats an earned boss checkpoint, while **Travel** lets you clear a source for the first time. Map tooltips show each zone's trophy. Trophies survive both resets, and cleared bosses can supply them offline. These are addon resources, not real WoW inventory items.

Identical ordinary items stack. Loot rules salvage unwanted future drops; **Disenchant** destroys stored equipment for gold and Relic dust. Equipped gear, heirlooms and protected items are kept. **Disenchant all** includes unprotected upgrades across every page and filter.

Empty torso, leg and foot slots use cosmetic clothing with no stats. Exact offline alt appearances and matching equipment visuals remain unfinished. See [item rules and sources](Content/ITEMS.md) for formulas and unsupported item effects.

## Commander, routes and collections

At lifetime idle level **22**, learn one of four party boosts permanently with Essence or **1 Heritage**. Equip one at a time: effects last **5 adventure minutes**, with a **10-minute cooldown from activation**. Uses are free. At lifetime idle level **45**, learn on-cooldown automation for **1 Heritage**; level **60** opens conditional automation for **2 Heritage**. Enable both **Automation** and **Auto-cast** to use it.

Unlock difficulty tier **3** to learn route planning for **1 Heritage**. Save destinations and milestones, then enable the route to travel between encounters. Manual travel pauses it until Resume. Profiles save your boost, automation, route preferences and selected collection effect without restoring currencies or cooldowns.

**Collections** come from eligible kills by your real WoW character. Hover a piece for its creature families, locations and chance. Each kill rolls independently; no discovery is guaranteed. Passive discovery bonuses survive both resets, and a completed set unlocks a selectable effect. Only one set effect can be active. Fieldcraft and Relic Hunter improve outdoor and dungeon chances respectively; each has three permanent ranks costing **1, 2 and 3 Heritage**.

Collection acquisition is enabled only for the verified Forever source profiles and still needs live-client testing. Retail hunting remains disabled. Idle battles, crafting and offline farming never discover collection pieces.

## Resets and permanent progress

Defeat a **level 8 milestone boss** to unlock ordinary prestige in **Heritage**. Review the exact reward and losses before confirming. Current tuning aims for first access in **45–60 minutes**; this is a simulation target, not a required reset time or playtested promise.

| Progress | New chapter | Transcendence |
| --- | --- | --- |
| Hero levels/XP, ordinary gear, gold, materials and run progress | Reset | Reset |
| Profession work ranks/XP | Kept | Reset; allocation plan kept |
| Heroes, talents, earned points, Mastery and Growth | Kept | Kept |
| Adventure rank/XP, Essence, Heritage, heirlooms and recipes | Kept | Kept |
| Boost ownership, cooldowns, automation, profiles, routes and collections | Kept | Kept |
| Active boost effects | End | End |

New chapters award Heritage and permanent party strength. Each Heritage earned adds **2 percentage points** to party health, damage and healing. Spent Essence is not refunded.

**Transcendence** requires a current level-60 hero and an online victory over **Spire dragonmarshal**, the final Blackrock Mountain champion, in that cycle. Choose an unlocked tier and review the deeper reset. Each completed tier pays Inheritance once, funding permanent rebuilding bonuses. Both reset types remain manual.

## Returning and window controls

The adventure continues while its window is closed. On the next login, up to **24 hours** of safe offline farming is calculated and applied automatically. No code runs while WoW is closed. Offline routes default off; when enabled, they visit only checkpoints cleared in the current run and tier before departure, with at most **12 transitions**. New progression and resets wait for you.

Switch between fullscreen, windowed and compact views using the top-right controls. Drag the top edge to move a window and the bottom-right grip to resize it. Compact mode has a lock and an accessible unlock control; management opens a larger view. Menus reveal their names and icons as features are discovered.

**Settings → AddOns → WoWIdle** controls display, locking, chat and sound. Audio uses WoW sound-effects volume and plays only while the adventure is visible. **Reset all adventure progress** permanently erases the shared account adventure, including Heritage and heirlooms; display and audio preferences are kept.

## Development status

The accepted gameplay systems are implemented. Remaining work is Forever integration, live reward/save/visual checks, pacing and management-effort playtests, then broader UI polish. Collection timing and high-tier affordability remain provisional.

See [design](DESIGN.md), [balance evidence](BALANCE.md), [architecture](ARCHITECTURE.md), [tooling](TOOLING.md), [map maintenance](MAPS.md), and [remaining work](HANDOFF.md).

## License and credits

WoWIdle uses an **All Rights Reserved** notice. See [LICENSE](LICENSE).

Bundled third-party libraries retain their own licenses and notices; see [embedded libraries](Libs/README.md). Landscape artwork sources and credits are listed in [backdrop credits](Assets/Backdrops/SOURCES.md). The project notice does not replace those third-party terms.
