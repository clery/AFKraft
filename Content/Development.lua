local _, W = ...
local C = W.Content
C.development = {
    {
        id = "might",
        name = "Might",
        icon = "Ability_Warrior_BattleShout",
        summary = "Damage and healing",
        description = "Invest Essence in the whole company. Each rank improves damage and healing with diminishing returns.",
        choices = {
            {
                id = "assault",
                name = "Assault",
                icon = "Ability_Warrior_BattleShout",
                description = "+5% damage while Might is rank 3 or higher.",
            },
            {
                id = "restoration",
                name = "Restoration",
                icon = "Spell_Holy_MagicalSentry",
                description = "+5% healing while Might is rank 3 or higher.",
            },
        },
    },
    {
        id = "resolve",
        name = "Resolve",
        icon = "Ability_Warrior_ShieldWall",
        summary = "Health, defense and recovery",
        description = "Improve maximum health, reduce damage taken and recover a small health fraction after victories.",
        choices = {
            {
                id = "bulwark",
                name = "Bulwark",
                icon = "Ability_Warrior_ShieldWall",
                description = "+5% maximum health while Resolve is rank 3 or higher.",
            },
            {
                id = "renewal",
                name = "Renewal",
                icon = "Spell_Holy_MagicalSentry",
                description = "+0.5% maximum health recovered after victories while Resolve is rank 3 or higher.",
            },
        },
    },
    {
        id = "provisioning",
        name = "Provisioning",
        icon = "Trade_BlackSmithing",
        summary = "Materials, rebuilding and crafting",
        description = "Earn more zone materials and hero XP while reducing crafting costs. Real WoW Adventure XP is unchanged.",
        choices = {
            {
                id = "harvest",
                name = "Harvest",
                icon = "Trade_BlackSmithing",
                description = "+10% zone materials while Provisioning is rank 3 or higher.",
            },
            {
                id = "rebuild",
                name = "Rebuild",
                icon = "INV_Misc_Book_09",
                description = "+10% hero XP while Provisioning is rank 3 or higher.",
            },
        },
    },
}
C.developmentByID = {}
for _, branch in ipairs(C.development) do
    C.developmentByID[branch.id] = branch
end
C.developmentRankCap = 10
