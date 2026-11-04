local _, W = ...
local L = W.L
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
    strength = L.STRENGTH,
    agility = L.AGILITY,
    intellect = L.INTELLECT,
    stamina = L.STAMINA,
    spirit = L.SPIRIT,
    haste = L.HASTE,
    armor = L.ARMOR,
    weaponDPS = L.WEAPON_DPS,
    attackPower = L.ATTACK_POWER,
    spellPower = L.SPELL_POWER,
    healingPower = L.HEALING_POWER,
    healthRegen = L.HEALTH_5_SEC,
    arcaneResistance = L.ARCANE_RESISTANCE,
    fireResistance = L.FIRE_RESISTANCE,
    frostResistance = L.FROST_RESISTANCE,
    natureResistance = L.NATURE_RESISTANCE,
    shadowResistance = L.SHADOW_RESISTANCE,
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
C.items, C.itemByID, C.itemNames, C.itemNotes = {}, {}, {}, {}
local function item(id, nameKey, icon, slot, quality, requiredLevel, stats, noteKey)
    local entry = {
        itemID = id,
        name = W.Locales.enUS[nameKey],
        icon = icon,
        slot = slot,
        quality = quality,
        requiredLevel = requiredLevel,
        level = math.max(1, math.ceil(requiredLevel / 4)),
        stats = stats,
        note = noteKey and W.Locales.enUS[noteKey],
    }
    C.itemNames[id] = L[nameKey]
    C.itemNotes[id] = noteKey and L[noteKey]
    C.items[#C.items + 1], C.itemByID[id] = entry, entry
end

item(25, "ITEM_WORN_SHORTSWORD", "inv_sword_04", 1, 1, 1, { weaponDPS = 1.05 })
item(35, "ITEM_BENT_STAFF", "inv_staff_08", 1, 1, 1, { weaponDPS = 1.38 })
item(36, "ITEM_WORN_MACE", "inv_mace_03", 1, 1, 1, { weaponDPS = 1.05 })
item(37, "ITEM_WORN_AXE", "inv_axe_11", 1, 1, 1, { weaponDPS = 1.0 })
item(
    821,
    "ITEM_RIVERPAW_LEATHER_VEST",
    "inv_shirt_07",
    2,
    2,
    8,
    { agility = 1, stamina = 2, armor = 65 }
)
item(
    935,
    "ITEM_NIGHT_WATCH_SHORTSWORD",
    "inv_sword_26",
    1,
    3,
    15,
    { stamina = 4, weaponDPS = 13.46 }
)
item(
    1455,
    "ITEM_BLACKROCK_CHAMPION_S_AXE",
    "inv_weapon_halbard_01",
    1,
    2,
    19,
    { strength = 8, weaponDPS = 16.09 }
)
item(
    1539,
    "ITEM_GNARLED_HERMIT_S_STAFF",
    "inv_staff_17",
    1,
    2,
    14,
    { spirit = 6, weaponDPS = 12.5 }
)
item(5111, "ITEM_RATHORIAN_S_CAPE", "inv_helmet_48", 4, 2, 10, { stamina = 2, armor = 14 })
item(1930, "ITEM_STONEMASON_CLOAK", "inv_misc_cape_11", 4, 2, 13, { stamina = 3, armor = 16 })
item(2961, "ITEM_BURNT_LEATHER_VEST", "inv_shirt_09", 2, 2, 6, { spirit = 2, armor = 58 })
item(
    2973,
    "ITEM_HUNTING_TUNIC",
    "inv_chest_wolf",
    2,
    2,
    12,
    { agility = 2, stamina = 4, armor = 73 }
)
item(
    2981,
    "ITEM_SEER_S_ROBE",
    "inv_chest_cloth_08",
    2,
    2,
    16,
    { intellect = 6, spirit = 3, armor = 35 }
)
item(
    2985,
    "ITEM_INSCRIBED_LEATHER_BREASTPLATE",
    "inv_chest_leather_09",
    2,
    2,
    16,
    { stamina = 5, spirit = 3, armor = 79 }
)
item(
    3055,
    "ITEM_FOREST_LEATHER_CHESTPIECE",
    "inv_chest_leather_08",
    2,
    2,
    21,
    { stamina = 4, spirit = 7, armor = 87 }
)
item(
    3069,
    "ITEM_BRIGHT_ROBE",
    "inv_chest_cloth_26",
    2,
    2,
    22,
    { intellect = 4, spirit = 8, armor = 41 }
)
item(
    4038,
    "ITEM_NIGHTSKY_ROBE",
    "inv_chest_cloth_28",
    2,
    2,
    32,
    { stamina = 8, intellect = 8, spirit = 8, armor = 49 }
)
item(
    4057,
    "ITEM_INSIGNIA_CHESTGUARD",
    "inv_chest_leather_06",
    2,
    2,
    31,
    { stamina = 13, spirit = 3, armor = 103 }
)
item(
    4074,
    "ITEM_MAIL_COMBAT_ARMOR",
    "inv_chest_chain_13",
    2,
    2,
    31,
    { strength = 13, stamina = 3, armor = 216 }
)
item(
    12988,
    "ITEM_STARSIGHT_TUNIC",
    "inv_chest_leather_10",
    2,
    3,
    17,
    { stamina = 4, spirit = 10, armor = 89 }
)
item(
    13110,
    "ITEM_WOLFFEAR_HARNESS",
    "inv_chest_leather_04",
    2,
    3,
    31,
    { agility = 17, stamina = 6, spirit = 3, armor = 113 }
)
item(13009, "ITEM_COW_KING_S_HIDE", "inv_chest_leather_06", 2, 3, 46, {
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
    "ITEM_DREAMWALKER_ARMOR",
    "inv_chest_chain_06",
    2,
    3,
    57,
    { stamina = 17, intellect = 20, spirit = 20, armor = 365 }
)
item(
    2721,
    "ITEM_HOLY_SHROUD",
    "inv_helmet_16",
    3,
    3,
    27,
    { spirit = 6, armor = 40, healingPower = 33 }
)
item(
    3020,
    "ITEM_ENDURING_CAP",
    "inv_helmet_15",
    3,
    3,
    28,
    { intellect = 16, spirit = 7, armor = 88 }
)
item(
    13102,
    "ITEM_CASSANDRA_S_GRACE",
    "inv_jewelry_ring_03",
    3,
    3,
    42,
    { stamina = 7, spirit = 9, armor = 55, healingPower = 44 }
)
item(
    13113,
    "ITEM_FEATHERMOON_HEADDRESS",
    "inv_helmet_04",
    3,
    3,
    58,
    { stamina = 13, intellect = 20, spirit = 21, armor = 143 }
)
item(
    13014,
    "ITEM_AXE_OF_RIN_JI",
    "inv_axe_21",
    1,
    3,
    48,
    { agility = 5, stamina = 11, weaponDPS = 35.0 }
)
item(
    13015,
    "ITEM_SERATHIL",
    "inv_axe_08",
    1,
    3,
    56,
    { strength = 9, armor = 100, weaponDPS = 40.0 }
)
item(
    13022,
    "ITEM_GRYPHONWING_LONG_BOW",
    "inv_weapon_bow_11",
    1,
    3,
    50,
    { agility = 8, stamina = 4, weaponDPS = 28.33 }
)
item(
    13023,
    "ITEM_EAGLEHORN_LONG_BOW",
    "inv_weapon_bow_11",
    1,
    3,
    58,
    { agility = 10, stamina = 4, weaponDPS = 32.22 }
)
item(
    13024,
    "ITEM_BEAZEL_S_BASHER",
    "inv_hammer_04",
    1,
    3,
    24,
    { strength = 6, spirit = 2, weaponDPS = 18.4 }
)
item(
    13027,
    "ITEM_BONESNAPPER",
    "inv_hammer_20",
    1,
    3,
    48,
    { strength = 11, stamina = 5, weaponDPS = 35.19 }
)
item(
    13028,
    "ITEM_BLUDSTONE_HAMMER",
    "inv_hammer_19",
    1,
    3,
    56,
    { stamina = 5, spirit = 12, weaponDPS = 40.24 }
)
item(
    13040,
    "ITEM_HEARTSEEKING_CROSSBOW",
    "inv_weapon_crossbow_04",
    1,
    3,
    51,
    { agility = 9, stamina = 4, weaponDPS = 28.87 }
)
item(
    13043,
    "ITEM_BLADE_OF_THE_TITANS",
    "inv_sword_07",
    1,
    3,
    44,
    { strength = 10, stamina = 24, weaponDPS = 42.58 }
)

item(2962, "ITEM_BURNT_LEATHER_BREECHES", "inv_pants_06", 10, 2, 5, { agility = 1, armor = 48 })
item(2963, "ITEM_BURNT_LEATHER_BOOTS", "inv_boots_09", 11, 1, 4, { armor = 34 })
item(2964, "ITEM_BURNT_LEATHER_GLOVES", "inv_gauntlets_18", 8, 1, 5, { armor = 33 })
item(2965, "ITEM_WARRIOR_S_TUNIC", "inv_chest_chain", 2, 2, 6, { strength = 2, armor = 115 })
item(2966, "ITEM_WARRIOR_S_PANTS", "inv_pants_03", 10, 2, 5, { stamina = 1, armor = 94 })
item(2967, "ITEM_WARRIOR_S_BOOTS", "inv_boots_plate_08", 11, 1, 5, { armor = 70 })
item(2968, "ITEM_WARRIOR_S_GLOVES", "inv_gauntlets_28", 8, 1, 4, { armor = 59 })
item(2969, "ITEM_SPELLBINDER_VEST", "inv_chest_cloth_06", 2, 2, 12, { intellect = 5, armor = 30 })
item(
    2970,
    "ITEM_SPELLBINDER_PANTS",
    "inv_pants_10",
    10,
    2,
    11,
    { stamina = 2, intellect = 3, armor = 25 }
)
item(2971, "ITEM_SPELLBINDER_BOOTS", "inv_boots_09", 11, 1, 9, { armor = 17 })
item(2972, "ITEM_SPELLBINDER_GLOVES", "inv_gauntlets_21", 8, 1, 9, { armor = 16 })
item(
    2974,
    "ITEM_HUNTING_PANTS",
    "inv_pants_wolf",
    10,
    2,
    11,
    { agility = 3, spirit = 2, armor = 62 }
)
item(2975, "ITEM_HUNTING_BOOTS", "inv_boots_wolf", 11, 1, 9, { armor = 45 })
item(
    2976,
    "ITEM_HUNTING_GLOVES",
    "inv_gauntlets_05",
    8,
    2,
    10,
    { agility = 2, stamina = 1, armor = 43 }
)
item(
    2977,
    "ITEM_VETERAN_ARMOR",
    "inv_chest_chain_09",
    2,
    2,
    11,
    { strength = 3, stamina = 2, armor = 151 }
)
item(
    2978,
    "ITEM_VETERAN_LEGGINGS",
    "inv_pants_09",
    10,
    2,
    10,
    { strength = 2, agility = 2, armor = 126 }
)
item(2979, "ITEM_VETERAN_BOOTS", "inv_boots_09", 11, 1, 9, { armor = 89 })
item(2980, "ITEM_VETERAN_GLOVES", "inv_gauntlets_05", 8, 2, 10, { strength = 3, armor = 90 })
item(2982, "ITEM_SEER_S_PANTS", "inv_pants_01", 10, 2, 15, { stamina = 3, spirit = 5, armor = 29 })
item(
    2983,
    "ITEM_SEER_S_BOOTS",
    "inv_boots_05",
    11,
    2,
    12,
    { stamina = 3, intellect = 1, armor = 21 }
)
item(2984, "ITEM_SEER_S_GLOVES", "inv_gauntlets_18", 8, 2, 13, { spirit = 4, armor = 20 })
item(
    2986,
    "ITEM_INSCRIBED_LEATHER_PANTS",
    "inv_pants_02",
    10,
    2,
    15,
    { stamina = 4, intellect = 4, armor = 68 }
)
item(
    2987,
    "ITEM_INSCRIBED_LEATHER_BOOTS",
    "inv_boots_05",
    11,
    2,
    13,
    { agility = 2, stamina = 3, armor = 51 }
)
item(
    2988,
    "ITEM_INSCRIBED_LEATHER_GLOVES",
    "inv_gauntlets_18",
    8,
    2,
    14,
    { agility = 2, spirit = 3, armor = 47 }
)
item(
    2989,
    "ITEM_BURNISHED_TUNIC",
    "inv_chest_chain_06",
    2,
    2,
    16,
    { strength = 6, stamina = 3, armor = 171 }
)
item(3065, "ITEM_BRIGHT_BOOTS", "inv_boots_07", 11, 2, 18, { stamina = 5, spirit = 2, armor = 25 })
item(
    3066,
    "ITEM_BRIGHT_GLOVES",
    "inv_gauntlets_23",
    8,
    2,
    19,
    { intellect = 4, spirit = 4, armor = 24 }
)
item(3067, "ITEM_BRIGHT_PANTS", "inv_pants_02", 10, 2, 21, { stamina = 6, spirit = 6, armor = 35 })
item(
    4035,
    "ITEM_SILVER_THREAD_ROBE",
    "inv_chest_cloth_32",
    2,
    2,
    26,
    { intellect = 11, spirit = 4, armor = 44 }
)
item(
    4036,
    "ITEM_SILVER_THREAD_CUFFS",
    "inv_bracer_07",
    12,
    2,
    22,
    { stamina = 2, intellect = 5, armor = 18 }
)
item(
    4037,
    "ITEM_SILVER_THREAD_PANTS",
    "inv_pants_08",
    10,
    2,
    25,
    { stamina = 4, intellect = 8, spirit = 4, armor = 37 }
)
item(
    4039,
    "ITEM_NIGHTSKY_COWL",
    "inv_helmet_30",
    3,
    2,
    30,
    { intellect = 12, spirit = 5, armor = 38 }
)
item(
    4040,
    "ITEM_NIGHTSKY_GLOVES",
    "inv_gauntlets_21",
    8,
    2,
    29,
    { stamina = 7, intellect = 6, armor = 29 }
)
item(
    4041,
    "ITEM_AURORA_COWL",
    "inv_helmet_33",
    3,
    2,
    34,
    { stamina = 10, intellect = 10, armor = 42 }
)
item(
    4042,
    "ITEM_AURORA_GLOVES",
    "inv_gauntlets_27",
    8,
    2,
    34,
    { agility = 8, intellect = 8, armor = 32 }
)
item(
    4043,
    "ITEM_AURORA_BRACERS",
    "inv_bracer_07",
    12,
    2,
    33,
    { stamina = 2, intellect = 8, armor = 22 }
)
item(
    4044,
    "ITEM_AURORA_PANTS",
    "inv_pants_01",
    10,
    2,
    35,
    { intellect = 11, spirit = 10, armor = 46 }
)
item(
    4045,
    "ITEM_MISTSCAPE_BRACERS",
    "inv_bracer_09",
    12,
    2,
    37,
    { stamina = 3, intellect = 8, armor = 24 }
)
item(
    4071,
    "ITEM_GLIMMERING_MAIL_BREASTPLATE",
    "inv_chest_plate16",
    2,
    2,
    26,
    { strength = 3, stamina = 11, armor = 201 }
)
item(
    4072,
    "ITEM_GLIMMERING_MAIL_GAUNTLETS",
    "inv_gauntlets_03",
    8,
    2,
    25,
    { strength = 7, agility = 3, armor = 124 }
)
item(
    4073,
    "ITEM_GLIMMERING_MAIL_GREAVES",
    "inv_boots_plate_03",
    11,
    2,
    26,
    { strength = 6, stamina = 6, armor = 138 }
)
item(4694, "ITEM_BURNISHED_PAULDRONS", "inv_shoulder_28", 7, 1, 17, { armor = 124 })
item(4701, "ITEM_INSCRIBED_CLOAK", "inv_misc_cape_11", 4, 2, 11, { stamina = 2, armor = 15 })
item(
    4713,
    "ITEM_SILVER_THREAD_CLOAK",
    "inv_misc_cape_02",
    4,
    2,
    21,
    { intellect = 4, spirit = 2, armor = 20 }
)
item(
    4714,
    "ITEM_SILVER_THREAD_SASH",
    "inv_belt_03",
    9,
    2,
    22,
    { stamina = 4, intellect = 5, armor = 23 }
)
item(
    4721,
    "ITEM_INSIGNIA_MANTLE",
    "inv_shoulder_07",
    7,
    2,
    30,
    { agility = 7, spirit = 7, armor = 76 }
)
item(
    13115,
    "ITEM_SHEEPSHEAR_MANTLE",
    "inv_shoulder_19",
    7,
    3,
    40,
    { stamina = 3, intellect = 16, spirit = 6, armor = 100 }
)
item(
    13116,
    "ITEM_SPAULDERS_OF_THE_UNSEEN",
    "inv_shoulder_18",
    7,
    3,
    56,
    { agility = 22, stamina = 7, intellect = 4, armor = 129 }
)
item(
    13117,
    "ITEM_OGRON_S_SASH",
    "inv_belt_15",
    9,
    3,
    37,
    { strength = 9, agility = 9, stamina = 9, armor = 71 }
)
item(
    13118,
    "ITEM_SERPENTINE_SASH",
    "inv_belt_25",
    9,
    3,
    52,
    { strength = 9, agility = 14, stamina = 14, armor = 92 }
)
item(
    13119,
    "ITEM_ENCHANTED_KODO_BRACERS",
    "inv_bracer_09",
    12,
    3,
    34,
    { intellect = 4, spirit = 10, armor = 52 }
)
item(
    13120,
    "ITEM_DEEPFURY_BRACERS",
    "inv_bracer_07",
    12,
    3,
    50,
    { strength = 4, agility = 15, stamina = 4, armor = 69 }
)
item(
    13121,
    "ITEM_WING_OF_THE_WHELPLING",
    "inv_misc_cape_04",
    4,
    3,
    33,
    { agility = 4, stamina = 10, armor = 28 }
)
item(
    13122,
    "ITEM_DARK_PHANTOM_CAPE",
    "inv_misc_cape_21",
    4,
    3,
    50,
    { agility = 15, spirit = 6, armor = 39 }
)
item(
    13099,
    "ITEM_MOCCASINS_OF_THE_WHITE_HARE",
    "inv_boots_05",
    11,
    3,
    24,
    { agility = 3, spirit = 8, armor = 32 }
)
item(
    13100,
    "ITEM_FUREN_S_BOOTS",
    "inv_boots_03",
    11,
    3,
    39,
    { intellect = 7, spirit = 16, armor = 44 }
)
item(
    13101,
    "ITEM_WOLFRUNNER_SHOES",
    "inv_boots_05",
    11,
    3,
    54,
    { stamina = 11, intellect = 11, spirit = 11, armor = 58, spellPower = 13 }
)
item(
    13103,
    "ITEM_PADS_OF_THE_VENOM_SPIDER",
    "inv_shoulder_18",
    7,
    3,
    33,
    { stamina = 12, spirit = 6, natureResistance = 5, armor = 41 }
)
item(
    13105,
    "ITEM_SUTARN_S_RING",
    "inv_belt_11",
    9,
    3,
    32,
    { stamina = 6, intellect = 10, spirit = 6, armor = 30 }
)
item(
    13106,
    "ITEM_GLOWING_MAGICAL_BRACELETS",
    "inv_bracer_19",
    12,
    3,
    26,
    { strength = 3, intellect = 8, armor = 21 }
)
item(
    13107,
    "ITEM_MAGISKULL_CUFFS",
    "inv_bracer_13",
    12,
    3,
    57,
    { stamina = 7, intellect = 17, armor = 38 }
)
item(
    13108,
    "ITEM_TIGERSTRIKE_MANTLE",
    "inv_misc_pelt_04",
    4,
    3,
    29,
    { agility = 8, stamina = 7, armor = 25 }
)
item(
    13109,
    "ITEM_BLACKFLAME_CAPE",
    "inv_misc_cape_20",
    4,
    3,
    44,
    { agility = 12, fireResistance = 5, shadowResistance = 5, armor = 35 }
)
item(
    13111,
    "ITEM_SANDALS_OF_THE_INSURGENT",
    "inv_boots_fabric_01",
    11,
    3,
    49,
    { intellect = 8, spirit = 20, armor = 107 }
)
item(
    13112,
    "ITEM_WINGED_HELM",
    "inv_helmet_19",
    3,
    3,
    43,
    { intellect = 23, spirit = 10, armor = 115 }
)
item(
    13114,
    "ITEM_TROLL_S_BANE_LEGGINGS",
    "inv_pants_06",
    10,
    3,
    25,
    { agility = 14, stamina = 4, spirit = 4, armor = 90 }
)
item(4666, "ITEM_BURNT_LEATHER_BELT", "inv_belt_04", 9, 1, 4, { armor = 27 })
item(3200, "ITEM_BURNT_LEATHER_BRACERS", "inv_bracer_10", 12, 1, 3, { armor = 20 })
item(3213, "ITEM_VETERAN_BRACERS", "inv_bracer_05", 12, 1, 8, { armor = 54 })
item(14169, "ITEM_ABORIGINAL_SHOULDER_PADS", "inv_shoulder_06", 7, 1, 16, { armor = 25 })
item(
    1280,
    "ITEM_CLOAKED_HOOD",
    "inv_helmet_30",
    3,
    2,
    33,
    { agility = 10, stamina = 10, armor = 86 }
)
item(
    12987,
    "ITEM_DARKWEAVE_BREECHES",
    "inv_pants_06",
    10,
    3,
    17,
    { stamina = 4, intellect = 7, spirit = 6, armor = 35 }
)
item(
    12977,
    "ITEM_MAGEFIST_GLOVES",
    "inv_gauntlets_27",
    8,
    3,
    15,
    { stamina = 3, intellect = 5, spirit = 4, armor = 23 }
)
item(
    13010,
    "ITEM_DREAMSINGER_LEGGUARDS",
    "inv_pants_03",
    10,
    3,
    21,
    { strength = 8, stamina = 8, spirit = 5, armor = 179 }
)
item(
    13124,
    "ITEM_RAVASAUR_SCALE_BOOTS",
    "inv_boots_01",
    11,
    3,
    30,
    { strength = 3, stamina = 11, spirit = 5, armor = 161 }
)
item(
    13125,
    "ITEM_ELVEN_CHAIN_BOOTS",
    "inv_boots_01",
    11,
    3,
    45,
    { agility = 18, stamina = 3, spirit = 7, armor = 206 }
)
item(
    13126,
    "ITEM_BATTLECALLER_GAUNTLETS",
    "inv_gauntlets_10",
    8,
    3,
    48,
    { strength = 8, stamina = 9, spirit = 15, armor = 198 }
)
item(
    13127,
    "ITEM_FROSTREAVER_CROWN",
    "inv_helmet_24",
    3,
    3,
    27,
    { strength = 4, stamina = 15, spirit = 4, armor = 182 }
)
item(
    13128,
    "ITEM_HIGH_BERGG_HELM",
    "inv_helmet_18",
    3,
    3,
    42,
    { stamina = 10, intellect = 15, spirit = 15, armor = 231 }
)
item(
    13129,
    "ITEM_FIREMANE_LEGGINGS",
    "inv_pants_03",
    10,
    3,
    34,
    { strength = 19, stamina = 5, fireResistance = 10, armor = 218 }
)
item(
    13130,
    "ITEM_WINDRUNNER_LEGGUARDS",
    "inv_pants_03",
    10,
    3,
    51,
    { agility = 27, spirit = 11, armor = 291 }
)
item(
    13131,
    "ITEM_SPARKLESHELL_MANTLE",
    "inv_shoulder_18",
    7,
    3,
    24,
    { agility = 4, stamina = 10, armor = 161 }
)
item(
    13132,
    "ITEM_SKELETAL_SHOULDERS",
    "inv_shoulder_11",
    7,
    3,
    38,
    { strength = 6, stamina = 15, armor = 199 }
)

item(
    13066,
    "ITEM_WYRMSLAYER_SPAULDERS",
    "inv_shoulder_24",
    7,
    3,
    46,
    { strength = 12, agility = 8, stamina = 12, armor = 403 }
)
item(
    13067,
    "ITEM_HYDRALICK_ARMOR",
    "inv_chest_plate06",
    2,
    3,
    49,
    { strength = 13, agility = 8, stamina = 20, fireResistance = 10, armor = 567 }
)
item(
    13068,
    "ITEM_OBSIDIAN_GREAVES",
    "inv_boots_plate_09",
    11,
    3,
    40,
    { strength = 10, agility = 6, stamina = 10, armor = 257 }
)
item(
    13071,
    "ITEM_PLATED_FIST_OF_HAKOO",
    "inv_gauntlets_10",
    8,
    3,
    40,
    { strength = 10, agility = 10, stamina = 10, armor = 300 }
)
item(
    13073,
    "ITEM_MUGTHOL_S_HELM",
    "inv_helmet_25",
    3,
    3,
    47,
    { strength = 10, stamina = 17, spirit = 17, armor = 445 }
)
item(13074, "ITEM_GOLEM_SHARD_LEGGINGS", "inv_pants_04", 10, 3, 41, { strength = 22, armor = 429 })
item(
    13076,
    "ITEM_GIANTSLAYER_BRACERS",
    "inv_bracer_17",
    12,
    3,
    43,
    { strength = 10, agility = 5, stamina = 6, armor = 223 }
)
item(
    13077,
    "ITEM_GIRDLE_OF_UTHER",
    "inv_belt_32",
    9,
    3,
    52,
    { strength = 9, agility = 9, stamina = 10, intellect = 9, spirit = 10, armor = 336 }
)

item(10046, "ITEM_SIMPLE_LINEN_BOOTS", "inv_boots_05", 11, 1, 4, { armor = 11 })
item(10045, "ITEM_SIMPLE_LINEN_PANTS", "inv_pants_11", 10, 1, 2, { armor = 12 })
item(2568, "ITEM_BROWN_LINEN_VEST", "inv_shirt_05", 2, 1, 3, { armor = 15 })

-- Additional class and role choices use the same fixed source-stat model.
item(2092, "ITEM_WORN_DAGGER", "inv_weapon_shortblade_05", 1, 1, 1, { weaponDPS = 0.94 })
item(
    3848,
    "ITEM_BIG_BRONZE_KNIFE",
    "inv_weapon_shortblade_04",
    1,
    2,
    15,
    { stamina = 3, weaponDPS = 10.0 }
)
item(
    1935,
    "ITEM_ASSASSIN_S_BLADE",
    "inv_weapon_shortblade_24",
    1,
    3,
    19,
    { strength = 3, agility = 4, weaponDPS = 15.53 }
)
item(776, "ITEM_VENDETTA", "inv_weapon_shortblade_02", 1, 3, 26, { agility = 6, weaponDPS = 19.23 })
item(
    2236,
    "ITEM_BLACKFANG",
    "inv_weapon_shortblade_02",
    1,
    3,
    20,
    { spirit = 2, shadowResistance = 5, weaponDPS = 16.33 }
)
item(
    6660,
    "ITEM_JULIE_S_DAGGER",
    "inv_weapon_shortblade_07",
    1,
    3,
    50,
    { weaponDPS = 36.54 },
    "SOURCE_HEALING_PROC_IS_NOT_SIMULATED"
)
item(2504, "ITEM_WORN_SHORTBOW", "inv_weapon_bow_05", 1, 1, 1, { weaponDPS = 1.52 })
item(13020, "ITEM_SKYSTRIKER_BOW", "inv_weapon_bow_11", 1, 3, 34, { weaponDPS = 20.71 })
item(
    13021,
    "ITEM_NEEDLE_THREADER",
    "inv_weapon_bow_08",
    1,
    3,
    42,
    { stamina = 6, spirit = 4, weaponDPS = 24.5 }
)
item(2509, "ITEM_ORNATE_BLUNDERBUSS", "inv_weapon_rifle_02", 1, 1, 4, { weaponDPS = 2.95 })
item(4577, "ITEM_COMPACT_SHOTGUN", "inv_weapon_rifle_03", 1, 2, 8, { weaponDPS = 5.25 })
item(13137, "ITEM_IRONWEAVER", "inv_weapon_rifle_08", 1, 3, 29, { weaponDPS = 17.31 })
item(
    13138,
    "ITEM_THE_SILENCER",
    "inv_weapon_rifle_08",
    1,
    3,
    37,
    { weaponDPS = 22.32, attackPower = 14 }
)
item(
    13139,
    "ITEM_GUTTBUSTER",
    "inv_weapon_rifle_08",
    1,
    3,
    45,
    { strength = 3, agility = 8, weaponDPS = 26.11 }
)
item(11287, "ITEM_LESSER_MAGIC_WAND", "inv_staff_02", 1, 2, 5, { weaponDPS = 11.33 })
item(13062, "ITEM_THUNDERWOOD", "inv_staff_02", 1, 3, 22, { weaponDPS = 27.11 })
item(
    13064,
    "ITEM_JAINA_S_FIRESTARTER",
    "inv_wand_09",
    1,
    3,
    37,
    { intellect = 6, spirit = 3, weaponDPS = 39.38 }
)
item(
    13065,
    "ITEM_WAND_OF_ALLISTARJ",
    "inv_wand_09",
    1,
    3,
    45,
    { arcaneResistance = 9, weaponDPS = 48.42 }
)
item(
    13004,
    "ITEM_TORCH_OF_AUSTEN",
    "inv_wand_11",
    1,
    3,
    53,
    { fireResistance = 10, weaponDPS = 56.79 }
)
item(
    890,
    "ITEM_TWISTED_CHANTER_S_STAFF",
    "inv_staff_04",
    1,
    3,
    19,
    { intellect = 10, stamina = 6, weaponDPS = 20.44 }
)
item(
    791,
    "ITEM_GNARLED_ASH_STAFF",
    "inv_staff_02",
    1,
    3,
    26,
    { stamina = 6, spirit = 15, weaponDPS = 25.63 }
)
item(
    1607,
    "ITEM_SOULKEEPER",
    "spell_shadow_haunting",
    1,
    3,
    49,
    { intellect = 11, spirit = 26, weaponDPS = 46.58 }
)
item(
    13000,
    "ITEM_STAFF_OF_HALE_MAGEFIRE",
    "inv_staff_23",
    1,
    3,
    57,
    { intellect = 25, spirit = 22, weaponDPS = 53.03 }
)
item(
    13033,
    "ITEM_ZEALOT_BLADE",
    "inv_sword_15",
    1,
    3,
    29,
    { intellect = 5, spirit = 6, weaponDPS = 22.14 }
)
item(
    13034,
    "ITEM_SPEEDSTEEL_RAPIER",
    "inv_sword_30",
    1,
    3,
    36,
    { agility = 8, stamina = 3, weaponDPS = 28.06 }
)
item(
    13038,
    "ITEM_SWIFTWIND",
    "inv_weapon_crossbow_04",
    1,
    3,
    35,
    { agility = 7, weaponDPS = 21.25 }
)
item(
    13039,
    "ITEM_SKULL_SPLITTING_CROSSBOW",
    "inv_weapon_crossbow_04",
    1,
    3,
    43,
    { strength = 3, weaponDPS = 25.19, attackPower = 14 }
)
item(
    13045,
    "ITEM_VISCOUS_HAMMER",
    "inv_mace_13",
    1,
    3,
    30,
    { strength = 3, stamina = 6, weaponDPS = 30.17, attackPower = 34 }
)
item(
    13046,
    "ITEM_BLANCHARD_S_STOUT",
    "inv_hammer_04",
    1,
    3,
    45,
    { strength = 20, stamina = 15, fireResistance = 5, weaponDPS = 43.39 }
)
item(
    13047,
    "ITEM_TWIG_OF_THE_WORLD_TREE",
    "inv_mace_13",
    1,
    3,
    53,
    { strength = 14, stamina = 21, spirit = 12, weaponDPS = 49.73 }
)
item(
    12989,
    "ITEM_GARGOYLE_S_BITE",
    "inv_spear_05",
    1,
    3,
    20,
    { strength = 10, armor = 60, weaponDPS = 18.97 }
)
item(
    13055,
    "ITEM_BONECHEWER",
    "inv_spear_06",
    1,
    3,
    43,
    { strength = 23, stamina = 10, weaponDPS = 41.96 }
)
item(
    13059,
    "ITEM_STONERAVEN",
    "inv_spear_07",
    1,
    3,
    47,
    { strength = 13, agility = 13, stamina = 15, spirit = 9, weaponDPS = 44.85 }
)
item(
    12998,
    "ITEM_MAGICIAN_S_MANTLE",
    "inv_shoulder_13",
    7,
    3,
    20,
    { intellect = 9, armor = 32, spellPower = 5 }
)
item(
    13008,
    "ITEM_DALEWIND_TROUSERS",
    "inv_pants_06",
    10,
    3,
    47,
    { intellect = 9, stamina = 5, spirit = 25, armor = 65 }
)
item(
    13013,
    "ITEM_ELDER_WIZARD_S_MANTLE",
    "inv_shoulder_14",
    7,
    3,
    51,
    { intellect = 20, armor = 60, spellPower = 11 }
)
item(
    12994,
    "ITEM_THORBIA_S_GAUNTLETS",
    "inv_gauntlets_11",
    8,
    3,
    18,
    { strength = 8, stamina = 3, armor = 122 }
)
item(
    15048,
    "ITEM_BLUE_DRAGONSCALE_BREASTPLATE",
    "inv_chest_chain_04",
    2,
    3,
    52,
    { intellect = 28, spirit = 8, armor = 338, arcaneResistance = 8 },
    "SOURCE_SET_BONUSES_ARE_NOT_SIMULATED"
)
item(
    15049,
    "ITEM_BLUE_DRAGONSCALE_SHOULDERS",
    "inv_shoulder_18",
    7,
    3,
    54,
    { intellect = 21, spirit = 6, armor = 262, arcaneResistance = 6 },
    "SOURCE_SET_BONUSES_ARE_NOT_SIMULATED"
)
item(
    15050,
    "ITEM_BLACK_DRAGONSCALE_BREASTPLATE",
    "inv_chest_plate06",
    2,
    3,
    53,
    { stamina = 8, armor = 344, fireResistance = 12, attackPower = 50 },
    "SOURCE_SET_BONUSES_ARE_NOT_SIMULATED"
)
item(
    15052,
    "ITEM_BLACK_DRAGONSCALE_LEGGINGS",
    "inv_pants_03",
    10,
    3,
    57,
    { stamina = 8, armor = 320, fireResistance = 13, attackPower = 54 },
    "SOURCE_SET_BONUSES_ARE_NOT_SIMULATED"
)
item(
    15059,
    "ITEM_LIVING_BREASTPLATE",
    "inv_chest_plate07",
    2,
    3,
    55,
    { stamina = 10, spirit = 25, armor = 169, natureResistance = 5, healingPower = 26 }
)
item(
    15060,
    "ITEM_LIVING_LEGGINGS",
    "inv_pants_05",
    10,
    3,
    52,
    { stamina = 8, spirit = 25, armor = 142, natureResistance = 5, healingPower = 26 }
)
item(
    15061,
    "ITEM_LIVING_SHOULDERS",
    "inv_shoulder_18",
    7,
    3,
    49,
    { stamina = 8, spirit = 13, armor = 117, natureResistance = 3, healingPower = 31 }
)
item(
    15062,
    "ITEM_DEVILSAUR_LEGGINGS",
    "inv_pants_wolf",
    10,
    3,
    55,
    { stamina = 12, armor = 148, attackPower = 46 },
    "SOURCE_CRITICAL_STRIKE_AND_SET_BONUSES_ARE_NOT_SIMULATED"
)
item(
    15063,
    "ITEM_DEVILSAUR_GAUNTLETS",
    "inv_gauntlets_26",
    8,
    3,
    53,
    { stamina = 9, armor = 103, attackPower = 28 },
    "SOURCE_CRITICAL_STRIKE_AND_SET_BONUSES_ARE_NOT_SIMULATED"
)
item(
    15066,
    "ITEM_IRONFEATHER_BREASTPLATE",
    "inv_chest_leather_06",
    2,
    3,
    53,
    { intellect = 12, spirit = 28, armor = 165 },
    "SOURCE_SET_BONUSES_ARE_NOT_SIMULATED"
)
item(
    15067,
    "ITEM_IRONFEATHER_SHOULDERS",
    "inv_shoulder_06",
    7,
    3,
    49,
    { intellect = 20, spirit = 8, armor = 117 },
    "SOURCE_SET_BONUSES_ARE_NOT_SIMULATED"
)

item(
    1483,
    "ITEM_FACE_SMASHER",
    "inv_hammer_08",
    1,
    3,
    16,
    { strength = 3, stamina = 3, weaponDPS = 14.04 }
)
item(
    1716,
    "ITEM_ROBE_OF_THE_MAGI",
    "inv_chest_cloth_17",
    2,
    3,
    35,
    { intellect = 6, spirit = 5, armor = 58, spellPower = 22 }
)
item(
    7728,
    "ITEM_BEGUILER_ROBES",
    "inv_chest_cloth_25",
    2,
    3,
    29,
    { stamina = 7, intellect = 12, spirit = 8, armor = 50 }
)
item(
    17050,
    "ITEM_CHAN_S_IMPERIAL_ROBES",
    "inv_chest_cloth_04",
    2,
    3,
    47,
    { stamina = 20, intellect = 10, spirit = 10, armor = 75, natureResistance = 5 }
)
item(
    12999,
    "ITEM_DRAKEWING_BANDS",
    "inv_bracer_09",
    12,
    3,
    20,
    { stamina = 3, spirit = 6, armor = 41 }
)
item(
    13135,
    "ITEM_LORDLY_ARMGUARDS",
    "inv_bracer_17",
    12,
    3,
    54,
    { strength = 7, agility = 7, stamina = 8, intellect = 7, spirit = 8, armor = 153 }
)

-- Classic weapon proficiencies are idle class rules, independent of the live client.
-- Training and talent requirements are simplified; each hero has one weapon slot.
C.weaponNames = {
    sword = L.ONE_HANDED_SWORDS,
    axe = L.ONE_HANDED_AXES,
    mace = L.ONE_HANDED_MACES,
    staff = L.STAVES,
    twoHandSword = L.TWO_HANDED_SWORDS,
    twoHandAxe = L.TWO_HANDED_AXES,
    bow = L.BOWS,
    crossbow = L.CROSSBOWS,
    dagger = L.DAGGERS,
    gun = L.GUNS,
    wand = L.WANDS,
    twoHandMace = L.TWO_HANDED_MACES,
    polearm = L.POLEARMS,
}
C.classWeapons = {
    WARRIOR = {
        dagger = true,
        gun = true,
        twoHandMace = true,
        polearm = true,
        sword = true,
        axe = true,
        mace = true,
        staff = true,
        twoHandSword = true,
        twoHandAxe = true,
        bow = true,
        crossbow = true,
    },
    PALADIN = {
        twoHandMace = true,
        polearm = true,
        sword = true,
        axe = true,
        mace = true,
        twoHandSword = true,
        twoHandAxe = true,
    },
    HUNTER = {
        dagger = true,
        gun = true,
        polearm = true,
        sword = true,
        axe = true,
        staff = true,
        twoHandSword = true,
        twoHandAxe = true,
        bow = true,
        crossbow = true,
    },
    ROGUE = { dagger = true, gun = true, sword = true, mace = true, bow = true, crossbow = true },
    PRIEST = { dagger = true, wand = true, mace = true, staff = true },
    SHAMAN = {
        dagger = true,
        twoHandMace = true,
        axe = true,
        mace = true,
        staff = true,
        twoHandAxe = true,
    },
    MAGE = { dagger = true, wand = true, sword = true, staff = true },
    WARLOCK = { dagger = true, wand = true, sword = true, staff = true },
    DRUID = { dagger = true, twoHandMace = true, mace = true, staff = true },
}
local weaponItems = {
    polearm = { 12989, 13055, 13059 },
    twoHandMace = { 13045, 13046, 13047 },
    wand = { 11287, 13062, 13064, 13065, 13004 },
    gun = { 2509, 4577, 13137, 13138, 13139 },
    dagger = { 2092, 3848, 1935, 776, 2236, 6660 },
    sword = { 13033, 13034, 25, 935 },
    axe = { 37, 13014, 13015 },
    mace = { 1483, 36, 13024, 13027, 13028 },
    staff = { 890, 791, 1607, 13000, 35, 1539 },
    twoHandSword = { 13043 },
    twoHandAxe = { 1455 },
    bow = { 2504, 13020, 13021, 13022, 13023 },
    crossbow = { 13038, 13039, 13040 },
}
for weaponType, items in pairs(weaponItems) do
    for _, id in ipairs(items) do
        C.itemByID[id].weaponType = weaponType
    end
end

C.armorRanks = { cloth = 1, leather = 2, mail = 3, plate = 4 }
C.armorNames = { cloth = L.CLOTH, leather = L.LEATHER, mail = L.MAIL, plate = L.PLATE }
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
        17050,
        7728,
        1716,
        12998,
        13008,
        13013,
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
        12999,
        15059,
        15060,
        15061,
        15062,
        15063,
        15066,
        15067,
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
        13135,
        12994,
        15048,
        15049,
        15050,
        15052,
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
        2092,
        2504,
        2509,
        11287,
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
        2977,
        2978,
        2980,
        2974,
        2976,
        2969,
        2970,
        2983,
    },
    durotar = {
        2092,
        2504,
        2509,
        11287,
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
        2977,
        2978,
        2980,
        2974,
        2976,
        2969,
        2970,
        2983,
    },
    westfall = {
        1483,
        12999,
        4577,
        3848,
        1935,
        890,
        12998,
        12994,
        12989,
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
        1483,
        12999,
        4577,
        3848,
        1935,
        890,
        12998,
        12994,
        12989,
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
        1483,
        2236,
        13062,
        776,
        791,
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
        935,
        1483,
        2236,
        13062,
        776,
        791,
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
        791,
        1483,
        7728,
        1716,
        13137,
        13033,
        13045,
        13020,
        13034,
        13038,
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
        791,
        1483,
        7728,
        1716,
        13137,
        13033,
        13045,
        13020,
        13034,
        13038,
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
        791,
        13045,
        13138,
        13064,
        13021,
        13039,
        13055,
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
        791,
        13045,
        13138,
        13064,
        13021,
        13039,
        13055,
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
        17050,
        13139,
        13046,
        13059,
        13065,
        1607,
        13008,
        15061,
        15067,
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
        17050,
        13135,
        6660,
        13000,
        13047,
        13004,
        13013,
        15048,
        15049,
        15050,
        15052,
        15059,
        15060,
        15062,
        15063,
        15066,
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

-- Expanded destinations share curated pools from the same progression band.
-- These are idle encounter rewards, independent of live creature drop tables.
C.zoneItems.dun_morogh = C.zoneItems.elwynn
C.zoneItems.teldrassil = C.zoneItems.elwynn
C.zoneItems.mulgore = C.zoneItems.durotar
C.zoneItems.tirisfal = C.zoneItems.elwynn
C.zoneItems.loch_modan = C.zoneItems.westfall
C.zoneItems.darkshore = C.zoneItems.barrens
C.zoneItems.silverpine = C.zoneItems.westfall
C.zoneItems.stonetalon = C.zoneItems.ashenvale
C.zoneItems.hillsbrad = C.zoneItems.wetlands
C.zoneItems.thousand_needles = C.zoneItems.desolace
C.zoneItems.alterac = C.zoneItems.duskwood
C.zoneItems.arathi = C.zoneItems.stranglethorn
C.zoneItems.badlands = C.zoneItems.tanaris
C.zoneItems.swamp_sorrows = C.zoneItems.stranglethorn
C.zoneItems.dustwallow = C.zoneItems.stranglethorn
C.zoneItems.feralas = C.zoneItems.tanaris
C.zoneItems.hinterlands = C.zoneItems.tanaris
C.zoneItems.azshara = C.zoneItems.tanaris
C.zoneItems.searing_gorge = C.zoneItems.tanaris
C.zoneItems.blasted_lands = C.zoneItems.winterspring
C.zoneItems.felwood = C.zoneItems.winterspring
C.zoneItems.ungoro = C.zoneItems.winterspring
C.zoneItems.burning_steppes = C.zoneItems.winterspring
C.zoneItems.western_plaguelands = C.zoneItems.winterspring
C.zoneItems.deadwind = C.zoneItems.winterspring
C.zoneItems.eastern_plaguelands = C.zoneItems.winterspring
C.zoneItems.silithus = C.zoneItems.winterspring
C.zoneItems.moonglade = C.zoneItems.tanaris
C.zoneItems.blackrock_mountain = C.zoneItems.winterspring
