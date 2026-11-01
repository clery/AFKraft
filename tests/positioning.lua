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

return cases
