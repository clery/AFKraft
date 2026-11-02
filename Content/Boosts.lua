local _, W = ...

-- Initial prototype values; shared by previews, commands, and simulation.
W.Content.boosts = {
    {
        id = "battleOrders",
        name = "Battle Orders",
        description = "+25% basic-attack speed. Does not accelerate spells or healing.",
        cost = 30,
        duration = 300,
        cooldown = 600,
        attackSpeed = 1.25,
    },
    {
        id = "ironResolve",
        name = "Iron Resolve",
        description = "Up to 20% less incoming damage. Existing defenses still apply.",
        cost = 30,
        duration = 300,
        cooldown = 600,
        damageTaken = 0.8,
    },
}
W.Content.boostByID = {}
for _, boost in ipairs(W.Content.boosts) do
    W.Content.boostByID[boost.id] = boost
end
