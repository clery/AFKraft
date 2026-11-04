local _, W = ...
local L = W.L
local C = W.Content
C.professions = {
    {
        id = "crafting",
        name = L["Crafting"],
        icon = "Trade_BlackSmithing",
        unlockLevel = 1,
        branches = {
            {
                id = "efficiency",
                name = L["Resourceful"],
                description = L["5% lower crafting costs per rank."],
            },
            {
                id = "quality",
                name = L["Refinement"],
                description = L["2% stronger crafted stats per rank; rank 3 adds one quality tier."],
            },
            {
                id = "precision",
                name = L["Precision"],
                description = L["5% stronger crafted stats per rank."],
            },
        },
    },
    {
        id = "enchanting",
        name = L["Enchanting"],
        icon = "Trade_Engraving",
        unlockLevel = 30,
        branches = {
            {
                id = "offense",
                name = L["Offense"],
                description = L["10% stronger offense enchantments per rank."],
            },
            {
                id = "defense",
                name = L["Defense"],
                description = L["10% stronger defense enchantments per rank."],
            },
            {
                id = "utility",
                name = L["Utility"],
                description = L["10% stronger utility enchantments per rank."],
            },
        },
    },
    {
        id = "titanforging",
        name = L["Titanforging"],
        icon = "INV_Hammer_20",
        unlockLevel = 50,
        branches = {
            {
                id = "efficiency",
                name = L["Efficient forging"],
                description = L["5% lower forging costs per rank."],
            },
            {
                id = "potential",
                name = L["Higher potential"],
                description = L["Each forge tier adds another 0.5% item power per rank."],
            },
            {
                id = "heirloom",
                name = L["Lasting investment"],
                description = L["5% lower heirloom forging costs per rank. Heirloom upgrades survive both resets."],
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
        name = L["Fury"],
        icon = "Ability_Warrior_BattleShout",
        stats = { attackPower = 6, spellPower = 6 },
    },
    {
        id = "defense",
        name = L["Fortitude"],
        icon = "Ability_Warrior_ShieldWall",
        stats = { stamina = 8, armor = 25 },
    },
    {
        id = "utility",
        name = L["Clarity"],
        icon = "Spell_Holy_MagicalSentry",
        stats = { spirit = 4, haste = 3 },
    },
}
C.enchants[#C.enchants + 1] = {
    id = "runicFury",
    name = L["Runic Fury"],
    icon = "Ability_Warrior_BattleShout",
    branch = "offense",
    tier = 2,
    fragments = 3,
    stats = { attackPower = 8, spellPower = 8 },
}
C.enchants[#C.enchants + 1] = {
    id = "runicFortitude",
    name = L["Runic Fortitude"],
    icon = "Ability_Warrior_ShieldWall",
    branch = "defense",
    tier = 5,
    fragments = 5,
    stats = { stamina = 10, armor = 32 },
}
C.enchants[#C.enchants + 1] = {
    id = "runicClarity",
    name = L["Runic Clarity"],
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
    boosts = { level = 22, hint = L["Reach lifetime idle level 22 to learn Commander boosts."] },
    onCooldown = { level = 45, hint = L["Reach lifetime idle level 45 to learn automation."] },
    conditional = {
        level = 60,
        hint = L["Reach lifetime idle level 60 to learn conditional automation."],
    },
    routes = { tier = 3, hint = L["Unlock difficulty tier 3 to learn route planning."] },
    heirlooms = { tier = 4, hint = L["Unlock difficulty tier 4 to learn heirloom recipes."] },
}

-- Idle boss trophies use zone IDs, independent of real WoW inventory items.
C.zoneComponents, C.forgeComponentZones = {}, {}
for _, zone in ipairs(C.zones) do
    C.zoneComponents[zone.id] = { name = zone.name .. L[" trophy"], zone = zone.id }
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
