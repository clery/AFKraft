local _, W = ...
if not W then
    return
end
local G, P = W.Game, W.CombatPosition
local cases = {}
local function case(name, fn)
    cases[#cases + 1] = { name, fn }
end

case("Melee fighters close distance before dealing damage and dead targets are replaced", function()
    local s = G.New(1000)
    G.AddHero(s, "WARRIOR")
    G.StartBattle(s)
    local b = s.battle
    -- Exercise replacement independently of the solo opening's enemy count.
    b.enemies[2] = G.Copy(b.enemies[1])
    b.enemies[2].id, b.enemies[2].x, b.enemies[2].y = 2, nil, nil
    P.Ensure(s, b)
    local hero, enemy = b.heroes[1], b.enemies[1]
    local hp, x, enemyX = enemy.hp, hero.x, enemy.x
    G.Step(s, 0.25)
    assert(enemy.hp == hp and hero.hp == hero.maxHP)
    assert(hero.x > x and enemy.x < enemyX)
    assert(hero.targetID == 1 and enemy.targetID == 1)
    local hit = false
    for _ = 1, 50 do
        s.events = {}
        G.Step(s, 0.25)
        for _, event in ipairs(s.events) do
            if event.kind == "hit" and event.enemy then
                assert(P.InRange(hero, b.enemies[event.target]))
                hit = true
            end
        end
        if hit then
            break
        end
    end
    assert(hit)
    enemy.hp = 0
    b.enemies[2].x = 1100
    local before = hero.x
    G.Step(s, 0.25)
    assert(hero.targetID == 2)
    assert(hero.x > before)
    assert(enemy.x == enemy.destinationX and not enemy.moving)
end)

case("Ranged fighters keep their distance and monsters pursue the current guard", function()
    local s = G.New(1000)
    G.AddHero(s, "MAGE")
    G.AddHero(s, "WARRIOR")
    G.StartBattle(s)
    local b = s.battle
    local mage, warrior = b.heroes[1], b.heroes[2]
    s.heroes[2].talents.guard = true
    for _ = 1, 40 do
        P.Step(s, b, 0.25)
    end
    assert(mage.x > mage.homeX)
    assert(P.InRange(mage, b.enemies[1]))
    assert(not P.InRange(b.enemies[1], mage))
    assert(warrior.x > warrior.homeX)
    for _, enemy in ipairs(b.enemies) do
        assert(enemy.targetID == 2)
    end
    warrior.hp = 0
    P.Step(s, b, 0.25)
    assert(b.enemies[1].targetID == 1)
    assert(not warrior.moving)
    b.enemies[1].x = mage.x + P.rangedRange - 10
    assert(P.InRange(mage, b.enemies[1]))
    assert(not P.InRange(b.enemies[1], mage))
end)

case("Ranged companions behind a melee guard can attack throughout the encounter", function()
    local s = G.New(1000)
    G.AddHero(s, "MAGE")
    G.AddHero(s, "WARRIOR")
    G.StartBattle(s)
    local b = s.battle
    for _, unit in ipairs(b.heroes) do
        unit.hp, unit.maxHP = 100000, 100000
    end
    for _, enemy in ipairs(b.enemies) do
        enemy.hp, enemy.maxHP = 100000, 100000
    end
    local attacks = 0
    for _ = 1, 120 do
        s.events = {}
        G.Step(s, 0.25)
        if b.elapsed > 10 then
            for _, event in ipairs(s.events) do
                if event.kind == "hit" and event.enemy and event.source == 1 then
                    attacks = attacks + 1
                end
            end
        end
    end
    assert(attacks >= 5, "Ranged companion remained outside attack range")
end)

case("Older active saves gain bounded coordinates without changing health or cooldowns", function()
    local s = G.New(1000)
    G.AddHero(s, "ROGUE")
    G.StartBattle(s)
    local hero = s.battle.heroes[1]
    local hp, cd = hero.hp, hero.attackCD
    hero.x, hero.y = nil, math.huge
    local loaded = assert(G.Load(s, 1000))
    P.Ensure(loaded, loaded.battle)
    assert(hero.x == hero.homeX and hero.y == hero.homeY)
    assert(hero.hp == hp and hero.attackCD == cd)
end)

case("Periodic and reflected hits do not represent fresh attacks", function()
    local s = G.New(1000)
    G.AddHero(s, "DRUID")
    for _, node in ipairs(G.TalentList(s.heroes[1])) do
        if node.effect == "thorns" then
            s.heroes[1].talents[node.id] = true
        end
    end
    G.StartBattle(s)
    local b = s.battle
    local hero, enemy = b.heroes[1], b.enemies[1]
    hero.hp, hero.maxHP = 10000, 10000
    enemy.hp, enemy.maxHP = 10000, 10000
    enemy.dots = { [1] = { damage = 100, remaining = 6 } }
    local periodic, reflected, attack = false, false, false
    for _ = 1, 60 do
        s.events = {}
        G.Step(s, 0.1)
        for _, event in ipairs(s.events) do
            if event.kind == "hit" then
                if event.passive then
                    if event.amount == 10 then
                        periodic = true
                    else
                        reflected = true
                    end
                else
                    attack = true
                end
            end
        end
    end
    assert(
        periodic and reflected and attack,
        tostring(periodic) .. " " .. tostring(reflected) .. " " .. tostring(attack)
    )
end)

case(
    "Hero target priorities use living health percentages with stable ties and matching movement",
    function()
        local s = G.New(0)
        G.AddHero(s, "WARRIOR")
        G.AddHero(s, "ROGUE")
        G.StartBattle(s)
        local b = s.battle
        for index = 1, 3 do
            b.enemies[index] = G.Copy(b.enemies[1])
            b.enemies[index].id = index
            b.enemies[index].maxHP = index == 2 and 2000 or 1000
            b.enemies[index].hp = index == 2 and 600 or 800
        end
        assert(G.Configure(s, 1, "targetMode", "weakest"))
        assert(G.Configure(s, 2, "targetMode", "strongest"))
        assert(P.Target(s, b, false, 1) == b.enemies[2])
        assert(P.Target(s, b, false, 2) == b.enemies[1])
        P.Step(s, b, 0.25)
        assert(b.heroes[1].targetID == 2 and b.heroes[2].targetID == 1)
        b.enemies[2].hp = 0
        assert(P.Target(s, b, false, 1) == b.enemies[1])
        assert(not G.Configure(s, 1, "targetMode", "invalid"))
        assert(s.heroes[1].targetMode == "weakest")
        local hp, cd = b.heroes[1].hp, b.heroes[1].cd
        assert(G.Configure(s, 1, "targetMode", "front"))
        assert(b.heroes[1].hp == hp and b.heroes[1].cd == cd)
        assert(G.Load(G.Copy(s), 0))
        local old = G.Copy(s)
        old.heroes[1].targetMode = nil
        assert(G.Load(old, 0))
        old.heroes[1].targetMode = "removed"
        assert(not G.Load(old, 0))
    end
)

case("Basic attacks and strikes damage the configured primary enemy", function()
    for _, basic in ipairs({ true, false }) do
        local s = G.New(0)
        G.AddHero(s, "MAGE")
        assert(G.Configure(s, 1, "targetMode", "weakest"))
        assert(G.Configure(s, 1, "priority", "attack"))
        G.StartBattle(s)
        local b, unit = s.battle, s.battle.heroes[1]
        b.enemies[2] = G.Copy(b.enemies[1])
        for index, enemy in ipairs(b.enemies) do
            enemy.id, enemy.x, enemy.y = index, 350, 100
            enemy.maxHP, enemy.hp, enemy.attackCD = 10000, index == 1 and 9000 or 4000, 100
        end
        unit.x, unit.y, unit.damage = 100, 100, 10
        unit.attackCD, unit.cd = basic and 0 or 100, basic and 100 or 0
        G.Step(s, 0.25)
        assert(b.enemies[1].hp == 9000 and b.enemies[2].hp < 4000)
    end
end)

case("Hero target preferences survive both prestige resets and same-class replacement", function()
    local s = G.New(0)
    G.AddHero(s, "WARRIOR")
    assert(G.Configure(s, 1, "targetMode", "strongest"))
    assert(G.Replace(s, 1, { class = "WARRIOR", name = "Replacement", guid = "fixture" }))
    assert(s.heroes[1].targetMode == "strongest")
    s.prestigeUnlocked, s.runBest = true, 9
    assert(G.Prestige(s))
    assert(s.heroes[1].targetMode == "strongest")
    s.heroes[1].level = 60
    G.TalentProgress(s.heroes[1])
    s.encounter = 1
    assert(
        G.DifficultyVictory(
            s,
            { boss = true, level = 61, zone = "blackrock_mountain", stage = 220 }
        )
    )
    assert(G.PrestigePlus(s, 1))
    assert(s.heroes[1].targetMode == "strongest" and s.heroes[1].level == 1)
end)

return cases
