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

local function prerequisites(state, h, talent)
    for row = 1, talent.row - 1 do
        for _, node in ipairs(G.TalentList(h)) do
            if node.path == talent.path and node.row == row then
                if not h.talents[node.id] then
                    assert(G.Talent(state, 1, node.id))
                end
                break
            end
        end
    end
end

case("Rows require the immediately preceding row in the same specialization", function()
    for _, class in ipairs(C.classes) do
        local state, h = hero(class.id)
        for _, node in ipairs(G.TalentList(h)) do
            if node.row > 1 then
                h.talents = {}
                assert(not G.Talent(state, 1, node.id))
                for _, candidate in ipairs(G.TalentList(h)) do
                    if candidate.path ~= node.path or candidate.row < node.row - 1 then
                        h.talents[candidate.id] = true
                    end
                end
                assert(not G.Talent(state, 1, node.id))
                h.talents = {}
                prerequisites(state, h, node)
                assert(G.Talent(state, 1, node.id))
                local previous
                for _, candidate in ipairs(G.TalentList(h)) do
                    if candidate.path == node.path and candidate.row == node.row - 1 then
                        previous = previous or candidate
                    end
                end
                assert(not G.Talent(state, 1, previous.id))
                for _, candidate in ipairs(G.TalentList(h)) do
                    if
                        candidate.path == node.path
                        and candidate.row == previous.row
                        and candidate ~= previous
                    then
                        assert(G.Talent(state, 1, candidate.id))
                    end
                end
                assert(G.Talent(state, 1, previous.id))
                assert(G.Talent(state, 1, node.id))
            end
        end
    end
end)

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
        end
        for i = #C.talentsByClass[class.id], 1, -1 do
            local node = C.talentsByClass[class.id][i]
            if h.talents[node.id] then
                assert(G.Talent(state, 1, node.id))
            end
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
        for _, node in ipairs(C.talentsByClass[class.id]) do
            h.talents = {}
            prerequisites(state, h, node)
            local points = G.Points(h)
            local base = G.Stats(state, h)
            assert(G.Talent(state, 1, node.id))
            assert(h.talents[node.id] and G.TalentEffects(h)[node.effect])
            if stats[node.effect] then
                assert(G.Stats(state, h)[stats[node.effect]] > base[stats[node.effect]])
            end
            assert(G.Talent(state, 1, node.id))
            assert(not h.talents[node.id] and G.Points(h) == points)
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
    prerequisites(state, state.heroes[1], C.talentsByClass.WARRIOR[5])
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
    for _, node in ipairs(G.TalentList(h)) do
        if node.effect == "healing" then
            prerequisites(state, h, node)
        end
    end
    local base = G.Stats(state, h).healing
    local initial = G.TalentEffects(h).healing or 0
    local count = 0
    for _, node in ipairs(C.talentsByClass.PALADIN) do
        if node.effect == "healing" and not h.talents[node.id] then
            assert(G.Talent(state, 1, node.id))
            count = count + 1
        end
    end
    assert(count > 1)
    assert(
        math.abs(G.Stats(state, h).healing / base - ((1 + initial + count * 0.2) / (1 + initial)))
            < 0.000001
    )
end)

case("Speed and regeneration talents change live simulation ticks", function()
    local state, h = hero("WARRIOR")
    prerequisites(state, h, C.talentByClassID.WARRIOR.warrior_2_5)
    G.StartBattle(state)
    if not h.talents.warrior_2_3 then
        assert(G.Talent(state, 1, "warrior_2_3"))
    end
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
