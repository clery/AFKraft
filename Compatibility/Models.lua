local _, W = ...

-- Creature IDs resolve complete NPC appearances, including their baked skins.
-- Bare race display IDs do not contain a character's composite textures.
W.ModelAssets = {
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
    },
}
