local _, W = ...

-- Initial prototype values; shared by previews, commands, and simulation.
W.Content.boosts = {
    {
        id = "battleOrders",
        name = "Battle Orders",
        icon = "Ability_Warrior_BattleShout",
        description = "+25% basic-attack speed. Does not accelerate spells or healing.",
        cost = 30,
        duration = 300,
        cooldown = 600,
        attackSpeed = 1.25,
    },
    {
        id = "ironResolve",
        name = "Iron Resolve",
        icon = "Ability_Warrior_ShieldWall",
        description = "Up to 20% less incoming damage. Existing defenses still apply.",
        cost = 30,
        duration = 300,
        cooldown = 600,
        damageTaken = 0.8,
    },
    {
        id = "focusedAssault",
        name = "Focused Assault",
        icon = "Ability_Warrior_SavageBlow",
        description = "+20% party damage, including strikes and ongoing effects.",
        cost = 60,
        duration = 300,
        cooldown = 600,
        damage = 1.2,
    },
    {
        id = "restorativeFocus",
        name = "Restorative Focus",
        icon = "Spell_Holy_FlashHeal",
        description = "+25% healing-spell output. Does not revive fallen allies.",
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
    onCooldown = { name = "On cooldown", currency = "legacy", cost = 1 },
    conditional = { name = "Conditional", currency = "legacy", cost = 2 },
}
W.Content.boostAutomationModes = {
    { id = "manual", name = "Manual" },
    { id = "onCooldown", name = "On cooldown", capability = "onCooldown" },
    { id = "boss", name = "Bosses", capability = "conditional" },
    { id = "lowHealth", name = "Low health", capability = "conditional" },
    { id = "farming", name = "Farming", capability = "conditional" },
    { id = "pushing", name = "Pushing", capability = "conditional" },
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
