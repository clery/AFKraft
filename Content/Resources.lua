local _, W = ...
local L = W.L
local C = W.Content
-- Authored idle-combat rules, independent of the real character's resource APIs.
C.heroResources = {
    rage = {
        name = L["Rage"],
        maximum = 100,
        initial = 0,
        regen = 0,
        swing = 15,
        damage = 5,
        costs = { attack = 20, heal = 15, special = 30 },
        description = L["Starts empty each encounter. Basic attacks generate 15 Rage; receiving damage generates 5. No passive regeneration."],
    },
    energy = {
        name = L["Energy"],
        maximum = 100,
        initial = 100,
        regen = 8,
        swing = 0,
        damage = 0,
        costs = { attack = 45, heal = 30, special = 60 },
        description = L["Starts full each encounter and regenerates 8 Energy per second."],
    },
    mana = {
        name = L["Mana"],
        maximum = 100,
        initial = 100,
        regen = 4,
        swing = 0,
        damage = 0,
        costs = { attack = 30, heal = 20, special = 40 },
        description = L["Starts full each encounter and regenerates 4 Mana per second."],
    },
}
C.heroResourceByClass = {
    WARRIOR = "rage",
    ROGUE = "energy",
    PALADIN = "mana",
    HUNTER = "mana",
    PRIEST = "mana",
    SHAMAN = "mana",
    MAGE = "mana",
    WARLOCK = "mana",
    DRUID = "mana",
}
