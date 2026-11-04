local _, W = ...
local L = W.L
local C = W.Content

-- Permanent hunt investments; see BALANCE.md for acquisition distributions.
C.collectionTalents = {
    { id = "fieldcraft", name = L["Fieldcraft"], kind = "outdoor", condition = L["Outdoor kills"] },
    {
        id = "relicHunter",
        name = L["Relic Hunter"],
        kind = "dungeon",
        condition = L["Dungeon kills"],
    },
}
C.collectionTalentRankCap = 3
C.collectionTalentBonus = 0.2
C.collectionTalentCosts = { 1, 2, 3 }
C.collectionTalentByID = {}
for _, talent in ipairs(C.collectionTalents) do
    C.collectionTalentByID[talent.id] = talent
end

-- Archived simulated rewards, retained only to protect existing earned value.
-- Item identities and artwork reuse the catalog snapshots in Content/ITEMS.md.
C.legacyCollections = {
    {
        id = "westfallOutriders",
        name = L["Westfall Outriders"],
        description = L["A weathered cloak and leather field kit from Westfall's outlaw country."],
        pieces = { 1930, 2985, 2986, 2987, 2988 },
        zones = { westfall = true },
        families = { humanoid = true },
        minLevel = 3,
        chance = 5,
        guarantee = 30,
        source = L["Idle Westfall humanoid victories, idle level 3+. Outdoor minigame rewards; no dungeon required."],
        family = "humanoid",
        milestones = {
            basicAttack = { pieces = 2, bonus = 0.02 },
            materials = { pieces = 4, bonus = 0.03 },
        },
        defense = 0.03,
    },
}
-- Collection identities do not enter ordinary item loot or crafting pools.
C.collectionItemByID = {
    [10399] = {
        itemID = 10399,
        name = L["Blackened Defias Armor"],
        icon = "inv_chest_leather_08",
        slot = 2,
    },
    [10400] = {
        itemID = 10400,
        name = L["Blackened Defias Leggings"],
        icon = "inv_pants_12",
        slot = 10,
    },
    [10401] = {
        itemID = 10401,
        name = L["Blackened Defias Gloves"],
        icon = "inv_gauntlets_18",
        slot = 8,
    },
    [10402] = {
        itemID = 10402,
        name = L["Blackened Defias Boots"],
        icon = "inv_boots_05",
        slot = 11,
    },
    [10403] = { itemID = 10403, name = L["Blackened Defias Belt"], icon = "inv_belt_26", slot = 9 },
    [3288] = { itemID = 3288, name = L["Tribal Vest"], icon = "inv_chest_cloth_16", slot = 2 },
    [3287] = { itemID = 3287, name = L["Tribal Pants"], icon = "inv_pants_06", slot = 10 },
    [3284] = { itemID = 3284, name = L["Tribal Boots"], icon = "inv_boots_08", slot = 11 },
    [3286] = { itemID = 3286, name = L["Tribal Gloves"], icon = "inv_gauntlets_19", slot = 8 },
    [4674] = { itemID = 4674, name = L["Tribal Cloak"], icon = "inv_helmet_48", slot = 4 },
    [14167] = { itemID = 14167, name = L["Buccaneer's Cape"], icon = "inv_misc_cape_18", slot = 4 },
    [14173] = { itemID = 14173, name = L["Buccaneer's Cord"], icon = "inv_belt_22", slot = 9 },
    [14174] = { itemID = 14174, name = L["Buccaneer's Boots"], icon = "inv_boots_05", slot = 11 },
    [14166] = { itemID = 14166, name = L["Buccaneer's Bracers"], icon = "inv_bracer_12", slot = 12 },
    [14168] = {
        itemID = 14168,
        name = L["Buccaneer's Gloves"],
        icon = "inv_gauntlets_16",
        slot = 8,
    },
    [9775] = { itemID = 9775, name = L["Bandit Cinch"], icon = "inv_belt_03", slot = 9 },
    [9777] = { itemID = 9777, name = L["Bandit Bracers"], icon = "inv_bracer_05", slot = 12 },
    [9780] = { itemID = 9780, name = L["Bandit Gloves"], icon = "inv_gauntlets_15", slot = 8 },
    [9776] = { itemID = 9776, name = L["Bandit Boots"], icon = "inv_boots_05", slot = 11 },
    [9781] = { itemID = 9781, name = L["Bandit Pants"], icon = "inv_pants_06", slot = 10 },
    [3211] = { itemID = 3211, name = L["Burnished Bracers"], icon = "inv_bracer_01", slot = 12 },
    [2992] = { itemID = 2992, name = L["Burnished Gloves"], icon = "inv_gauntlets_10", slot = 8 },
    [2991] = { itemID = 2991, name = L["Burnished Boots"], icon = "inv_boots_plate_07", slot = 11 },
    [4697] = { itemID = 4697, name = L["Burnished Girdle"], icon = "inv_belt_34", slot = 9 },
    [9784] = { itemID = 9784, name = L["Raider's Boots"], icon = "inv_boots_01", slot = 11 },
    [9787] = { itemID = 9787, name = L["Raider's Gauntlets"], icon = "inv_gauntlets_04", slot = 8 },
    [9789] = { itemID = 9789, name = L["Raider's Legguards"], icon = "inv_pants_03", slot = 10 },
    [9783] = {
        itemID = 9783,
        name = L["Raider's Chestpiece"],
        icon = "inv_chest_chain_07",
        slot = 2,
    },
    [9788] = { itemID = 9788, name = L["Raider's Belt"], icon = "inv_belt_11", slot = 9 },
    [4699] = { itemID = 4699, name = L["Seer's Belt"], icon = "inv_belt_22", slot = 9 },
    [4698] = { itemID = 4698, name = L["Seer's Mantle"], icon = "inv_shoulder_09", slot = 7 },
    [6563] = { itemID = 6563, name = L["Shimmering Bracers"], icon = "inv_bracer_12", slot = 12 },
    [6570] = { itemID = 6570, name = L["Shimmering Sash"], icon = "inv_belt_25", slot = 9 },
    [6565] = { itemID = 6565, name = L["Shimmering Gloves"], icon = "inv_gauntlets_16", slot = 8 },
    [6562] = { itemID = 6562, name = L["Shimmering Boots"], icon = "inv_boots_05", slot = 11 },
    [6564] = { itemID = 6564, name = L["Shimmering Cloak"], icon = "inv_misc_cape_15", slot = 4 },
    [6575] = { itemID = 6575, name = L["Defender Cloak"], icon = "inv_misc_cape_05", slot = 4 },
    [6574] = { itemID = 6574, name = L["Defender Bracers"], icon = "inv_bracer_14", slot = 12 },
    [6576] = { itemID = 6576, name = L["Defender Girdle"], icon = "inv_belt_22", slot = 9 },
    [6578] = { itemID = 6578, name = L["Defender Leggings"], icon = "inv_pants_03", slot = 10 },
    [6573] = { itemID = 6573, name = L["Defender Boots"], icon = "inv_boots_plate_01", slot = 11 },
    [285331] = {
        itemID = 285331,
        name = L["Mark of the Pack Leader"],
        icon = "inv_jewelry_necklace_04",
    },
    [285330] = { itemID = 285330, name = L["Signet of the Zhevra"], icon = "inv_jewelry_ring_03" },
    [285329] = {
        itemID = 285329,
        name = L["Raptor Hide Cloak"],
        icon = "inv_misc_cape_17",
        slot = 4,
    },
    [271097] = {
        itemID = 271097,
        name = L["Spiritwraith Drape"],
        icon = "inv_misc_cape_12",
        slot = 4,
    },
    [271096] = {
        itemID = 271096,
        name = L["Aetherwisp Bracers"],
        icon = "inv_bracer_11",
        slot = 12,
    },
    [270230] = { itemID = 270230, name = L["Kindlegem Girdle"], icon = "inv_belt_20", slot = 9 },
    [270231] = { itemID = 270231, name = L["Flamefist Grips"], icon = "inv_gauntlets_25", slot = 8 },
    [271098] = { itemID = 271098, name = L["Golemguard Chest"], icon = "inv_chest_chain", slot = 2 },
    [10412] = { itemID = 10412, name = L["Belt of the Fang"], icon = "inv_belt_30", slot = 9 },
    [10411] = { itemID = 10411, name = L["Footpads of the Fang"], icon = "inv_boots_04", slot = 11 },
    [10413] = {
        itemID = 10413,
        name = L["Gloves of the Fang"],
        icon = "inv_gauntlets_18",
        slot = 8,
    },
    [10410] = { itemID = 10410, name = L["Leggings of the Fang"], icon = "inv_pants_11", slot = 10 },
    [6473] = { itemID = 6473, name = L["Armor of the Fang"], icon = "inv_shirt_16", slot = 2 },
    [286978] = { itemID = 286978, name = L["Rotmender's Garb"], icon = "inv_shirt_04", slot = 2 },
    [286980] = { itemID = 286980, name = L["Rotmender's Sash"], icon = "inv_belt_11", slot = 9 },
    [271207] = {
        itemID = 271207,
        name = L["Rotmender's Leggings"],
        icon = "inv_pants_cloth_05",
        slot = 10,
    },
    [271214] = { itemID = 271214, name = L["Rotmender's Treads"], icon = "inv_boots_05", slot = 11 },
    [286979] = {
        itemID = 286979,
        name = L["Rotmender's Gloves"],
        icon = "inv_gauntlets_22",
        slot = 8,
    },
    [5254] = { itemID = 5254, name = L["Rugged Spaulders"], icon = "inv_shoulder_08", slot = 7 },
    [6319] = {
        itemID = 6319,
        name = L["Girdle of the Blindwatcher"],
        icon = "inv_belt_03",
        slot = 9,
    },
    [6340] = { itemID = 6340, name = L["Fenrus' Hide"], icon = "inv_misc_pelt_wolf_02", slot = 4 },
    [3230] = { itemID = 3230, name = L["Black Wolf Bracers"], icon = "inv_bracer_07", slot = 12 },
    [6324] = { itemID = 6324, name = L["Robes of Arugal"], icon = "inv_chest_cloth_31", slot = 2 },
    [6907] = { itemID = 6907, name = L["Tortoise Armor"], icon = "inv_shirt_06", slot = 2 },
    [6908] = { itemID = 6908, name = L["Ghamoo-ra's Bind"], icon = "inv_belt_24", slot = 9 },
    [888] = { itemID = 888, name = L["Naga Battle Gloves"], icon = "inv_gauntlets_13", slot = 8 },
    [6901] = {
        itemID = 6901,
        name = L["Glowing Thresher Cape"],
        icon = "inv_misc_monsterscales_03",
        slot = 4,
    },
    [6902] = { itemID = 6902, name = L["Bands of Serra'kis"], icon = "inv_bracer_08", slot = 12 },
}
C.collections = {
    {
        id = "redridgeOutriders",
        kind = "outdoor",
        name = L["Redridge Outriders"],
        description = L["An outdoor cloak and leather collection. Hover pieces for their hunting locations."],
        pieces = { 4701, 2985, 2986, 2987, 2988 },
        milestones = {
            basicAttack = { pieces = 2, bonus = 0.005 },
            materials = { pieces = 4, bonus = 0.005 },
        },
        effect = { basicAttack = 0.04 },
    },
}
C.collections[#C.collections + 1] = {
    id = "defiasLeather",
    kind = "dungeon",
    name = L["Defias Leather"],
    description = L["A dungeon collection from the Deadmines. Hunt Defias families inside the instance."],
    pieces = { 10399, 10400, 10401, 10402, 10403 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "humanoid", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "tribalTrail",
    kind = "outdoor",
    name = L["Tribal Trail"],
    description = L["A Tribal leather field kit from the starting lands."],
    pieces = { 3288, 3287, 3284, 3286, 4674 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "beast", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "buccaneerFieldKit",
    kind = "outdoor",
    name = L["Buccaneer's Field Kit"],
    description = L["Buccaneer cloth kit from outdoor creatures."],
    pieces = { 14167, 14173, 14174, 14166, 14168 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { basicAttack = 0.04 },
}

C.collections[#C.collections + 1] = {
    id = "banditFieldKit",
    kind = "outdoor",
    name = L["Bandit Field Kit"],
    description = L["Bandit leather kit from outdoor creatures."],
    pieces = { 9775, 9777, 9780, 9776, 9781 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "humanoid", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "burnishedFieldKit",
    kind = "outdoor",
    name = L["Burnished Field Kit"],
    description = L["Burnished mail kit from outdoor creatures."],
    pieces = { 3211, 2992, 2991, 4697, 2989 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "humanoid", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "raiderFieldKit",
    kind = "outdoor",
    name = L["Raider's Field Kit"],
    description = L["Raider mail kit from outdoor creatures."],
    pieces = { 9784, 9787, 9789, 9783, 9788 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "beast", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "seerFieldKit",
    kind = "outdoor",
    name = L["Seer's Field Kit"],
    description = L["Seer cloth kit from outdoor creatures."],
    pieces = { 2982, 2984, 4699, 2981, 4698 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { basicAttack = 0.04 },
}

C.collections[#C.collections + 1] = {
    id = "shimmeringFieldKit",
    kind = "outdoor",
    name = L["Shimmering Field Kit"],
    description = L["Shimmering cloth kit from outdoor creatures."],
    pieces = { 6563, 6570, 6565, 6562, 6564 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { basicAttack = 0.04 },
}

C.collections[#C.collections + 1] = {
    id = "defenderFieldKit",
    kind = "outdoor",
    name = L["Defender Field Kit"],
    description = L["Defender mail kit from outdoor creatures."],
    pieces = { 6575, 6574, 6576, 6578, 6573 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "humanoid", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "blessingOfKalimdor",
    kind = "outdoor",
    name = L["Blessing of Kalimdor"],
    description = L["Three keepsakes from rare outdoor creatures in the Barrens."],
    pieces = { 285331, 285330, 285329 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 3, bonus = 0.005 },
    },
    effect = { family = "beast", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "hallOfThanes",
    kind = "dungeon",
    name = L["Heirlooms of the Thanes"],
    description = L["A collection from the Hall of Thanes."],
    pieces = { 271097, 271096, 270230, 270231, 271098 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "elemental", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "embraceOfTheViper",
    kind = "dungeon",
    name = L["Embrace of the Viper"],
    description = L["Fang leather from the druids of the Wailing Caverns."],
    pieces = { 10412, 10411, 10413, 10410, 6473 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "beast", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "rotmenderRaiment",
    kind = "dungeon",
    name = L["Rotmender's Raiment"],
    description = L["Rotmender cloth from the Ruins of Lordaeron."],
    pieces = { 286978, 286980, 271207, 271214, 286979 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "undead", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "shadowfangRelics",
    kind = "dungeon",
    name = L["Shadowfang Relics"],
    description = L["A collection from Shadowfang Keep."],
    pieces = { 5254, 6319, 6340, 3230, 6324 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "undead", damageTaken = 0.96 },
}

C.collections[#C.collections + 1] = {
    id = "blackfathomRelics",
    kind = "dungeon",
    name = L["Blackfathom Relics"],
    description = L["A collection from Blackfathom Deeps."],
    pieces = { 6907, 6908, 888, 6901, 6902 },
    milestones = {
        basicAttack = { pieces = 2, bonus = 0.005 },
        materials = { pieces = 4, bonus = 0.005 },
    },
    effect = { family = "beast", damageTaken = 0.96 },
}

C.legacyCollectionByID, C.legacyCollectionByItem = {}, {}
for _, collection in ipairs(C.legacyCollections) do
    C.legacyCollectionByID[collection.id] = collection
    for _, itemID in ipairs(collection.pieces) do
        C.legacyCollectionByItem[itemID] = collection.id
    end
end
C.collectionByID, C.collectionByItem = {}, {}
for _, collection in ipairs(C.collections) do
    C.collectionByID[collection.id] = collection
    for _, itemID in ipairs(collection.pieces) do
        assert(C.itemByID[itemID] or C.collectionItemByID[itemID], L["Unknown collection item"])
        C.collectionByItem[itemID] = collection.id
    end
end
