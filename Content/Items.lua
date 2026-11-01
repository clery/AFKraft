local _, W = ...
local C = W.Content

C.itemStatOrder = {
    "strength",
    "agility",
    "intellect",
    "stamina",
    "spirit",
    "haste",
    "armor",
    "weaponDPS",
    "attackPower",
    "spellPower",
    "healingPower",
    "healthRegen",
    "arcaneResistance",
    "fireResistance",
    "frostResistance",
    "natureResistance",
    "shadowResistance",
}
C.itemStatNames = {
    strength = "Strength",
    agility = "Agility",
    intellect = "Intellect",
    stamina = "Stamina",
    spirit = "Spirit",
    haste = "Haste",
    armor = "Armor",
    weaponDPS = "Weapon DPS",
    attackPower = "Attack Power",
    spellPower = "Spell Power",
    healingPower = "Healing Power",
    healthRegen = "Health / 5 sec",
    arcaneResistance = "Arcane Resistance",
    fireResistance = "Fire Resistance",
    frostResistance = "Frost Resistance",
    natureResistance = "Nature Resistance",
    shadowResistance = "Shadow Resistance",
}
C.primaryStats = {
    WARRIOR = "strength",
    PALADIN = "strength",
    HUNTER = "agility",
    ROGUE = "agility",
    PRIEST = "intellect",
    SHAMAN = "intellect",
    MAGE = "intellect",
    WARLOCK = "intellect",
    DRUID = "intellect",
}

