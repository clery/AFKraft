-- Run from the repository root: lua scripts/balance_activity.lua
-- Activity counts include travel and downtime; these are playtest hypotheses.
local W = {}
for _, file in ipairs({
    "Content.lua",
    "Content/Items.lua",
    "Domain/State.lua",
    "Domain/Party.lua",
    "Domain/Inventory.lua",
    "Domain/Adventure.lua",
}) do
    assert(loadfile(file))("WoWIdle", W)
end
local C, G = W.Content, W.Game
local profiles = {
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
local firstBundle = 5 * G.TrainingCost({ rank = 0 }).essence
    + 10 * G.UpgradeCost({ upgrade = 0 }).essence
    + 5 * G.Cost({}, { level = 4 }, false).essence
local bundleXP = math.ceil(firstBundle / C.adventure.essencePerRank) * C.adventure.xpPerRank
print("Initial bundle: five level-cap raises, ten item upgrades, five level-4 crafts")
print(string.format("%d Essence; %d XP after whole-rank payouts", firstBundle, bundleXP))
print(
    "Profile | XP/hour | Essence/hour | First bundle hours | P10-P90 XP/hour | 100h Essence | Training tiers"
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
    G.AdventureXP(state, math.floor(baseline * 100), "model", profile.name)
    local income, wallet, tiers = state.essence, state.essence - firstBundle, 1
    while wallet >= 5 * G.TrainingCost({ rank = tiers }).essence do
        wallet = wallet - 5 * G.TrainingCost({ rank = tiers }).essence
        tiers = tiers + 1
    end
    print(
        string.format(
            "%s | %.0f | %.0f | %.2f | %.0f-%.0f | %d | %d",
            profile.name,
            baseline,
            baseline / C.adventure.xpPerRank * C.adventure.essencePerRank,
            bundleXP / baseline,
            rates[math.floor(samples * 0.1)],
            rates[math.floor(samples * 0.9)],
            income,
            tiers
        )
    )
end
