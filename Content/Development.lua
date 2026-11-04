local _, W = ...
local L = W.L
local C = W.Content
C.development = {
    {
        id = "might",
        name = L["Might"],
        icon = "Ability_Warrior_BattleShout",
        summary = L["Damage and healing"],
        description = L["Party-wide damage and healing. Later ranks give smaller gains."],
        choices = {
            {
                id = "assault",
                name = L["Assault"],
                icon = "Ability_Warrior_BattleShout",
                description = L["+5% damage while Might is rank 3 or higher."],
            },
            {
                id = "restoration",
                name = L["Restoration"],
                icon = "Spell_Holy_MagicalSentry",
                description = L["+5% healing while Might is rank 3 or higher."],
            },
        },
    },
    {
        id = "resolve",
        name = L["Resolve"],
        icon = "Ability_Warrior_ShieldWall",
        summary = L["Health, defense and recovery"],
        description = L["Party-wide maximum health, damage reduction and victory recovery."],
        choices = {
            {
                id = "bulwark",
                name = L["Bulwark"],
                icon = "Ability_Warrior_ShieldWall",
                description = L["+5% maximum health while Resolve is rank 3 or higher."],
            },
            {
                id = "renewal",
                name = L["Renewal"],
                icon = "Spell_Holy_MagicalSentry",
                description = L["Recover +0.5% maximum health after victories at Resolve rank 3+."],
            },
        },
    },
    {
        id = "provisioning",
        name = L["Provisioning"],
        icon = "Trade_BlackSmithing",
        summary = L["Materials, rebuilding and crafting"],
        description = L["More zone materials and hero XP; lower equipment costs. Adventure XP is unchanged."],
        choices = {
            {
                id = "harvest",
                name = L["Harvest"],
                icon = "Trade_BlackSmithing",
                description = L["+10% zone materials while Provisioning is rank 3 or higher."],
            },
            {
                id = "rebuild",
                name = L["Rebuild"],
                icon = "INV_Misc_Book_09",
                description = L["+10% hero XP while Provisioning is rank 3 or higher."],
            },
        },
    },
}
C.developmentByID = {}
for _, branch in ipairs(C.development) do
    C.developmentByID[branch.id] = branch
end
C.developmentRankCap = 10
