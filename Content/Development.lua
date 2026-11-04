local _, W = ...
local L = W.L
local C = W.Content
C.development = {
    {
        id = "might",
        name = L.MIGHT,
        icon = "Ability_Warrior_BattleShout",
        summary = L.DAMAGE_AND_HEALING,
        description = L.PARTY_WIDE_DAMAGE_AND_HEALING_LATER_RANKS_GIVE_SMALLER,
        choices = {
            {
                id = "assault",
                name = L.ASSAULT,
                icon = "Ability_Warrior_BattleShout",
                description = L.BONUS_5_DAMAGE_WHILE_MIGHT_IS_RANK_3_OR_HIGHER,
            },
            {
                id = "restoration",
                name = L.RESTORATION,
                icon = "Spell_Holy_MagicalSentry",
                description = L.BONUS_5_HEALING_WHILE_MIGHT_IS_RANK_3_OR_HIGHER,
            },
        },
    },
    {
        id = "resolve",
        name = L.RESOLVE,
        icon = "Ability_Warrior_ShieldWall",
        summary = L.HEALTH_DEFENSE_AND_RECOVERY,
        description = L.PARTY_WIDE_MAXIMUM_HEALTH_DAMAGE_REDUCTION_AND_VICTORY_RECOVERY,
        choices = {
            {
                id = "bulwark",
                name = L.BULWARK,
                icon = "Ability_Warrior_ShieldWall",
                description = L.BONUS_5_MAXIMUM_HEALTH_WHILE_RESOLVE_IS_RANK_3_OR,
            },
            {
                id = "renewal",
                name = L.RENEWAL,
                icon = "Spell_Holy_MagicalSentry",
                description = L.RECOVER_0_5_MAXIMUM_HEALTH_AFTER_VICTORIES_AT_RESOLVE,
            },
        },
    },
    {
        id = "provisioning",
        name = L.PROVISIONING,
        icon = "Trade_BlackSmithing",
        summary = L.MATERIALS_REBUILDING_AND_CRAFTING,
        description = L.MORE_ZONE_MATERIALS_AND_HERO_XP_LOWER_EQUIPMENT_COSTS,
        choices = {
            {
                id = "harvest",
                name = L.HARVEST,
                icon = "Trade_BlackSmithing",
                description = L.BONUS_10_ZONE_MATERIALS_WHILE_PROVISIONING_IS_RANK_3_OR,
            },
            {
                id = "rebuild",
                name = L.REBUILD,
                icon = "INV_Misc_Book_09",
                description = L.BONUS_10_HERO_XP_WHILE_PROVISIONING_IS_RANK_3_OR,
            },
        },
    },
}
C.developmentByID = {}
for _, branch in ipairs(C.development) do
    C.developmentByID[branch.id] = branch
end
C.developmentRankCap = 10
