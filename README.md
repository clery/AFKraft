# WoWIdle

**Your adventures. Their growing legend.**

WoWIdle is an idle party RPG inside World of Warcraft. Build a company of five heroes, watch them battle through Azeroth, and help them grow while you play your own character. Collect equipment, craft upgrades, experiment with builds, and start new adventures with a lasting inheritance.

**Early playable prototype.** Retail is the current development and testing client. WoW Forever is the intended content target, but its release build still needs integration verification.

## Getting started

1. Place the addon folder, named `WoWIdle`, in your client's `Interface/AddOns` directory. The folder should contain `WoWIdle.toc` directly.
2. Enable **WoWIdle** in the character selection AddOns list, then log in. If you installed it while the game was running, restart the client.
3. Enter `/wowidle` or `/wi` to open the adventure.
4. Begin with one hero. Follow the dismissible starter guide to learn battles, equipment, talents and travel. Open **Party** to manage the selected hero.
5. Let your heroes fight, collect their rewards, and choose new destinations from the **World map** as they unlock.

Required libraries are included; you do not need to install them separately.

## A party of your own

Your adventure starts with one hero and grows to five. Defeat milestone bosses at levels **1, 3, 5 and 7** to discover companions, then select their empty cards in **Party** to choose a class. You can choose from nine original class identities, including duplicates. Discovered slots and recruited heroes carry across chapters; existing parties are preserved.

Enemy groups grow with your company, early bosses suit smaller parties, and your first victory guarantees an equipment drop. Combine damage, healing, and survival as your company grows to tackle harder encounters.

Combat runs automatically. Heroes use their abilities according to configurable priorities, while talents and equipment shape their strengths. You can equip items, train, and adjust talents or priorities during a battle. Equipment changes preserve current health proportions and cooldowns.

Your heroes' levels, equipment, and combat belong to the minigame. Their growth is separate from your real character's power, gear, and talents. Minigame gold, materials, and equipment are used within WoWIdle.

## Adventure through Azeroth

Choose destinations on clickable maps of **Kalimdor** and the **Eastern Kingdoms**. The outdoor roster covers 41 Classic destinations, including all six starting regions, the leveling and endgame zones, Moonglade, Deadwind Pass, and the Blackrock Mountain hub. Cities, dungeons, and raids are not destinations. Each region has enemies, a milestone boss, local resources, and a curated loot pool. New regions temporarily share existing landscape backdrops and loot pools from a similar progression band; frontier levels and rewards remain provisional. Your idle destination is independent of your real character's location.

Battles earn hero experience, gold, equipment, and crafting materials. Push forward when your party is ready, or keep farming to improve its gear. After a defeat, the party falls back to a safe encounter. Traveling abandons the current encounter without its rewards and preserves your heroes' current health.

Close the window with Escape when you want to return to WoW; the adventure continues while the addon is running.

## Your WoW adventures fuel theirs

Eligible activities on your real character fill a shared, account-wide **Adventure XP** bar. Every **100 Adventure XP** awards **60 Essence**, which you can spend on training, crafting, and equipment improvements.

| Activity | Adventure XP |
| --- | ---: |
| Eligible enemy kill | 1 |
| Eligible herb or ore gather | 4 |
| Eligible skinning | 0.25 |
| Quest completion | 20 |
| Eligible boss | 25 |
| Confirmed eligible dungeon completion | 40 bonus |
| Character level gained | 5 bonus |

Hover the Adventure bar for activity rewards. Hero experience comes from idle battles; Adventure XP supplies Essence for their upgrades.

Ordinary questing, combat, and gathering can support progression; dungeons are optional. Gray enemies and legacy boss farming do not qualify. Gathering must have a skill-up-eligible difficulty, and dungeon completion bonuses require an explicit client completion signal. Eligible bosses can still reward XP during manual dungeon runs.

Credit depends on information available from the client. Some kills or gathers cannot be confirmed and will not award XP. Reward detection and balance are still being tested.

## Equipment, crafting, and loot

Every hero, including your main character, starts with cosmetic clothing covering the torso, legs, and feet. It adds no stats and is replaced visually as you equip armor. Empty slots regain this clothing automatically.

Each hero has ten wearable equipment slots: weapon, armor, head, back, shoulders, hands, waist, legs, feet, and wrists. Rings, necklaces, and trinkets are excluded entirely and removed from older saves on load. Use the shared inventory to compare drops and equip upgrades. Drops use real Classic-era WoW item names, icons, rarity, and fixed stat snapshots in curated pools for each destination. Power is calculated from the item’s stats for the selected hero’s class; ordinary drops do not gain raw power from encounter level. Strength, agility, and intellect support offense, stamina raises health, armor reduces incoming damage, and spirit supports healing. Haste support is ready for future items. Hover equipment to see its stats and compare the equipped item. Identical ordinary items stack, and inventory is sorted by effective power, strongest first.

