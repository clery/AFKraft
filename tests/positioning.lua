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
    for _ = 1, 8 do
        P.Step(s, b, 0.25)
    end
    assert(mage.x == mage.homeX)
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

return cases
