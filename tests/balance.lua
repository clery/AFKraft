local _, W = ...
if not W then
    return
end
local G, C = W.Game, W.Content
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

case("Enemy growth preserves opening levels one through eight exactly", function()
    for count = 1, 5, 4 do
        for level = 1, 8 do
            for _, boss in ipairs({ false, true }) do
                local state = G.New(0)
                for _ = 1, count do
                    assert(G.AddHero(state, "WARRIOR"))
                end
                state.stage = (level - 1) * 5 + (boss and 5 or 1)
                G.StartBattle(state)
                local enemy = state.battle.enemies[1]
                local health = math.floor(
                    (60 + level * 24) * 1.16 ^ (level - 1) * (boss and math.min(4, count + 1) or 1)
                )
                local damage = (6 + level * 3)
                    * 1.12 ^ (level - 1)
                    * (boss and (count == 1 and 1.2 or 1.8) or 1)
                assert(enemy.hp == health and enemy.damage == damage)
            end
        end
    end
end)

case("A mixed level sixty party can finish base and first-tier milestone bosses", function()
    local preferred = { WARRIOR = 3, PRIEST = 2, MAGE = 1, ROGUE = 2, SHAMAN = 3 }
    for _, tier in ipairs({ 0, 1 }) do
        local state = G.New(0)
        state.tier = tier
        if tier > 0 then
            state.difficulty.unlocked, state.difficulty.maxTier = true, tier
        end
        for _, class in ipairs({ "WARRIOR", "PRIEST", "MAGE", "ROGUE", "SHAMAN" }) do
            assert(G.AddHero(state, class))
            local hero = state.heroes[#state.heroes]
            hero.level, hero.rank = 60, 14
            local progress = assert(G.TalentProgress(hero))
            hero.mastery.rank = 8
            progress.earned = math.min(#G.TalentList(hero), progress.earned + 8)
            for _, slot in ipairs(C.equipmentSlots) do
                hero.gear[slot] = assert(G.CraftItem(hero, slot, false, state))
            end
            for pass = 1, 3 do
                local path = (preferred[class] + pass - 2) % 3 + 1
                for _, talent in ipairs(G.TalentList(hero)) do
                    if talent.path == path and not hero.talents[talent.id] then
                        G.Talent(state, hero.id, talent.id)
                    end
                end
            end
            hero.priority = C.classByID[class].role == "healer" and "heal" or "special"
        end
        state.stage = 300
        G.StartBattle(state)
        local ticks = 0
        while state.battle and ticks < 720 do
            G.Step(state, 0.25)
            ticks = ticks + 1
        end
        assert(state.stats.victories == 1 and ticks < 720)
        assert(state.difficulty.cycleComplete and ticks >= 40)
    end
end)

case("Legacy prestige strength migrates without reducing existing party stats", function()
    local state = G.New(0)
    assert(G.AddHero(state, "WARRIOR"))
    state.prestiges, state.prestigeStrength = 10, nil
    local before = G.Stats(state, state.heroes[1])
    state = assert(G.Load(state, 0))
    local after = G.Stats(state, state.heroes[1])
    assert(state.prestigeStrength == 10 and state.prestiges == 10)
    assert(
        before.hp == after.hp and before.damage == after.damage and before.healing == after.healing
    )
end)

case("Equal earned Legacy grants equal prestige strength regardless of reset count", function()
    local short, long = G.New(0), G.New(0)
    short.prestigeUnlocked, long.prestigeUnlocked = true, true
    for _ = 1, 3 do
        short.runBest = 8
        assert(G.Prestige(short))
    end
    long.runBest = 20
    assert(G.Prestige(long))
    assert(short.legacy == 6 and long.legacy == 6)
    assert(short.prestiges == 3 and long.prestiges == 1)
    assert(short.prestigeStrength == 3 and long.prestigeStrength == 3)
    assert(G.Prestige(short) and short.prestigeStrength == 3)
    assert(G.ResetAdventure(long, true) and long.prestigeStrength == 3)
    assert(G.Load(G.Copy(short), 0).prestigeStrength == 3)
end)

case("Prestige strength rejects negative, fractional and non-finite saved values", function()
    for _, value in ipairs({ -1, 0.25, 0 / 0, math.huge, "1" }) do
        local state = G.New(0)
        state.prestigeStrength = value
        assert(not G.Load(state, 0))
    end
    local state = G.New(0)
    state.prestigeStrength = 1.5
    assert(G.Load(state, 0).prestigeStrength == 1.5)
end)

return cases
