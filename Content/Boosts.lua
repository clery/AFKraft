local _, W = ...
local L = W.L

-- Shared by previews, commands, and simulation; see BALANCE.md for uptime tradeoffs.
W.Content.boosts = {
    {
        id = "battleOrders",
        name = L["Battle Orders"],
        icon = "Ability_Warrior_BattleShout",
        description = L["+25% basic-attack speed. Spell and healing cooldowns are unchanged."],
        cost = 30,
        duration = 300,
        cooldown = 600,
        attackSpeed = 1.25,
    },
    {
        id = "ironResolve",
        name = L["Iron Resolve"],
        icon = "Ability_Warrior_ShieldWall",
        description = L["Up to 20% less incoming damage, limited by 90% total reduction. Stronger defenses are kept."],
        cost = 30,
        duration = 300,
        cooldown = 600,
        damageTaken = 0.8,
    },
    {
        id = "focusedAssault",
        name = L["Focused Assault"],
        icon = "Ability_Warrior_SavageBlow",
        description = L["+20% party damage, including strikes and ongoing effects."],
        cost = 60,
        duration = 300,
        cooldown = 600,
        damage = 1.2,
    },
    {
        id = "restorativeFocus",
        name = L["Restorative Focus"],
        icon = "Spell_Holy_FlashHeal",
        description = L["+25% healing from spells. Cannot revive fallen allies."],
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
    onCooldown = { name = L["On cooldown"], currency = "legacy", cost = 1 },
    conditional = { name = L["Conditional"], currency = "legacy", cost = 2 },
}
W.Content.boostAutomationModes = {
    { id = "manual", name = L["Manual"] },
    { id = "onCooldown", name = L["On cooldown"], capability = "onCooldown" },
    { id = "boss", name = L["Bosses"], capability = "conditional" },
    { id = "lowHealth", name = L["Low health"], capability = "conditional" },
    { id = "farming", name = L["Farming"], capability = "conditional" },
    { id = "pushing", name = L["Pushing"], capability = "conditional" },
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
