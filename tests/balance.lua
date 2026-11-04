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

case("A developed prestige party can finish base and first-tier capstones", function()
    local preferred = { WARRIOR = 3, PRIEST = 2, MAGE = 1, ROGUE = 2, SHAMAN = 3 }
    for _, tier in ipairs({ 0, 1 }) do
        local state = G.New(0)
        state.tier, state.prestigeStrength = tier, 1000
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
        state.zone, state.stage = "blackrock_mountain", C.transcendenceBoss.stage
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

case("Replacement gear stays affordable while repeated enhancement yields to forging", function()
    local state = G.New(0)
    assert(G.AddHero(state, "WARRIOR"))
    local hero = state.heroes[1]
    for _, level in ipairs({ 1, 20, 40, 60 }) do
        hero.level = level
        local quote = G.Cost(state, hero, false)
        assert(quote.material >= 5 and quote.material <= 19)
        assert(quote.gold == level * 8 and quote.essence == 0)
    end
    local item = assert(G.CraftItem(hero, 1, false, state))
    hero.gear[1] = item
    G.ProfessionUnlocks(state)
    local _, forge = G.ForgeQuote(state, 1, 1)
    assert(forge and forge.materials.relic == 3 and forge.materials.ore == 6)
    local first = G.UpgradeCost(item, state)
    assert(first.gold == 16 and first.materials.ore == 2)
    assert(first.gold / 0.1 < forge.gold / 0.04)
    item.upgrade = 10
    local later = G.UpgradeCost(item, state)
    assert(later.gold / (0.1 / 2) > forge.gold / 0.04)
    assert(item.upgrade == 10 and G.Load(G.Copy(state), 0))
end)

case("All challenge tiers remain bounded with a useful health progression", function()
    local state = G.New(0)
    local previous = G.DifficultyModifiers(state)
    for tier = 1, 10 do
        state.tier = tier
        local current = G.DifficultyModifiers(state)
        assert(current.enemyHealth > previous.enemyHealth)
        assert(current.enemyHealth / previous.enemyHealth < 1.43)
        assert(current.enemyDamage > previous.enemyDamage)
        assert(current.gold > previous.gold and current.masteryXP > previous.masteryXP)
        previous = current
    end
    assert(previous.enemyHealth > 25 and previous.enemyHealth < 28 and previous.enemyDamage < 6)
end)

case("Post-opening enemy growth creates an early prestige wall without changing rewards", function()
    local state = G.New(0)
    assert(G.AddHero(state, "WARRIOR"))
    state.stage = 100
    G.StartBattle(state)
    local level, enemy = state.battle.level, state.battle.enemies[1]
    local openingHP = (60 + level * 24) * 1.16 ^ 7
    local openingDamage = (6 + level * 3) * 1.12 ^ 7 * 1.2
    assert(enemy.hp == math.floor(openingHP * 1.14 ^ (level - 8) * 2))
    assert(math.abs(enemy.damage / openingDamage - 1.065 ^ (level - 8)) < 0.000001)
    assert(G.PrestigeReward({ runBest = 15 }) == 4)
end)

return cases
