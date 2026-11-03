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
    local state = G.New(0)
    G.AddHero(state, "WARRIOR")
    return state
end
local function qualify(state)
    state.heroes[1].level = 60
    assert(G.TalentProgress(state.heroes[1]))
    state.encounter = state.encounter + 1
    return G.DifficultyVictory(state, { boss = true, level = 60 })
end

case("Prestige+ unlock requires current hero cap and an online level 60 boss", function()
    local state = party()
    state.encounter = 1
    assert(not G.DifficultyVictory(state, { boss = true, level = 60 }))
    state.heroes[1].level = 60
    state.encounter, state.offline = 2, true
    assert(not G.DifficultyVictory(state, { boss = true, level = 60 }))
    assert(not state.difficulty.unlocked)
    state.offline, state.encounter = nil, 3
    assert(not G.DifficultyVictory(state, { boss = false, level = 60 }))
    state.encounter = 4
    assert(not G.DifficultyVictory(state, { boss = true, level = 59 }))
    assert(qualify(state))
    assert(state.difficulty.unlocked and state.difficulty.cycleComplete)
    assert(state.difficulty.maxTier == 1 and state.difficulty.currency == 0)
    assert(not G.DifficultyVictory(state, { boss = true, level = 60 }))
    assert(G.ValidateDifficulty(state))
end)

case("Difficulty selection is bounded and never changes the active tier in a preview", function()
    local state = party()
    assert(not G.PrestigePlusPreview(state, 0).eligible)
    assert(not G.PrestigePlus(state, 1))
    qualify(state)
    for _, value in ipairs({ -1, 2, 0.5, math.huge, "1" }) do
        assert(not G.PrestigePlusPreview(state, value).eligible)
        assert(not G.PrestigePlus(state, value))
    end
    assert(G.PrestigePlusPreview(state, 1).eligible)
    assert(state.tier == 0 and state.heroes[1].level == 60)
end)

