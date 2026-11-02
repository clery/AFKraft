local _, W = ...

-- Creature IDs resolve complete NPC appearances, including their baked skins.
-- Bare race display IDs do not contain a character's composite textures.
W.ModelAssets = {
    -- Cosmetic coverage for empty chest, leg and foot slots; no inventory items or stats.
    starterOutfits = {
        WARRIOR = { [2] = 38, [10] = 39, [11] = 40 },
        PALADIN = { [2] = 45, [10] = 44, [11] = 43 },
        HUNTER = { [2] = 127, [10] = 39, [11] = 129 },
        ROGUE = { [2] = 49, [10] = 48, [11] = 47 },
        PRIEST = { [2] = 57, [10] = 1396, [11] = 59 },
        SHAMAN = { [2] = 6134, [10] = 6124, [11] = 6127 },
        MAGE = { [2] = 56, [10] = 1395, [11] = 55 },
        WARLOCK = { [2] = 6129, [10] = 1396, [11] = 59 },
        DRUID = { [2] = 6123, [10] = 6124, [11] = 59 },
    },
    -- Align the fitted creature camera's ground with native full-body characters
    -- in the shared 240-unit-high viewport. Parent scaling preserves this in compact mode.
    creatureGroundOffset = 24,
    -- Complete textured presets; body customizations remain together as authored.
    variants = {
        human_male = { 911, 925, 915, 198, 906 },
        human_female = { 375, 459 },
        orc_male = { 3153, 3156 },
        orc_female = { 3157 },
        dwarf_male = { 1229 },
        dwarf_female = { 5142 },
        nightelf_male = { 3597, 3594 },
        nightelf_female = { 3596 },
        undead_male = { 2122, 3049 },
        undead_female = { 2124 },
        tauren_male = { 3060 },
        tauren_female = { 3062 },
    },
    levelUp = "Spells\\LevelUp\\LevelUp.m2",
    -- Particle-heavy creatures need more room than their default portrait camera gives them.
    framing = {
        [832] = { cameraDistance = 2.3 }, -- Dust devil (also used by the Tanaris boss)
    },
    appearances = {
        human_male = 911, -- Llane Beshere
        human_female = 375, -- Priestess Anetta
        orc_male = 3153, -- Frang
        orc_female = 3157, -- Shikrik
        dwarf_male = 1229, -- Granis Swiftaxe
        dwarf_female = 5142, -- Braenna Flintcrag
        nightelf_male = 3597, -- Mardant Strongoak
        nightelf_female = 3596, -- Ayanna Everstride
        undead_male = 2122, -- David Trias
        undead_female = 2124, -- Isabella
        tauren_male = 3060, -- Gart Mistrunner
        tauren_female = 3062, -- Meela Dawnstrider
    },
    classes = {
        WARRIOR = { default = 911, human_male = 911, orc_male = 3153, dwarf_male = 1229 },
        PALADIN = { default = 925, human_male = 925 },
        HUNTER = { default = 3596, nightelf_female = 3596 },
        ROGUE = { default = 915, human_male = 915, nightelf_male = 3594, undead_male = 2122 },
        PRIEST = { default = 375, human_female = 375, dwarf_female = 5142 },
        SHAMAN = { default = 3157, orc_female = 3157, tauren_female = 3062 },
        MAGE = { default = 198, human_male = 198, undead_male = 3049, undead_female = 2124 },
        WARLOCK = { default = 459, human_male = 906, human_female = 459, orc_male = 3156 },
        DRUID = { default = 3597, nightelf_male = 3597, tauren_male = 3060 },
    },
    -- Ordered like Content.zones[].enemies. Bosses have their own appearance.
    zones = {
        elwynn = { enemies = { 299, 6, 448 }, boss = 448 },
        durotar = { enemies = { 3098, 3124, 3111 }, boss = 3100 },
        westfall = { enemies = { 38, 114, 832 }, boss = 114 },
        barrens = { enemies = { 3425, 3272, 3261 }, boss = 3272 },
        redridge = { enemies = { 4064, 446, 441 }, boss = 4064 },
        ashenvale = { enemies = { 2033, 3749, 3919 }, boss = 3919 },
        duskwood = { enemies = { 48, 898, 215 }, boss = 48 },
        wetlands = { enemies = { 1693, 2102, 48 }, boss = 1693 },
        stranglethorn = { enemies = { 687, 595, 675 }, boss = 687 },
        desolace = { enemies = { 4640, 4695, 4663 }, boss = 4663 },
        tanaris = { enemies = { 5618, 5646, 5474 }, boss = 832 },
        winterspring = { enemies = { 7431, 7439, 7459 }, boss = 7459 },
        dun_morogh = { enemies = { 1125, 1126, 1397 }, boss = 1130 },
        teldrassil = { enemies = { 1984, 1986, 2002 }, boss = 2038 },
        mulgore = { enemies = { 2955, 2956, 2964 }, boss = 3058 },
        tirisfal = { enemies = { 1501, 1522, 1535 }, boss = 1658 },
        loch_modan = { enemies = { 1186, 1190, 1161 }, boss = 1398 },
        darkshore = { enemies = { 2172, 2185, 2235 }, boss = 2175 },
        silverpine = { enemies = { 1778, 1780, 1891 }, boss = 1947 },
        stonetalon = { enemies = { 4001, 4044, 3993 }, boss = 5930 },
        hillsbrad = { enemies = { 2384, 2269, 2372 }, boss = 14279 },
        thousand_needles = { enemies = { 4113, 4093, 4140 }, boss = 5935 },
        alterac = { enemies = { 2258, 2242, 2240 }, boss = 2452 },
        arathi = { enemies = { 2562, 2559, 2570 }, boss = 2604 },
        badlands = { enemies = { 2735, 2725, 2740 }, boss = 2744 },
        swamp_sorrows = { enemies = { 744, 764, 740 }, boss = 1063 },
        dustwallow = { enemies = { 4344, 4351, 4366 }, boss = 4380 },
        feralas = { enemies = { 5296, 5251, 5229 }, boss = 5354 },
        hinterlands = { enemies = { 2923, 2641, 2926 }, boss = 8210 },
        azshara = { enemies = { 6116, 6140, 6190 }, boss = 6648 },
        searing_gorge = { enemies = { 5850, 5840, 5860 }, boss = 8279 },
        blasted_lands = { enemies = { 5990, 5992, 5988 }, boss = 8297 },
        felwood = { enemies = { 7086, 7100, 7132 }, boss = 14467 },
        ungoro = { enemies = { 6505, 6510, 6520 }, boss = 6584 },
        burning_steppes = { enemies = { 7026, 7025, 7040 }, boss = 8978 },
        western_plaguelands = { enemies = { 1783, 1793, 1802 }, boss = 1847 },
        deadwind = { enemies = { 7370, 7376, 7379 }, boss = 7369 },
        eastern_plaguelands = { enemies = { 8543, 8550, 8598 }, boss = 10821 },
        silithus = { enemies = { 11722, 11724, 11730 }, boss = 14473 },
        moonglade = { enemies = { 15466 }, boss = 15467 },
        blackrock_mountain = { enemies = { 7025, 7026, 5850 }, boss = 9026 },
    },
}
