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

item(2962, "Burnt Leather Breeches", "inv_pants_06", 10, 2, 5, { agility = 1, armor = 48 })
item(2963, "Burnt Leather Boots", "inv_boots_09", 11, 1, 4, { armor = 34 })
item(2964, "Burnt Leather Gloves", "inv_gauntlets_18", 8, 1, 5, { armor = 33 })
item(2965, "Warrior's Tunic", "inv_chest_chain", 2, 2, 6, { strength = 2, armor = 115 })
item(2966, "Warrior's Pants", "inv_pants_03", 10, 2, 5, { stamina = 1, armor = 94 })
item(2967, "Warrior's Boots", "inv_boots_plate_08", 11, 1, 5, { armor = 70 })
item(2968, "Warrior's Gloves", "inv_gauntlets_28", 8, 1, 4, { armor = 59 })
item(2969, "Spellbinder Vest", "inv_chest_cloth_06", 2, 2, 12, { intellect = 5, armor = 30 })
item(
    2970,
    "Spellbinder Pants",
    "inv_pants_10",
    10,
    2,
    11,
    { stamina = 2, intellect = 3, armor = 25 }
)
item(2971, "Spellbinder Boots", "inv_boots_09", 11, 1, 9, { armor = 17 })
item(2972, "Spellbinder Gloves", "inv_gauntlets_21", 8, 1, 9, { armor = 16 })
item(2974, "Hunting Pants", "inv_pants_wolf", 10, 2, 11, { agility = 3, spirit = 2, armor = 62 })
item(2975, "Hunting Boots", "inv_boots_wolf", 11, 1, 9, { armor = 45 })
item(2976, "Hunting Gloves", "inv_gauntlets_05", 8, 2, 10, { agility = 2, stamina = 1, armor = 43 })
item(
    2977,
    "Veteran Armor",
    "inv_chest_chain_09",
    2,
    2,
    11,
    { strength = 3, stamina = 2, armor = 151 }
)
item(
    2978,
    "Veteran Leggings",
    "inv_pants_09",
    10,
    2,
    10,
    { strength = 2, agility = 2, armor = 126 }
)
item(2979, "Veteran Boots", "inv_boots_09", 11, 1, 9, { armor = 89 })
item(2980, "Veteran Gloves", "inv_gauntlets_05", 8, 2, 10, { strength = 3, armor = 90 })
item(2982, "Seer's Pants", "inv_pants_01", 10, 2, 15, { stamina = 3, spirit = 5, armor = 29 })
item(2983, "Seer's Boots", "inv_boots_05", 11, 2, 12, { stamina = 3, intellect = 1, armor = 21 })
item(2984, "Seer's Gloves", "inv_gauntlets_18", 8, 2, 13, { spirit = 4, armor = 20 })
item(
    2986,
    "Inscribed Leather Pants",
    "inv_pants_02",
    10,
    2,
    15,
    { stamina = 4, intellect = 4, armor = 68 }
)
item(
    2987,
    "Inscribed Leather Boots",
    "inv_boots_05",
    11,
    2,
    13,
    { agility = 2, stamina = 3, armor = 51 }
)
item(
    2988,
    "Inscribed Leather Gloves",
    "inv_gauntlets_18",
    8,
    2,
    14,
    { agility = 2, spirit = 3, armor = 47 }
)
item(
    2989,
    "Burnished Tunic",
    "inv_chest_chain_06",
    2,
    2,
    16,
    { strength = 6, stamina = 3, armor = 171 }
)
item(3065, "Bright Boots", "inv_boots_07", 11, 2, 18, { stamina = 5, spirit = 2, armor = 25 })
item(3066, "Bright Gloves", "inv_gauntlets_23", 8, 2, 19, { intellect = 4, spirit = 4, armor = 24 })
item(3067, "Bright Pants", "inv_pants_02", 10, 2, 21, { stamina = 6, spirit = 6, armor = 35 })
item(
    4035,
    "Silver-thread Robe",
    "inv_chest_cloth_32",
    2,
    2,
    26,
    { intellect = 11, spirit = 4, armor = 44 }
)
item(
    4036,
    "Silver-thread Cuffs",
    "inv_bracer_07",
    12,
    2,
    22,
    { stamina = 2, intellect = 5, armor = 18 }
)
item(
    4037,
    "Silver-thread Pants",
    "inv_pants_08",
    10,
    2,
    25,
    { stamina = 4, intellect = 8, spirit = 4, armor = 37 }
)
item(4039, "Nightsky Cowl", "inv_helmet_30", 3, 2, 30, { intellect = 12, spirit = 5, armor = 38 })
item(
    4040,
    "Nightsky Gloves",
    "inv_gauntlets_21",
    8,
    2,
    29,
    { stamina = 7, intellect = 6, armor = 29 }
)
item(4041, "Aurora Cowl", "inv_helmet_33", 3, 2, 34, { stamina = 10, intellect = 10, armor = 42 })
item(
    4042,
    "Aurora Gloves",
    "inv_gauntlets_27",
    8,
    2,
    34,
    { agility = 8, intellect = 8, armor = 32 }
)
item(4043, "Aurora Bracers", "inv_bracer_07", 12, 2, 33, { stamina = 2, intellect = 8, armor = 22 })
item(4044, "Aurora Pants", "inv_pants_01", 10, 2, 35, { intellect = 11, spirit = 10, armor = 46 })
item(
    4045,
    "Mistscape Bracers",
    "inv_bracer_09",
    12,
    2,
    37,
    { stamina = 3, intellect = 8, armor = 24 }
)
item(
    4071,
    "Glimmering Mail Breastplate",
    "inv_chest_plate16",
    2,
    2,
    26,
    { strength = 3, stamina = 11, armor = 201 }
)
item(
    4072,
    "Glimmering Mail Gauntlets",
    "inv_gauntlets_03",
    8,
    2,
    25,
    { strength = 7, agility = 3, armor = 124 }
)
item(
    4073,
    "Glimmering Mail Greaves",
    "inv_boots_plate_03",
    11,
    2,
    26,
    { strength = 6, stamina = 6, armor = 138 }
)
item(4694, "Burnished Pauldrons", "inv_shoulder_28", 7, 1, 17, { armor = 124 })
item(4701, "Inscribed Cloak", "inv_misc_cape_11", 4, 2, 11, { stamina = 2, armor = 15 })
item(
    4713,
    "Silver-thread Cloak",
    "inv_misc_cape_02",
    4,
    2,
    21,
    { intellect = 4, spirit = 2, armor = 20 }
)
item(
    4714,
    "Silver-thread Sash",
    "inv_belt_03",
    9,
    2,
    22,
    { stamina = 4, intellect = 5, armor = 23 }
)
item(4721, "Insignia Mantle", "inv_shoulder_07", 7, 2, 30, { agility = 7, spirit = 7, armor = 76 })
item(
    13115,
    "Sheepshear Mantle",
    "inv_shoulder_19",
    7,
    3,
    40,
    { stamina = 3, intellect = 16, spirit = 6, armor = 100 }
)
item(
    13116,
    "Spaulders of the Unseen",
    "inv_shoulder_18",
    7,
    3,
    56,
    { agility = 22, stamina = 7, intellect = 4, armor = 129 }
)
item(
    13117,
    "Ogron's Sash",
    "inv_belt_15",
    9,
    3,
    37,
    { strength = 9, agility = 9, stamina = 9, armor = 71 }
)
item(
    13118,
    "Serpentine Sash",
    "inv_belt_25",
    9,
    3,
    52,
    { strength = 9, agility = 14, stamina = 14, armor = 92 }
)
item(
    13119,
    "Enchanted Kodo Bracers",
    "inv_bracer_09",
    12,
    3,
    34,
    { intellect = 4, spirit = 10, armor = 52 }
)
item(
    13120,
    "Deepfury Bracers",
    "inv_bracer_07",
    12,
    3,
    50,
    { strength = 4, agility = 15, stamina = 4, armor = 69 }
)
item(
    13121,
    "Wing of the Whelpling",
    "inv_misc_cape_04",
    4,
    3,
    33,
    { agility = 4, stamina = 10, armor = 28 }
)
item(
    13122,
    "Dark Phantom Cape",
    "inv_misc_cape_21",
    4,
    3,
    50,
    { agility = 15, spirit = 6, armor = 39 }
)
item(
    13099,
    "Moccasins of the White Hare",
    "inv_boots_05",
    11,
    3,
    24,
    { agility = 3, spirit = 8, armor = 32 }
)
item(13100, "Furen's Boots", "inv_boots_03", 11, 3, 39, { intellect = 7, spirit = 16, armor = 44 })
item(
    13101,
    "Wolfrunner Shoes",
    "inv_boots_05",
    11,
    3,
    54,
    { stamina = 11, intellect = 11, spirit = 11, armor = 58, spellPower = 13 }
)
item(
    13103,
    "Pads of the Venom Spider",
    "inv_shoulder_18",
    7,
    3,
    33,
    { stamina = 12, spirit = 6, natureResistance = 5, armor = 41 }
)
item(
    13105,
    "Sutarn's Ring",
    "inv_belt_11",
    9,
    3,
    32,
    { stamina = 6, intellect = 10, spirit = 6, armor = 30 }
)
item(
    13106,
    "Glowing Magical Bracelets",
    "inv_bracer_19",
    12,
    3,
    26,
    { strength = 3, intellect = 8, armor = 21 }
)
item(
    13107,
    "Magiskull Cuffs",
    "inv_bracer_13",
    12,
    3,
    57,
    { stamina = 7, intellect = 17, armor = 38 }
)
item(
    13108,
    "Tigerstrike Mantle",
    "inv_misc_pelt_04",
    4,
    3,
    29,
    { agility = 8, stamina = 7, armor = 25 }
)
item(
    13109,
    "Blackflame Cape",
    "inv_misc_cape_20",
    4,
    3,
    44,
    { agility = 12, fireResistance = 5, shadowResistance = 5, armor = 35 }
)
item(
    13111,
    "Sandals of the Insurgent",
    "inv_boots_fabric_01",
    11,
    3,
    49,
    { intellect = 8, spirit = 20, armor = 107 }
)
item(13112, "Winged Helm", "inv_helmet_19", 3, 3, 43, { intellect = 23, spirit = 10, armor = 115 })
item(
    13114,
    "Troll's Bane Leggings",
    "inv_pants_06",
    10,
    3,
    25,
    { agility = 14, stamina = 4, spirit = 4, armor = 90 }
)
item(4666, "Burnt Leather Belt", "inv_belt_04", 9, 1, 4, { armor = 27 })
item(3200, "Burnt Leather Bracers", "inv_bracer_10", 12, 1, 3, { armor = 20 })
item(3213, "Veteran Bracers", "inv_bracer_05", 12, 1, 8, { armor = 54 })
item(14169, "Aboriginal Shoulder Pads", "inv_shoulder_06", 7, 1, 16, { armor = 25 })
item(1280, "Cloaked Hood", "inv_helmet_30", 3, 2, 33, { agility = 10, stamina = 10, armor = 86 })
item(
    12987,
    "Darkweave Breeches",
    "inv_pants_06",
    10,
    3,
    17,
    { stamina = 4, intellect = 7, spirit = 6, armor = 35 }
)
item(
    12977,
    "Magefist Gloves",
    "inv_gauntlets_27",
    8,
    3,
    15,
    { stamina = 3, intellect = 5, spirit = 4, armor = 23 }
)
item(
    13010,
    "Dreamsinger Legguards",
    "inv_pants_03",
    10,
    3,
    21,
    { strength = 8, stamina = 8, spirit = 5, armor = 179 }
)
item(
    13124,
    "Ravasaur Scale Boots",
    "inv_boots_01",
    11,
    3,
    30,
    { strength = 3, stamina = 11, spirit = 5, armor = 161 }
)
item(
    13125,
    "Elven Chain Boots",
    "inv_boots_01",
    11,
    3,
    45,
    { agility = 18, stamina = 3, spirit = 7, armor = 206 }
)
item(
    13126,
    "Battlecaller Gauntlets",
    "inv_gauntlets_10",
    8,
    3,
    48,
    { strength = 8, stamina = 9, spirit = 15, armor = 198 }
)
item(
    13127,
    "Frostreaver Crown",
    "inv_helmet_24",
    3,
    3,
    27,
    { strength = 4, stamina = 15, spirit = 4, armor = 182 }
)
item(
    13128,
    "High Bergg Helm",
    "inv_helmet_18",
    3,
    3,
    42,
    { stamina = 10, intellect = 15, spirit = 15, armor = 231 }
)
item(
    13129,
    "Firemane Leggings",
    "inv_pants_03",
    10,
    3,
    34,
    { strength = 19, stamina = 5, fireResistance = 10, armor = 218 }
)
item(
    13130,
    "Windrunner Legguards",
    "inv_pants_03",
    10,
    3,
    51,
    { agility = 27, spirit = 11, armor = 291 }
)
item(
    13131,
    "Sparkleshell Mantle",
    "inv_shoulder_18",
    7,
    3,
    24,
    { agility = 4, stamina = 10, armor = 161 }
)
item(
    13132,
    "Skeletal Shoulders",
    "inv_shoulder_11",
    7,
    3,
    38,
    { strength = 6, stamina = 15, armor = 199 }
)

