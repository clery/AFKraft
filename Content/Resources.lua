local _, W = ...
local L = W.L
local C = W.Content
-- Authored idle-combat rules, independent of the real character's resource APIs.
C.heroResources = {
    rage = {
        name = L.RAGE,
        maximum = 100,
        initial = 0,
        regen = 0,
        swing = 15,
        damage = 5,
        costs = { attack = 20, heal = 15, special = 30 },
        description = L.STARTS_EMPTY_EACH_ENCOUNTER_BASIC_ATTACKS_GENERATE_15_RAGE,
    },
    energy = {
        name = L.ENERGY,
        maximum = 100,
        initial = 100,
        regen = 8,
        swing = 0,
        damage = 0,
        costs = { attack = 45, heal = 30, special = 60 },
        description = L.STARTS_FULL_EACH_ENCOUNTER_AND_REGENERATES_8_ENERGY_PER,
    },
    mana = {
        name = L.MANA,
        maximum = 100,
        initial = 100,
        regen = 4,
        swing = 0,
        damage = 0,
        costs = { attack = 30, heal = 20, special = 40 },
        description = L.STARTS_FULL_EACH_ENCOUNTER_AND_REGENERATES_4_MANA_PER,
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
