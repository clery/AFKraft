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
- In Loot, disenchant a stored equipment stack for gold (idle level × rarity per copy) and Relic dust (rarity − 1 per copy, minimum 1). The full stack reward is shown before destruction. Heirlooms and protected items cannot be disenchanted; equipped items must first return to inventory. Disenchanting grants no Essence and does not refund upgrades. Automatic salvage rules continue to apply only to future drops, awarding gold and ore.
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