Each purchased enhancement adds 10% of the item’s base stats. Heirlooms use the same item identities with separate idle level scaling. WoW item requirements are mapped to idle requirements. Armor follows original class proficiencies, including lighter armor and plate for warriors/paladins or mail for hunters/shamans unlocking at idle level 40. Heirlooms still require the right armor proficiency. Incompatible equipped armor returns to shared inventory on load or prestige. Weapon proficiencies remain simplified. Loot pools and drop rates are adapted for the minigame. See [item sources and stat rules](Content/ITEMS.md) for the catalog, calculations, and currently unsupported item effects.

In **Party**, select an equipment slot to compare items and preview the cost of an upgrade. Choose **Upgrade** to purchase it. Training raises a hero's level cap, letting further idle experience take them higher.

Crafting turns materials and Essence into targeted equipment. Configure salvage rules in the minigame to handle unwanted loot and protect items you want to keep. Talents and conditional ability priorities let you refine each hero's role as your party develops.

Talent selections and earned points survive prestige, and respecs stay free. Hero levels stop at 60. Personal level records award a point every two levels, starting at level 1; repeating those levels never awards points twice. At level 20, permanent **Mastery** unlocks: victories at or above that hero's hardest completed encounter level grant Mastery XP, with double XP for bosses. Every Mastery rank grants another permanent talent point, up to the tree's 48-point total. The first rank costs 100 XP, and each later rank costs 50 more. Mastery continues when character levels are capped. The Talents view shows both tracks.

## Prestige and heirlooms

Defeat a **level 8 milestone boss** to unlock prestige. Open **Legacy** to preview the rewards and reset consequences before confirming.

Prestige starts a new run: hero levels and training reset, ordinary equipment and purchased run upgrades are lost, and gold, zone materials, and destination progress start over. Your heroes keep their identities, classes, talents, earned talent points, and Mastery. Lower-level encounters after a reset do not grant Mastery XP.

Adventure rank, partial Adventure XP, unspent Essence, discoveries, unlocked recipes, Legacy currency, and heirlooms carry forward. Spent Essence is not refunded. Heirlooms scale with a hero's current idle level, giving future runs a useful foundation.

## Coming back later

Progress is saved account-wide, so your characters share one adventure. When you return, WoWIdle calculates up to **24 hours** of offline farming from your last safe encounter and presents a summary. New bosses and destination choices wait for you to return.

No addon code runs while WoW is closed; catch-up rewards are calculated when the addon next loads.

## Window controls and options

Use the top-right controls to switch between **compact**, **windowed**, and **fullscreen** views. Drag a window's top edge to move it and its bottom-right grip to resize it. Compact mode has an optional lock; management opens a larger view for equipment and builds.

Open **Settings → AddOns → WoWIdle** to adjust display preferences, window locking, the minimap button, chat announcements, floating combat text, and audio. Preferences are saved account-wide and apply immediately. Loot rules remain in the minigame.

To test a fresh start, open **Settings → AddOns → WoWIdle → New adventure** and choose **Reset all adventure progress**. Confirming permanently erases the account-wide adventure, including Legacy and heirlooms, and starts with one hero and the starter guide. Display and audio preferences are kept.

Audio can be muted entirely or by category, including combat, encounters, progression, loot, and travel. Sounds play only while the adventure window is visible, use WoW's sound-effects volume, and stay silent during offline catch-up.

| Command | Action |
| --- | --- |
| `/wowidle` | Toggle the adventure window |
| `/wi` | Toggle the adventure window |

## Current development

The prototype already includes automatic party combat, zone travel, equipment, crafting, salvage, talents, ability priorities, offline catch-up, prestige, and scaling heirlooms.

Full class-specific talent trees, final dungeon-completion mappings, and prestige pacing are still in development. Each class has three 16-talent specialization trees (48 talents per class), mixing shared foundations with signature mechanics and situational bonuses for its combat style. Exact offline alt appearances and matching equipment visuals are unfinished. Models, textures, and animations still need in-client visual verification.

For design details and contribution guidance, see [the game design](DESIGN.md), [balance notes](BALANCE.md), [architecture](ARCHITECTURE.md), and [development tooling](TOOLING.md) and [map maintenance and porting](MAPS.md).

## License and credits

WoWIdle uses an **All Rights Reserved** notice, matching ArtisanFinder. See [LICENSE](LICENSE).

Bundled third-party libraries retain their own licenses and notices; see [embedded libraries](Libs/README.md). Landscape artwork sources and credits are listed in [backdrop credits](Assets/Backdrops/SOURCES.md). The project notice does not replace those third-party terms.
