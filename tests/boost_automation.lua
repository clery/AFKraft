local _, W = ...
if not W then
    return
end
local G = W.Game
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

local function party()
    local s = G.New(0)
    s.professions.bestLevel = 60
    G.AddHero(s, "WARRIOR")
    s.essence, s.legacy = 60, 3
    assert(G.BuyBoost(s, "battleOrders"))
    assert(G.BuyBoost(s, "ironResolve"))
    return s
end

local function automated(mode)
    local s = party()
    assert(G.BuyBoostAutomation(s, "onCooldown"))
    assert(G.BuyBoostAutomation(s, "conditional"))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "mode", mode or "onCooldown"))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", true))
    assert(G.SetBoostAutomationEnabled(s, true))
    return s
end

case(
    "Automation capabilities charge once and conditional modes require the first unlock",
    function()
        local s = party()
        assert(not G.BuyBoostAutomation(s, "conditional"))
        assert(not G.BuyBoostAutomation(s, "unknown"))
        assert(s.legacy == 3)
        s.legacy = 0
        assert(not G.BuyBoostAutomation(s, "onCooldown"))
        s.legacy = 3
        assert(G.BuyBoostAutomation(s, "onCooldown"))
        assert(s.legacy == 2)
        assert(not G.BuyBoostAutomation(s, "onCooldown"))
        assert(s.legacy == 2)
        assert(G.BuyBoostAutomation(s, "conditional"))
        assert(not G.BuyBoostAutomation(s, "conditional"))
        assert(s.legacy == 0 and s.essence == 0)
    end
)

case("Automation configuration validates capability gates and typed bounded values", function()
    local s = party()
    assert(not G.SetBoostAutomationEnabled(s, true))
    assert(not G.SetBoostAutomationEnabled(s, "true"))
    assert(not G.ConfigureBoostAutomation(s, "battleOrders", "enabled", true))
    assert(not G.ConfigureBoostAutomation(s, "battleOrders", "mode", "onCooldown"))
    assert(G.BuyBoostAutomation(s, "onCooldown"))
    assert(not G.ConfigureBoostAutomation(s, "battleOrders", "mode", "boss"))
    assert(not G.ConfigureBoostAutomation(s, "unknown", "enabled", true))
    assert(not G.ConfigureBoostAutomation(s, "battleOrders", "script", "anything"))
    assert(not G.ConfigureBoostAutomation(s, "battleOrders", "enabled", 1))
    assert(not G.ConfigureBoostAutomation(s, "battleOrders", "mode", "unknown"))
    for _, value in ipairs({ -1, 9, 91, 50.5, 0 / 0, math.huge, "50" }) do
        assert(not G.ConfigureBoostAutomation(s, "battleOrders", "healthBelow", value))
    end
    assert(s.boosts.automation.abilities.battleOrders.healthBelow == 50)
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "healthBelow", 65))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "mode", "onCooldown"))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", true))
    assert(G.SetBoostAutomationEnabled(s, true))
end)

case("Automation is opt-in and never spends a ready boost outside a living encounter", function()
    local s = automated()
    assert(not G.AutomateBoost(s))
    assert(not next(s.boosts.readyAt))
    s.rest = 1
    G.Step(s, 0.25)
    assert(not next(s.boosts.readyAt))
    s.rest = 0
    G.Step(s, 0.25)
    assert(s.battle and not next(s.boosts.readyAt))
    local start = s.clock
    G.Step(s, 0.25)
    assert(s.boosts.readyAt.battleOrders == start + 600)
    assert(s.boosts.activeUntil.battleOrders == start + 300)
    assert(s.essence == 0 and s.legacy == 0)
    assert(G.SetBoostAutomationEnabled(s, false))
    s.clock = start + 600
    local readyAt = s.boosts.readyAt.battleOrders
    G.Step(s, 0.25)
    assert(s.boosts.readyAt.battleOrders == readyAt)
end)

case("Paused and individually disabled automation never block manual activation", function()
    local s = automated()
    assert(G.SetBoostAutomationEnabled(s, false))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", false))
    G.StartBattle(s)
    assert(not G.AutomateBoost(s))
    assert(G.ActivateBoost(s, "battleOrders"))
    local active, cooldown = G.BoostRemaining(s, "battleOrders")
    assert(active == 300 and cooldown == 600)
    assert(G.SetBoostAutomationEnabled(s, true))
    s.clock = 600
    assert(not G.AutomateBoost(s))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", true))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "mode", "manual"))
    assert(not G.AutomateBoost(s))
    assert(G.ActivateBoost(s, "battleOrders"))
end)

