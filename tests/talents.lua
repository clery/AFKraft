local _, W = ...
if not W then
    return
end
local C, G = W.Content, W.Game
local cases = {}
local function case(name, run)
    cases[#cases + 1] = { name, run }
end
local function hero(class)
    local state = G.New(1000)
    assert(G.AddHero(state, class))
    state.heroes[1].level = 48
    return state, state.heroes[1]
end

case("Every class has three distinct eight-node specialization trees", function()
    local total = 0
    for _, class in ipairs(C.classes) do
        local paths, ids, names, positions = {}, {}, {}, {}
        local list = C.talentsByClass[class.id]
        assert(#list == 24)
        for _, node in ipairs(list) do
            assert(not ids[node.id] and not names[node.name])
            assert(C.talentByClassID[class.id][node.id] == node)
            assert(C.talentEffects[node.effect] and node.text ~= "" and node.icon ~= "")
            local position = node.path .. ":" .. node.row .. ":" .. node.column
            assert(not positions[position])
            positions[position], ids[node.id], names[node.name] = true, true, true
            paths[node.path] = (paths[node.path] or 0) + 1
            total = total + 1
        end
        for path = 1, #class.paths do
            assert(paths[path] == 8)
        end
    end
    assert(total == 216)
end)

case("Legacy builds retain all nine selections in every class", function()
    local legacy =
        { "cleave", "execute", "haste", "sustain", "renew", "leech", "guard", "thorns", "control" }
    for _, class in ipairs(C.classes) do
        local state, h = hero(class.id)
        for _, id in ipairs(legacy) do
            h.talents[id] = true
        end
        local loaded = assert(G.Load(state, 1000))
        assert(G.Points(loaded.heroes[1]) == 15)
        local effects = G.TalentEffects(h)
        for _, id in ipairs(legacy) do
            assert(h.talents[id] and effects[id])
            assert(G.Talent(state, 1, id))
        end
        assert(G.Points(h) == 24)
    end
end)

case("All new talents can be learned, affect their declared stat, and refund", function()
    local stats = {
        damage = "damage",
        healing = "healing",
        health = "hp",
        speed = "haste",
        mitigation = "mitigation",
        regen = "regen",
    }
    for _, class in ipairs(C.classes) do
        local state, h = hero(class.id)
        local base = G.Stats(state, h)
        for _, node in ipairs(C.talentsByClass[class.id]) do
            assert(G.Talent(state, 1, node.id))
            assert(h.talents[node.id] and G.TalentEffects(h)[node.effect])
            if stats[node.effect] then
                assert(G.Stats(state, h)[stats[node.effect]] > base[stats[node.effect]])
            end
            assert(G.Talent(state, 1, node.id))
            assert(not h.talents[node.id] and G.Points(h) == 24)
        end
    end
end)

case("Expanded points unlock gradually and class-owned IDs cannot cross classes", function()
    local state, h = hero("WARRIOR")
    h.level = 1
    assert(G.Points(h) == 1)
    assert(G.Talent(state, 1, "cleave"))
    assert(not G.Talent(state, 1, "guard"))
    h.level = 20
    assert(G.Points(h) == 9)
    local foreign = C.talentsByClass.MAGE[1].id
    assert(not G.Talent(state, 1, foreign))
    h.talents[foreign] = true
    h.talents.unknown = true
    h.talents.guard = "invalid"
    assert(G.Points(h) == 9)
    assert(not h.talents[foreign] and not h.talents.unknown and not h.talents.guard)
    h.level = 100
    assert(G.Points(h) == 23)
end)

case("Live stat talents preserve health ratio, cooldowns, and death", function()
    local state = hero("WARRIOR")
    G.StartBattle(state)
    local unit = state.battle.heroes[1]
    unit.hp = unit.maxHP * 0.5
    unit.cd, unit.attackCD = 3, 1
    local node = C.talentsByClass.WARRIOR[5]
    assert(node.effect == "health")
    local maximum = unit.maxHP
    assert(G.Talent(state, 1, node.id))
    assert(unit.maxHP > maximum and unit.hp / unit.maxHP == 0.5)
    assert(unit.cd == 3 and unit.attackCD == 1)
    unit.hp = 0
    assert(G.Talent(state, 1, node.id))
    assert(unit.hp == 0 and unit.maxHP == maximum)
end)

case("Repeated specialization motifs stack numeric bonuses", function()
    local state, h = hero("PALADIN")
    local base = G.Stats(state, h).healing
    local count = 0
    for _, node in ipairs(C.talentsByClass.PALADIN) do
        if node.effect == "healing" then
            assert(G.Talent(state, 1, node.id))
            count = count + 1
        end
    end
    assert(count > 1)
    assert(math.abs(G.Stats(state, h).healing / base - (1 + count * 0.2)) < 0.000001)
end)

case("Speed and regeneration talents change live simulation ticks", function()
    local state, h = hero("WARRIOR")
    G.StartBattle(state)
    assert(G.Talent(state, 1, "warrior_2_3"))
    assert(G.Talent(state, 1, "warrior_2_5"))
    local unit = state.battle.heroes[1]
    unit.hp = unit.maxHP * 0.5
    unit.cd, unit.attackCD = 3, 3
    local before = unit.hp
    G.Step(state, 0.25)
    assert(h.talents.warrior_2_3 and unit.cd < 2.75 and unit.attackCD < 2.75)
    assert(unit.hp > before)
end)

return cases
