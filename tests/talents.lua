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
    state.heroes[1].level = 60
    state.heroes[1].rank = 14
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

case("Every class has three eighteen-node specialization trees", function()
    local total = 0
    for _, class in ipairs(C.classes) do
        local paths, ids, names, positions = {}, {}, {}, {}
        local list = C.talentsByClass[class.id]
        assert(#list == 54)
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
            assert(paths[path] == 18)
        end
    end
    assert(total == 486)
end)

case("Legacy builds retain all nine selections in every class", function()
    local legacy =
        { "cleave", "execute", "haste", "sustain", "renew", "leech", "guard", "thorns", "control" }
    for _, class in ipairs(C.classes) do
        local state, h = hero(class.id)
        h.level, h.talentProgress = 48, nil -- A save from the previous point system.
        for _, id in ipairs(legacy) do
            h.talents[id] = true
        end
        local loaded = assert(G.Load(state, 1000))
        assert(G.Points(loaded.heroes[1]) == 15)
        local effects = G.TalentEffects(h)
        for _, id in ipairs(legacy) do
            local node = C.talentByClassID[class.id][C.legacyTalentIDs[class.id][id]]
            assert(h.talents[id] and node and effects[node.effect])
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
    assert(G.Points(h) == 29)
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

local function encounter(class, effect)
    local state, h = hero(class)
    for _, node in ipairs(G.TalentList(h)) do
        if node.effect == effect then
            h.talents[node.id] = true
        end
    end
    assert(G.TalentEffects(h)[effect])
    G.StartBattle(state)
    local unit, enemy = state.battle.heroes[1], state.battle.enemies[1]
    unit.x, unit.y, enemy.x, enemy.y = 600, 100, 700, 100
    unit.hp = unit.maxHP * 0.25
    enemy.hp, enemy.maxHP, enemy.attackCD = 100000, 100000, 100
    unit.attackCD = 100
    unit.resource = 100 -- Isolate talent effects from resource generation.
    h.priority = "attack"
    return state, h, unit, enemy
end

case(
    "Each specialization owns a distinct signature mechanic and preserves saved node IDs",
    function()
        local seen, count = {}, 0
        for _, class in ipairs(C.classes) do
            for name, mechanic in pairs(C.classTalentMechanics[class.id]) do
                assert(not seen[mechanic[1]])
                seen[mechanic[1]], count = true, count + 1
                local found
                for _, node in ipairs(C.talentsByClass[class.id]) do
                    if node.name == name then
                        assert(node.effect == mechanic[1] and node.text == mechanic[2])
                        found = true
                    end
                end
                assert(found)
            end
        end
        assert(count == 27)
    end
)

case("Class strikes apply bleeds, burns, drains, and conditional damage", function()
    for _, spec in ipairs({
        { "WARRIOR", "wounds" },
        { "HUNTER", "trap" },
        { "MAGE", "ignite" },
    }) do
        local s, h, unit, enemy = encounter(spec[1], spec[2])
        if spec[2] == "trap" then
            h.priority, h.specialCount = "special", 1
        end
        G.Step(s, 0.25)
        assert(enemy.dots[1] and enemy.dots[1].remaining >= 3)
        local hp = enemy.hp
        unit.cd, unit.attackCD = 100, 100
        G.Step(s, 0.25)
        assert(enemy.hp < hp)
    end
    for _, spec in ipairs({
        { "HUNTER", "aim", 1.45 },
        { "ROGUE", "opener", 2 },
        { "PRIEST", "deathWord", 1.8 },
        { "DRUID", "predator", 1.35 },
    }) do
        local s, _, unit, enemy = encounter(spec[1], spec[2])
        if spec[2] == "deathWord" then
            enemy.maxHP = enemy.hp * 10
        elseif spec[2] == "predator" then
            enemy.dots = { [1] = { damage = 0, remaining = 5, physical = true } }
        end
        local hp = enemy.hp
        G.Step(s, 0.25)
        assert(hp - enemy.hp == math.floor(unit.damage * 1.7 * spec[3]))
    end
    for _, spec in ipairs({ { "WARRIOR", "bloodthirst" }, { "WARLOCK", "drain" } }) do
        local s, _, unit = encounter(spec[1], spec[2])
        local hp = unit.hp
        G.Step(s, 0.25)
        assert(unit.hp > hp)
    end
end)

case("Class basic attacks trigger pets, poison, Windfury, cooldown recovery and frost", function()
    for _, spec in ipairs({
        { "HUNTER", "beast" },
        { "ROGUE", "poison" },
        { "ROGUE", "potency" },
        { "SHAMAN", "windfury" },
        { "MAGE", "frost" },
    }) do
        local s, _, unit, enemy = encounter(spec[1], spec[2])
        unit.cd, unit.attackCD, unit.swings = 10, 0, 2
        local hp = enemy.hp
        G.Step(s, 0.25)
        local multiplier = spec[2] == "beast" and 1.25 or spec[2] == "windfury" and 2 or 1
        assert(hp - enemy.hp == math.floor(unit.damage * multiplier))
        if spec[2] == "poison" then
            assert(enemy.dots[1].physical)
        elseif spec[2] == "potency" then
            assert(unit.cd < 9.5)
        elseif spec[2] == "frost" then
            assert(enemy.attackCD > 100)
        end
    end
end)

case("Healing talents deliver shields, group healing, faster tides and rejuvenation", function()
    for _, spec in ipairs({
        { "PALADIN", "holyShield" },
        { "PRIEST", "hymn" },
        { "SHAMAN", "tides" },
        { "DRUID", "rejuvenation" },
    }) do
        local s, h, unit = encounter(spec[1], spec[2])
        h.priority, h.healBelow = "heal", 100
        unit.hp = 1
        if spec[2] == "hymn" then
            s.battle.heroes[2] = G.Copy(unit)
            s.battle.heroes[2].id = 2
            s.heroes[2] = G.Copy(h)
            s.battle.heroes[2].hp = unit.maxHP * 0.8
            s.battle.heroes[2].cd = 100
        end
        G.Step(s, 0.25)
        if spec[2] == "holyShield" then
            assert(unit.shield > 0)
        elseif spec[2] == "hymn" then
            assert(s.battle.heroes[2].hp > unit.maxHP * 0.8)
        elseif spec[2] == "tides" then
            assert(unit.cd == 4)
        else
            assert(unit.rejuvenation == 6)
            local hp = unit.hp
            G.Step(s, 0.25)
            assert(unit.hp > hp)
        end
    end
end)

case("Class strikes chain, ramp, empower specials, and delay enemies", function()
    for _, spec in ipairs({
        { "SHAMAN", "chain" },
        { "MAGE", "arcane" },
        { "DRUID", "starfall" },
        { "WARLOCK", "shadowfury" },
    }) do
        local s, h, unit, enemy = encounter(spec[1], spec[2])
        if spec[2] == "chain" then
            s.battle.enemies[2] = G.Copy(enemy)
            s.battle.enemies[2].id = 2
        elseif spec[2] == "starfall" or spec[2] == "shadowfury" then
            h.priority, h.specialCount = "special", 1
        end
        local hp = enemy.hp
        G.Step(s, 0.25)
        if spec[2] == "chain" then
            assert(s.battle.enemies[2].hp < hp)
        elseif spec[2] == "arcane" then
            local damage = hp - enemy.hp
            unit.cd = 0
            hp = enemy.hp
            G.Step(s, 0.25)
            assert(hp - enemy.hp > damage)
        elseif spec[2] == "starfall" then
            assert(unit.cd == 5 and hp - enemy.hp == math.floor(unit.damage * 0.95 * 1.4))
        else
            assert(enemy.attackCD > 101)
        end
    end
end)

case("Support strikes and Beacon heal allies without reviving fallen heroes", function()
    for _, spec in ipairs({
        { "PALADIN", "judgement" },
        { "PRIEST", "atonement" },
        { "PALADIN", "beacon" },
    }) do
        local s, h, unit = encounter(spec[1], spec[2])
        s.heroes[2], s.heroes[3] = G.Copy(h), G.Copy(h)
        local ally, fallen = G.Copy(unit), G.Copy(unit)
        ally.id, ally.hp, ally.cd, ally.attackCD = 2, 1, 100, 100
        fallen.id, fallen.hp = 3, 0
        s.battle.heroes[2], s.battle.heroes[3] = ally, fallen
        if spec[2] == "beacon" then
            h.priority, h.healBelow = "heal", 100
        end
        local hp = unit.hp
        G.Step(s, 0.25)
        assert(ally.hp > 1 and fallen.hp == 0)
        if spec[2] == "beacon" then
            assert(unit.hp > hp)
        end
    end
end)

case("Revenge recovers cooldowns and Soul Link changes damage and targeting", function()
    for _, spec in ipairs({ { "WARRIOR", "revenge" }, { "WARLOCK", "soulLink" } }) do
        local s, _, unit, enemy = encounter(spec[1], spec[2])
        unit.hp, unit.cd, unit.attackCD = unit.maxHP, 10, 100
        enemy.attackCD = 0
        local hp = unit.hp
        G.Step(s, 0.25)
        if spec[2] == "revenge" then
            assert(unit.cd < 9)
        else
            assert(hp - unit.hp == math.floor(enemy.damage * 0.8 * (1 - unit.mitigation)))
            assert(W.CombatPosition.Target(s, s.battle, true) == unit)
        end
    end
end)

case("Periodic damage expires, preserves fractional ticks, and survives reload", function()
    local s, _, unit, enemy = encounter("WARRIOR", "wounds")
    G.Step(s, 0.25)
    unit.cd, unit.attackCD = 100, 100
    local hp = enemy.hp
    local total = math.floor(enemy.dots[1].damage * enemy.dots[1].remaining)
    assert(G.Load(s, 1000))
    for _ = 1, 17 do
        G.Step(s, 0.25)
    end
    assert(not next(enemy.dots) and hp - enemy.hp == total)
end)

case("Expanded trees keep distinct choices while permitting shared foundations", function()
    local icons, descriptions, names, count = {}, {}, {}, 0
    local unique = {}
    for _, class in ipairs(C.classes) do
        for _, node in ipairs(C.talentsByClass[class.id]) do
            local icon = node.icon:lower()
            assert(not names[node.name], node.name .. " repeats another talent name")
            names[node.name] = true
            assert(not icons[icon], node.name .. " shares an icon with " .. (icons[icon] or ""))
            local choice = class.id .. ":" .. node.path .. ":" .. node.text
            assert(not descriptions[choice], node.name .. " repeats an effect in its own tree")
            descriptions[choice], unique[node.text] = true, true
            icons[icon] = node.name
            if node.trait then
                count = count + 1
            end
        end
    end
    assert(count == 405)
    local distinct = 0
    for _ in pairs(unique) do
        distinct = distinct + 1
    end
    assert(distinct >= 300)
end)

local function traitEncounter(class, name)
    local state, h = hero(class)
    local selected
    for _, node in ipairs(G.TalentList(h)) do
        if node.name == name then
            h.talents[node.id], selected = true, node
        end
    end
    assert(selected and selected.trait)
    G.StartBattle(state)
    local unit, enemy = state.battle.heroes[1], state.battle.enemies[1]
    unit.x, unit.y, enemy.x, enemy.y = 600, 100, 700, 100
    enemy.hp, enemy.maxHP, enemy.attackCD = 100000, 100000, 100
    unit.attackCD = 100
    unit.resource = 100 -- Isolate talent effects from resource generation.
    h.priority = "attack"
    return state, h, unit, enemy, selected
end

case("Opening strike bonuses expire and respec immediately removes the bonus", function()
    local s, h, unit, enemy, node = traitEncounter("ROGUE", "Shadowstep")
    local hp = enemy.hp
    G.Step(s, 0.25)
    assert(hp - enemy.hp == math.floor(unit.damage * 1.7 * 1.24))
    s.battle.elapsed, unit.cd = 6, 0
    hp = enemy.hp
    G.Step(s, 0.25)
    assert(hp - enemy.hp == math.floor(unit.damage * 1.7))
    s.battle.elapsed, unit.cd = 0, 0
    h.talents[node.id] = nil
    unit.resource = 100
    hp = enemy.hp
    G.Step(s, 0.25)
    assert(hp - enemy.hp == math.floor(unit.damage * 1.7))
end)

case("Poison synergy changes basic attacks only while the target has a physical dot", function()
    local s, _, unit, enemy = traitEncounter("ROGUE", "Seal Fate")
    unit.cd, unit.attackCD = 100, 0
    enemy.dots = { [1] = { damage = 0, remaining = 5, physical = true } }
    local hp = enemy.hp
    G.Step(s, 0.25)
    assert(hp - enemy.hp == math.floor(unit.damage * 1.18))
    enemy.dots, unit.attackCD = nil, 0
    hp = enemy.hp
    G.Step(s, 0.25)
    assert(hp - enemy.hp == math.floor(unit.damage))
end)

case("Shielded healing bonuses inspect the recipient and survive reloading", function()
    local s, h, unit = traitEncounter("PRIEST", "Grace")
    h.priority, h.healBelow = "heal", 100
    unit.hp, unit.shield = 1, 10
    local expected = math.floor(unit.healing * 1.26)
    assert(G.Load(s, 1000))
    G.Step(s, 0.25)
    assert(unit.hp == math.min(unit.maxHP, 1 + expected))
    unit.hp, unit.shield, unit.cd = 1, 0, 0
    G.Step(s, 0.25)
    assert(unit.hp == math.min(unit.maxHP, 1 + math.floor(unit.healing)))
end)

case("Boss defenses apply to incoming hits and disappear outside bosses", function()
    local s, _, unit, enemy = traitEncounter("WARRIOR", "Shield Discipline")
    unit.cd, unit.attackCD = 100, 100
    s.battle.boss, enemy.attackCD = true, 0
    local hp = unit.hp
    G.Step(s, 0.25)
    assert(hp - unit.hp == math.floor(enemy.damage * (1 - unit.mitigation) * 0.9))
    s.battle.boss, enemy.attackCD = false, 0
    hp = unit.hp
    G.Step(s, 0.25)
    assert(hp - unit.hp == math.floor(enemy.damage * (1 - unit.mitigation)))
end)

case("All 54 permanent choices reload and refund even after current levels decrease", function()
    for _, class in ipairs(C.classes) do
        local state, h = hero(class.id)
        h.level, h.rank = 60, 14
        G.RewardMastery(h, 1, 1000000, false)
        assert(G.Points(h) == 54)
        for _, node in ipairs(G.TalentList(h)) do
            assert(G.Talent(state, 1, node.id))
        end
        assert(G.Points(h) == 0)
        local loaded = assert(G.Load(state, 1000))
        h = loaded.heroes[1]
        for _, node in ipairs(G.TalentList(h)) do
            assert(h.talents[node.id])
        end
        local list = G.TalentList(h)
        for index = #list, 1, -1 do
            assert(G.Talent(loaded, 1, list[index].id))
        end
        assert(G.Points(h) == 54)
        h.level = 49
        assert(G.Points(h) == 54)
        h.level = 54
        assert(G.Points(h) == 54)
    end
end)

case("Sustained-cast talents begin after three offensive abilities", function()
    local s, _, unit, enemy = traitEncounter("MAGE", "Rule of Threes")
    for cast = 1, 4 do
        unit.resource = 100
        unit.cd = 0
        local hp = enemy.hp
        G.Step(s, 0.25)
        local bonus = cast == 4 and 1.26 or 1
        assert(hp - enemy.hp == math.floor(unit.damage * 1.7 * bonus))
    end
end)

case("Burning-target talents distinguish magical dots from bleeds and expired effects", function()
    local s, _, unit, enemy = traitEncounter("MAGE", "Pyroclasm")
    for _, sample in ipairs({
        { physical = true, remaining = 5, bonus = 1 },
        { physical = false, remaining = 5, bonus = 1.26 },
        { physical = false, remaining = 0.1, bonus = 1 },
    }) do
        enemy.dots =
            { [1] = { damage = 0, physical = sample.physical, remaining = sample.remaining } }
        unit.cd = 0
        local hp = enemy.hp
        G.Step(s, 0.25)
        assert(hp - enemy.hp == math.floor(unit.damage * 1.7 * sample.bonus))
    end
end)

case("Emergency healing uses the recipient's health and excludes fallen allies", function()
    local s, h, unit = traitEncounter("PALADIN", "Healing Hands")
    h.priority, h.healBelow = "heal", 100
    local ally = G.Copy(unit)
    ally.id, ally.hp, ally.maxHP, ally.cd, ally.attackCD = 2, 10, 10000, 100, 100
    s.heroes[2], s.battle.heroes[2] = G.Copy(h), ally
    local fallen = G.Copy(ally)
    fallen.id, fallen.hp = 3, 0
    s.heroes[3], s.battle.heroes[3] = G.Copy(h), fallen
    G.Step(s, 0.25)
    assert(ally.hp == 10 + math.floor(unit.healing * 1.28))
    assert(fallen.hp == 0)
end)

case("Outnumbered defense counts living participants rather than roster slots", function()
    local s, h, unit, enemy = traitEncounter("WARRIOR", "Defiant Rage")
    unit.cd, unit.attackCD = 100, 100
    local fallen = G.Copy(unit)
    fallen.id, fallen.hp = 2, 0
    s.heroes[2], s.battle.heroes[2] = G.Copy(h), fallen
    local other = G.Copy(enemy)
    other.id = 2
    s.battle.enemies[2] = other
    enemy.attackCD = 0
    local hp = unit.hp
    G.Step(s, 0.25)
    assert(hp - unit.hp == math.floor(enemy.damage * (1 - unit.mitigation) * 0.88))
    other.hp, enemy.attackCD = 0, 0
    hp = unit.hp
    G.Step(s, 0.25)
    assert(hp - unit.hp == math.floor(enemy.damage * (1 - unit.mitigation)))
end)

case("Shared magical-dot talents let each caster start its own burning-target synergies", function()
    for _, spec in ipairs({
        { "SHAMAN", "Flame Shock" },
        { "WARLOCK", "Agony" },
        { "PRIEST", "Misery" },
    }) do
        local state, _, unit, enemy = traitEncounter(spec[1], spec[2])
        local hp = enemy.hp
        G.Step(state, 0.25)
        local opening = hp - enemy.hp
        assert(enemy.dots[1] and not enemy.dots[1].physical)
        assert(enemy.dots[1].remaining == 6)
        unit.cd, unit.attackCD = 100, 100
        hp = enemy.hp
        G.Step(state, 1)
        assert(hp - enemy.hp == math.floor(unit.damage * 0.12))
        enemy.dots[1].damage, unit.cd = 0, 0
        hp = enemy.hp
        G.Step(state, 0.25)
        assert(hp - enemy.hp > opening)
    end
end)

case("Basic-attack momentum survives reload and starts on the third attack", function()
    local state, _, unit, enemy = traitEncounter("HUNTER", "Pack Tactics")
    unit.cd = 100
    for swing = 1, 3 do
        unit.attackCD = 0
        local hp = enemy.hp
        G.Step(state, 0.25)
        assert(hp - enemy.hp == math.floor(unit.damage * (swing == 3 and 1.22 or 1)))
        if swing == 2 then
            state = assert(G.Load(state, 1000))
            unit, enemy = state.battle.heroes[1], state.battle.enemies[1]
        end
    end
end)

case("Support defenses react to endangered living allies without counting the fallen", function()
    local state, h, unit, enemy = traitEncounter("PALADIN", "Shining Protector")
    unit.cd, unit.attackCD = 100, 100
    local ally = G.Copy(unit)
    ally.id, ally.hp, ally.cd, ally.attackCD = 2, 0, 100, 100
    state.heroes[2], state.battle.heroes[2] = G.Copy(h), ally
    for _, alive in ipairs({ false, true }) do
        ally.hp = alive and 1 or 0
        unit.hp, enemy.attackCD = unit.maxHP, 0
        local hp = unit.hp
        G.Step(state, 0.25)
        local expected = enemy.damage * (1 - unit.mitigation) * (alive and 0.88 or 1)
        assert(hp - unit.hp == math.floor(expected))
    end
end)

case("Full-health defense protects the opening hit without persisting after injury", function()
    local state, _, unit, enemy = traitEncounter("ROGUE", "Veiled Resilience")
    unit.cd, unit.attackCD = 100, 100
    for _, full in ipairs({ true, false }) do
        unit.hp, enemy.attackCD = full and unit.maxHP or unit.maxHP - 1, 0
        local hp = unit.hp
        G.Step(state, 0.25)
        assert(
            hp - unit.hp == math.floor(enemy.damage * (1 - unit.mitigation) * (full and 0.8 or 1))
        )
    end
end)

case(
    "Specialization damage-over-time talents supply their own synergy without another class",
    function()
        for _, entry in ipairs({
            { "HUNTER", "Barbed Shot", true },
            { "DRUID", "Rend and Tear", true },
            { "SHAMAN", "Hot Hand", false },
            { "WARLOCK", "From the Shadows", false },
            { "WARLOCK", "Infernal Combustion", false },
        }) do
            local state, _, unit, enemy = traitEncounter(entry[1], entry[2])
            G.Step(state, 0.25)
            assert(enemy.dots and next(enemy.dots), entry[2] .. " did not apply its damage effect")
            for _, dot in pairs(enemy.dots) do
                assert((dot.physical == true) == entry[3])
            end
            unit.cd, unit.attackCD = 100, 100
            local hp = enemy.hp
            G.Step(state, 0.25)
            assert(enemy.hp < hp)
        end
    end
)

case(
    "Previously complete builds retain their points and resume Mastery toward the new choices",
    function()
        local state, h = hero("WARRIOR")
        local experience = 0
        for rank = 0, 17 do
            experience = experience + G.MasteryCost(rank)
        end
        G.RewardMastery(h, 60, experience, false)
        assert(G.Points(h) == 48)
        for _, node in ipairs(G.TalentList(h)) do
            if node.row <= 8 then
                assert(G.Talent(state, 1, node.id))
            end
        end
        assert(G.Points(h) == 0)
        local loaded = assert(G.Load(G.Copy(state), 1000))
        h = loaded.heroes[1]
        assert(G.Points(h) == 0 and h.mastery.rank == 18)
        G.RewardMastery(h, 60, G.MasteryCost(h.mastery.rank), false)
        assert(G.Points(h) == 1 and h.mastery.rank == 19)
        assert(G.Talent(loaded, 1, "warrior_1_17"))
    end
)

return cases