item(
    13066,
    "Wyrmslayer Spaulders",
    "inv_shoulder_24",
    7,
    3,
    46,
    { strength = 12, agility = 8, stamina = 12, armor = 403 }
)
item(
    13067,
    "Hydralick Armor",
    "inv_chest_plate06",
    2,
    3,
    49,
    { strength = 13, agility = 8, stamina = 20, fireResistance = 10, armor = 567 }
)
item(
    13068,
    "Obsidian Greaves",
    "inv_boots_plate_09",
    11,
    3,
    40,
    { strength = 10, agility = 6, stamina = 10, armor = 257 }
)
item(
    13071,
    "Plated Fist of Hakoo",
    "inv_gauntlets_10",
    8,
    3,
    40,
    { strength = 10, agility = 10, stamina = 10, armor = 300 }
)
item(
    13073,
    "Mugthol's Helm",
    "inv_helmet_25",
    3,
    3,
    47,
    { strength = 10, stamina = 17, spirit = 17, armor = 445 }
)
item(13074, "Golem Shard Leggings", "inv_pants_04", 10, 3, 41, { strength = 22, armor = 429 })
item(
    13076,
    "Giantslayer Bracers",
    "inv_bracer_17",
    12,
    3,
    43,
    { strength = 10, agility = 5, stamina = 6, armor = 223 }
)
item(
    13077,
    "Girdle of Uther",
    "inv_belt_32",
    9,
    3,
    52,
    { strength = 9, agility = 9, stamina = 10, intellect = 9, spirit = 10, armor = 336 }
)

