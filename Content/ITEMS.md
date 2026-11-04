# Item catalog

The catalog uses fixed Classic-era WoWhead tooltip snapshots, checked on 2026-11-01, rather than the connected client’s scaled item cache. Names, icon paths, rarity, primary attributes, armor, weapon DPS, attack power, healing power, resistances, and passive health regeneration come from those tooltips. The structured source for each entry is `https://nether.wowhead.com/classic/tooltip/item/ITEM_ID`. No network access is used by the addon.

## Basic clothing

Every hero model, including the main character, uses a class-themed starter outfit for empty torso, leg, and foot slots. This is a cosmetic fallback, not inventory equipment: it adds no stats, item identities, crafting recipes, salvage rewards, or saved state. Equipped armor replaces the matching part; removing it restores basic clothing. Existing saves and prestige use the same fallback automatically.

Elwynn and Durotar also offer Brown Linen Vest, Simple Linen Pants, and Simple Linen Boots as weak stat-bearing drops wearable by every class from idle level 1. Loot remains random, so cosmetic coverage does not depend on drops.

Starter appearance item references (shirt items cover the torso until chest armor is equipped):

| Class | Torso | Legs | Feet |
| --- | --- | --- | --- |
| Warrior | [Recruit's Shirt](https://www.wowhead.com/classic/item=38) | [Recruit's Pants](https://www.wowhead.com/classic/item=39) | [Recruit's Boots](https://www.wowhead.com/classic/item=40) |
| Paladin | [Squire's Shirt](https://www.wowhead.com/classic/item=45) | [Squire's Pants](https://www.wowhead.com/classic/item=44) | [Squire's Boots](https://www.wowhead.com/classic/item=43) |
| Hunter | [Trapper's Shirt](https://www.wowhead.com/classic/item=127) | [Recruit's Pants](https://www.wowhead.com/classic/item=39) | [Rugged Trapper's Boots](https://www.wowhead.com/classic/item=129) |
| Rogue | [Footpad's Shirt](https://www.wowhead.com/classic/item=49) | [Footpad's Pants](https://www.wowhead.com/classic/item=48) | [Footpad's Shoes](https://www.wowhead.com/classic/item=47) |
| Priest | [Acolyte's Robe](https://www.wowhead.com/classic/item=57) | [Acolyte's Pants](https://www.wowhead.com/classic/item=1396) | [Acolyte's Shoes](https://www.wowhead.com/classic/item=59) |
| Shaman | [Primitive Mantle](https://www.wowhead.com/classic/item=6134) | [Novice's Pants](https://www.wowhead.com/classic/item=6124) | [Trapper's Boots](https://www.wowhead.com/classic/item=6127) |
| Mage | [Apprentice's Robe](https://www.wowhead.com/classic/item=56) | [Apprentice's Pants](https://www.wowhead.com/classic/item=1395) | [Apprentice's Boots](https://www.wowhead.com/classic/item=55) |
| Warlock | [Acolyte's Robe](https://www.wowhead.com/classic/item=6129) | [Acolyte's Pants](https://www.wowhead.com/classic/item=1396) | [Acolyte's Shoes](https://www.wowhead.com/classic/item=59) |
| Druid | [Novice's Robe](https://www.wowhead.com/classic/item=6123) | [Novice's Pants](https://www.wowhead.com/classic/item=6124) | [Acolyte's Shoes](https://www.wowhead.com/classic/item=59) |

## Idle adaptations

- Zone tables are curated minigame pools, not complete live mob loot tables or authentic drop percentages. Riverpaw Leather Vest belongs to Elwynn’s gnolls, Stonemason Cloak to Westfall’s Defias, Blackrock Champion’s Axe to Redridge’s Blackrock enemies, and Rathorian’s Cape to the Barrens. Other entries are level-appropriate world finds. Starter weapons are included to supply basic equipment.
- Source stats stay fixed. WoW required level maps to idle level as `max(1, ceil(requiredLevel / 4))`; items become available as encounter levels reach that requirement. An item’s source WoW requirement is also shown in its tooltip.
- From Party’s equipment inventory, open Disenchant to select a stack in a dedicated workbench and protect it or disenchant copies for gold (idle level × rarity per copy) and Relic dust (rarity − 1 per copy, minimum 1). Choose 1, 10, or 100 beside the list; smaller stacks consume only their remaining copies. The selected stack’s exact reward is shown before destruction. Disenchant all consumes all unprotected stored equipment across pages and filters, including upgrades, regardless of the quantity selector. Equipped gear, heirlooms and protected items are kept. Disenchanting grants no Essence and does not refund upgrades. Loot rules affect future drops only, awarding gold and ore.
- Crafting chooses the strongest usable source item for the selected hero and slot, including effective heirloom scaling. It retains the source rarity, rather than recoloring it. Low-level slots with no available source item cannot be crafted yet. Armor proficiencies follow the original class rules: all classes can wear cloth; rogues and druids can also wear leather; hunters and shamans unlock mail at idle level 40; warriors and paladins can wear mail immediately and unlock plate at idle level 40. Lighter armor remains usable. Cloaks have no armor proficiency restriction. Heirlooms bypass item-level requirements, but never class or armor-unlock requirements. Weapons follow Classic class proficiencies, distinguishing one-handed and two-handed types. Training and talent requirements are automatic in the idle game; unique-equipped restrictions and hand occupancy remain simplified by its single weapon slot. Both starting zones offer level-1 swords, axes, maces, and staves, providing at least two usable weapon choices for every class. Crafting, automatic equipment, upgrade retention, and inventory filters respect these proficiencies. Loading a save returns incompatible equipped weapons to inventory with their enhancements intact.
- New loot and crafting use ten wearable slots: weapon, armor, head, back, shoulders, hands, waist, legs, feet, and wrists. Rings, necklaces, and trinkets are removed from the catalog. Loading an older save removes these items from inventory and equipped gear, including protected stacks and heirlooms, and removes their recipe unlocks. Other equipment and progression are preserved. Encounters with removed equipped gear restart without rewards.
- An enhancement adds 10% of base stats, additively. Heirloom stats additionally scale by `hero idle level / source idle requirement`. Both are minigame enhancements, not claims about the original WoW item.
- Existing synthetic saved equipment keeps its identity, stacks, protections, effects, and purchased enhancements. Its old power is converted once into attributes; an active encounter from that older stat model restarts without rewards. New drops and crafts use catalog items.
- Loading an older save returns armor the hero cannot wear to the shared inventory without losing identities, stacks, protections, or enhancements; affected encounters restart without rewards. Prestige also returns heirlooms that require a higher armor proficiency to inventory until the hero reaches idle level 40 again. Old synthetic armor without a source subclass is treated as cloth.
- Golem Shard Leggings retain their source +6 Defense as tooltip information; Defense is not simulated.
- Heartseeking Crossbow’s Shadowbolt proc is not simulated. Cow King’s Hide retains its resistance values for display; damage schools are not modeled, so those values contribute no power. Tooltips identify these limitations.

## Derived stats and power

The current primary attributes are strength for warriors and paladins, agility for hunters and rogues, and intellect for priests, shamans, mages, warlocks, and druids. These class defaults can be extended when specializations affect item valuation.

Power is a comparison estimate rounded to one decimal, computed from effective item attributes. It is not stored as an item stat. Weights are: primary attribute 1; stamina 0.6; spirit 0.4; haste 0.8; armor 0.04; weapon DPS 1.5; attack power 0.5; spell power 0.8; healing power 0.5; health restored per five seconds 1. Off-primary attributes and resistances score zero. These are idle balance weights, not Blizzard formulas.

Combat aggregates effective attributes directly. Stamina adds 10 health per point. Armor reduces incoming damage by `armor / (500 + 50 × hero level + armor)`, capped at 60%. Primary attributes, weapon DPS, and attack/spell power add damage; intellect, spirit, and healing/spell power add healing. Haste multiplies attack and ability cooldown recovery by `1 + haste / 100`. Passive health regeneration is applied each simulation step. Existing hero-level baselines and prestige bonuses remain. No haste is invented for Classic items without that stat; the stat path is available for later catalog expansion.

## Sources

| Item ID | WoWhead Classic reference |
| --- | --- |
| 25 | [Worn Shortsword](https://www.wowhead.com/classic/item=25) |
| 35 | [Bent Staff](https://www.wowhead.com/classic/item=35) |
| 36 | [Worn Mace](https://www.wowhead.com/classic/item=36) |
| 37 | [Worn Axe](https://www.wowhead.com/classic/item=37) |
| 821 | [Riverpaw Leather Vest](https://www.wowhead.com/classic/item=821) |
| 935 | [Night Watch Shortsword](https://www.wowhead.com/classic/item=935) |
| 1455 | [Blackrock Champion's Axe](https://www.wowhead.com/classic/item=1455) |
| 1539 | [Gnarled Hermit's Staff](https://www.wowhead.com/classic/item=1539) |
| 5111 | [Rathorian's Cape](https://www.wowhead.com/classic/item=5111) |
| 1930 | [Stonemason Cloak](https://www.wowhead.com/classic/item=1930) |
| 2961 | [Burnt Leather Vest](https://www.wowhead.com/classic/item=2961) |
| 2973 | [Hunting Tunic](https://www.wowhead.com/classic/item=2973) |
| 2981 | [Seer's Robe](https://www.wowhead.com/classic/item=2981) |
| 2985 | [Inscribed Leather Breastplate](https://www.wowhead.com/classic/item=2985) |
| 3055 | [Forest Leather Chestpiece](https://www.wowhead.com/classic/item=3055) |
| 3069 | [Bright Robe](https://www.wowhead.com/classic/item=3069) |
| 4038 | [Nightsky Robe](https://www.wowhead.com/classic/item=4038) |
| 4057 | [Insignia Chestguard](https://www.wowhead.com/classic/item=4057) |
| 4074 | [Mail Combat Armor](https://www.wowhead.com/classic/item=4074) |
| 12988 | [Starsight Tunic](https://www.wowhead.com/classic/item=12988) |
| 13110 | [Wolffear Harness](https://www.wowhead.com/classic/item=13110) |
| 13009 | [Cow King's Hide](https://www.wowhead.com/classic/item=13009) |
| 13123 | [Dreamwalker Armor](https://www.wowhead.com/classic/item=13123) |
| 2721 | [Holy Shroud](https://www.wowhead.com/classic/item=2721) |
| 3020 | [Enduring Cap](https://www.wowhead.com/classic/item=3020) |
| 13102 | [Cassandra's Grace](https://www.wowhead.com/classic/item=13102) |
| 13113 | [Feathermoon Headdress](https://www.wowhead.com/classic/item=13113) |
| 13014 | [Axe of Rin'ji](https://www.wowhead.com/classic/item=13014) |
| 13015 | [Serathil](https://www.wowhead.com/classic/item=13015) |
| 13022 | [Gryphonwing Long Bow](https://www.wowhead.com/classic/item=13022) |
| 13023 | [Eaglehorn Long Bow](https://www.wowhead.com/classic/item=13023) |
| 13024 | [Beazel's Basher](https://www.wowhead.com/classic/item=13024) |
| 13027 | [Bonesnapper](https://www.wowhead.com/classic/item=13027) |
| 13028 | [Bludstone Hammer](https://www.wowhead.com/classic/item=13028) |
| 13040 | [Heartseeking Crossbow](https://www.wowhead.com/classic/item=13040) |
| 13043 | [Blade of the Titans](https://www.wowhead.com/classic/item=13043) |
| 2962 | [Burnt Leather Breeches](https://www.wowhead.com/classic/item=2962) |
| 2963 | [Burnt Leather Boots](https://www.wowhead.com/classic/item=2963) |
| 2964 | [Burnt Leather Gloves](https://www.wowhead.com/classic/item=2964) |
| 2965 | [Warrior's Tunic](https://www.wowhead.com/classic/item=2965) |
| 2966 | [Warrior's Pants](https://www.wowhead.com/classic/item=2966) |
| 2967 | [Warrior's Boots](https://www.wowhead.com/classic/item=2967) |
| 2968 | [Warrior's Gloves](https://www.wowhead.com/classic/item=2968) |
| 2969 | [Spellbinder Vest](https://www.wowhead.com/classic/item=2969) |
| 2970 | [Spellbinder Pants](https://www.wowhead.com/classic/item=2970) |
| 2971 | [Spellbinder Boots](https://www.wowhead.com/classic/item=2971) |
| 2972 | [Spellbinder Gloves](https://www.wowhead.com/classic/item=2972) |
| 2974 | [Hunting Pants](https://www.wowhead.com/classic/item=2974) |
| 2975 | [Hunting Boots](https://www.wowhead.com/classic/item=2975) |
| 2976 | [Hunting Gloves](https://www.wowhead.com/classic/item=2976) |
| 2977 | [Veteran Armor](https://www.wowhead.com/classic/item=2977) |
| 2978 | [Veteran Leggings](https://www.wowhead.com/classic/item=2978) |
| 2979 | [Veteran Boots](https://www.wowhead.com/classic/item=2979) |
| 2980 | [Veteran Gloves](https://www.wowhead.com/classic/item=2980) |
| 2982 | [Seer's Pants](https://www.wowhead.com/classic/item=2982) |
| 2983 | [Seer's Boots](https://www.wowhead.com/classic/item=2983) |
| 2984 | [Seer's Gloves](https://www.wowhead.com/classic/item=2984) |
| 2986 | [Inscribed Leather Pants](https://www.wowhead.com/classic/item=2986) |
| 2987 | [Inscribed Leather Boots](https://www.wowhead.com/classic/item=2987) |
| 2988 | [Inscribed Leather Gloves](https://www.wowhead.com/classic/item=2988) |
| 2989 | [Burnished Tunic](https://www.wowhead.com/classic/item=2989) |
| 3065 | [Bright Boots](https://www.wowhead.com/classic/item=3065) |
| 3066 | [Bright Gloves](https://www.wowhead.com/classic/item=3066) |
| 3067 | [Bright Pants](https://www.wowhead.com/classic/item=3067) |
| 4035 | [Silver-thread Robe](https://www.wowhead.com/classic/item=4035) |
| 4036 | [Silver-thread Cuffs](https://www.wowhead.com/classic/item=4036) |
| 4037 | [Silver-thread Pants](https://www.wowhead.com/classic/item=4037) |
| 4039 | [Nightsky Cowl](https://www.wowhead.com/classic/item=4039) |
| 4040 | [Nightsky Gloves](https://www.wowhead.com/classic/item=4040) |
| 4041 | [Aurora Cowl](https://www.wowhead.com/classic/item=4041) |
| 4042 | [Aurora Gloves](https://www.wowhead.com/classic/item=4042) |
| 4043 | [Aurora Bracers](https://www.wowhead.com/classic/item=4043) |
| 4044 | [Aurora Pants](https://www.wowhead.com/classic/item=4044) |
| 4045 | [Mistscape Bracers](https://www.wowhead.com/classic/item=4045) |
| 4071 | [Glimmering Mail Breastplate](https://www.wowhead.com/classic/item=4071) |
| 4072 | [Glimmering Mail Gauntlets](https://www.wowhead.com/classic/item=4072) |
| 4073 | [Glimmering Mail Greaves](https://www.wowhead.com/classic/item=4073) |
| 4694 | [Burnished Pauldrons](https://www.wowhead.com/classic/item=4694) |
| 4701 | [Inscribed Cloak](https://www.wowhead.com/classic/item=4701) |
| 4713 | [Silver-thread Cloak](https://www.wowhead.com/classic/item=4713) |
| 4714 | [Silver-thread Sash](https://www.wowhead.com/classic/item=4714) |
| 4721 | [Insignia Mantle](https://www.wowhead.com/classic/item=4721) |
| 13115 | [Sheepshear Mantle](https://www.wowhead.com/classic/item=13115) |
| 13116 | [Spaulders of the Unseen](https://www.wowhead.com/classic/item=13116) |
| 13117 | [Ogron's Sash](https://www.wowhead.com/classic/item=13117) |
| 13118 | [Serpentine Sash](https://www.wowhead.com/classic/item=13118) |
| 13119 | [Enchanted Kodo Bracers](https://www.wowhead.com/classic/item=13119) |
| 13120 | [Deepfury Bracers](https://www.wowhead.com/classic/item=13120) |
| 13121 | [Wing of the Whelpling](https://www.wowhead.com/classic/item=13121) |
| 13122 | [Dark Phantom Cape](https://www.wowhead.com/classic/item=13122) |
| 13099 | [Moccasins of the White Hare](https://www.wowhead.com/classic/item=13099) |
| 13100 | [Furen's Boots](https://www.wowhead.com/classic/item=13100) |
| 13101 | [Wolfrunner Shoes](https://www.wowhead.com/classic/item=13101) |
| 13103 | [Pads of the Venom Spider](https://www.wowhead.com/classic/item=13103) |
| 13105 | [Sutarn's Ring](https://www.wowhead.com/classic/item=13105) |
| 13106 | [Glowing Magical Bracelets](https://www.wowhead.com/classic/item=13106) |
| 13107 | [Magiskull Cuffs](https://www.wowhead.com/classic/item=13107) |
| 13108 | [Tigerstrike Mantle](https://www.wowhead.com/classic/item=13108) |
| 13109 | [Blackflame Cape](https://www.wowhead.com/classic/item=13109) |
| 13111 | [Sandals of the Insurgent](https://www.wowhead.com/classic/item=13111) |
| 13112 | [Winged Helm](https://www.wowhead.com/classic/item=13112) |
| 13114 | [Troll's Bane Leggings](https://www.wowhead.com/classic/item=13114) |
| 4666 | [Burnt Leather Belt](https://www.wowhead.com/classic/item=4666) |
| 3200 | [Burnt Leather Bracers](https://www.wowhead.com/classic/item=3200) |
| 3213 | [Veteran Bracers](https://www.wowhead.com/classic/item=3213) |
| 14169 | [Aboriginal Shoulder Pads](https://www.wowhead.com/classic/item=14169) |
| 1280 | [Cloaked Hood](https://www.wowhead.com/classic/item=1280) |
| 12987 | [Darkweave Breeches](https://www.wowhead.com/classic/item=12987) |
| 12977 | [Magefist Gloves](https://www.wowhead.com/classic/item=12977) |
| 13010 | [Dreamsinger Legguards](https://www.wowhead.com/classic/item=13010) |
| 13124 | [Ravasaur Scale Boots](https://www.wowhead.com/classic/item=13124) |
| 13125 | [Elven Chain Boots](https://www.wowhead.com/classic/item=13125) |
| 13126 | [Battlecaller Gauntlets](https://www.wowhead.com/classic/item=13126) |
| 13127 | [Frostreaver Crown](https://www.wowhead.com/classic/item=13127) |
| 13128 | [High Bergg Helm](https://www.wowhead.com/classic/item=13128) |
| 13129 | [Firemane Leggings](https://www.wowhead.com/classic/item=13129) |
| 13130 | [Windrunner Legguards](https://www.wowhead.com/classic/item=13130) |
| 13131 | [Sparkleshell Mantle](https://www.wowhead.com/classic/item=13131) |
| 13132 | [Skeletal Shoulders](https://www.wowhead.com/classic/item=13132) |
| 13066 | [Wyrmslayer Spaulders](https://www.wowhead.com/classic/item=13066) |
| 13067 | [Hydralick Armor](https://www.wowhead.com/classic/item=13067) |
| 13068 | [Obsidian Greaves](https://www.wowhead.com/classic/item=13068) |
| 13071 | [Plated Fist of Hakoo](https://www.wowhead.com/classic/item=13071) |
| 13073 | [Mugthol's Helm](https://www.wowhead.com/classic/item=13073) |
| 13074 | [Golem Shard Leggings](https://www.wowhead.com/classic/item=13074) |
| 13076 | [Giantslayer Bracers](https://www.wowhead.com/classic/item=13076) |
| 13077 | [Girdle of Uther](https://www.wowhead.com/classic/item=13077) |
| 2568 | [Brown Linen Vest](https://www.wowhead.com/classic/item=2568) |
| 10045 | [Simple Linen Pants](https://www.wowhead.com/classic/item=10045) |
| 10046 | [Simple Linen Boots](https://www.wowhead.com/classic/item=10046) |

Armor proficiency reference: [Blizzard’s original game manual](https://bnetcmsus-a.akamaihd.net/cms/template_resource/263A8NGR8HLZ1556919642368.pdf). The unlock uses the minigame hero’s idle level, independently of the source item requirement mapping.

## Idle encounter families

Destination enemy-family tags use the Classic tooltip taxonomy of the existing appearance NPC IDs in `Compatibility/Models.lua`, checked 2026-11-03 through `https://nether.wowhead.com/classic/tooltip/npc/NPC_ID`. These are authored idle encounter profiles; they do not query real creature APIs, establish current-client loot sources or enable outdoor collection acquisition. The existing Westfall authored boss/family contract is retained. Seven appearance records omit a creature type (6140, 6510, 7086, 11722, 11724, 11730 and 14473); their corresponding new tags remain `unknown` rather than guessing a taxonomy. Tags align with each destination's enemy order and have a separate boss entry.

Family material choices are minigame rules: humanoids yield timber, beasts/dragonkin/critters hide, machines/giants ore, and elementals/undead/demons Relic dust. Unknown families yield no secondary material. A shared 25% encounter budget prevents extra enemies from multiplying the bonus.

## Forever outdoor collection sources

The Forever item pages were inspected on 2026-11-03, including their rendered “Dropped by” tables and creature links. The selected outdoor sources are Redridge Mongrel (NPC 423, Redridge Mountains) for [Inscribed Cloak 4701](https://www.wowhead.com/forever/item=4701/inscribed-cloak), and Mo'grosh Mystic (NPC 1183, Loch Modan) for [Breastplate 2985](https://www.wowhead.com/forever/item=2985/inscribed-leather-breastplate), [Pants 2986](https://www.wowhead.com/forever/item=2986/inscribed-leather-pants), [Boots 2987](https://www.wowhead.com/forever/item=2987/inscribed-leather-boots), and [Gloves 2988](https://www.wowhead.com/forever/item=2988/inscribed-leather-gloves). These pages list other sources too; this initial profile deliberately uses one confirmed outdoor source per piece. Each linked NPC is marked unchanged in the database. Database evidence establishes the mapping used by the addon; it does not constitute in-game addon validation or guarantee future server loot tables.

The enabled profile is restricted to Forever interface 16001. Its 5% collection discovery chance are addon rules, separate from Wowhead's real-item drop rates. Retail mappings remain independent and disabled pending their own creature-specific evidence. No offline or simulated kills qualify.

## Forever dungeon collection sources

The Forever item pages and rendered Dropped by tables were inspected on 2026-11-03. The Deadmines profile uses one confirmed creature per piece: [Blackened Defias Armor 10399](https://www.wowhead.com/forever/item=10399/blackened-defias-armor) from Edwin VanCleef (639); [Leggings 10400](https://www.wowhead.com/forever/item=10400/blackened-defias-leggings) and [Gloves 10401](https://www.wowhead.com/forever/item=10401/blackened-defias-gloves) from Defias Overseer (634); [Boots 10402](https://www.wowhead.com/forever/item=10402/blackened-defias-boots) from Defias Strip Miner (4416); and [Belt 10403](https://www.wowhead.com/forever/item=10403/blackened-defias-belt) from Captain Greenskin (647). Display groups these as monster families within The Deadmines; exact creature identities remain in source metadata.

Only Forever interface 16001 party-instance kills qualify. Retail has no enabled dungeon profile. A 20% discovery chance per piece are provisional addon rules, not the real items' loot rates. Offline, outdoor, raid and unattributed kills do not qualify. Database inspection does not establish actual client validation.


## Low-level Forever collection expansion

The following item identities, icons, required levels, and selected creature links were checked in Wowhead’s rendered Forever item and creature drop tables on 2026-11-04. The eight named outdoor field kits and the two dungeon relic collections are authored collections, not claims of native equipment set bonuses. One verified source is selected per piece; other real drop sources are not automatically eligible. Tribal spans required levels 4–8; the other outdoor kits span 13–20, and the dungeon collections span 13–24.

Outdoor sources use the existing Forever 16001 profile (5% discovery per eligible kill); dungeon sources use its party-instance profile (20% per eligible kill). These are addon discovery rules, not real-item drop chances. Two pieces grant 0.5% basic attacks and four grant 0.5% materials; Blessing of Kalimdor grants its material milestone at three pieces. Existing shared 5% milestone caps and one selected completed-set effect still apply. This expansion adds no items to ordinary loot or crafting pools; existing equipment identities are reused where available. Retail remains disabled and live-client validation remains outstanding.

| Collection | Item | Selected drop mob | Location |
| --- | --- | --- | --- |
| Tribal Trail | [Tribal Vest (3288)](https://www.wowhead.com/forever/item=3288) | [Burning Blade Crusher (12320)](https://www.wowhead.com/forever/npc=12320) | The Barrens |
| Tribal Trail | [Tribal Pants (3287)](https://www.wowhead.com/forever/item=3287) | [Ursal the Mauler (2039)](https://www.wowhead.com/forever/npc=2039) | Teldrassil |
| Tribal Trail | [Tribal Boots (3284)](https://www.wowhead.com/forever/item=3284) | [Gnarlpine Totemic (2014)](https://www.wowhead.com/forever/npc=2014) | Teldrassil |
| Tribal Trail | [Tribal Gloves (3286)](https://www.wowhead.com/forever/item=3286) | [Snagglespear (5786)](https://www.wowhead.com/forever/npc=5786) | Mulgore |
| Tribal Trail | [Tribal Cloak (4674)](https://www.wowhead.com/forever/item=4674) | [Burning Blade Fanatic (3197)](https://www.wowhead.com/forever/npc=3197) | Durotar |
| Buccaneer's Field Kit | [Buccaneer's Cape (14167)](https://www.wowhead.com/forever/item=14167) | [Riverpaw Overseer (125)](https://www.wowhead.com/forever/npc=125) | Westfall |
| Buccaneer's Field Kit | [Buccaneer's Cord (14173)](https://www.wowhead.com/forever/item=14173) | [Mo'grosh Brute (1180)](https://www.wowhead.com/forever/npc=1180) | Loch Modan |
| Buccaneer's Field Kit | [Buccaneer's Boots (14174)](https://www.wowhead.com/forever/item=14174) | [Mo'grosh Brute (1180)](https://www.wowhead.com/forever/npc=1180) | Loch Modan |
| Buccaneer's Field Kit | [Buccaneer's Bracers (14166)](https://www.wowhead.com/forever/item=14166) | [Mo'grosh Enforcer (1179)](https://www.wowhead.com/forever/npc=1179) | Loch Modan |
| Buccaneer's Field Kit | [Buccaneer's Gloves (14168)](https://www.wowhead.com/forever/item=14168) | [Blackrock Scout (4064)](https://www.wowhead.com/forever/npc=4064) | Redridge Mountains |
| Bandit Field Kit | [Bandit Cinch (9775)](https://www.wowhead.com/forever/item=9775) | [Mo'grosh Mystic (1183)](https://www.wowhead.com/forever/npc=1183) | Loch Modan |
| Bandit Field Kit | [Bandit Bracers (9777)](https://www.wowhead.com/forever/item=9777) | [Mo'grosh Mystic (1183)](https://www.wowhead.com/forever/npc=1183) | Loch Modan |
| Bandit Field Kit | [Bandit Gloves (9780)](https://www.wowhead.com/forever/item=9780) | [Mo'grosh Mystic (1183)](https://www.wowhead.com/forever/npc=1183) | Loch Modan |
| Bandit Field Kit | [Bandit Boots (9776)](https://www.wowhead.com/forever/item=9776) | [Mo'grosh Mystic (1183)](https://www.wowhead.com/forever/npc=1183) | Loch Modan |
| Bandit Field Kit | [Bandit Pants (9781)](https://www.wowhead.com/forever/item=9781) | [Taskmaster Whipfang (5932)](https://www.wowhead.com/forever/npc=5932) | Stonetalon Mountains |
| Burnished Field Kit | [Burnished Bracers (3211)](https://www.wowhead.com/forever/item=3211) | [Apothecary Berard (2106)](https://www.wowhead.com/forever/npc=2106) | Silverpine Forest |
| Burnished Field Kit | [Burnished Gloves (2992)](https://www.wowhead.com/forever/item=2992) | [Greater Tarantula (271898)](https://www.wowhead.com/forever/npc=271898) | Redridge Mountains |
| Burnished Field Kit | [Burnished Boots (2991)](https://www.wowhead.com/forever/item=2991) | [Blackrock Sentry (4065)](https://www.wowhead.com/forever/npc=4065) | Redridge Mountains |
| Burnished Field Kit | [Burnished Girdle (4697)](https://www.wowhead.com/forever/item=4697) | [Blackrock Scout (4064)](https://www.wowhead.com/forever/npc=4064) | Redridge Mountains |
| Burnished Field Kit | [Burnished Tunic (2989)](https://www.wowhead.com/forever/item=2989) | [Blackrock Sentry (4065)](https://www.wowhead.com/forever/npc=4065) | Redridge Mountains |
| Raider's Field Kit | [Raider's Boots (9784)](https://www.wowhead.com/forever/item=9784) | [Mo'grosh Mystic (1183)](https://www.wowhead.com/forever/npc=1183) | Loch Modan |
| Raider's Field Kit | [Raider's Gauntlets (9787)](https://www.wowhead.com/forever/item=9787) | [Foreman Grills (5835)](https://www.wowhead.com/forever/npc=5835) | The Barrens |
| Raider's Field Kit | [Raider's Legguards (9789)](https://www.wowhead.com/forever/item=9789) | [Sister Rathtalon (5830)](https://www.wowhead.com/forever/npc=5830) | The Barrens |
| Raider's Field Kit | [Raider's Chestpiece (9783)](https://www.wowhead.com/forever/item=9783) | [Mo'grosh Mystic (1183)](https://www.wowhead.com/forever/npc=1183) | Loch Modan |
| Raider's Field Kit | [Raider's Belt (9788)](https://www.wowhead.com/forever/item=9788) | [Carnivous the Breaker (2186)](https://www.wowhead.com/forever/npc=2186) | Darkshore |
| Seer's Field Kit | [Seer's Pants (2982)](https://www.wowhead.com/forever/item=2982) | [Mo'grosh Brute (1180)](https://www.wowhead.com/forever/npc=1180) | Loch Modan |
| Seer's Field Kit | [Seer's Gloves (2984)](https://www.wowhead.com/forever/item=2984) | [Mo'grosh Shaman (1181)](https://www.wowhead.com/forever/npc=1181) | Loch Modan |
| Seer's Field Kit | [Seer's Belt (4699)](https://www.wowhead.com/forever/item=4699) | [Mo'grosh Enforcer (1179)](https://www.wowhead.com/forever/npc=1179) | Loch Modan |
| Seer's Field Kit | [Seer's Robe (2981)](https://www.wowhead.com/forever/item=2981) | [Blackrock Scout (4064)](https://www.wowhead.com/forever/npc=4064) | Redridge Mountains |
| Seer's Field Kit | [Seer's Mantle (4698)](https://www.wowhead.com/forever/item=4698) | [Fen Dweller (1039)](https://www.wowhead.com/forever/npc=1039) | Wetlands |
| Shimmering Field Kit | [Shimmering Bracers (6563)](https://www.wowhead.com/forever/item=6563) | [Seeker Aqualon (14269)](https://www.wowhead.com/forever/npc=14269) | Redridge Mountains |
| Shimmering Field Kit | [Shimmering Sash (6570)](https://www.wowhead.com/forever/item=6570) | [Taskmaster Whipfang (5932)](https://www.wowhead.com/forever/npc=5932) | Stonetalon Mountains |
| Shimmering Field Kit | [Shimmering Gloves (6565)](https://www.wowhead.com/forever/item=6565) | [Taskmaster Whipfang (5932)](https://www.wowhead.com/forever/npc=5932) | Stonetalon Mountains |
| Shimmering Field Kit | [Shimmering Boots (6562)](https://www.wowhead.com/forever/item=6562) | [Mo'grosh Mystic (1183)](https://www.wowhead.com/forever/npc=1183) | Loch Modan |
| Shimmering Field Kit | [Shimmering Cloak (6564)](https://www.wowhead.com/forever/item=6564) | [Swiftmane (5831)](https://www.wowhead.com/forever/npc=5831) | The Barrens |
| Defender Field Kit | [Defender Cloak (6575)](https://www.wowhead.com/forever/item=6575) | [Seeker Aqualon (14269)](https://www.wowhead.com/forever/npc=14269) | Redridge Mountains |
| Defender Field Kit | [Defender Bracers (6574)](https://www.wowhead.com/forever/item=6574) | [Apothecary Falthis (3735)](https://www.wowhead.com/forever/npc=3735) | Ashenvale |
| Defender Field Kit | [Defender Girdle (6576)](https://www.wowhead.com/forever/item=6576) | [Apothecary Falthis (3735)](https://www.wowhead.com/forever/npc=3735) | Ashenvale |
| Defender Field Kit | [Defender Leggings (6578)](https://www.wowhead.com/forever/item=6578) | [Mo'grosh Mystic (1183)](https://www.wowhead.com/forever/npc=1183) | Loch Modan |
| Defender Field Kit | [Defender Boots (6573)](https://www.wowhead.com/forever/item=6573) | [Gnawbone (14425)](https://www.wowhead.com/forever/npc=14425) | Wetlands |
| Blessing of Kalimdor | [Mark of the Pack Leader (285331)](https://www.wowhead.com/forever/item=285331) | [Humar the Pridelord (5828)](https://www.wowhead.com/forever/npc=5828) | The Barrens |
| Blessing of Kalimdor | [Signet of the Zhevra (285330)](https://www.wowhead.com/forever/item=285330) | [Swiftmane (5831)](https://www.wowhead.com/forever/npc=5831) | The Barrens |
| Blessing of Kalimdor | [Raptor Hide Cloak (285329)](https://www.wowhead.com/forever/item=285329) | [Takk the Leaper (5842)](https://www.wowhead.com/forever/npc=5842) | The Barrens |
| Heirlooms of the Thanes | [Spiritwraith Drape (271097)](https://www.wowhead.com/forever/item=271097) | [Faldrim Anvilmar (261306)](https://www.wowhead.com/forever/npc=261306) | The Hall of Thanes |
| Heirlooms of the Thanes | [Aetherwisp Bracers (271096)](https://www.wowhead.com/forever/item=271096) | [Faldrim Anvilmar (261306)](https://www.wowhead.com/forever/npc=261306) | The Hall of Thanes |
| Heirlooms of the Thanes | [Kindlegem Girdle (270230)](https://www.wowhead.com/forever/item=270230) | [Magmatus (261316)](https://www.wowhead.com/forever/npc=261316) | The Hall of Thanes |
| Heirlooms of the Thanes | [Flamefist Grips (270231)](https://www.wowhead.com/forever/item=270231) | [Magmatus (261316)](https://www.wowhead.com/forever/npc=261316) | The Hall of Thanes |
| Heirlooms of the Thanes | [Golemguard Chest (271098)](https://www.wowhead.com/forever/item=271098) | [Plunder (261311)](https://www.wowhead.com/forever/npc=261311) | The Hall of Thanes |
| Embrace of the Viper | [Belt of the Fang (10412)](https://www.wowhead.com/forever/item=10412) | [Lady Anacondra (3671)](https://www.wowhead.com/forever/npc=3671) | Wailing Caverns |
| Embrace of the Viper | [Footpads of the Fang (10411)](https://www.wowhead.com/forever/item=10411) | [Lord Serpentis (3673)](https://www.wowhead.com/forever/npc=3673) | Wailing Caverns |
| Embrace of the Viper | [Gloves of the Fang (10413)](https://www.wowhead.com/forever/item=10413) | [Druid of the Fang (3840)](https://www.wowhead.com/forever/npc=3840) | Wailing Caverns |
| Embrace of the Viper | [Leggings of the Fang (10410)](https://www.wowhead.com/forever/item=10410) | [Lord Cobrahn (3669)](https://www.wowhead.com/forever/npc=3669) | Wailing Caverns |
| Embrace of the Viper | [Armor of the Fang (6473)](https://www.wowhead.com/forever/item=6473) | [Lord Pythas (3670)](https://www.wowhead.com/forever/npc=3670) | Wailing Caverns |
| Rotmender's Raiment | [Rotmender's Garb (286978)](https://www.wowhead.com/forever/item=286978) | [Flesh Golem (255109)](https://www.wowhead.com/forever/npc=255109) | Ruins of Lordaeron |
| Rotmender's Raiment | [Rotmender's Sash (286980)](https://www.wowhead.com/forever/item=286980) | [Shrieking Banshee (250620)](https://www.wowhead.com/forever/npc=250620) | Ruins of Lordaeron |
| Rotmender's Raiment | [Rotmender's Leggings (271207)](https://www.wowhead.com/forever/item=271207) | [The Abandoned (250631)](https://www.wowhead.com/forever/npc=250631) | Ruins of Lordaeron |
| Rotmender's Raiment | [Rotmender's Treads (271214)](https://www.wowhead.com/forever/item=271214) | [Rath'mael (250657)](https://www.wowhead.com/forever/npc=250657) | Ruins of Lordaeron |
| Rotmender's Raiment | [Rotmender's Gloves (286979)](https://www.wowhead.com/forever/item=286979) | [Stone Watcher (250629)](https://www.wowhead.com/forever/npc=250629) | Ruins of Lordaeron |
| Shadowfang Relics | [Rugged Spaulders (5254)](https://www.wowhead.com/forever/item=5254) | [Rethilgore (3914)](https://www.wowhead.com/forever/npc=3914) | Shadowfang Keep |
| Shadowfang Relics | [Girdle of the Blindwatcher (6319)](https://www.wowhead.com/forever/item=6319) | [Odo the Blindwatcher (4279)](https://www.wowhead.com/forever/npc=4279) | Shadowfang Keep |
| Shadowfang Relics | [Fenrus' Hide (6340)](https://www.wowhead.com/forever/item=6340) | [Fenrus the Devourer (4274)](https://www.wowhead.com/forever/npc=4274) | Shadowfang Keep |
| Shadowfang Relics | [Black Wolf Bracers (3230)](https://www.wowhead.com/forever/item=3230) | [Fenrus the Devourer (4274)](https://www.wowhead.com/forever/npc=4274) | Shadowfang Keep |
| Shadowfang Relics | [Robes of Arugal (6324)](https://www.wowhead.com/forever/item=6324) | [Archmage Arugal (4275)](https://www.wowhead.com/forever/npc=4275) | Shadowfang Keep |
| Blackfathom Relics | [Tortoise Armor (6907)](https://www.wowhead.com/forever/item=6907) | [Ghamoo-ra (4887)](https://www.wowhead.com/forever/npc=4887) | Blackfathom Deeps |
| Blackfathom Relics | [Ghamoo-ra's Bind (6908)](https://www.wowhead.com/forever/item=6908) | [Ghamoo-ra (4887)](https://www.wowhead.com/forever/npc=4887) | Blackfathom Deeps |
| Blackfathom Relics | [Naga Battle Gloves (888)](https://www.wowhead.com/forever/item=888) | [Lady Sarevess (4831)](https://www.wowhead.com/forever/npc=4831) | Blackfathom Deeps |
| Blackfathom Relics | [Glowing Thresher Cape (6901)](https://www.wowhead.com/forever/item=6901) | [Old Serra'kis (4830)](https://www.wowhead.com/forever/npc=4830) | Blackfathom Deeps |
| Blackfathom Relics | [Bands of Serra'kis (6902)](https://www.wowhead.com/forever/item=6902) | [Old Serra'kis (4830)](https://www.wowhead.com/forever/npc=4830) | Blackfathom Deeps |
