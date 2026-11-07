local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end

local function same(actual, expected, path)
    path = path or "state"
    assert(type(actual) == type(expected), path .. " type")
    if type(actual) ~= "table" then
        assert(actual == expected, path .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
        return
    end
    for key, value in pairs(expected) do
        same(actual[key], value, path .. "." .. tostring(key))
    end
    for key in pairs(actual) do
        assert(expected[key] ~= nil, path .. " extra " .. tostring(key))
    end
end

local function party()
    local state = G.New(1000)
    G.AddHero(state, "WARRIOR")
    G.AddHero(state, "PRIEST")
    state.safe.elwynn, state.runBest, state.best = 35, 60, 60
    for _, hero in ipairs(state.heroes) do
        hero.level = 60
        G.TalentProgress(hero)
        for _, node in ipairs(G.TalentList(hero)) do
            if node.effect == "criticalChance" or node.effect == "superCriticalChance" then
                hero.talents[node.id] = node.maxRanks
            end
        end
    end
    return state
end

local function compare(state, seconds, batch)
    local job = assert(G.BeginCatchup(state, state.lastTime + seconds))
    local reference = G.Copy(job.state)
    for _ = 1, job.remaining do
        G.Step(reference, 0.25)
    end
    reference.events = {}
    while not G.CatchupBatch(job, batch) do
    end
    same(job.state, reference)
    return job
end

case("Stable offline fights skip most ticks and preserve every reward and partial fight", function()
    local job = compare(party(), 86400, 1600)
    assert(job.skippedTicks > 86400 * 4 * 0.8)
    assert(#job.combatKeys <= 512)
    compare(party(), 123.75, 1)
    compare(party(), 123.75, 37)
end)

case("Offline fast-forward recalibrates at level-ups and boost transitions", function()
    local state = party()
    state.heroes[1].level, state.heroes[1].xp = 2, G.LevelXP(2) - 1
    state.safe.elwynn = 1
    state.professions.bestLevel, state.essence, state.legacy = 60, 1000, 10
    assert(G.BuyBoost(state, "battleOrders"))
    assert(G.BuyBoostAutomation(state, "onCooldown"))
    assert(G.ConfigureBoostAutomation(state, "battleOrders", "enabled", true))
    assert(G.SetBoostAutomationEnabled(state, true))
    local job = compare(state, 4000, 1600)
    assert(job.state.heroes[1].level > 2)
    assert(job.state.stats.boostUses >= 3)
    assert(job.skippedTicks > 0)
end)

case(
    "Offline fast-forward resumes without persisting cached battles or duplicating rewards",
    function()
        local state = party()
        local job = assert(G.BeginCatchup(state, 4600))
        G.CatchupBatch(job, 4000)
        assert(job.skippedTicks > 0)
        local expected = G.Copy(job.state)
        assert(G.FinishCatchup(state, job))
        assert(not G.FinishCatchup(state, job))
        assert(state.combats == nil and state.sample == nil)
        local resumed = assert(G.BeginCatchup(state, 4600))
        assert(resumed.seconds == 2600 and resumed.combats == nil)
        -- Reload recovery intentionally starts a fresh fight, just as the normal path does.
        expected.battle, expected.rest = nil, 0
        for _ = 1, resumed.remaining do
            G.Step(expected, 0.25)
        end
        while not G.CatchupBatch(resumed, 1600) do
        end
        assert(resumed.state.gold == expected.gold)
        assert(resumed.state.seed == expected.seed)
        assert(resumed.state.stats.victories == expected.stats.victories)
        assert(resumed.state.clock == expected.clock)
    end
)

return cases