item(10046, "Simple Linen Boots", "inv_boots_05", 11, 1, 4, { armor = 11 })
item(10045, "Simple Linen Pants", "inv_pants_11", 10, 1, 2, { armor = 12 })
item(2568, "Brown Linen Vest", "inv_shirt_05", 2, 1, 3, { armor = 15 })

C.armorRanks = { cloth = 1, leather = 2, mail = 3, plate = 4 }
C.armorNames = { cloth = "Cloth", leather = "Leather", mail = "Mail", plate = "Plate" }
C.classArmor = {
    WARRIOR = { 3, 4 },
    PALADIN = { 3, 4 },
    HUNTER = { 2, 3 },
    SHAMAN = { 2, 3 },
    ROGUE = { 2, 2 },
    DRUID = { 2, 2 },
    MAGE = { 1, 1 },
    PRIEST = { 1, 1 },
    WARLOCK = { 1, 1 },
}
-- Source armor subclasses, independent of client-scaled item data.
local armorItems = {
    cloth = {
        10046,
        10045,
        2568,
        2981,
        3069,
        4038,
        2721,
        13102,
        2969,
        2970,
        2971,
        2972,
        2982,
        2983,
        2984,
        3065,
        3066,
        3067,
        4035,
        4036,
        4037,
        4039,
        4040,
        4041,
        4042,
        4043,
        4044,
        4045,
        4714,
        13099,
        13100,
        13101,
        13103,
        13105,
        13106,
        13107,
        14169,
        12987,
        12977,
    },
    leather = {
        821,
        2961,
        2973,
        2985,
        3055,
        4057,
        12988,
        13110,
        13009,
        3020,
        13113,
        2962,
        2963,
        2964,
        2974,
        2975,
        2976,
        2986,
        2987,
        2988,
        4721,
        13115,
        13116,
        13117,
        13118,
        13119,
        13120,
        13111,
        13112,
        13114,
        4666,
        3200,
        1280,
    },
    mail = {
        4074,
        13123,
        2965,
        2966,
        2967,
        2968,
        2977,
        2978,
        2979,
        2980,
        2989,
        4071,
        4072,
        4073,
        4694,
        3213,
        13010,
        13124,
        13125,
        13126,
        13127,
        13128,
        13129,
        13130,
        13131,
        13132,
    },
    plate = { 13066, 13067, 13068, 13071, 13073, 13074, 13076, 13077 },
}
for armorType, items in pairs(armorItems) do
    for _, id in ipairs(items) do
        C.itemByID[id].armorType = armorType
    end
