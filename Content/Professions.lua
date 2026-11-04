local _, W = ...
local L = W.L
local C = W.Content
C.professions = {
    {
        id = "crafting",
        name = L.CRAFTING,
        icon = "Trade_BlackSmithing",
        unlockLevel = 1,
        branches = {
            {
                id = "efficiency",
                name = L.RESOURCEFUL,
                description = L.TEXT_5_LOWER_CRAFTING_COSTS_PER_RANK,
            },
            {
                id = "quality",
                name = L.REFINEMENT,
                description = L.TEXT_2_STRONGER_CRAFTED_STATS_PER_RANK_RANK_3_ADDS,
            },
            {
                id = "precision",
                name = L.PRECISION,
                description = L.TEXT_5_STRONGER_CRAFTED_STATS_PER_RANK,
            },
        },
    },
    {
        id = "enchanting",
        name = L.ENCHANTING,
        icon = "Trade_Engraving",
        unlockLevel = 30,
        branches = {
            {
                id = "offense",
                name = L.OFFENSE,
                description = L.TEXT_10_STRONGER_OFFENSE_ENCHANTMENTS_PER_RANK,
            },
            {
                id = "defense",
                name = L.DEFENSE,
                description = L.TEXT_10_STRONGER_DEFENSE_ENCHANTMENTS_PER_RANK,
            },
            {
                id = "utility",
                name = L.UTILITY,
                description = L.TEXT_10_STRONGER_UTILITY_ENCHANTMENTS_PER_RANK,
            },
        },
    },
    {
        id = "titanforging",
        name = L.TITANFORGING,
        icon = "INV_Hammer_20",
        unlockLevel = 50,
        branches = {
            {
                id = "efficiency",
                name = L.EFFICIENT_FORGING,
                description = L.TEXT_5_LOWER_FORGING_COSTS_PER_RANK,
            },
            {
                id = "potential",
                name = L.HIGHER_POTENTIAL,
                description = L.EACH_FORGE_TIER_ADDS_ANOTHER_0_5_ITEM_POWER,
            },
            {
                id = "heirloom",
                name = L.LASTING_INVESTMENT,
                description = L.TEXT_5_LOWER_HEIRLOOM_FORGING_COSTS_PER_RANK_HEIRLOOM_UPGRADES,
            },
        },
    },
}
C.professionByID = {}
for _, profession in ipairs(C.professions) do
    C.professionByID[profession.id] = profession
end
C.enchants = {
    {
        id = "offense",
        name = L.FURY,
        icon = "Ability_Warrior_BattleShout",
        stats = { attackPower = 6, spellPower = 6 },
    },
    {
        id = "defense",
        name = L.FORTITUDE,
        icon = "Ability_Warrior_ShieldWall",
        stats = { stamina = 8, armor = 25 },
    },
    {
        id = "utility",
        name = L.CLARITY,
        icon = "Spell_Holy_MagicalSentry",
        stats = { spirit = 4, haste = 3 },
    },
}
C.enchants[#C.enchants + 1] = {
    id = "runicFury",
    name = L.RUNIC_FURY,
    icon = "Ability_Warrior_BattleShout",
    branch = "offense",
    tier = 2,
    fragments = 3,
    stats = { attackPower = 8, spellPower = 8 },
}
C.enchants[#C.enchants + 1] = {
    id = "runicFortitude",
    name = L.RUNIC_FORTITUDE,
    icon = "Ability_Warrior_ShieldWall",
    branch = "defense",
    tier = 5,
    fragments = 5,
    stats = { stamina = 10, armor = 32 },
}
C.enchants[#C.enchants + 1] = {
    id = "runicClarity",
    name = L.RUNIC_CLARITY,
    icon = "Spell_Holy_MagicalSentry",
    branch = "utility",
    tier = 8,
    fragments = 8,
    stats = { spirit = 5, haste = 4 },
}
C.runicFragmentCap = 1000
C.enchantByID = {}
for _, enchant in ipairs(C.enchants) do
    C.enchantByID[enchant.id] = enchant
end
C.professionRankCap, C.professionBranchCap, C.forgeCap = 30, 3, 5

-- Convenience follows hands-on progression; tiers use the permanent unlocked record.
C.featureMilestones = {
    boosts = { level = 22, hint = L.REACH_LIFETIME_IDLE_LEVEL_22_TO_LEARN_COMMANDER_BOOSTS },
    onCooldown = { level = 45, hint = L.REACH_LIFETIME_IDLE_LEVEL_45_TO_LEARN_AUTOMATION },
    conditional = {
        level = 60,
        hint = L.REACH_LIFETIME_IDLE_LEVEL_60_TO_LEARN_CONDITIONAL_AUTOMATION,
    },
    routes = { tier = 3, hint = L.UNLOCK_DIFFICULTY_TIER_3_TO_LEARN_ROUTE_PLANNING },
    heirlooms = { tier = 4, hint = L.UNLOCK_DIFFICULTY_TIER_4_TO_LEARN_HEIRLOOM_RECIPES },
}

-- Idle boss trophies use zone IDs, independent of real WoW inventory items.
C.zoneComponents, C.forgeComponentZones = {}, {}
for _, zone in ipairs(C.zones) do
    C.zoneComponents[zone.id] = { name = zone.name .. L.TROPHY_SUFFIX, zone = zone.id }
    if zone.id ~= "blackrock_mountain" then
        C.forgeComponentZones[#C.forgeComponentZones + 1] = zone.id
    end
end
table.sort(C.forgeComponentZones, function(a, b)
    local first, second = C.zoneByID[a], C.zoneByID[b]
    return first.level == second.level and a < b or first.level < second.level
end)
C.forgeComponentZones[#C.forgeComponentZones + 1] = "blackrock_mountain"
C.enchantComponentZones = {
    offense = "westfall",
    defense = "barrens",
    utility = "ashenvale",
    runicFury = "burning_steppes",
    runicFortitude = "eastern_plaguelands",
    runicClarity = "winterspring",
}
C.componentCap = 1000000000
