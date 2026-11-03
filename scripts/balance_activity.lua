-- Run from the repository root: lua scripts/balance_activity.lua
-- Activity counts include travel and downtime; these are playtest hypotheses.
local W = {}
for _, file in ipairs({
    "Content.lua",
    "Content/Items.lua",
    "Content/Boosts.lua",
    "Content/Professions.lua",
    "Content/Development.lua",
    "Domain/State.lua",
    "Domain/Development.lua",
    "Domain/Boosts.lua",
    "Domain/Party.lua",
    "Domain/Inventory.lua",
    "Domain/Professions.lua",
    "Domain/Adventure.lua",
}) do
    assert(loadfile(file))("WoWIdle", W)
end
local C, G = W.Content, W.Game
local profiles = {
    { name = "Idle only", hourly = {} },
    { name = "Mixed questing", hourly = { quest = 8, kill = 80, gather = 4 } },
    { name = "Herb / ore route", hourly = { gather = 60, kill = 20 } },
    { name = "Kill and skin", hourly = { kill = 150, skinning = 150 } },
    { name = "Dense skinnable packs", hourly = { kill = 240, skinning = 240 } },
    {
        name = "Dungeon, 45 min",
        hourly = { kill = 80 / 0.75, boss = 4 / 0.75, dungeon = 1 / 0.75 },
    },
    { name = "Manual dungeon, 45 min", hourly = { kill = 80 / 0.75, boss = 4 / 0.75 } },
    { name = "Pure mob farming", hourly = { kill = 180 } },
}
local seed, samples = G.New(17), 5000
local preview = G.New(0)
local firstBundle = C.boostByID.battleOrders.cost
for _, branch in ipairs(C.development) do
    firstBundle = firstBundle + G.DevelopmentQuote(preview, branch.id).cost
end
local bundleXP = math.ceil(firstBundle / C.adventure.essencePerRank) * C.adventure.xpPerRank
print("Optional first bundle: one rank in each Development branch and Battle Orders")
print("Hero growth to 60 and routine equipment require no Essence.")
print(string.format("%d Essence; %d XP after whole-rank payouts", firstBundle, bundleXP))
print(
    "Profile | XP/hour | Essence/hour | Optional bundle hours | P10-P90 XP/hour | 100h income | Board ranks M/R/P | Unspent"
)
for _, profile in ipairs(profiles) do
    local baseline = 0
    for kind, count in pairs(profile.hourly) do
        baseline = baseline + count * C.activityRewards[kind].xp
    end
    local rates = {}
    for i = 1, samples do
        local rate = 0
        for _, kind in ipairs(C.activityOrder) do
            local count = profile.hourly[kind] or 0
            local efficiency = 0.75 + (G.Random(seed, 10001) - 1) / 10000 * 0.5
            rate = rate + count * efficiency * C.activityRewards[kind].xp
        end
        rates[i] = rate
    end
    table.sort(rates)
    local state = G.New(0)
    if baseline > 0 then
        G.AdventureXP(state, math.floor(baseline * 100), "model", profile.name)
    end
    local income = state.essence
    if state.essence >= C.boostByID.battleOrders.cost then
        G.BuyBoost(state, "battleOrders")
    end
    for _ = 1, C.developmentRankCap do
        for _, branch in ipairs(C.development) do
            local quote = G.DevelopmentQuote(state, branch.id)
            if not quote.maximum and state.essence >= quote.cost then
                G.BuyDevelopment(state, branch.id)
            end
        end
    end
    print(
        string.format(
            "%s | %.0f | %.0f | %s | %.0f-%.0f | %d | %d/%d/%d | %d",
            profile.name,
            baseline,
            baseline / C.adventure.xpPerRank * C.adventure.essencePerRank,
            baseline > 0 and string.format("%.2f", bundleXP / baseline) or "not funded",
            rates[math.floor(samples * 0.1)],
            rates[math.floor(samples * 0.9)],
            income,
            state.development.ranks.might,
            state.development.ranks.resolve,
            state.development.ranks.provisioning,
            state.essence
        )
    )
end