end

-- Curated zone encounters, not a claim to reproduce live drop rates.
C.zoneItems = {
    elwynn = {
        10046,
        10045,
        2568,
        25,
        35,
        36,
        37,
        2961,
        821,
        2962,
        2963,
        2964,
        2965,
        2966,
        2967,
        2968,
        4666,
        3200,
        3213,
    },
    durotar = {
        10046,
        10045,
        2568,
        25,
        35,
        36,
        37,
        2961,
        2973,
        2962,
        2963,
        2964,
        2965,
        2966,
        2967,
        2968,
        4666,
        3200,
        3213,
    },
    westfall = {
        2973,
        2981,
        2985,
        1930,
        2969,
        2970,
        2971,
        2972,
        2974,
        2975,
        2976,
        2977,
        2978,
        2979,
        2980,
        2982,
        2983,
        2984,
        2986,
        2987,
        2988,
        2989,
        4701,
        14169,
        12977,
    },
    barrens = {
        2973,
        2981,
        2985,
        5111,
        1539,
        2969,
        2970,
        2971,
        2972,
        2974,
        2975,
        2976,
        2977,
        2978,
        2979,
        2980,
        2982,
        2983,
        2984,
        2986,
        2987,
        2988,
        2989,
        4701,
        14169,
        12977,
    },
    redridge = {
        1455,
        3055,
        3069,
        12988,
        3065,
        3066,
        3067,
        4036,
        4694,
        4713,
        4714,
        13099,
        12987,
        13010,
        13131,
    },
    ashenvale = {
        1539,
        3055,
        3069,
        12988,
        3065,
        3066,
        3067,
        4036,
        4694,
        4713,
        4714,
        13099,
        12987,
        13010,
        13131,
    },
    duskwood = {
        935,
        4038,
        4057,
        4074,
        2721,
        4035,
        4037,
        4039,
        4040,
        4071,
        4072,
        4073,
        4721,
        13105,
        13106,
        13108,
        13114,
        13124,
        13127,
    },
    wetlands = {
        935,
        4038,
        4057,
        4074,
        3020,
        4035,
        4037,
        4039,
        4040,
        4071,
        4072,
        4073,
        4721,
        13105,
        13106,
        13108,
        13114,
        13124,
        13127,
    },
    stranglethorn = {
        13110,
        4038,
        4074,
        13024,
        13102,
        4041,
        4042,
        4043,
        4044,
        4045,
        13115,
        13117,
        13119,
        13121,
        13100,
        13103,
        1280,
        13129,
        13132,
    },
    desolace = {
        13110,
        4057,
        4074,
        13024,
        13102,
        4041,
        4042,
        4043,
        4044,
        4045,
        13115,
        13117,
        13119,
        13121,
        13100,
        13103,
        1280,
        13129,
        13132,
    },
    tanaris = {
        13066,
        13067,
        13068,
        13071,
        13073,
        13074,
        13076,
        13009,
        13014,
        13022,
        13027,
        13040,
        13043,
        13120,
        13122,
        13109,
        13111,
        13112,
        13125,
        13126,
        13128,
    },
    winterspring = {
        13066,
        13067,
        13068,
        13071,
        13073,
        13074,
        13076,
        13077,
        13123,
        13113,
        13015,
        13023,
        13028,
        13116,
        13118,
        13101,
        13107,
        13130,
    },
}