-- Fixed Classic-era tooltip snapshots; see Content/ITEMS.md. No client cache required.
C.items, C.itemByID = {}, {}
local function item(id, name, icon, slot, quality, requiredLevel, stats)
    local entry = {
        itemID = id,
        name = name,
        icon = icon,
        slot = slot,
        quality = quality,
        requiredLevel = requiredLevel,
        level = math.max(1, math.ceil(requiredLevel / 4)),
        stats = stats,
    }
    C.items[#C.items + 1], C.itemByID[id] = entry, entry
end

item(25, "Worn Shortsword", "inv_sword_04", 1, 1, 1, { weaponDPS = 1.05 })
item(35, "Bent Staff", "inv_staff_08", 1, 1, 1, { weaponDPS = 1.38 })
item(36, "Worn Mace", "inv_mace_03", 1, 1, 1, { weaponDPS = 1.05 })
item(37, "Worn Axe", "inv_axe_11", 1, 1, 1, { weaponDPS = 1.0 })
item(
    821,
    "Riverpaw Leather Vest",
    "inv_shirt_07",
    2,
    2,
    8,
    { agility = 1, stamina = 2, armor = 65 }
)
item(935, "Night Watch Shortsword", "inv_sword_26", 1, 3, 15, { stamina = 4, weaponDPS = 13.46 })
item(
    1455,
    "Blackrock Champion's Axe",
    "inv_weapon_halbard_01",
    1,
    2,
    19,
    { strength = 8, weaponDPS = 16.09 }
)
item(1539, "Gnarled Hermit's Staff", "inv_staff_17", 1, 2, 14, { spirit = 6, weaponDPS = 12.5 })
item(5111, "Rathorian's Cape", "inv_helmet_48", 4, 2, 10, { stamina = 2, armor = 14 })
item(1930, "Stonemason Cloak", "inv_misc_cape_11", 4, 2, 13, { stamina = 3, armor = 16 })
item(2961, "Burnt Leather Vest", "inv_shirt_09", 2, 2, 6, { spirit = 2, armor = 58 })
item(2973, "Hunting Tunic", "inv_chest_wolf", 2, 2, 12, { agility = 2, stamina = 4, armor = 73 })
item(2981, "Seer's Robe", "inv_chest_cloth_08", 2, 2, 16, { intellect = 6, spirit = 3, armor = 35 })
item(
    2985,
    "Inscribed Leather Breastplate",
    "inv_chest_leather_09",
    2,
    2,
    16,
    { stamina = 5, spirit = 3, armor = 79 }
)
item(
    3055,
    "Forest Leather Chestpiece",
    "inv_chest_leather_08",
    2,
    2,
    21,
    { stamina = 4, spirit = 7, armor = 87 }
)
item(3069, "Bright Robe", "inv_chest_cloth_26", 2, 2, 22, { intellect = 4, spirit = 8, armor = 41 })
item(
    4038,
    "Nightsky Robe",
    "inv_chest_cloth_28",
    2,
    2,
    32,
    { stamina = 8, intellect = 8, spirit = 8, armor = 49 }
)
item(
    4057,
    "Insignia Chestguard",
    "inv_chest_leather_06",
    2,
    2,
    31,
    { stamina = 13, spirit = 3, armor = 103 }
)
item(
    4074,
    "Mail Combat Armor",
    "inv_chest_chain_13",
    2,
    2,
    31,
    { strength = 13, stamina = 3, armor = 216 }
)
item(
    12988,
    "Starsight Tunic",
    "inv_chest_leather_10",
    2,
    3,
    17,
    { stamina = 4, spirit = 10, armor = 89 }
)
item(
    13110,
    "Wolffear Harness",
    "inv_chest_leather_04",
    2,
    3,
    31,
    { agility = 17, stamina = 6, spirit = 3, armor = 113 }
)
item(13009, "Cow King's Hide", "inv_chest_leather_06", 2, 3, 46, {
    stamina = 10,
    armor = 148,
    arcaneResistance = 10,
    fireResistance = 10,
    frostResistance = 10,
    natureResistance = 10,
    shadowResistance = 10,
})
item(
    13123,
    "Dreamwalker Armor",
    "inv_chest_chain_06",
    2,
    3,
    57,
    { stamina = 17, intellect = 20, spirit = 20, armor = 365 }
)
item(2721, "Holy Shroud", "inv_helmet_16", 3, 3, 27, { spirit = 6, armor = 40, healingPower = 33 })
item(3020, "Enduring Cap", "inv_helmet_15", 3, 3, 28, { intellect = 16, spirit = 7, armor = 88 })
item(
    13102,
    "Cassandra's Grace",
    "inv_jewelry_ring_03",
    3,
    3,
    42,
    { stamina = 7, spirit = 9, armor = 55, healingPower = 44 }
)
item(
    13113,
    "Feathermoon Headdress",
    "inv_helmet_04",
    3,
    3,
    58,
    { stamina = 13, intellect = 20, spirit = 21, armor = 143 }
)
item(
    13094,
    "The Queen's Jewel",
    "inv_jewelry_ring_26",
    4,
    3,
    25,
    { stamina = 1, intellect = 2, spirit = 8 }
)
item(
    13095,
    "Assault Band",
    "inv_jewelry_ring_04",
    4,
    3,
    39,
    { stamina = 7, spirit = 5, attackPower = 20 }
)
item(13097, "Thunderbrow Ring", "inv_jewelry_ring_09", 4, 3, 24, { strength = 8, agility = 3 })
item(
    13002,
    "Lady Alizabeth's Pendant",
    "inv_jewelry_amulet_03",
    4,
    3,
    54,
    { stamina = 8, spirit = 15 }
)
item(
    13085,
    "Horizon Choker",
    "inv_jewelry_necklace_11",
    4,
    3,
    46,
    { stamina = 4, intellect = 14, spirit = 4 }
)
item(
    13096,
    "Band of the Hierophant",
    "inv_jewelry_ring_17",
    4,
    3,
    55,
    { stamina = 7, intellect = 10, spirit = 11 }
)
item(
    13014,
    "Axe of Rin'ji",
    "inv_axe_21",
    1,
    3,
    48,
    { agility = 5, stamina = 11, weaponDPS = 35.0 }
)
item(13015, "Serathil", "inv_axe_08", 1, 3, 56, { strength = 9, armor = 100, weaponDPS = 40.0 })
item(
    13022,
    "Gryphonwing Long Bow",
    "inv_weapon_bow_11",
    1,
    3,
    50,
    { agility = 8, stamina = 4, weaponDPS = 28.33 }
)
item(
    13023,
    "Eaglehorn Long Bow",
    "inv_weapon_bow_11",
    1,
    3,
    58,
    { agility = 10, stamina = 4, weaponDPS = 32.22 }
)
item(
    13024,
    "Beazel's Basher",
    "inv_hammer_04",
    1,
    3,
    24,
    { strength = 6, spirit = 2, weaponDPS = 18.4 }
)
item(
    13027,
    "Bonesnapper",
    "inv_hammer_20",
    1,
    3,
    48,
    { strength = 11, stamina = 5, weaponDPS = 35.19 }
)
item(
    13028,
    "Bludstone Hammer",
    "inv_hammer_19",
    1,
    3,
    56,
    { stamina = 5, spirit = 12, weaponDPS = 40.24 }
)
item(
    13040,
    "Heartseeking Crossbow",
    "inv_weapon_crossbow_04",
    1,
    3,
    51,
    { agility = 9, stamina = 4, weaponDPS = 28.87 }
)
item(
    13043,
    "Blade of the Titans",
    "inv_sword_07",
    1,
    3,
    44,
    { strength = 10, stamina = 24, weaponDPS = 42.58 }
)
item(833, "Lifestone", "inv_ore_truesilver_01", 5, 4, 51, { healthRegen = 10 })

-- Curated zone encounters, not a claim to reproduce live drop rates.
C.zoneItems = {
    elwynn = { 25, 35, 36, 37, 2961, 821 },
    durotar = { 25, 35, 36, 37, 2961, 2973 },
    westfall = { 2973, 2981, 2985, 1930 },
    barrens = { 2973, 2981, 2985, 5111, 1539 },
    redridge = { 1455, 3055, 3069, 12988, 13097 },
    ashenvale = { 1539, 3055, 3069, 12988, 13094 },
    duskwood = { 935, 4038, 4057, 4074, 2721, 13097 },
    wetlands = { 935, 4038, 4057, 4074, 3020, 13094 },
    stranglethorn = { 13110, 4038, 4074, 13024, 13095, 13102 },
    desolace = { 13110, 4057, 4074, 13024, 13095, 13102 },
    tanaris = { 13009, 13014, 13022, 13027, 13040, 13043, 13085, 833 },
    winterspring = { 13123, 13113, 13015, 13023, 13028, 13002, 13096, 833 },
}