case("Deeper reset grants each tier Inheritance once and retains permanent progress", function()
    local state = party()
    state.essence, state.legacy = 75, 10
    assert(G.BuyBoost(state, "battleOrders"))
    assert(G.ActivateBoost(state, "battleOrders"))
    assert(G.BuyBoostAutomation(state, "onCooldown"))
    assert(G.ConfigureBoostAutomation(state, "battleOrders", "enabled", true))
    assert(G.SetBoostAutomationEnabled(state, true))
    assert(G.BuyRoutes(state))
    local saved, id = G.SaveRoute(
        state,
        nil,
        "Retain",
        { { destination = "durotar", trigger = { kind = "unlock", zone = "durotar" } } }
    )
    assert(saved and G.SelectRoute(state, id))
    assert(G.SetRoutesEnabled(state, true))
    assert(qualify(state))
    local talent = G.Copy(state.heroes[1].talentProgress)
    local legacy, essence, cooldown = state.legacy, state.essence, state.boosts.readyAt.battleOrders
    local adventure = G.Copy(state.adventure)
    state.gold, state.materials.ore = 100, 100
    assert(G.PrestigePlus(state, 1))
    assert(state.tier == 1 and state.heroes[1].level == 1 and state.heroes[1].rank == 0)
    assert(state.gold == 0 and state.materials.ore == 0 and state.zone == "elwynn")
    assert(
        state.legacy == legacy
            and state.essence == essence
            and state.adventure.totalXP == adventure.totalXP
    )
    assert(state.boosts.owned.battleOrders and state.boosts.readyAt.battleOrders == cooldown)
    assert(not next(state.boosts.activeUntil) and state.boosts.automation.enabled)
    assert(state.routes.owned and state.routes.enabled and #state.routes.templates == 1)
    assert(state.routes.run.cursor == 1)
    assert(state.heroes[1].talentProgress.earned == talent.earned)
    assert(state.difficulty.currency == 1 and state.difficulty.ascensions == 1)
    assert(not state.difficulty.cycleComplete and not G.PrestigePlus(state, 0))
    assert(qualify(state))
    assert(G.PrestigePlus(state, 0))
    assert(state.difficulty.currency == 3 and state.difficulty.maxTier == 2)
    assert(qualify(state))
    assert(G.PrestigePlusPreview(state, 1).inheritance == 0)
    assert(G.PrestigePlus(state, 1) and state.difficulty.currency == 3)
    assert(G.ValidateDifficulty(state))
end)

case(
    "Inheritance purchases have bounded permanent ranks and never affect real activity XP",
    function()
        local state = party()
        assert(not G.BuyInheritance(state, "rebuilding"))
        qualify(state)
        state.difficulty.currency = 30
        local essence, adventure = state.essence, state.adventure.totalXP
        assert(not G.BuyInheritance(state, "unknown"))
        for _ = 1, 5 do
            assert(G.BuyInheritance(state, "rebuilding"))
        end
        assert(not G.BuyInheritance(state, "rebuilding"))
        assert(state.difficulty.currency == 15)
        for _ = 1, 5 do
            assert(G.BuyInheritance(state, "supplies"))
        end
        assert(state.difficulty.currency == 0)
        local base = G.DifficultyModifiers(state)
        assert(
            base.enemyHealth == 1
                and base.enemyDamage == 1
                and base.heroXP == 2
                and base.basicDamageTaken == 1
        )
        assert(base.gold == 1.75 and base.materials == 1.75)
        state.tier = 2
        local high = G.DifficultyModifiers(state)
        assert(high.basicDamageTaken == 0.95)
        assert(high.enemyHealth > base.enemyHealth and high.enemyDamage > base.enemyDamage)
        assert(
            high.heroXP > base.heroXP and high.masteryXP > base.masteryXP and high.loot > base.loot
        )
        assert(state.essence == essence and state.adventure.totalXP == adventure)
    end
)

case("Malformed difficulty saves fail strict validation", function()
    local original = party()
    qualify(original)
    for _, corrupt in ipairs({
        function(s)
            s.tier = 11
        end,
        function(s)
            s.tier = -1
        end,
        function(s)
            s.difficulty.currency = -1
        end,
        function(s)
            s.difficulty.maxTier = 11
        end,
        function(s)
            s.difficulty.unlocked = false
        end,
        function(s)
            s.difficulty.purchases.extra = 1
        end,
        function(s)
            s.difficulty.purchases.rebuilding = 6
        end,
        function(s)
            s.difficulty.records[0].best = math.huge
        end,
        function(s)
            s.difficulty.records[0].lastEncounter = s.encounter + 1
        end,
    }) do
        local state = G.Copy(original)
        corrupt(state)
        assert(not G.ValidateDifficulty(state))
    end
end)

case("Prestige+ tier cap stays finite and a failed reset does not pay Inheritance", function()
    local state = party()
    state.tier, state.difficulty.maxTier = 10, 10
    qualify(state)
    assert(state.difficulty.maxTier == 10)
    local modifiers = G.DifficultyModifiers(state)
    assert(modifiers.enemyHealth < math.huge and modifiers.enemyDamage < math.huge)
    local reset = G.ResetAdventure
    G.ResetAdventure = function()
        return false, "Invalid hero progression."
    end
    local ok = G.PrestigePlus(state, 10)
    G.ResetAdventure = reset
    assert(not ok and state.difficulty.currency == 0 and state.difficulty.cycleComplete)
    assert(not state.difficulty.records[10].rewarded and state.difficulty.ascensions == 0)
end)

case("Tier affixes are fixed, cumulative, bounded and independent of reward multipliers", function()
    for tier = 0, 10 do
        local s = party()
        s.tier = tier
        local affixes = G.DifficultyAffixes(tier)
        local expected = (tier >= 2 and 1 or 0) + (tier >= 5 and 1 or 0) + (tier >= 8 and 1 or 0)
        assert(#affixes == expected)
        local m = G.DifficultyModifiers(s)
        assert(m.enemyAttackInterval == (tier >= 2 and 2.16 or 2.4))
        assert(m.enemyRegen == (tier >= 5 and 0.002 or 0))
        assert(m.bossDamage == (tier >= 8 and 1.2 or 1))
        assert(m.heroXP == 1 + tier * 0.25 and m.gold == 1 + tier * 0.2)
    end
end)

local function affixBattle(tier, boss)
    local s = party()
    s.tier, s.stage = tier, boss and 5 or 1
    G.StartBattle(s)
    local b, unit = s.battle, s.battle.heroes[1]
    unit.hp, unit.maxHP, unit.regen, unit.mitigation = 100000, 100000, 0, 0
    unit.cd, unit.attackCD, unit.x, unit.y = 100, 100, 600, 100
    local enemy = b.enemies[1]
    enemy.hp, enemy.maxHP, enemy.damage, enemy.attackCD = 5000, 10000, 100, 100
    enemy.x, enemy.y = 650, 100
    return s, b, unit, enemy
end

case("Renewal starts after its delay, clamps health and never revives dead enemies", function()
    local s, b, _, enemy = affixBattle(5, false)
    b.elapsed = 9.75
    G.Step(s, 0.25)
    assert(enemy.hp == 5000)
    G.Step(s, 0.25)
    assert(enemy.hp == 5005)
    enemy.hp = 9999
    G.Step(s, 0.25)
    assert(enemy.hp == 10000)
    enemy.hp = 0
    G.Step(s, 0.25)
    assert(enemy.hp == 0)
    s, b, _, enemy = affixBattle(4, false)
    b.elapsed = 20
    G.Step(s, 0.25)
    assert(enemy.hp == 5000)
end)

case(
    "Relentless changes attack cadence and boss fury applies once at the exact boundary",
    function()
        local s, b, unit, enemy = affixBattle(8, true)
        b.elapsed, enemy.attackCD = 29.5, 0
        G.Step(s, 0.25)
        assert(unit.hp == 99900 and enemy.attackCD == 2.16)
        enemy.attackCD = 0
        G.Step(s, 0.25)
        assert(unit.hp == 99780)
        enemy.attackCD = 0
        G.Step(s, 0.25)
        assert(unit.hp == 99660)
        s, b, unit, enemy = affixBattle(8, false)
        b.elapsed, enemy.attackCD = 40, 0
        G.Step(s, 0.25)
        assert(unit.hp == 99900)
    end
)

case("Affixed offline farming remains deterministic across catchup batch sizes", function()
    local s = party()
    s.tier, s.difficulty.maxTier, s.difficulty.unlocked = 8, 8, true
    s.safe.elwynn = 1
    local job = assert(G.BeginCatchup(s, 60))
    local comparison = G.Copy(job.state)
    G.Advance(comparison, 60)
    while not G.CatchupBatch(job, 37) do
    end
    assert(job.state.gold == comparison.gold and job.state.seed == comparison.seed)
    assert(
        job.state.encounter == comparison.encounter
            and job.state.stats.kills == comparison.stats.kills
    )
end)

return cases
