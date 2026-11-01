# Item catalog

The catalog uses fixed Classic-era WoWhead tooltip snapshots, checked on 2026-11-01, rather than the connected client’s scaled item cache. Names, icon paths, rarity, primary attributes, armor, weapon DPS, attack power, healing power, resistances, and passive health regeneration come from those tooltips. The structured source for each entry is `https://nether.wowhead.com/classic/tooltip/item/ITEM_ID`. No network access is used by the addon.

## Idle adaptations

- Zone tables are curated minigame pools, not complete live mob loot tables or authentic drop percentages. Riverpaw Leather Vest belongs to Elwynn’s gnolls, Stonemason Cloak to Westfall’s Defias, Blackrock Champion’s Axe to Redridge’s Blackrock enemies, and Rathorian’s Cape to the Barrens. Other entries are level-appropriate world finds. Starter weapons are included to supply basic equipment.
- Source stats stay fixed. WoW required level maps to idle level as `max(1, ceil(requiredLevel / 4))`; items become available as encounter levels reach that requirement. An item’s source WoW requirement is also shown in its tooltip.
- Crafting chooses the nearest available source item for the selected slot and idle level. It retains the source rarity, rather than recoloring it. Low-level slots with no available source item cannot be crafted yet. Weapon and armor proficiencies, unique-equipped restrictions, and two-handed weapon rules are simplified by the existing six-slot idle inventory.
- One accessory slot represents a cloak, ring, or necklace; either trinket slot accepts Lifestone. More trinkets and low-level headgear can be added as verified entries later.
- An enhancement adds 10% of base stats, additively. Heirloom stats additionally scale by `hero idle level / source idle requirement`. Both are minigame enhancements, not claims about the original WoW item.
- Existing synthetic saved equipment keeps its identity, stacks, protections, effects, and purchased enhancements. Its old power is converted once into attributes; an active encounter from that older stat model restarts without rewards. New drops and crafts use catalog items.
- Heartseeking Crossbow’s Shadowbolt proc and Lifestone’s on-use heal are not simulated. Lifestone’s passive regeneration works. Cow King’s Hide retains its resistance values for display; damage schools are not modeled, so those values contribute no power. Tooltips identify these limitations.

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
| 13094 | [The Queen's Jewel](https://www.wowhead.com/classic/item=13094) |
| 13095 | [Assault Band](https://www.wowhead.com/classic/item=13095) |
| 13097 | [Thunderbrow Ring](https://www.wowhead.com/classic/item=13097) |
| 13002 | [Lady Alizabeth's Pendant](https://www.wowhead.com/classic/item=13002) |
| 13085 | [Horizon Choker](https://www.wowhead.com/classic/item=13085) |
| 13096 | [Band of the Hierophant](https://www.wowhead.com/classic/item=13096) |
| 13014 | [Axe of Rin'ji](https://www.wowhead.com/classic/item=13014) |
| 13015 | [Serathil](https://www.wowhead.com/classic/item=13015) |
| 13022 | [Gryphonwing Long Bow](https://www.wowhead.com/classic/item=13022) |
| 13023 | [Eaglehorn Long Bow](https://www.wowhead.com/classic/item=13023) |
| 13024 | [Beazel's Basher](https://www.wowhead.com/classic/item=13024) |
| 13027 | [Bonesnapper](https://www.wowhead.com/classic/item=13027) |
| 13028 | [Bludstone Hammer](https://www.wowhead.com/classic/item=13028) |
| 13040 | [Heartseeking Crossbow](https://www.wowhead.com/classic/item=13040) |
| 13043 | [Blade of the Titans](https://www.wowhead.com/classic/item=13043) |
| 833 | [Lifestone](https://www.wowhead.com/classic/item=833) |
