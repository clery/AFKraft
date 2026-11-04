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
    G.AddHero(s, "WARRIOR")
    s.essence = 60
    s.professions.bestLevel = math.max(s.professions.bestLevel, 22)
    assert(G.BuyBoost(s, "battleOrders"))
    assert(G.BuyBoost(s, "ironResolve"))
    return s
end

case("Boost purchases are permanent, atomic, and available before prestige", function()
    local s = G.New(0)
    assert(not G.BuyBoost(s, "unknown"))
    assert(not G.BuyBoost(s, "battleOrders"))
    s.essence = 60
    s.professions.bestLevel = math.max(s.professions.bestLevel, 22)
    assert(G.BuyBoost(s, "battleOrders"))
    assert(s.essence == 30 and s.boosts.equipped == "battleOrders")
    assert(not G.BuyBoost(s, "battleOrders"))
    assert(s.essence == 30)
    assert(not G.ActivateBoost(s, "battleOrders"))
    assert(not next(s.boosts.readyAt))
end)

case("Boost activation validates loadout, living party, cooldown, and capacity", function()
    local s = party()
    G.StartBattle(s)
    local unit = s.battle.heroes[1]
    unit.hp = 0
    assert(not G.ActivateBoost(s, "battleOrders"))
    unit.hp = 1
    unit.attackCD, unit.cd = 1, 3
    assert(not G.ActivateBoost(s, "ironResolve"))
    assert(G.ActivateBoost(s, "battleOrders"))
    assert(unit.hp == 1 and unit.attackCD == 1 and unit.cd == 3)
    assert(not G.ActivateBoost(s, "battleOrders"))
    assert(G.EquipBoost(s, "ironResolve"))
    assert(not G.ActivateBoost(s, "ironResolve"))
    s.clock = 900
    assert(G.ActivateBoost(s, "ironResolve"))
    assert(G.EquipBoost(s, "battleOrders"))
    assert(not G.ActivateBoost(s, "battleOrders"))
    s.clock = 1800
    assert(G.ActivateBoost(s, "battleOrders"))
end)

case("Battle Orders accelerates only basic cooldowns and expires without a free action", function()
    local s = party()
    G.StartBattle(s)
    assert(G.ActivateBoost(s, "battleOrders"))
    local unit = s.battle.heroes[1]
    unit.attackCD, unit.cd = 2, 4
    G.Step(s, 0.25)
    assert(unit.attackCD == 2 - 0.25 * unit.haste * 1.25)
    assert(unit.cd == 4 - 0.25 * unit.haste)
    s.clock = 900
    unit.attackCD, unit.cd = 2, 4
    G.Step(s, 0.25)
    assert(unit.attackCD == 2 - 0.25 * unit.haste)
    assert(unit.cd == 4 - 0.25 * unit.haste)
end)

case("Battle Orders produces extra basic attacks in the quarter-second simulator", function()
    local s = party()
    G.StartBattle(s)
    local unit, enemy = s.battle.heroes[1], s.battle.enemies[1]
    unit.cd, unit.hp, unit.maxHP = 10000, 10000, 10000
    enemy.hp, enemy.damage = 1000000, 0
    enemy.x, enemy.y = unit.x, unit.y
    local ordinary = G.Copy(s)
    assert(G.ActivateBoost(s, "battleOrders"))
    for _ = 1, 160 do
        G.Step(s, 0.25)
        G.Step(ordinary, 0.25)
    end
    assert(s.battle.heroes[1].swings > ordinary.battle.heroes[1].swings)
    assert(s.battle.heroes[1].cd == ordinary.battle.heroes[1].cd)
end)

case("Iron Resolve multiplies defenses before shields and retains positive damage", function()
    local s = party()
    assert(G.EquipBoost(s, "ironResolve"))
    assert(G.ActivateBoost(s, "ironResolve"))
    G.StartBattle(s)
    local unit, enemy = s.battle.heroes[1], s.battle.enemies[1]
    unit.hp, unit.maxHP, unit.shield = 10000, 10000, 5
    unit.attackCD, unit.cd = 100, 100
    unit.mitigation, unit.regen = 0.5, 0
    enemy.damage, enemy.attackCD = 100, 0
    enemy.x, enemy.y = unit.x, unit.y
    G.Step(s, 0.25)
    assert(unit.hp == 9965 and unit.shield == 0)
    unit.mitigation = 0.75
    enemy.attackCD = 0
    G.Step(s, 0.25)
    assert(unit.hp == 9945)
    -- A build already above the boost's mitigation cap must never be weakened.
    unit.mitigation = 0.95
    enemy.attackCD = 0
    G.Step(s, 0.25)
    assert(unit.hp == 9940)
end)

