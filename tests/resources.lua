local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end
case("Every hero class has a bounded encounter resource", function()
    for _, class in ipairs(C.classes) do
        local hero, unit = { class = class.id }, {}
        assert(G.EnsureHeroResource(hero, unit))
        local profile, value = G.HeroResource(hero, unit)
        assert(value == profile.initial and unit.resourceMax == 100)
        assert(G.GainHeroResource(hero, unit, 200) and unit.resource == 100)
        assert(not G.GainHeroResource(hero, unit, 0 / 0))
        assert(not G.GainHeroResource(hero, unit, math.huge))
        assert(unit.resource == 100)
    end
end)
case("Resource thresholds check before payment and failed casts spend nothing", function()
    local hero, unit = { class = "MAGE", resourceThreshold = 50 }, { resource = 49 }
    assert(not G.SpendHeroResource(hero, unit, "attack") and unit.resource == 49)
    unit.resource = 50
    assert(G.SpendHeroResource(hero, unit, "attack") and unit.resource == 20)
    hero.resourceThreshold = 0
    assert(not G.SpendHeroResource(hero, unit, "attack") and unit.resource == 20)
    assert(not G.SpendHeroResource(hero, unit, "unknown") and unit.resource == 20)
end)
case("Empty Rage permits basics while conserving ability cooldown", function()
    local state = G.New(1000)
    assert(G.AddHero(state, "WARRIOR"))
    G.StartBattle(state)
    local unit, enemy = state.battle.heroes[1], state.battle.enemies[1]
    unit.x, unit.y, enemy.x, enemy.y = 600, 100, 700, 100
    enemy.hp, enemy.maxHP, enemy.attackCD = 100000, 100000, 100
    unit.cd, unit.attackCD = 0, 0
    assert(unit.resource == 0)
    G.Step(state, 0.25)
    assert(unit.swings == 1 and unit.resource == 15)
    assert(unit.cd <= 0 and not unit.casts)
    assert(enemy.hp < enemy.maxHP)
end)
case("Resource settings validate saves and preserve live encounter state", function()
    local state = G.New(1000)
    assert(G.AddHero(state, "ROGUE"))
    G.StartBattle(state)
    local battle, unit = state.battle, state.battle.heroes[1]
    unit.resource, unit.cd = 42, 3
    local hp = unit.hp
    assert(G.Configure(state, 1, "resourceThreshold", 75))
    assert(state.battle == battle and unit.resource == 42 and unit.cd == 3 and unit.hp == hp)
    assert(not G.Configure(state, 1, "resourceThreshold", 101))
    assert(G.Load(state, 1000))
    state.heroes[1].resourceThreshold = 101
    assert(not G.Load(state, 1000))
end)
case("Encounter resources regenerate and reset without altering saved preferences", function()
    for _, spec in ipairs({ { "ROGUE", 8 }, { "MAGE", 4 }, { "WARRIOR", 0 } }) do
        local state = G.New(1000)
        assert(G.AddHero(state, spec[1]))
        assert(G.Configure(state, 1, "resourceThreshold", 75))
        G.StartBattle(state)
        local unit = state.battle.heroes[1]
        unit.resource, unit.cd, unit.attackCD = 10, 100, 100
        for _, enemy in ipairs(state.battle.enemies) do
            enemy.attackCD = 100
        end
        G.Step(state, 0.25)
        assert(unit.resource == 10 + spec[2] * 0.25)
        unit.resource = nil -- An encounter saved before resources existed.
        G.Step(state, 0.25)
        local profile = G.HeroResource(state.heroes[1], unit)
        assert(unit.resource == math.min(100, profile.initial + spec[2] * 0.25))
        G.StartBattle(state)
        assert(state.battle.heroes[1].resource == profile.initial)
        assert(state.heroes[1].resourceThreshold == 75)
    end
end)
case("Hero resource preferences survive replacement and both reset layers", function()
    local state = G.New(1000)
    assert(G.AddHero(state, "WARRIOR"))
    assert(G.Configure(state, 1, "resourceThreshold", 75))
    G.StartBattle(state)
    local unit = state.battle.heroes[1]
    unit.resource, unit.cd = 42, 3
    assert(G.Replace(state, 1, { class = "WARRIOR", name = "Alt", guid = "Player-resource-test" }))
    assert(unit.resource == 42 and unit.cd == 3)
    state.best, state.runBest, state.prestigeUnlocked = 8, 8, true
    assert(G.Prestige(state))
    assert(state.heroes[1].resourceThreshold == 75)
    state.heroes[1].level = 60
    G.TalentProgress(state.heroes[1])
    state.encounter = state.encounter + 1
    assert(G.DifficultyVictory(state, { boss = true, level = 60 }))
    assert(G.PrestigePlus(state, 1))
    assert(state.heroes[1].resourceThreshold == 75)
    G.StartBattle(state)
    assert(state.battle.heroes[1].resource == 0)
end)
case("All resource classes reproduce safe farming across offline batch sizes", function()
    for _, class in ipairs({ "WARRIOR", "ROGUE", "MAGE" }) do
        local state = G.New(1000)
        assert(G.AddHero(state, class))
        assert(G.Configure(state, 1, "resourceThreshold", 75))
        state.safe.elwynn = 1
        local small = assert(G.BeginCatchup(state, 1060))
        local large = G.Copy(small)
        local online = G.Copy(small.state)
        online.offline, online.offlineRoute = nil, nil
        G.Advance(online, 60)
        while not G.CatchupBatch(small, 7) do
        end
        while not G.CatchupBatch(large, 1600) do
        end
        for _, other in ipairs({ large.state, online }) do
            assert(small.state.seed == other.seed)
            assert(small.state.gold == other.gold)
            assert(small.state.encounter == other.encounter)
            assert(small.state.stats.kills == other.stats.kills)
            assert(small.state.heroes[1].xp == other.heroes[1].xp)
            if small.state.battle then
                assert(other.battle)
                assert(small.state.battle.heroes[1].resource == other.battle.heroes[1].resource)
            end
        end
    end
end)
return cases