case(
    "Manual activation wins a simultaneous automatic request without refreshing or extending it",
    function()
        local s = automated()
        G.StartBattle(s)
        assert(G.ActivateBoost(s, "battleOrders"))
        local journalSize = #s.log
        assert(not G.AutomateBoost(s))
        G.Step(s, 0.25)
        assert(s.boosts.readyAt.battleOrders == 600 and s.boosts.activeUntil.battleOrders == 300)
        assert(#s.log == journalSize)
    end
)

case(
    "Automation honors cooldown boundaries and shared effect capacity after loadout swaps",
    function()
        local s = automated()
        assert(G.ConfigureBoostAutomation(s, "ironResolve", "mode", "onCooldown"))
        assert(G.ConfigureBoostAutomation(s, "ironResolve", "enabled", true))
        G.StartBattle(s)
        assert(G.AutomateBoost(s))
        assert(G.EquipBoost(s, "ironResolve"))
        assert(not G.AutomateBoost(s))
        assert(not s.boosts.readyAt.ironResolve)
        s.clock = 300
        assert(G.AutomateBoost(s))
        assert(s.boosts.readyAt.ironResolve == 900)
        assert(G.EquipBoost(s, "battleOrders"))
        s.clock = 599.75
        assert(not G.AutomateBoost(s))
        s.clock = 600
        assert(G.AutomateBoost(s))
        assert(s.boosts.readyAt.battleOrders == 1200)
    end
)

case("Boss rules reserve readiness and never activate on completed battles", function()
    local s = automated("boss")
    G.StartBattle(s)
    assert(not G.AutomateBoost(s))
    local _, reason = G.BoostAutomationStatus(s, "battleOrders")
    assert(reason == "Waiting for a boss encounter.")
    s.battle.boss = true
    s.battle.enemies[1].hp = 0
    assert(not G.AutomateBoost(s))
    s.battle.enemies[1].hp = 1
    assert(G.AutomateBoost(s))
end)

case("Health rules inspect the lowest living ally and treat the threshold strictly", function()
    local s = automated("lowHealth")
    G.AddHero(s, "PRIEST")
    G.StartBattle(s)
    local first, second = s.battle.heroes[1], s.battle.heroes[2]
    first.hp, first.maxHP = 0, 100
    second.hp, second.maxHP = 50, 100
    assert(not G.AutomateBoost(s))
    second.hp = 49
    assert(G.AutomateBoost(s))
    assert(first.hp == 0 and second.hp == 49)
end)

case("Farming and pushing rules use current run context without changing destinations", function()
    for _, mode in ipairs({ "farming", "pushing" }) do
        local s = automated(mode)
        G.StartBattle(s)
        s.farming = mode ~= "farming"
        assert(not G.AutomateBoost(s))
        s.farming = not s.farming
        assert(G.AutomateBoost(s))
        assert(s.zone == "elwynn" and s.stage == 1)
    end
end)

case(
    "Newly learned automation stays disabled and expired cooldowns do not bypass ownership",
    function()
        local s = party()
        assert(G.BuyBoostAutomation(s, "onCooldown"))
        G.StartBattle(s)
        s.clock = 10000
        assert(not G.AutomateBoost(s))
        assert(not s.boosts.automation.enabled)
        assert(s.boosts.automation.abilities.battleOrders.mode == "manual")
        local unlearned = G.New(0)
        assert(not G.ConfigureBoostAutomation(unlearned, "battleOrders", "mode", "manual"))
    end
)

case(
    "Automation ownership, rules and pause preferences survive reload and prestige at level one",
    function()
        local s = automated("lowHealth")
        assert(G.ConfigureBoostAutomation(s, "battleOrders", "healthBelow", 65))
        assert(G.ConfigureBoostAutomation(s, "ironResolve", "mode", "boss"))
        s.prestigeUnlocked, s.runBest = true, 9
        s = assert(G.Load(G.Copy(s), 90000))
        assert(s.boosts.automation.abilities.battleOrders.healthBelow == 65)
        assert(G.Prestige(s))
        assert(s.heroes[1].level == 1 and s.boosts.automation.owned.conditional)
        assert(s.boosts.automation.enabled)
        G.StartBattle(s)
        s.battle.heroes[1].hp = s.battle.heroes[1].maxHP * 0.5
        assert(G.AutomateBoost(s))
        assert(G.SetBoostAutomationEnabled(s, false))
        assert(G.Prestige(s))
        s = assert(G.Load(G.Copy(s), 100000))
        assert(not s.boosts.automation.enabled)
        assert(s.boosts.automation.abilities.battleOrders.enabled)
        assert(s.boosts.automation.abilities.ironResolve.mode == "boss")
    end
)

case("Pre-automation saves migrate without spending currency or changing boost timers", function()
    local s = party()
    assert(G.ActivateBoost(s, "battleOrders"))
    s.clock, s.boosts.automation = 100, nil
    s = assert(G.Load(s, 1000))
    assert(s.boosts.owned.battleOrders and s.boosts.equipped == "battleOrders")
    assert(not next(s.boosts.automation.owned) and not s.boosts.automation.enabled)
    local active, cooldown = G.BoostRemaining(s, "battleOrders")
    assert(active == 200 and cooldown == 500 and s.legacy == 3)
end)

case(
    "Malformed automation saves are rejected instead of silently enabling or rewriting rules",
    function()
        local corruptions = {
            function(a)
                a.enabled = "true"
            end,
            function(a)
                a.enabled, a.owned = true, {}
            end,
            function(a)
                a.owned.onCooldown = nil
            end,
            function(a)
                a.owned.extra = true
            end,
            function(a)
                a.abilities = false
            end,
            function(a)
                a.abilities.battleOrders.mode = "unknown"
            end,
            function(a)
                a.abilities.battleOrders.enabled = 1
            end,
            function(a)
                a.abilities.battleOrders.enabled = nil
            end,
            function(a)
                a.abilities.battleOrders.healthBelow = 0 / 0
            end,
            function(a)
                a.abilities.battleOrders.healthBelow = 0
            end,
            function(a)
                a.abilities.unknown = {}
            end,
        }
        for _, corrupt in ipairs(corruptions) do
            local s = automated()
            corrupt(s.boosts.automation)
            assert(not G.Load(s, 10))
            assert(s.essence == 0 and s.legacy == 0)
        end
    end
)

case(
    "Offline automation matches ordinary safe farming including repeated activations and live rewards",
    function()
        local s = automated("farming")
        s.safe.elwynn, s.farming = 1, true
        local online = G.Copy(s)
        local job = assert(G.BeginCatchup(s, 1300))
        for _ = 1, 5200 do
            G.Step(online, 0.25)
        end
        G.AdventureXP(s, 100, "test", "Activity")
        while not G.CatchupBatch(job, 700) do
        end
        G.FinishCatchup(s, job)
        assert(s.gold == online.gold and s.stats.victories == online.stats.victories)
        assert(s.heroes[1].xp == online.heroes[1].xp)
        assert(s.boosts.readyAt.battleOrders == online.boosts.readyAt.battleOrders)
        assert(s.boosts.activeUntil.battleOrders == online.boosts.activeUntil.battleOrders)
        assert(s.boosts.readyAt.battleOrders > 1200 and s.clock == 1300)
        assert(s.essence == 60 and s.legacy == 0)
    end
)

case("Interrupted catch-up and reload cannot repeat an already automatic activation", function()
    local s = automated()
    s.safe.elwynn = 1
    local job = assert(G.BeginCatchup(s, 90000))
    assert(job.seconds == 86400)
    G.CatchupBatch(job, 400)
    G.FinishCatchup(s, job)
    local readyAt = s.boosts.readyAt.battleOrders
    s = assert(G.Load(G.Copy(s), 90000))
    assert(not G.BeginCatchup(s, s.lastTime - 100))
    job = assert(G.BeginCatchup(s, 90000))
    assert(job.seconds == 86300)
    G.CatchupBatch(job, 400)
    G.FinishCatchup(s, job)
    assert(s.boosts.readyAt.battleOrders == readyAt and s.clock == 200)
    assert(s.essence == 0 and s.legacy == 0)
end)

case("Automatic failures do not create notifications or an unbounded journal", function()
    local s = automated("boss")
    G.StartBattle(s)
    local size = #s.log
    for _ = 1, 100 do
        assert(not G.AutomateBoost(s))
    end
    assert(#s.log == size)
    s.battle.boss = true
    local previous, notices = W.OnLog, 0
    W.OnLog = function()
        notices = notices + 1
    end
    local ok = G.AutomateBoost(s)
    W.OnLog = previous
    assert(ok and notices == 0 and #s.log == size + 1)
end)

case("Dead parties and ineligible offline absence cannot trigger automatic boosts", function()
    local s = automated()
    G.StartBattle(s)
    s.battle.heroes[1].hp = 0
    assert(not G.AutomateBoost(s))
    assert(not next(s.boosts.readyAt))
    assert(not G.BeginCatchup(s, 90000))
    assert(s.clock == 0 and not next(s.boosts.readyAt))
    assert(s.boosts.automation.enabled)
end)

case(
    "Missing catalog rule entries gain disabled defaults without altering existing rules",
    function()
        local s = automated("lowHealth")
        assert(G.ConfigureBoostAutomation(s, "battleOrders", "healthBelow", 65))
        s.boosts.automation.abilities.ironResolve = nil
        s = assert(G.Load(s, 100))
        local rules = s.boosts.automation.abilities
        assert(not rules.ironResolve.enabled and rules.ironResolve.mode == "manual")
        assert(rules.battleOrders.enabled and rules.battleOrders.mode == "lowHealth")
        assert(rules.battleOrders.healthBelow == 65 and s.boosts.automation.enabled)
    end
)

case("Enabling a boost supplies on-cooldown behavior without replacing saved conditions", function()
    local s = party()
    assert(G.BuyBoostAutomation(s, "onCooldown"))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", true))
    local config = s.boosts.automation.abilities.battleOrders
    assert(config.mode == "onCooldown" and not s.boosts.automation.enabled)
    assert(G.BuyBoostAutomation(s, "conditional"))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "mode", "boss"))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", false))
    assert(G.ConfigureBoostAutomation(s, "battleOrders", "enabled", true))
    assert(config.mode == "boss")
end)

case("Convenience unlocks require earned milestones and never charge early", function()
    local s = G.New(0)
    assert(G.AddHero(s, "WARRIOR"))
    s.legacy = 100
    assert(not G.BuyBoost(s, "battleOrders"))
    assert(not G.BuyBoost(s, "battleOrders", "legacy"))
    s.professions.bestLevel = 22
    assert(G.BuyBoost(s, "battleOrders", "legacy"))
    s.legacy = 100
    s.clock = 1000000
    for _, level in ipairs({ 1, 44 }) do
        s.professions.bestLevel = level
        assert(not G.BuyBoostAutomation(s, "onCooldown"))
        assert(s.legacy == 100)
    end
    s.heroes[1].level = 45
    assert(G.BuyBoostAutomation(s, "onCooldown"))
    assert(not G.BuyBoostAutomation(s, "conditional") and s.legacy == 99)
    s.professions.bestLevel = 60
    assert(G.BuyBoostAutomation(s, "conditional"))
    s.difficulty.unlocked, s.difficulty.maxTier = true, 2
    assert(not G.BuyRoutes(s) and s.legacy == 97)
    s.difficulty.maxTier = 3
    assert(G.BuyRoutes(s) and s.legacy == 96)
    assert(not G.UnlockRecipe(s, 1) and s.legacy == 96)
    s.difficulty.maxTier = 4
    assert(G.UnlockRecipe(s, 1) and s.legacy == 95)
    s = assert(G.Load(G.Copy(s), 0))
    s.heroes[1].level, s.professions.bestLevel = 1, 1
    s.difficulty.maxTier = 0
    assert(not G.FeatureHint(s, "onCooldown"))
    assert(not G.FeatureHint(s, "conditional"))
    assert(not G.FeatureHint(s, "routes"))
    assert(G.BuyBoost(s, "ironResolve", "legacy"))
    assert(G.UnlockRecipe(s, 2)) -- Grandfather the whole heirloom feature for existing owners.
end)

return cases