case("Partial boost expiry preserves proportional attack progress and ability timing", function()
    local s = party()
    G.StartBattle(s)
    assert(G.ActivateBoost(s, "battleOrders"))
    s.clock = 899.875
    local unit = s.battle.heroes[1]
    unit.attackCD, unit.cd = 2, 4
    G.Step(s, 0.25)
    local expected = 2 - 0.25 * unit.haste * 1.125
    assert(math.abs(unit.attackCD - expected) < 0.000001)
    assert(unit.cd == 4 - 0.25 * unit.haste)
    G.Step(s, 0.25)
    assert(math.abs(unit.attackCD - (expected - 0.25 * unit.haste)) < 0.000001)
end)

case("Load and prestige retain cooldowns while reset ends active effects", function()
    local s = party()
    assert(G.ActivateBoost(s, "battleOrders"))
    s.clock = 100
    s = assert(G.Load(G.Copy(s), 9999))
    local active, cooldown = G.BoostRemaining(s, "battleOrders")
    assert(active == 800 and cooldown == 1700)
    s.prestigeUnlocked, s.runBest = true, 9
    assert(G.Prestige(s))
    assert(s.boosts.owned.battleOrders and s.boosts.owned.ironResolve)
    active, cooldown = G.BoostRemaining(s, "battleOrders")
    assert(active == 0 and cooldown == 1700)
    assert(not G.ActivateBoost(s, "battleOrders"))
end)

case("Existing saves gain boost defaults and malformed ledgers are rejected", function()
    local old = party()
    old.boosts = nil
    assert(G.Load(old, 0).boosts.equipped == nil)
    for _, value in ipairs({ -1, math.huge, 0 / 0, "bad" }) do
        local s = party()
        s.boosts.readyAt.battleOrders = value
        assert(not G.Load(s, 0))
    end
    local s = party()
    s.boosts.activeUntil.ironResolve = 700
    s.boosts.readyAt.ironResolve = 600
    assert(not G.Load(s, 0))
end)

case("Offline timer reconciliation matches online steps and preserves live Essence", function()
    local s = party()
    assert(G.ActivateBoost(s, "battleOrders"))
    s.safe.elwynn, s.farming = 1, true
    local online = G.Copy(s)
    local job = assert(G.BeginCatchup(s, 400))
    for _ = 1, 1600 do
        G.Step(online, 0.25)
    end
    G.AdventureXP(s, 100, "test", "Activity")
    while not G.CatchupBatch(job, 300) do
    end
    G.FinishCatchup(s, job)
    local active, cooldown = G.BoostRemaining(s, "battleOrders")
    assert(active == 500 and cooldown == 1400 and s.clock == online.clock)
    assert(s.gold == online.gold and s.stats.victories == online.stats.victories)
    assert(s.heroes[1].xp == online.heroes[1].xp)
    assert(s.essence == 60)
    assert(not G.BeginCatchup(s, 300))
    assert(s.clock == 400)
end)

case("Interrupted offline catch-up advances only processed boost time", function()
    local s = party()
    assert(G.ActivateBoost(s, "battleOrders"))
    s.safe.elwynn = 1
    local job = assert(G.BeginCatchup(s, 90000))
    assert(job.seconds == 86400)
    G.CatchupBatch(job, 400)
    G.FinishCatchup(s, job)
    assert(s.clock == 100)
    local active, cooldown = G.BoostRemaining(s, "battleOrders")
    assert(active == 800 and cooldown == 1700)
    job = assert(G.BeginCatchup(s, 90000))
    assert(job.seconds == 86300)
end)

case("Half-hour boost cycles preserve earlier saved deadlines and maximum uptime", function()
    for _, boost in ipairs(W.Content.boosts) do
        assert(boost.duration == 900 and boost.cooldown == 1800)
        assert(boost.duration / boost.cooldown == 0.5)
    end
    local s = party()
    s.boosts.activeUntil.battleOrders, s.boosts.readyAt.battleOrders = 300, 600
    s.clock = 100
    s = assert(G.Load(G.Copy(s), 0))
    local active, cooldown = G.BoostRemaining(s, "battleOrders")
    assert(active == 200 and cooldown == 500)
end)

return cases
