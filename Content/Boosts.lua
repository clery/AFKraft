local _, W = ...
local L = W.L

-- Shared by previews, commands, and simulation; see BALANCE.md for uptime tradeoffs.
W.Content.boosts = {
    {
        id = "battleOrders",
        name = L.BATTLE_ORDERS,
        icon = "Ability_Warrior_BattleShout",
        description = L.BONUS_25_BASIC_ATTACK_SPEED_SPELL_AND_HEALING_COOLDOWNS_ARE,
        cost = 30,
        duration = 300,
        cooldown = 600,
        attackSpeed = 1.25,
    },
    {
        id = "ironResolve",
        name = L.IRON_RESOLVE,
        icon = "Ability_Warrior_ShieldWall",
        description = L.UP_TO_20_LESS_INCOMING_DAMAGE_LIMITED_BY_90,
        cost = 30,
        duration = 300,
        cooldown = 600,
        damageTaken = 0.8,
    },
    {
        id = "focusedAssault",
        name = L.FOCUSED_ASSAULT,
        icon = "Ability_Warrior_SavageBlow",
        description = L.BONUS_20_PARTY_DAMAGE_INCLUDING_STRIKES_AND_ONGOING_EFFECTS,
        cost = 60,
        duration = 300,
        cooldown = 600,
        damage = 1.2,
    },
    {
        id = "restorativeFocus",
        name = L.RESTORATIVE_FOCUS,
        icon = "Spell_Holy_FlashHeal",
        description = L.BONUS_25_HEALING_FROM_SPELLS_CANNOT_REVIVE_FALLEN_ALLIES,
        cost = 60,
        duration = 300,
        cooldown = 600,
        healing = 1.25,
    },
}
W.Content.boostByID = {}
for _, boost in ipairs(W.Content.boosts) do
    boost.legacyCost = 1
    W.Content.boostByID[boost.id] = boost
end

-- Automation unlocks are permanent capabilities, never activation fees.
W.Content.boostAutomation = {
    onCooldown = { name = L.ON_COOLDOWN, currency = "legacy", cost = 1 },
    conditional = { name = L.CONDITIONAL, currency = "legacy", cost = 2 },
}
W.Content.boostAutomationModes = {
    { id = "manual", name = L.MANUAL },
    { id = "onCooldown", name = L.ON_COOLDOWN, capability = "onCooldown" },
    { id = "boss", name = L.BOSSES, capability = "conditional" },
    { id = "lowHealth", name = L.LOW_HEALTH, capability = "conditional" },
    { id = "farming", name = L.FARMING, capability = "conditional" },
    { id = "pushing", name = L.PUSHING, capability = "conditional" },
}
W.Content.boostAutomationModeByID = {}
W.Content.boostAutomationDefaults = { owned = {}, enabled = false, abilities = {} }
for _, mode in ipairs(W.Content.boostAutomationModes) do
    W.Content.boostAutomationModeByID[mode.id] = mode
end
for _, boost in ipairs(W.Content.boosts) do
    W.Content.boostAutomationDefaults.abilities[boost.id] = {
        enabled = false,
        mode = "manual",
        healthBelow = 50,
    }
end
