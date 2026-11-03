local _, W = ...
local C = W.Content
C.professions = {
    {
        id = "crafting",
        name = "Crafting",
        icon = "Trade_BlackSmithing",
        unlockLevel = 1,
        branches = {
            {
                id = "efficiency",
                name = "Resourceful",
                description = "5% lower crafting costs per rank.",
            },
            {
                id = "quality",
                name = "Refinement",
                description = "2% stronger crafted stats per rank; rank 3 adds one quality tier.",
            },
            {
                id = "precision",
                name = "Precision",
                description = "5% stronger crafted stats per rank.",
            },
        },
    },
    {
        id = "enchanting",
        name = "Enchanting",
        icon = "Trade_Engraving",
        unlockLevel = 30,
        branches = {
            {
                id = "offense",
                name = "Offense",
                description = "10% stronger offense enchantments per rank.",
            },
            {
                id = "defense",
                name = "Defense",
                description = "10% stronger defense enchantments per rank.",
            },
            {
                id = "utility",
                name = "Utility",
                description = "10% stronger utility enchantments per rank.",
            },
        },
    },
    {
        id = "titanforging",
        name = "Titanforging",
        icon = "INV_Hammer_20",
        unlockLevel = 40,
        branches = {
            {
                id = "efficiency",
                name = "Efficient forging",
                description = "5% lower forging costs per rank.",
            },
            {
                id = "potential",
                name = "Higher potential",
                description = "Each forge tier adds another 0.5% item power per rank.",
            },
            {
                id = "heirloom",
                name = "Lasting investment",
                description = "5% lower heirloom forging costs per rank. Item investments survive resets.",
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
        name = "Fury",
        icon = "Ability_Warrior_BattleShout",
        stats = { attackPower = 6, spellPower = 6 },
    },
    {
        id = "defense",
        name = "Fortitude",
        icon = "Ability_Warrior_ShieldWall",
        stats = { stamina = 8, armor = 25 },
    },
    {
        id = "utility",
        name = "Clarity",
        icon = "Spell_Holy_MagicalSentry",
        stats = { spirit = 4, haste = 3 },
    },
}
C.enchantByID = {}
for _, enchant in ipairs(C.enchants) do
    C.enchantByID[enchant.id] = enchant
end
C.professionRankCap, C.professionBranchCap, C.forgeCap = 30, 3, 5
